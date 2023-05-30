// SPDX-License-Identifier: MIT
/*
 * PLAK721.sol
 *
 * Author: Jack Kasbeer
 * Created: November 30, 2021
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PLAKStorage.sol";
import "./PLAKAccessControl.sol";
import "./LibPart.sol";


//@author Jack Kasbeer (git:@jcksber, tw:@satoshigoat)
contract PLAK721 is ERC721, PLAKAccessControl, PLAKStorage {

	using Counters for Counters.Counter;
	using SafeMath for uint256;

	event PaymentLinksAccessKeyMinted(uint256 indexed tid);
	event PaymentLinksAccessKeyBurned(uint256 indexed tid);
	
	constructor(string memory temp_name, string memory temp_symbol) 
		ERC721(temp_name, temp_symbol) {}

	// -----------
	// RESTRICTORS
	// -----------
	
	modifier onlyValidTokenId(uint256 tid)
	{
		require(1 <= tid && tid <= MAX_NUM_TOKENS, "PaymentLinksAccessKey: tid OOB");
		_;
	}

	// ------
	// ERC721 
	// ------

	//@dev All of the asset's will be pinned to IPFS
	function _baseURI() 
		internal view virtual override returns (string memory)
	{
		return "ipfs://";
	}

	//@dev This is here as a reminder to override for custom transfer functionality
	function _beforeTokenTransfer(address from, address to, uint256 tid) 
		internal virtual override 
	{ 
		super._beforeTokenTransfer(from, to, tid);
	}

	//@dev Allows owners to mint for free
    function mint(address to)
    	onlyOwner public virtual returns (uint256)
    {
    	_tokenIds.increment();

		uint256 newId = _tokenIds.current();
		_safeMint(to, newId);
		emit PaymentLinksAccessKeyMinted(newId);

		return newId;
    }

	//@dev Custom burn function - nothing special
	function burn(uint256 tid) 
		onlyOwner public virtual
	{
		_burn(tid);
		emit PaymentLinksAccessKeyBurned(tid);
	}

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

    // ----------------------
    // IPFS HASH MANIPULATION
    // ----------------------

	//@dev Allows us to update the IPFS hash values
	function updateHash(string memory newHash, string memory hashType) 
		onlyOwner public
	{
		require(_stringsEqual(hashType, "disabled") || 
				_stringsEqual(hashType, "standard") ||
				_stringsEqual(hashType, "legendary"), 
				"PLAK721: hashType must be 'disabled'/'standard'/'legendary'");

		if (_stringsEqual(hashType, "disabled")) {
			_disabledHash = newHash;
		} else if (_stringsEqual(hashType, "standard")) {
			_standardHash = newHash;
		} else {
			_legendaryHash = newHash;
		}
	}

	// -------------
	// CONTRACT LIFE
	// -------------

	//@dev Allows us to withdraw funds collected
	function withdraw(address payable wallet, uint256 amount)
		onlyOwner public
	{
		require(amount <= address(this).balance,
			"PLAK721: Insufficient funds to withdraw");
		wallet.transfer(amount);
	}

	//@dev Destroy contract and reclaim leftover funds
    function kill() onlyOwner public 
    {
        selfdestruct(payable(msg.sender));
    }

	//@dev Controls the contract-level metadata to include things like royalties
	function contractURI()
		public view returns(string memory)
	{
		return _contractUri;
	}

	//@dev Ability to change the contract URI
	function updateContractUri(string memory updatedContractUri) 
		onlyOwner public
	{
        _contractUri = updatedContractUri;
    }
	
    // -----------------
    // SECONDARY MARKETS
	// -----------------

	//@dev Rarible Royalties V2
    function getRaribleV2Royalties(uint256 tid) 
    	onlyValidTokenId(tid) external view returns (LibPart.Part[] memory) 
    {
        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
            account: payable(payoutAddress),
            value: uint96(royaltyFeeBps)
        });

        return royalties;
    }

    //@dev EIP-2981
    function royaltyInfo(uint256 tid, uint256 salePrice) external view onlyValidTokenId(tid) returns (address receiver, uint256 amount) {
        uint256 ourCut = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (payoutAddress, ourCut);
    }

    // -------
    // HELPERS
    // -------

    //@dev Returns the current token id (number minted so far)
	function getCurrentId() 
		public view returns (uint256)
	{
		return _tokenIds.current();
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
}