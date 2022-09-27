// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./NFT_Contract_V1.sol";

contract NFT_Contract_Factory_V1 {
	function create(
		string memory _name,
		string memory _symbol,
		string memory _baseURI,
		uint256 _cost,
		uint256 _freeLimit,
		uint256 _totalSupply,
		uint256 _perWalletLimit,
		bool _saleIsActive,
		bool _isPreSale,
		address paymentAddress,
		address _owner
	) external returns(address) {
		NFT_Contract_V1 newContract = new NFT_Contract_V1(_name, _symbol, _baseURI, _cost, _freeLimit, _totalSupply, _perWalletLimit, _saleIsActive, _isPreSale, payable(paymentAddress), _owner);

		return address(newContract);
	}
}