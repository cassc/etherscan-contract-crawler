// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./NFT_Contract_Lib_V1.sol";

contract NFT_Contract_V1 is NFT_Contract_Lib_V1 {
	constructor(
		string memory _name,
		string memory _symbol,
		string memory _baseURI,
		uint256 _cost,
		uint256 _freeLimit,
		uint256 _totalSupply,
		uint256 _perWalletLimit,
		bool _saleIsActive,
		bool _isPreSale,
		address payable _payments,
		address _owner
	) ERC721(_name, _symbol) public payable {
		baseURI = _baseURI;
		cost = _cost;
		freeLimit = _freeLimit;
		MAX_TOKENS = _totalSupply;
		perWalletLimit = _perWalletLimit;
		saleIsActive = _saleIsActive;
		isPreSale = _isPreSale;
		payments = _payments;
		transferOwnership(_owner);
	}
}