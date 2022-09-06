// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IGochugaru.sol";

contract FeesManager is Ownable, ERC1967Proxy {

    uint256 public buyBurnFee;
    uint256 public sellBurnFee;

    uint256 public buyDevFee;
    uint256 public sellDevFee;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    IGochugaru public gochugaruContract;
    address public gochugaruAddress;

	constructor(
		address _logic, 
		bytes memory _data
	) 
		payable 
		ERC1967Proxy(_logic, _data)
	{
		buyBurnFee = 4;
        sellBurnFee = 4;

        buyDevFee = 1;
        sellDevFee = 1;

        buyTotalFees = buyBurnFee + buyDevFee;
        sellTotalFees = sellBurnFee + sellDevFee;
	}

	function upgradeImplementation(address newImplementation) external onlyOwner {
		_upgradeTo(newImplementation);
	}
	
	function getImplementation() external view returns (address) {
		return _getImplementation();
	}
}