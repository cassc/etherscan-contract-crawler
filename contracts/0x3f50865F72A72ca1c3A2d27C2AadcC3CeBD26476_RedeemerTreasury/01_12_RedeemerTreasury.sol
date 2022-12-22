// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IRedeemersBookkeeper.sol";
import "./interfaces/IProtocolManager.sol";

/// @title Contract to migrate funds of Fed Member's Redeemer
/// @author Fluent Protocol - Development Team

contract RedeemerTreasury is Pausable, AccessControl {
    event RedeemerBalanceMigrated(
        address indexed oldRedeemer,
        address indexed newRedeemer,
        uint amount
    );

    int public constant Version = 3;

    address public fedMember;
    address public USPlusAddr;
    address public redeemersBookkeeper;
    address public ProtocolManager;

    constructor(
        address _fedMember,
        address _USPlusAddr,
        address _redeemersBookkeeper,
        address _ProtocolManager
    ) {
        require(_fedMember != address(0x0), "ZERO Addr is not allowed");
        require(_USPlusAddr != address(0x0), "ZERO Addr is not allowed");
        require(
            _redeemersBookkeeper != address(0x0),
            "ZERO Addr is not allowed"
        );
        require(_ProtocolManager != address(0x0), "ZERO Addr is not allowed");
        fedMember = _fedMember;
        USPlusAddr = _USPlusAddr;
        redeemersBookkeeper = _redeemersBookkeeper;
        ProtocolManager = _ProtocolManager;
    }

    error transferFailed(uint oldRedeemerBalance, uint newRedeemerBalance);

    function migrate(address oldRedeemer, address newRedeemer) external {
        require(
            IRedeemersBookkeeper(redeemersBookkeeper).getRedeemerStatus(
                newRedeemer
            ),
            "New Redeemer Not Active"
        );
        require(msg.sender == fedMember, "Caller is not the FedMember");
        require(
            _verifyRedeemerOwnership(oldRedeemer),
            "Caller is the Old Redeemer Admin"
        );
        uint totalAmountToTransfer = IERC20(USPlusAddr).balanceOf(oldRedeemer);

        emit RedeemerBalanceMigrated(
            oldRedeemer,
            newRedeemer,
            totalAmountToTransfer
        );

        require(
            IERC20(USPlusAddr).transferFrom(
                oldRedeemer,
                newRedeemer,
                totalAmountToTransfer
            ),
            "Transfer Failed"
        );

        uint _newRedeemerBalance = IERC20(USPlusAddr).balanceOf(newRedeemer);
        uint _oldRedeemerBalance = IERC20(USPlusAddr).balanceOf(oldRedeemer);

        if (
            _oldRedeemerBalance != 0 &&
            _newRedeemerBalance != totalAmountToTransfer
        ) {
            revert transferFailed({
                oldRedeemerBalance: _oldRedeemerBalance,
                newRedeemerBalance: _newRedeemerBalance
            });
        }
    }

    function _verifyRedeemerOwnership(
        address oldRedeemer
    ) internal view returns (bool verified) {
        address[] memory redeemers = IProtocolManager(ProtocolManager)
            .getRedeemers(fedMember);
        for (uint i = 0; i < redeemers.length; i++) {
            if (redeemers[i] == oldRedeemer) {
                verified = true;
                return verified;
            }
        }
    }
}