import { useState, useEffect, useCallback } from 'react'
import { useQuery, useMutation, useQueryClient } from 'react-query'
import { ethers } from 'ethers'
import { useAccount } from '@hyperverse/hyperverse-ethereum'
import { ContractABI, tenantAddress, contractAddress } from './Provider'

export const useTribes = () => {
  const [contract, setTribesContract] = useState(null)
  const queryClient = useQueryClient()
  const [{ data }] = useAccount()

  const setup = async () => {
    const signer = await data?.connector?.getSigner()
    const ctr = new ethers.Contract(contractAddress, ContractABI, signer)
    setTribesContract(ctr)
  }

  useEffect(() => {
    if (!data?.connector) {
      return
    }
    setup()
  }, [data?.connector])

  const checkInstance = useCallback(
    async (account) => {
      try {
        if (!contract) {
          return
        }
        const instance = await contract.instance(account)
        return instance
      } catch (err) {
        return false
      }
    },
    [contract],
  )

  const createInstance = useCallback(async () => {
    try {
      if (!contract) {
        return
      }
      const createTxn = await contract.createInstance()
      return createTxn.wait()
    } catch (err) {
      throw err
    }
  }, [contract])

  const addTribe = useCallback(
    async (metadata) => {
      try {
        if (!contract) {
          return
        }
        const addTxn = await contract.addNewTribe(metadata)
        return addTxn.wait()
      } catch (err) {
        throw err
      }
    },
    [contract],
  )

  const getTribeId = useCallback(
    async (account) => {
      if (!contract) {
        return
      }
      try {
        const id = await contract.getUserTribe(tenantAddress, account)
        return id.toNumber()
      } catch (err) {
        throw err
      }
    },
    [contract],
  )

  const getTribe = useCallback(
    async (id) => {
      try {
        if (!contract) {
          return
        }
        const userTribeTxn = await contract.getTribeData(tenantAddress, id)
        return userTribeTxn
      } catch (err) {
        throw err
      }
    },
    [contract],
  )

  const leaveTribe = useCallback(async () => {
    try {
      if (!contract) {
        return
      }
      const leaveTxn = await contract.leaveTribe(tenantAddress)
      await leaveTxn.wait()
      return leaveTxn.hash
    } catch (err) {
      throw err
    }
  }, [contract])

  const getAllTribes = useCallback(async () => {
    try {
      if (!contract) {
        return
      }
      const tribesData = await contract.totalTribes(tenantAddress)
      const tribes = []
      for (let i = 1; i <= tribesData.toNumber(); ++i) {
        // eslint-disable-next-line no-await-in-loop
        const txn = await contract.getTribeData(tenantAddress, i)
        tribes.push({
          id: i,
          txn: txn,
        })
      }
      return tribes
    } catch (err) {
      throw err
    }
  }, [contract])

  const joinTribe = useCallback(
    async (id) => {
      try {
        if (!contract) {
          return
        }
        const joinTxn = await contract.joinTribe(tenantAddress, id)
        return joinTxn.wait()
      } catch (err) {
        throw err
      }
    },
    [contract],
  )

  return {
    CheckInstance: () =>
      useQuery(
        ['checkInstance', data?.address, contract?.address],
        () => checkInstance(data?.address),
        {
          enabled: !!data?.address && !!contract?.address,
        },
      ),
    NewInstance: (options) => useMutation(createInstance, options),
    AddTribe: (options) =>
      useMutation((metadata) => addTribe(metadata), options),
    Tribes: () =>
      useQuery(['tribes', contract?.address], () => getAllTribes(), {
        enabled: !!contract?.address,
      }),
    Join: (options) => useMutation((id) => joinTribe(id), options),
    Leave: (options) =>
      useMutation(() => leaveTribe(), {
        ...options,
        onSuccess: (...args) => {
          queryClient.clear()
          const fn = options?.onSuccess
          if (fn) fn(...args)
        },
      }),
    TribeId: () =>
      useQuery(
        ['getTribeId', data?.address, contract?.address],
        () => getTribeId(data?.address),
        {
          enabled: !!data?.address && !!contract?.address,
          retry: false,
        },
      ),
    Tribe: () => {
      const { data: tribeId } = useQuery(
        ['getTribeId', data?.address, contract?.address],
        () => getTribeId(data?.address),
        { enabled: !!data?.address && !!contract?.address },
      )
      return useQuery(['getTribeData', tribeId], () => getTribe(tribeId), {
        enabled: !!tribeId,
      })
    },
  }
}

export default useTribes
