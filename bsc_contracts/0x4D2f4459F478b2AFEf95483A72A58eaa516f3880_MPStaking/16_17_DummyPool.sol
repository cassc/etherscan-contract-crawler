// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DummyPool is OwnableUpgradeable {
    address public controlContract;

    constructor(address _owner) initializer {
        __Ownable_init();
        transferOwnership(owner());
    }

    function doApprove(address _forTokenAtAddress) external { // Static assigning of approve, access control is irrelevant.
        IERC20Upgradeable(_forTokenAtAddress).approve(controlContract, type(uint256).max);
    }

    function emergencyWithdrawBNB() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function emergencyWithdrawToken(address _tokenAddress) external onlyOwner {
        IERC20Upgradeable(_tokenAddress).transfer(_msgSender(), IERC20Upgradeable(_tokenAddress).balanceOf(address(this)));
    }
}