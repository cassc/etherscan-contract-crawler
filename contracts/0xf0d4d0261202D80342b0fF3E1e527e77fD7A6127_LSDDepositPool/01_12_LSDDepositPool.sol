// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../LSDBase.sol";
import "../../interface/deposit/ILSDDepositPool.sol";
import "../../interface/owner/ILSDOwner.sol";
import "../../interface/token/ILSDTokenLSETH.sol";
import "../../interface/vault/ILSDLIDOVault.sol";
import "../../interface/vault/ILSDRPVault.sol";
import "../../interface/vault/ILSDSWISEVault.sol";
import "../../interface/ILSDVaultWithdrawer.sol";
import "../../interface/balance/ILSDUpdateBalance.sol";

// The main entry point for deposits into the LSD network.
// Accepts user deposits and mints lsETH; handles assignment of deposited ETH to various providers

contract LSDDepositPool is LSDBase, ILSDDepositPool, ILSDVaultWithdrawer {
    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

    // Modifiers
    modifier onlyThisContract() {
        // Compiler can optimise out this keccak at compile time
        require(
            address(this) ==
                getAddress(
                    keccak256(
                        abi.encodePacked("contract.address", "lsdDepositPool")
                    )
                ),
            "Invalid contract"
        );
        _;
    }

    // Construct
    constructor(ILSDStorage _lsdStorageAddress) LSDBase(_lsdStorageAddress) {
        version = 1;
    }

    // Receive a vault withdrawal
    // Only accepts calls from the Vault contract
    function receiveVaultWithdrawalETH()
        external
        payable
        override
    {}

    // Get current provider
    function getCurrentProvider() public view override returns (uint256) {
        ILSDOwner lsdOwner = ILSDOwner(getContractAddress("lsdOwner"));
        uint256 rpApy = lsdOwner.getRPApy();
        uint256 lidoApy = lsdOwner.getLIDOApy();
        uint256 swiseApy = lsdOwner.getSWISEApy();

        if (rpApy >= lidoApy && rpApy >= swiseApy) return 0;
        else if (lidoApy >= rpApy && lidoApy >= swiseApy) return 1;
        else return 2;
    }

    // Accept a deposit from a user
    function deposit() external payable override onlyThisContract {
        // Check deposit Settings
        ILSDOwner lsdOwner = ILSDOwner(getContractAddress("lsdOwner"));
        require(
            lsdOwner.getDepositEnabled(),
            "Deposit into LSD are currently disabled."
        );
        require(
            msg.value >= lsdOwner.getMinimumDepositAmount(),
            "The deposited amount is less than the minimum deposit size"
        );
        // Mint lsETH to user account
        ILSDTokenLSETH lsdTokenLsETH = ILSDTokenLSETH(
            getContractAddress("lsdTokenLSETH")
        );
        lsdTokenLsETH.mint(msg.value, msg.sender);
        // Emit deposit received event
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
        // Get the current provider
        // 0: RPL, 1: LIDO, 2: SWISE
        uint256 provider = getCurrentProvider();

        // Transfer ETH to the current Provider
        if (provider == 0) {
            // Rocket Pool
            ILSDRPVault lsdRPVault = ILSDRPVault(
                getContractAddress("lsdRPVault")
            );
            lsdRPVault.depositEther{value: msg.value}();
        } else if (provider == 1) {
            // LIDO
            ILSDLIDOVault lsdLIDOVault = ILSDLIDOVault(
                getContractAddress("lsdLIDOVault")
            );
            lsdLIDOVault.depositEther{value: msg.value}();
        } else {
            // Stake Wise
            ILSDSWISEVault lsdSWISEVault = ILSDSWISEVault(
                getContractAddress("lsdSWISEVault")
            );
            lsdSWISEVault.depositEther{value: msg.value}();
        }
    }

    // Get total withdrawal balance from the vault
    function getTotalCollateral() external view override returns (uint256) {
        uint256 currentProvider = getCurrentProvider();
        ILSDUpdateBalance lsdUpdateBalance = ILSDUpdateBalance(
            getContractAddress("lsdUpdateBalance")
        );
        if (currentProvider == 0) {
            return lsdUpdateBalance.getTotalETHInRP();
        } else if (currentProvider == 1) {
            return lsdUpdateBalance.getTotalETHInLIDO();
        } else {
            return lsdUpdateBalance.getTotalETHInSWISE();
        }
    }

    // Withdraw Ether from the vault
    function withdrawEther(uint256 _amount)
        public
        override
        onlyLSDContract("lsdTokenLSETH", msg.sender)
    {
        uint256 currentProvider = getCurrentProvider();
        if (currentProvider == 0) {
            ILSDRPVault lsdRPVault = ILSDRPVault(
                getContractAddress("lsdRPVault")
            );
            lsdRPVault.withdrawEther(_amount);
        } else if (currentProvider == 1) {
            ILSDLIDOVault lsdLIDOVault = ILSDLIDOVault(
                getContractAddress("lsdLIDOVault")
            );
            lsdLIDOVault.withdrawEther(_amount);
        } else {
            ILSDSWISEVault lsdSWISEVault = ILSDSWISEVault(
                getContractAddress("lsdSWISEVault")
            );
            lsdSWISEVault.withdrawEther(_amount);
        }
        payable(msg.sender).transfer(address(this).balance);     
    }
}