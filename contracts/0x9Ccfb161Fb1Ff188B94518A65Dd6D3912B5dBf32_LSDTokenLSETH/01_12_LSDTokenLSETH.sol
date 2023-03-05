// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../LSDBase.sol";
import "../../interface/token/ILSDTokenLSETH.sol";
import "../../interface/token/ILSDTokenVELSD.sol";
import "../../interface/deposit/ILSDDepositPool.sol";
import "../../interface/balance/ILSDUpdateBalance.sol";
import "../../interface/owner/ILSDOwner.sol";

// lsETH is a tokenised stake in the LSD network
// lsETH is backed by ETH (subject to liquidity) at a variable exchange rate

contract LSDTokenLSETH is LSDBase, ERC20, ILSDTokenLSETH {
    // Events
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);

    event TokensMinted(
        address indexed to,
        uint256 amount,
        uint256 ethAmount,
        uint256 time
    );
    event TokensBurned(
        address indexed from,
        uint256 amount,
        uint256 ethAmount,
        uint256 time
    );

    // Construct with our token details
    constructor(ILSDStorage _lsdStorageAddress)
        LSDBase(_lsdStorageAddress)
        ERC20("LSD ETH", "lsETH")
    {
        // Version
        version = 1;
    }

    // Receives an ETH deposit from generous individual
    receive() external payable {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Calculate the amount of ETH backing an amount of lsETH
    function getEthValue(uint256 _lsethAmount)
        public
        view
        override
        returns (uint256)
    {
        // Get balances
        ILSDUpdateBalance lsdUpdateBalance = ILSDUpdateBalance(
            getContractAddress("lsdUpdateBalance")
        );
        uint256 lsethSupply = totalSupply();
        uint256 virtualETHBalance = lsdUpdateBalance.getVirtualETHBalance();
        // Use 1:1 ratio if no lsETH is minted
        if (lsethSupply == 0) {
            return _lsethAmount;
        }
        // Calculate and return
        return (_lsethAmount * virtualETHBalance) / lsethSupply;
    }

    // Calculate the amount of lsETH backed by an amount of ETH
    function getLsethValue(uint256 _ethAmount)
        public
        view
        override
        returns (uint256)
    {
        // Get balances
        ILSDUpdateBalance lsdUpdateBalance = ILSDUpdateBalance(
            getContractAddress("lsdUpdateBalance")
        );
        uint256 lsethSupply = lsdUpdateBalance.getTotalLSETHSupply();
        uint256 virtualETHBalance = lsdUpdateBalance.getVirtualETHBalance();

        // Use 1:1 ratio if no lsETH is minted
        if (lsethSupply == 0) {
            return _ethAmount;
        }
        // Check ETH balance
        require(
            virtualETHBalance > 0,
            "Cannot calculate lsETH token amount while total network balance is zero"
        );
        // Calculate and return
        return (_ethAmount * lsethSupply) / virtualETHBalance;
    }

    // Get Multiplied amount
    function getMulipliedAmount(uint256 _amount)
        private
        view
        returns (uint256)
    {
        ILSDTokenVELSD lsdTokenVELSD = ILSDTokenVELSD(
            getContractAddress("lsdTokenVELSD")
        );
        uint256 veLSDBalance = lsdTokenVELSD.balanceOf(msg.sender);
        if (veLSDBalance == 0) {
            return _amount;
        }

        // Get Multiplier
        ILSDOwner lsdOwner = ILSDOwner(getContractAddress("lsdOwner"));
        uint256 multiplier = lsdOwner.getMultiplier();
        uint256 multiplierUnit = lsdOwner.getMultiplierUnit();
        return _amount + (_amount * multiplier) / multiplierUnit;
    }

    // Get the current ETH : lsETH exchange rate
    // Return the amount of ETH backing 1 lsETH
    function getExchangeRate() external view override returns (uint256) {
        return getEthValue(1 ether);
    }

    // Mint lsETH
    // Only accepts calls from the LSD contract
    function mint(uint256 _ethAmount, address _to)
        external
        override
        onlyLSDContract("lsdDepositPool", msg.sender)
    {
        // Get lsETH amount
        uint256 lsethAmount = getLsethValue(_ethAmount);
        // Check lsETH amount
        require(lsethAmount > 0, "Invalid token mint amount");
        // Update balance & supply
        _mint(_to, lsethAmount);

        ILSDUpdateBalance lsdUpdateBalance = ILSDUpdateBalance(
            getContractAddress("lsdUpdateBalance")
        );
        lsdUpdateBalance.addVirtualETHBalance(_ethAmount);
        // Emit tokens minted event
        emit TokensMinted(_to, lsethAmount, _ethAmount, block.timestamp);
    }

    // Burn lsETH for ETH
    function burn(uint256 _lsethAmount) external override {
        // Check lsETH amount
        require(_lsethAmount > 0, "Invalid token burn amount");
        require(
            balanceOf(msg.sender) >= _lsethAmount,
            "Insufficient lsETH balance"
        );

        // Get ETH amount
        uint256 ethAmount = getMulipliedAmount(getEthValue(_lsethAmount));
        // Get & Check ETH balance
        ILSDDepositPool lsdDepositPool = ILSDDepositPool(
            getContractAddress("lsdDepositPool")
        );
        uint256 ethBalance = lsdDepositPool.getTotalCollateral();
        require(
            ethBalance >= ethAmount,
            "Insufficient ETH balance for exchange"
        );
        // Update balance & supply
        _burn(msg.sender, _lsethAmount);
        // Withdraw ETH from deposit pool if required
        lsdDepositPool.withdrawEther(ethAmount);
        // Transfer ETH to sender
        payable(msg.sender).transfer(address(this).balance);
        ILSDUpdateBalance lsdUpdateBalance = ILSDUpdateBalance(
            getContractAddress("lsdUpdateBalance")
        );
        lsdUpdateBalance.subVirtualETHBalance(ethAmount);
        // Emit token burned event
        emit TokensBurned(msg.sender, _lsethAmount, ethAmount, block.timestamp);
    }

    // This is called by the ERC20 contract before all transfer, mint, and burns
    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal override {
        // Don't run check if this is a mint transaction
        if (from != address(0)) {
            // update the virtual ETH balance
            ILSDUpdateBalance lsdUpdateBalance = ILSDUpdateBalance(
                getContractAddress("lsdUpdateBalance")
            );
            lsdUpdateBalance.updateVirtualETHBalance();
        }
    }
}