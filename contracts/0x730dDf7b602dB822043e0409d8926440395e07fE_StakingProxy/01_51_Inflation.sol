// SPDX-License-Identifier: Apache 2.0

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020 Rigo Intl.

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

// solhint-disable-next-line
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import { SafeMath } from "../../utils/SafeMath/SafeMath.sol";
import { InflationFace } from "./InflationFace.sol";
import { RigoTokenFace } from "../RigoToken/RigoTokenFace.sol";
import { IStaking } from "../../staking/interfaces/IStaking.sol";


/// @title Inflation - Allows ProofOfPerformance to mint tokens.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract Inflation is
    SafeMath,
    InflationFace
{
    address public immutable override RIGO_TOKEN_ADDRESS;
    address public immutable override STAKING_PROXY_ADDRESS;

    uint256 public override slot;
    uint256 public override epochLength;

    uint32 internal immutable PPM_DENOMINATOR = 10**6; // 100% in parts-per-million
    uint256 internal immutable ANNUAL_INFLATION_RATE = 2 * 10**4; // 2% annual inflation

    uint256 private epochEndTime;

    modifier onlyStakingProxy {
        _assertCallerIsStakingProxy();
        _;
    }

    constructor(
        address _rigoTokenAddress,
        address _stakingProxyAddress
    ) {
        RIGO_TOKEN_ADDRESS = _rigoTokenAddress;
        STAKING_PROXY_ADDRESS = _stakingProxyAddress;
    }

    /*
     * CORE FUNCTIONS
     */
    /// @dev Allows staking proxy to mint rewards.
    /// @return mintedInflation Number of allocated tokens.
    function mintInflation()
        external
        override
        onlyStakingProxy
        returns (uint256 mintedInflation)
    {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < epochEndTime) {
            revert("NOT_ENOUGH_TIME_ERROR");
        }

        (uint256 epochDurationInSeconds, , , , ) = IStaking(STAKING_PROXY_ADDRESS).getParams();

        // sanity check for epoch length queried from staking
        if (epochLength != epochDurationInSeconds) {
            if (epochDurationInSeconds < 5 days || epochDurationInSeconds > 90 days) {
                revert("STAKING_EPOCH_TIME_ANOMALY_DETECTED_ERROR");
            } else {
                epochLength = epochDurationInSeconds;
            }
        }

        uint256 epochInflation = getEpochInflation();

        // solhint-disable-next-line not-rely-on-time
        epochEndTime = block.timestamp + epochLength;
        slot = safeAdd(slot, 1);

        // mint rewards
        RigoTokenFace(RIGO_TOKEN_ADDRESS).mintToken(
            STAKING_PROXY_ADDRESS,
            epochInflation
        );
        return (mintedInflation = epochInflation);
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @dev Returns whether an epoch has ended.
    /// @return Bool the epoch has ended.
    function epochEnded()
        external
        override
        view
        returns (bool)
    {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= epochEndTime) {
            return true;
        } else return false;
    }

    /// @dev Returns how long until next claim.
    /// @return Number in seconds.
    function timeUntilNextClaim()
        external
        view
        override
        returns (uint256)
    {
        /* solhint-disable not-rely-on-time */
        if (block.timestamp < epochEndTime) {
            return (epochEndTime - block.timestamp);
        } else return (uint256(0));
        /* solhint-disable not-rely-on-time */
    }

    /// @dev Returns the epoch inflation.
    /// @return Value of units of GRG minted in an epoch.
    function getEpochInflation()
        public
        view
        override
        returns (uint256)
    {
        uint256 epochInflation = 
            safeDiv(
                safeDiv(
                    safeMul(
                        RigoTokenFace(RIGO_TOKEN_ADDRESS).totalSupply(),
                        safeMul(
                            ANNUAL_INFLATION_RATE,
                            epochLength
                        )
                    ),
                    PPM_DENOMINATOR
                ),
                365 days
            );

        return epochInflation;
    }

    /*
     * INTERNAL METHODS
     */
    /// @dev Asserts that the caller is the Staking Proxy.
    function _assertCallerIsStakingProxy()
        internal
        view
    {
        if (msg.sender != STAKING_PROXY_ADDRESS) {
            revert("CALLER_NOT_STAKING_PROXY_ERROR");
        }
    }
}