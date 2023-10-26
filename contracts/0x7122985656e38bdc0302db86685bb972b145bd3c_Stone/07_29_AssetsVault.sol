// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract AssetsVault {
    address public stoneVault;
    address public strategyController;

    modifier onlyPermit() {
        require(
            stoneVault == msg.sender || strategyController == msg.sender,
            "not permit"
        );
        _;
    }

    constructor(address _stoneVault, address _strategyController) {
        require(
            _stoneVault != address(0) && _strategyController != address(0),
            "ZERO ADDRESS"
        );
        stoneVault = _stoneVault;
        strategyController = _strategyController;
    }

    function deposit() external payable {
        require(msg.value != 0, "too small");
    }

    function withdraw(address _to, uint256 _amount) external onlyPermit {
        TransferHelper.safeTransferETH(_to, _amount);
    }

    function setNewVault(address _vault) external onlyPermit {
        stoneVault = _vault;
    }

    function getBalance() external view returns (uint256 amount) {
        amount = address(this).balance;
    }

    receive() external payable {}
}