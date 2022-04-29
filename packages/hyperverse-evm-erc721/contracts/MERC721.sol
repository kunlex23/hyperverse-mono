// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './utils/Address.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract MERC721 is Context, ERC165, IERC721, IERC721Metadata {
	using Address for address;
	using Strings for uint256;

	/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ S T A T E @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
	// Token name
	string public name;

	// Token symbol
	string public symbol;

	bool public initialized;

	// Mapping from token ID to owner address
	mapping(uint256 => address) private _owners;

	// Mapping owner address to token count
	mapping(address => uint256) private _balances;

	// Mapping from token ID to approved address
	mapping(uint256 => address) private _tokenApprovals;

	// Mapping from owner to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ E V E N T S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

	/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ E R R O R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/
	error Unauthorized();
	error AlreadyInitialized();
	error ZeroAddress();
	error NonExistentToken();
	error SameAddress();
	error NonERC721Receiver();
	error TokenExists();
	error IncorrectOwner();

	/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ M O D I F I E R S @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

	modifier addressCheck(address _owner) {
		if (_owner == address(0)) {
			revert ZeroAddress();
		}
		_;
	}

	modifier checkToken(uint256 _tokenId) {
		if (!_exists(_tokenId)) {
			revert NonExistentToken();
		}
		_;
	}

	modifier approvedOrOwner(uint256 _tokenId) {
		if (!_isApprovedOrOwner(_msgSender(), _tokenId)) {
			revert Unauthorized();
		}
		_;
	}

	modifier checkERC721Reciever(address _from, address _to, uint256 _tokenId, bytes memory _data) {
			if (!_checkOnERC721Received(_from, _to, _tokenId, _data)) {
			revert NonERC721Receiver();
			}
			_;
		}

	/**
	 * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
	 */
	constructor() {}

	function merc721Init(string memory _name, string memory _symbol) internal {
		if (initialized) {
			revert AlreadyInitialized();
		}
		name = _name;
		symbol = _symbol;
		initialized = true;
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 _interfaceId)
		public
		view
		virtual
		override(ERC165, IERC165)
		returns (bool)
	{
		return
			_interfaceId == type(IERC721).interfaceId ||
			_interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(_interfaceId);
	}

	/**
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address _owner)
		public
		view
		virtual
		override
		addressCheck(_owner)
		returns (uint256)
	{
		return _balances[_owner];
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 _tokenId)
		public
		view
		virtual
		override
		addressCheck(_owners[_tokenId])
		returns (address)
	{
		address owner = _owners[_tokenId];
		return owner;
	}

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 */
	function tokenURI(uint256 _tokenId)
		public
		view
		virtual
		override
		checkToken(_tokenId)
		returns (string memory)
	{
		string memory baseURI = _baseURI();
		return
			bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : '';
	}

	/**
	 * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
	 * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
	 * by default, can be overriden in child contracts.
	 */
	function _baseURI() internal view virtual returns (string memory) {
		return '';
	}

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address _to, uint256 _tokenId) public virtual override addressCheck(_to) {
		address owner = MERC721.ownerOf(_tokenId);
		if (_to == owner) {
			revert SameAddress();
		}

		if (_msgSender() != owner || !isApprovedForAll(owner, _msgSender())) {
			revert Unauthorized();
		}

		_approve(_to, _tokenId);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 _tokenId)
		public
		view
		virtual
		override
		checkToken(_tokenId)
		returns (address)
	{
		return _tokenApprovals[_tokenId];
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address _operator, bool _approved) public virtual override {
		_setApprovalForAll(_msgSender(), _operator, _approved);
	}

	/**
	 * @dev See {IERC721-isApprovedForAll}.
	 */
	function isApprovedForAll(address _owner, address _operator)
		public
		view
		virtual
		override
		returns (bool)
	{
		return _operatorApprovals[_owner][_operator];
	}

	/**
	 * @dev See {IERC721-transferFrom}.
	 */
	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override approvedOrOwner(_tokenId) {
		//solhint-disable-next-line max-line-length
		_transfer(_from, _to, _tokenId);
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override {
		safeTransferFrom(_from, _to, _tokenId, '');
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) public virtual override approvedOrOwner(_tokenId) {
		_safeTransfer(_from, _to, _tokenId, _data);
	}

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
	 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
	 *
	 * `_data` is additional data, it has no specified format and it is sent in call to `to`.
	 *
	 * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
	 * implement alternative mechanisms to perform token transfer, such as signature-based.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeTransfer(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) internal checkERC721Reciever(_from, _to, _tokenId, _data) virtual {
		_transfer(_from, _to, _tokenId);

	}

	/**
	 * @dev Returns whether `tokenId` exists.
	 *
	 * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	 *
	 * Tokens start existing when they are minted (`_mint`),
	 * and stop existing when they are burned (`_burn`).
	 */
	function _exists(uint256 tokenId) internal view virtual returns (bool) {
		return _owners[tokenId] != address(0);
	}

	/**
	 * @dev Returns whether `spender` is allowed to manage `tokenId`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function _isApprovedOrOwner(address _spender, uint256 _tokenId)
		internal
		view
		virtual
		checkToken(_tokenId)
		returns (bool)
	{
		address owner = MERC721.ownerOf(_tokenId);
		return (_spender == owner ||
			getApproved(_tokenId) == _spender ||
			isApprovedForAll(owner, _spender));
	}

	/**
	 * @dev Safely mints `tokenId` and transfers it to `to`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeMint(address to, uint256 tokenId) internal virtual {
		_safeMint(to, tokenId, '');
	}

	/**
	 * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
	 * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
	 */
	function _safeMint(
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) internal checkERC721Reciever(address(0), _to, _tokenId, _data) virtual {
		_mint(_to, _tokenId);
	}

	/**
	 * @dev Mints `tokenId` and transfers it to `to`.
	 *
	 * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - `to` cannot be the zero address.
	 *
	 * Emits a {Transfer} event.
	 */
	function _mint(address _to, uint256 _tokenId) internal addressCheck(_to) checkToken(_tokenId) virtual {
		if(_exists(_tokenId)) {
			revert TokenExists();
		}

		_beforeTokenTransfer(address(0), _to, _tokenId);

		_balances[_to] += 1;
		_owners[_tokenId] = _to;

		emit Transfer(address(0), _to, _tokenId);

		_afterTokenTransfer(address(0), _to, _tokenId);
	}

	/**
	 * @dev Destroys `tokenId`.
	 * The approval is cleared when the token is burned.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 *
	 * Emits a {Transfer} event.
	 */
	function _burn(uint256 tokenId) internal virtual {
		address owner = MERC721.ownerOf(tokenId);

		_beforeTokenTransfer(owner, address(0), tokenId);

		// Clear approvals
		_approve(address(0), tokenId);

		_balances[owner] -= 1;
		delete _owners[tokenId];

		emit Transfer(owner, address(0), tokenId);

		_afterTokenTransfer(owner, address(0), tokenId);
	}

	/**
	 * @dev Transfers `tokenId` from `from` to `to`.
	 *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 *
	 * Emits a {Transfer} event.
	 */
	function _transfer(
		address _from,
		address _to,
		uint256 _tokenId
	) internal addressCheck(_to) virtual {
		if(MERC721.ownerOf(_tokenId) != _from) {
			revert IncorrectOwner();
		}
	
		_beforeTokenTransfer(_from, _to, _tokenId);

		// Clear approvals from the previous owner
		_approve(address(0), _tokenId);

		_balances[_from] -= 1;
		_balances[_to] += 1;
		_owners[_tokenId] = _to;

		emit Transfer(_from, _to, _tokenId);

		_afterTokenTransfer(_from, _to, _tokenId);
	}

	/**
	 * @dev Approve `to` to operate on `tokenId`
	 *
	 * Emits a {Approval} event.
	 */
	function _approve(address to, uint256 tokenId) internal virtual {
		_tokenApprovals[tokenId] = to;
		emit Approval(MERC721.ownerOf(tokenId), to, tokenId);
	}

	/**
	 * @dev Approve `operator` to operate on all of `owner` tokens
	 *
	 * Emits a {ApprovalForAll} event.
	 */
	function _setApprovalForAll(
		address _owner,
		address _operator,
		bool approved
	) internal addressCheck(_operator) addressCheck(_owner) virtual {
		if(_owner == _operator) {
			revert SameAddress();
		}
		_operatorApprovals[_owner][_operator] = approved;
		emit ApprovalForAll(_owner, _operator, approved);
	}

	/**
	 * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
	 * The call is not executed if the target address is not a contract.
	 *
	 * @param from address representing the previous owner of the given token ID
	 * @param to target address that will receive the tokens
	 * @param tokenId uint256 ID of the token to be transferred
	 * @param _data bytes optional data to send along with the call
	 * @return bool whether the call correctly returned the expected magic value
	 */
	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) private returns (bool) {
		if (to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (
				bytes4 retval
			) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert NonERC721Receiver();
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting
	 * and burning.
	 *
	 * Calling conditions:
	 *
	 * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
	 * transferred to `to`.
	 * - When `from` is zero, `tokenId` will be minted for `to`.
	 * - When `to` is zero, ``from``'s `tokenId` will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {}

	/**
	 * @dev Hook that is called after any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {}
}
