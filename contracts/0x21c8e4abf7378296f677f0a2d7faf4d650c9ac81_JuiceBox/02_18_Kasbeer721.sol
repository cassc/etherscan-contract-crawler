// SPDX-License-Identifier: MIT
/*
 * Kasbeer721.sol
 *
 * Created: October 27, 2021
 *
 * Tuned-up ERC721 that covers a multitude of features that are generally useful
 * so that it can be easily extended for quick customization .
 */

pragma solidity >=0.5.16 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./access/Whitelistable.sol";
import "./access/Pausable.sol";
import "./utils/LibPart.sol";


//@title Kasbeer721 - Beefed up ERC721
//@author Jack Kasbeer (git:@jcksber, tw:@satoshigoat, ig:overprivilegd)
contract Kasbeer721 is ERC721, Whitelistable, Pausable {

	using SafeMath for uint256;
	using Counters for Counters.Counter;

	// -------------
	// EVENTS & VARS
	// -------------

	event Kasbeer721Minted(uint256 indexed tokenId);
	event Kasbeer721Burned(uint256 indexed tokenId);

    //@dev Token incrementing
	Counters.Counter internal _tokenIds;

	//@dev Important numbers
	uint constant NUM_ASSETS = 4;//4 juice box variations
	uint constant MAX_NUM_TOKENS = 413;//nomad+chi+st.l dream chasers

	//@dev Properties
	string internal _contractUri;
	address public payoutAddress;

	//@dev These are needed for contract compatability
	uint256 constant public royaltyFeeBps = 1000; // 10%
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 internal constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    bytes4 internal constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;

	constructor(string memory temp_name, string memory temp_symbol) 
		ERC721(temp_name, temp_symbol) {}

	// ---------
	// MODIFIERS
	// ---------

	modifier hashIndexInRange(uint8 idx)
	{
		require(0 <= idx && idx < NUM_ASSETS, "Kasbeer721: index OOB");
		_;
	}
	
	modifier onlyValidTokenId(uint256 tokenId)
	{
		require(1 <= tokenId && tokenId <= MAX_NUM_TOKENS, "Kasbeer721: tokenId OOB");
		_;
	}

	// ----------
	// MAIN LOGIC
	// ----------

	//@dev All of the asset's will be pinned to IPFS
	function _baseURI() 
		internal view virtual override returns (string memory)
	{
		return "ipfs://";
	}

	//@dev This is here as a reminder to override for custom transfer functionality
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
		internal virtual override 
	{ 
		super._beforeTokenTransfer(from, to, tokenId);
	}

	//@dev Allows owners to mint for free
    function mint(address to) public virtual isSquad returns (uint256)
    {
    	_tokenIds.increment();

		uint256 newId = _tokenIds.current();
		_safeMint(to, newId);
		emit Kasbeer721Minted(newId);

		return newId;
    }

	//@dev Custom burn function - nothing special
	function burn(uint256 tokenId) public virtual
	{
		require(
			isInSquad(_msgSender()) || 
			_msgSender() == ownerOf(tokenId), 
			"Kasbeer721: not owner or in squad."
		);

		_burn(tokenId);
		emit Kasbeer721Burned(tokenId);
	}

    //// --------
	//// CONTRACT
	//// --------

	//@dev Controls the contract-level metadata to include things like royalties
	function contractURI() public view returns(string memory)
	{
		return _contractUri;
	}

	//@dev Ability to change the contract URI
	function updateContractUri(string memory updatedContractUri) public isSquad
	{
        _contractUri = updatedContractUri;
    }

    //@dev Allows us to withdraw funds collected
	function withdraw(address payable wallet, uint256 amount) public isSquad
	{
		require(amount <= address(this).balance,
			"Kasbeer721: Insufficient funds to withdraw");
		wallet.transfer(amount);
	}

	//@dev Destroy contract and reclaim leftover funds
    function kill() public onlyOwner 
    {
        selfdestruct(payable(_msgSender()));
    }
	
    // -------
    // HELPERS
    // -------

    //@dev Returns the current token id (number minted so far)
	function getCurrentId() public view returns (uint256)
	{
		return _tokenIds.current();
	}

	//@dev Increments `_tokenIds` by 1
	function _incrementTokenId() internal 
	{
		_tokenIds.increment();
	}

	//@dev Determine if two strings are equal using the length + hash method
	function _stringsEqual(string memory a, string memory b) 
		internal pure returns (bool)
	{
		bytes memory A = bytes(a);
		bytes memory B = bytes(b);

		if (A.length != B.length) {
			return false;
		} else {
			return keccak256(A) == keccak256(B);
		}
	}

	//@dev Determine if an address is a smart contract 
	function _isContract(address a) internal view returns (bool)
	{
		uint32 size;
		assembly {
			size := extcodesize(a)
		}
		return size > 0;
	}

	// -----------------
    // SECONDARY MARKETS
	// -----------------

	//@dev Rarible Royalties V2
    function getRaribleV2Royalties(uint256 id) 
    	onlyValidTokenId(id) external view returns (LibPart.Part[] memory) 
    {
        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
            account: payable(payoutAddress),
            value: uint96(royaltyFeeBps)
        });

        return royalties;
    }

    //@dev EIP-2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view onlyValidTokenId(tokenId) returns (address receiver, uint256 amount) {
        uint256 ourCut = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (payoutAddress, ourCut);
    }

    // -----------------
    // INTERFACE SUPPORT
    // -----------------

    //@dev Confirm that this contract is compatible w/ these interfaces
    function supportsInterface(bytes4 interfaceId) 
		public view virtual override returns (bool)
	{
		return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == _INTERFACE_ID_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
	}
}