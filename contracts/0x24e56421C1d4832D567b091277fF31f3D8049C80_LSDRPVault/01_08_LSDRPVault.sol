// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../LSDBase.sol";
import "../../interface/vault/ILSDRPVault.sol";
import "../../interface/ILSDVaultWithdrawer.sol";
import "../../interface/utils/rpl/IRocketDepositPool.sol";
import "../../interface/utils/rpl/IRocketTokenRETH.sol";

contract LSDRPVault is LSDBase, ILSDRPVault {
    // Events
    event EtherDeposited(string indexed by, uint256 amount, uint256 time);
    event EtherWithdrawn(string indexed by, uint256 amount, uint256 time);

    // Construct
    constructor(ILSDStorage _lsdStorageAddress) LSDBase(_lsdStorageAddress) {
        // Version
        version = 1;
    }

    receive() external payable {

    }
    // Accept an ETH deposit from a LSD contract
    // Only accepts calls from LSD contracts.
    function depositEther()
        public
        payable
        override
        onlyLSDContract("lsdDepositPool", msg.sender)
    {
        // Valid amount?
        require(msg.value > 0, "No valid amount of ETH given to deposit");
        // Emit ether deposited event
        emit EtherDeposited("LSDDepositPool", msg.value, block.timestamp);
        _processDeposit();
    }

    function _processDeposit() private {
        IRocketDepositPool rocketDepositPool = IRocketDepositPool(
            getContractAddress("rocketDepositPool")
        );
        rocketDepositPool.deposit{value: msg.value}();
    }

    function getBalanceOfRocketToken() public view override returns (uint256) {
        IRocketTokenRETH rocketTokenRETH = IRocketTokenRETH(
            getContractAddress("rocketTokenRETH")
        );
        return rocketTokenRETH.balanceOf(address(this));
    }

    function getETHBalance() public view override returns (uint256) {
        IRocketTokenRETH rocketTokenRETH = IRocketTokenRETH(
            getContractAddress("rocketTokenRETH")
        );
        return rocketTokenRETH.getEthValue(getBalanceOfRocketToken());
    }

    function withdrawEther(uint256 _ethAmount)
        public
        override
        onlyLSDContract("lsdDepositPool", msg.sender)
    {
        require(_ethAmount <= getETHBalance(), "Invalid Amount");
        IRocketTokenRETH rocketTokenRETH = IRocketTokenRETH(
            getContractAddress("rocketTokenRETH")
        );

        uint256 rethAmount = rocketTokenRETH.getRethValue(_ethAmount);
        rocketTokenRETH.burn(rethAmount);
        // Withdraw
        ILSDVaultWithdrawer withdrawer = ILSDVaultWithdrawer(msg.sender);
        withdrawer.receiveVaultWithdrawalETH{value: address(this).balance}();

        // Emit ether withdrawn event
        emit EtherWithdrawn("LSDDepositPool", _ethAmount, block.timestamp);
    }
}