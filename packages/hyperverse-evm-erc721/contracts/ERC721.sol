// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './MERC721.sol';
import './utils/SafeMath.sol';
import './hyperverse/IHyperverseModule.sol';
import './hyperverse/Initializable.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is MERC721, Initializable {
	uint256 public tokenCounter;

	// Account used to deploy contract
	address public immutable contractOwner;

	//stores the tenant owner
	address private tenantOwner;

	// Have to put ERC721 here to truly inherit this contract
	// _safeMint only available `internal`ly which is
	// only possible if we call the constructor like this
	constructor() {
		contractOwner = msg.sender;
	}

	function initialize(
		string memory name_,
		string memory symbol_,
		address _tenant
	) external initializer {
		merc721Init(name_, symbol_);
		tenantOwner = _tenant;
		tokenCounter = 0;
	}

	function createNFT(address to) public returns (uint256) {
		require(msg.sender == tenantOwner, 'Only the Tenant owner can mint an NFT');

		uint256 newNFTTokenId = tokenCounter;
		//safely mint token for the person that called the function
		_safeMint(to, newNFTTokenId);
		//set the token uri of the token id of the uri passed
		tokenURI(newNFTTokenId);
		//increment the counter
		tokenCounter = tokenCounter + 1;
		//return the token id
		return newNFTTokenId;
	}
}
