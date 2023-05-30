// SPDX-License-Identifier: MIT
/*
 * PLAKStorage.sol
 *
 * Author: Jack Kasbeer
 * Created: November 30, 2021
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

//@title A storage contract for relevant data
//@author Jack Kasbeer (@jcksber, @satoshigoat)
contract PLAKStorage {

	//@dev These take care of token id incrementing
	using Counters for Counters.Counter;
	Counters.Counter internal _tokenIds;

	//@dev These are needed for contract compatability
	uint256 constant public royaltyFeeBps = 500; // 5%
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 internal constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    bytes4 internal constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;

	//@dev Supply
	uint constant MAX_NUM_TOKENS = 300;

	//@dev Properties
	string internal _contractUri;
	address public payoutAddress;
	uint public weiPrice;

	//@dev Initial production hashes
	string internal _standardHash = "QmTFfVfvuZPkzeueZP9kxXTwpcHVjyzBqgLf6jF5Z8XeDb";
	string internal _disabledHash = "QmPWcbjegFCeRqujWf22Hu5cGGWzT46yzBtRSxQdT4E3pL";
	string internal _legendaryHash = "QmTZ6AWRBXoBZBH24NbkKusyJAN6oqznB5VsZUUFHFyMZG";
}