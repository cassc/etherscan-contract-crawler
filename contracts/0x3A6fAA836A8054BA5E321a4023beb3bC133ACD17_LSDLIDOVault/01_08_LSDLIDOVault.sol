// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../LSDBase.sol";
import "../../interface/vault/ILSDLIDOVault.sol";
import "../../interface/utils/lido/ILido.sol";
import "../../interface/ILSDVaultWithdrawer.sol";

import "../../interface/utils/uniswap/IUniswapV2Router02.sol";

contract LSDLIDOVault is LSDBase, ILSDLIDOVault {
    // Events
    event EtherDeposited(string indexed by, uint256 amount, uint256 time);
    event EtherWithdrawn(string indexed by, uint256 amount, uint256 time);

    // Construct
    constructor(ILSDStorage _lsdStorageAddress) LSDBase(_lsdStorageAddress) {
        // Version
        version = 1;
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
        processDeposit();
    }

    function processDeposit() private {
        ILido lido = ILido(getContractAddress("lido"));
        lido.submit{value: msg.value}(address(this));
    }

    function getETHBalance() public view override returns (uint256) {
        ILido lido = ILido(getContractAddress("lido"));
        return lido.balanceOf(address(this));
    }

    function getSharesOfStETH(uint256 _ethAmount)
        public
        view
        override
        returns (uint256)
    {
        ILido lido = ILido(getContractAddress("lido"));
        return lido.getSharesByPooledEth(_ethAmount);
    }

    function withdrawEther(uint256 _ethAmount)
        public
        override
        onlyLSDContract("lsdDepositPool", msg.sender)
    {
        require(_ethAmount <= getETHBalance(), "Invalid Amount");

        // Calls Uniswap Functions
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(
            getContractAddress("uniswapRouter")
        );

        address[] memory path;
        path = new address[](2);
        path[0] = getContractAddress("lido");
        path[1] = getContractAddress("weth");

        uint256[] memory amounts = uniswapRouter.getAmountsIn(_ethAmount, path);

        ILido lido = ILido(getContractAddress("lido"));
        lido.approve(getContractAddress("uniswapRouter"), amounts[0]);

        require(amounts[0] <= lido.sharesOf(address(this)), "Invalid Exchange");

        uniswapRouter.swapTokensForExactETH(
            _ethAmount,
            amounts[0],
            path,
            address(this),
            block.timestamp
        );

        // Withdraw
        ILSDVaultWithdrawer withdrawer = ILSDVaultWithdrawer(msg.sender);
        withdrawer.receiveVaultWithdrawalETH{value: address(this).balance}();
        // Emit ether withdrawn event
        emit EtherWithdrawn("LSDDepositPool", _ethAmount, block.timestamp);
    }
}