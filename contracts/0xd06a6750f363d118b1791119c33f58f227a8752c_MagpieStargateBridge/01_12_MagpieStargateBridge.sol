// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import {Ownable} from "openzeppelin-solidity/contracts/access/Ownable.sol";
import {IMagpieStargateBridge} from "./interfaces/IMagpieStargateBridge.sol";
import {IStargateRouter} from "./interfaces/stargate/IStargateRouter.sol";
import {LibAsset} from "./libraries/LibAsset.sol";
import {LibTransferKey, TransferKey} from "./libraries/LibTransferKey.sol";

error StargateBridgeIsNotReady();

contract MagpieStargateBridge is IMagpieStargateBridge, Ownable {
    using LibAsset for address;

    Settings public settings;
    mapping(uint16 => mapping(bytes32 => mapping(uint64 => mapping(address => uint256)))) public deposits;

    modifier onlyMagpieAggregator() {
        require(msg.sender == settings.aggregatorAddress);
        _;
    }

    modifier onlyStargate() {
        require(msg.sender == settings.routerAddress);
        _;
    }

    function updateSettings(Settings calldata _settings) external onlyOwner {
        settings = _settings;
    }

    function withdraw(WithdrawArgs calldata withdrawArgs) external onlyMagpieAggregator returns (uint256 amount) {
        amount = deposits[withdrawArgs.transferKey.networkId][withdrawArgs.transferKey.senderAddress][
            withdrawArgs.transferKey.swapSequence
        ][withdrawArgs.assetAddress];

        if (amount == 0) {
            IStargateRouter(settings.routerAddress).clearCachedSwap(
                withdrawArgs.srcChainId,
                withdrawArgs.srcAddress,
                withdrawArgs.nonce
            );
        }

        amount = deposits[withdrawArgs.transferKey.networkId][withdrawArgs.transferKey.senderAddress][
            withdrawArgs.transferKey.swapSequence
        ][withdrawArgs.assetAddress];

        if (amount == 0) {
            revert StargateBridgeIsNotReady();
        }

        deposits[withdrawArgs.transferKey.networkId][withdrawArgs.transferKey.senderAddress][
            withdrawArgs.transferKey.swapSequence
        ][withdrawArgs.assetAddress] = 0;

        withdrawArgs.assetAddress.transfer(settings.aggregatorAddress, amount);
    }

    function sgReceive(
        uint16,
        bytes calldata,
        uint256,
        address assetAddress,
        uint256 amount,
        bytes calldata payload
    ) external override onlyStargate {
        TransferKey memory transferKey = LibTransferKey.decode(payload);
        deposits[transferKey.networkId][transferKey.senderAddress][transferKey.swapSequence][assetAddress] += amount;
    }
}