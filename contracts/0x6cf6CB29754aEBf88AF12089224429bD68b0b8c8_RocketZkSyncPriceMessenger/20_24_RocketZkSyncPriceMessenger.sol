// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@matterlabs/zksync-era/ethereum/contracts/zksync/interfaces/IZkSync.sol";

import "rocketpool/contracts/interface/network/RocketNetworkBalancesInterface.sol";
import "rocketpool/contracts/interface/RocketStorageInterface.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Retrieves the rETH exchange rate from Rocket Pool and submits it to the oracle contract on Polygon
contract RocketZkSyncPriceMessenger {
    // Immutables
    RocketStorageInterface immutable rocketStorage;
    bytes32 immutable rocketNetworkBalancesKey;
    /// @notice Target address of the oracle contract on L2
    address public l2Target;

    /// @notice The ZkSync contract which handles L1->L2 transactions
    IZkSync public immutable zksync;

    /// @notice The most recently submitted rate
    uint256 lastRate;

    constructor(RocketStorageInterface _rocketStorage, address _zkSyncAddress) {
        rocketStorage = _rocketStorage;
        zksync = IZkSync(_zkSyncAddress);
        // Precompute storage key for RocketNetworkBalances address
        rocketNetworkBalancesKey = keccak256(abi.encodePacked("contract.address", "rocketNetworkBalances"));
    }

    /// @notice Sets the L2 oracle contract address
    function updateL2Target(address _l2Target) public {
        require(l2Target == address(0));
        l2Target = _l2Target;
    }

    /// @notice Returns whether the rate has changed since it was last submitted
    function rateStale() external view returns (bool) {
        return rate() != lastRate;
    }

    /// @notice Returns the calculated rETH exchange rate
    function rate() public view returns (uint256) {
        // Retrieve the inputs from RocketNetworkBalances and calculate the rate
        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(rocketStorage.getAddress(rocketNetworkBalancesKey));
        uint256 supply = rocketNetworkBalances.getTotalRETHSupply();
        if (supply == 0) {
            return 0;
        }
        return 1 ether * rocketNetworkBalances.getTotalETHBalance() / supply;
    }

    /// @notice Submits the current rETH exchange rate to the ZkSync cross domain messenger contract
    /// @param _l2GasLimit The gas limit for the L2 tx
    /// @param _l2GasPerPubdataByteLimit The L2 gas price per each published to L1 calldata byte
    function submitRate(uint256 _l2GasLimit, uint256 _l2GasPerPubdataByteLimit) external payable {
        lastRate = rate();
        // Send the cross chain message
        uint256 value = zksync.l2TransactionBaseCost(tx.gasprice, _l2GasLimit, _l2GasPerPubdataByteLimit);
        bytes memory data = abi.encodeWithSignature('updateRate(uint256)', lastRate);
        zksync.requestL2Transaction{value : value}(
            l2Target,                       // Target address
            0,                              // Call value
            data,                           // Call data
            _l2GasLimit,                    // L2 gas limit
            _l2GasPerPubdataByteLimit,      // L2 gas per pubdata byte limit
            new bytes[](0),                 // Factory deps
            msg.sender                      // Refund address
        );
        // Refund overfunded value
        if(address(this).balance > 0){
            (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
            require(success);
        }
    }
}