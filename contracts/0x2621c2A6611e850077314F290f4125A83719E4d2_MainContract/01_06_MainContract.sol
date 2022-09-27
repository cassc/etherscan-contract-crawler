// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ProxyStorage.sol";

interface INFTContractFactory {
	function create(
		string memory _name,
		string memory _symbol,
		string memory _baseURI,
		uint256 _cost,
		uint256 _freeLimit,
		uint256 _totalSupply,
		uint256 _maxTokenPurchase,
		bool _saleIsActive,
		bool _isPreSale,
		address paymentAddress,
		address _owner
	) external returns(address);
}

contract MainContract is ProxyStorage, Ownable {
	using SafeMath for uint256;
	using Strings for uint256;
	uint256 public cost = 0;
	address payable private bankAddress;

	struct InformationStruct {
		address paymentAddress;
		address contractAddress;
		address factoryAddress;
	}

	mapping(address => InformationStruct[]) public contracts;

	constructor(address _bankAddress) public {
		bankAddress = payable(_bankAddress);
		transferOwnership(msg.sender);
	}

	function setBankAddress(address _bankAddress) public onlyOwner {
		bankAddress = payable(_bankAddress);
	}

	function setCost(uint256 _cost) public onlyOwner {
		cost = _cost;
	}

	function createContract(
		string memory _name,
		string memory _symbol,
		string memory _baseURI,
		uint256 _cost,
		uint256 _freeLimit,
		uint256 _totalSupply,
		uint256 _maxTokenPurchase,
		bool _saleIsActive,
		bool _isPreSale,
		address _payment,
		address _nftFactoryAddress
	) external payable returns(address) {
		require(msg.value == cost, "Payment not enough!");
		payable(bankAddress).transfer(msg.value);
		address contractAddress = INFTContractFactory(_nftFactoryAddress).create(_name, _symbol, _baseURI, _cost, _freeLimit, _totalSupply, _maxTokenPurchase, _saleIsActive, _isPreSale, _payment, msg.sender);
		InformationStruct memory information = InformationStruct({
			paymentAddress: _payment,
			contractAddress: contractAddress,
			factoryAddress: _nftFactoryAddress
		});
		contracts[msg.sender].push(information);

		return contractAddress;
	}

	function getContractsCount() external view returns(uint count) {
		return contracts[msg.sender].length;
	}
}