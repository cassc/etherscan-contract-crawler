// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./utils/ReentrancyGuard.sol";
import "./access/Pausable.sol";

error DataError(string msg);

contract Satoshigoat is ERC721A, Pausable, ReentrancyGuard {
	
	//@dev Sale Data
	uint256 public constant MAX_NUM_TOKENS = 1000;//=> ~800 in the vault
	uint256 constant public royaltyFeeBps = 1000;//10%

	//@dev Properties
	string internal _contractURI;//*set in parent
	string internal _baseTokenURI;//*passed thru parent constructo
	address public payoutAddress;//*set in parent
	address public _owner;//*set in parent
	uint256 public purchasePrice;//*set in parent

	// -----------
	// RESTRICTORS
	// -----------

	modifier onlyValidTokenID(uint256 tid) {
		if (tid < 0 || tid >= MAX_NUM_TOKENS)
			revert DataError("tid OOB");
		_;
	}

	modifier notEqual(string memory str1, string memory str2) {
		if(_stringsEqual(str1, str2))
			revert DataError("strings must be different");
		_;
	}

	modifier enoughSupply(uint256 qty) {
		if (totalSupply() + qty > MAX_NUM_TOKENS)
			revert DataError("not enough left");
		_;
	}

	modifier purchaseArgsOK(address to, uint256 qty, uint256 amount) {
		if (amount < purchasePrice*qty)
            revert DataError("insufficient funds");
		if (_isContract(to))
			revert DataError("silly rabbit :P");
		_;
	}

	// ----
	// CORE
	// ----
	
    constructor(
    	string memory name_,
    	string memory symbol_,
    	string memory baseTokenURI
    ) 
    	ERC721A(name_, symbol_)
    {
    	_baseTokenURI = baseTokenURI;
    	_contractURI = "";
    }

    //@dev See {ERC721A-_baseURI}
	function _baseURI() internal view virtual override returns (string memory)
	{
		return _baseTokenURI;
	}

	//@dev Controls the contract-level metadata
	function contractURI() external view returns (string memory)
	{
		return _contractURI;
	}

    //@dev Allows us to withdraw funds collected
    function withdraw(address payable wallet, uint256 amount) 
        external isSquad nonReentrant
    {
        if (amount > address(this).balance)
            revert DataError("insufficient funds to withdraw");
        wallet.transfer(amount);
    }

    //@dev Ability to change _baseTokenURI
	function setBaseTokenURI(string calldata newBaseURI) 
		external isSquad notEqual(_baseTokenURI, newBaseURI) { _baseTokenURI = newBaseURI; }

	//@dev Ability to change the contract URI
	function setContractURI(string calldata newContractURI) 
		external isSquad notEqual(_contractURI, newContractURI) { _contractURI = newContractURI; }

	//@dev Ability to change the purchase/mint price
	function setPurchasePrice(uint256 newPriceInWei) external isSquad 
	{ 
		if (purchasePrice == newPriceInWei)
			revert DataError("prices can't be the same");
		purchasePrice = newPriceInWei;
	}

	// -------
	// HELPERS
	// -------

	//@dev Gives us access to the otw internal function `_numberMinted`
	function numberMinted(address owner) public view returns (uint256) 
	{
		return _numberMinted(owner);
	}

	//@dev Determine if two strings are equal using the length + hash method
	function _stringsEqual(string memory a, string memory b) 
		internal pure returns (bool)
	{
		bytes memory A = bytes(a);
		bytes memory B = bytes(b);

		if (A.length != B.length)
			return false;
		else
			return keccak256(A) == keccak256(B);
	}

	//@dev Determine if an address is a smart contract 
	function _isContract(address a) internal view returns (bool)
	{
		// This method relies on `extcodesize`, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
		uint32 size;
		assembly {
			size := extcodesize(a)
		}
		return size > 0;
	}
}