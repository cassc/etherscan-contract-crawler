// SPDX-License-Identifier: Apache 2.0

/*

  Original work Copyright 2019 ZeroEx Intl.
  Modified work Copyright 2020-2022 Rigo Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.8.17;

import "./libs/LibSafeDowncast.sol";
import "./immutable/MixinStorage.sol";
import "./immutable/MixinConstants.sol";
import "./interfaces/IStorageInit.sol";
import "./interfaces/IStakingProxy.sol";

/// #dev The RigoBlock Staking contract.
contract StakingProxy is IStakingProxy, MixinStorage, MixinConstants {
    using LibSafeDowncast for uint256;

    /// @notice Constructor.
    /// @param stakingImplementation Address of the staking contract to delegate calls to.
    /// @param newOwner Address of the staking proxy owner.
    constructor(address stakingImplementation, address newOwner) Authorizable(newOwner) MixinStorage() {
        // Deployer address must be authorized in order to call `init`
        // in the context of deterministic deployment, the deployer factory (msg.sender) must be authorized.
        _addAuthorizedAddress(msg.sender);

        // Attach the staking contract and initialize state
        _attachStakingContract(stakingImplementation);

        // Remove the sender as an authorized address
        _removeAuthorizedAddressAtIndex(msg.sender, 0);
    }

    /* solhint-disable payable-fallback, no-complex-fallback */
    /// @notice Delegates calls to the staking contract, if it is set.
    fallback() external {
        // Sanity check that we have a staking contract to call
        address stakingContract_ = stakingContract;
        require(stakingContract_ != _NIL_ADDRESS, "STAKING_ADDRESS_NULL_ERROR");

        // Call the staking contract with the provided calldata.
        (bool success, bytes memory returnData) = stakingContract_.delegatecall(msg.data);

        // Revert on failure or return on success.
        assembly {
            switch success
            case 0 {
                revert(add(0x20, returnData), mload(returnData))
            }
            default {
                return(add(0x20, returnData), mload(returnData))
            }
        }
    }

    /* solhint-enable payable-fallback, no-complex-fallback */

    /// @inheritdoc IStakingProxy
    function attachStakingContract(address stakingImplementation) external override onlyAuthorized {
        _attachStakingContract(stakingImplementation);
    }

    /// @inheritdoc IStakingProxy
    function detachStakingContract() external override onlyAuthorized {
        stakingContract = _NIL_ADDRESS;
        emit StakingContractDetachedFromProxy();
    }

    /// @inheritdoc IStakingProxy
    function batchExecute(bytes[] calldata data) external returns (bytes[] memory batchReturnData) {
        // Initialize commonly used variables.
        bool success;
        bytes memory returnData;
        uint256 dataLength = data.length;
        batchReturnData = new bytes[](dataLength);
        address staking = stakingContract;

        // Ensure that a staking contract has been attached to the proxy.
        require(staking != _NIL_ADDRESS, "STAKING_ADDRESS_NULL_ERROR");

        // Execute all of the calls encoded in the provided calldata.
        for (uint256 i = 0; i != dataLength; i++) {
            // Call the staking contract with the provided calldata.
            (success, returnData) = staking.delegatecall(data[i]);

            // Revert on failure.
            if (!success) {
                assembly {
                    revert(add(0x20, returnData), mload(returnData))
                }
            }

            // Add the returndata to the batch returndata.
            batchReturnData[i] = returnData;
        }

        return batchReturnData;
    }

    /// @inheritdoc IStakingProxy
    function assertValidStorageParams() public view override {
        // Epoch length must be between 5 and 90 days long
        uint256 _epochDurationInSeconds = epochDurationInSeconds;
        require(
            _epochDurationInSeconds >= 5 days && _epochDurationInSeconds <= 90 days,
            "STAKING_PROXY_INVALID_EPOCH_DURATION_ERROR"
        );

        // Alpha must be 0 < x <= 1
        uint32 _cobbDouglasAlphaDenominator = cobbDouglasAlphaDenominator;
        require(
            cobbDouglasAlphaNumerator <= _cobbDouglasAlphaDenominator && _cobbDouglasAlphaDenominator != 0,
            "STAKING_PROXY_INVALID_COBB_DOUGLAS_ALPHA_ERROR"
        );

        // Weight of delegated stake must be <= 100%
        require(rewardDelegatedStakeWeight <= _PPM_DENOMINATOR, "STAKING_PROXY_INVALID_STAKE_WEIGHT_ERROR");

        // Minimum stake must be > 1
        require(minimumPoolStake >= 2, "STAKING_PROXY_INVALID_MINIMUM_STAKE_ERROR");
    }

    /// @dev Attach a staking contract; future calls will be delegated to the staking contract.
    /// @param stakingImplementation Address of staking contract.
    function _attachStakingContract(address stakingImplementation) internal {
        // Attach the staking contract
        stakingContract = stakingImplementation;
        emit StakingContractAttachedToProxy(stakingImplementation);

        // Call `init()` on the staking contract to initialize storage.
        (bool didInitSucceed, bytes memory initReturnData) = stakingContract.delegatecall(
            abi.encodeWithSelector(IStorageInit.init.selector)
        );

        if (!didInitSucceed) {
            assembly {
                revert(add(initReturnData, 0x20), mload(initReturnData))
            }
        }

        // Assert initialized storage values are valid
        assertValidStorageParams();
    }
}