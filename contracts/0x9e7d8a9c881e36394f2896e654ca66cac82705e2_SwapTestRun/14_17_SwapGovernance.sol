// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SwapSetters.sol";

contract SwapGovernance is SwapSetters  {

    function updateFeePercent(uint256 _feePercent) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_feePercent <= 500000, "Key Pair:  Fee can't be more than 50% on one side.");
        FEE_PERCENT = _feePercent;
    }

    function updateFeeCollector(address _feeCollector) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not a admin");
        require(_feeCollector != address(0), "Key Pair: Fee Collector Invalid");
        FEE_COLLECTOR = _feeCollector;
    }
}