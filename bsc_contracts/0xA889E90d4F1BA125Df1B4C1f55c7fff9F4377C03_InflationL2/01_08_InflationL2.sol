// SPDX-License-Identifier: Apache 2.0

/*

 Copyright 2017-2019 RigoBlock, Rigo Investment Sagl, 2020-2022 Rigo Intl.

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
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import {IInflation} from "../interfaces/IInflation.sol";
import {IRigoToken} from "../interfaces/IRigoToken.sol";
import {IStaking} from "../../staking/interfaces/IStaking.sol";

/// @title Inflation - Allows ProofOfPerformance to mint tokens.
/// @author Gabriele Rigo - <[email protected]>
/// @notice Inflation on L2s is only produced by distributing tokens owned by this contract.
/// @dev excess tokens are held in this contract until fully distributed.
// solhint-disable-next-line
contract InflationL2 is IInflation {
    /// @inheritdoc IInflation
    address public override rigoToken;

    /// @inheritdoc IInflation
    address public override stakingProxy;

    /// @inheritdoc IInflation
    uint48 public override epochLength;

    /// @inheritdoc IInflation
    uint32 public override slot;

    uint32 private constant _ANNUAL_INFLATION_RATE = 2 * 10e4; // 2% annual inflation
    uint32 private constant _PPM_DENOMINATOR = 10e6; // 100% in parts-per-million

    uint48 private _epochEndTime;

    address private _initializer;

    modifier onlyInitializer() {
        require(msg.sender == _initializer, "INFLATIONL2_CALLER_ERROR");
        _;
    }

    modifier onlyStakingProxy() {
        _assertCallerIsStakingProxy();
        _;
    }

    modifier alreadyInitialized() {
        require(rigoToken != address(0) && stakingProxy != address(0), "INFLATIONL2_NOT_INIT_ERROR");
        _;
    }

    constructor(address initializer) {
        _initializer = initializer;
        epochLength = 0;
        slot = 0;
    }

    /*
     * CORE FUNCTIONS
     */
    /// @notice We initialize parameters here instead of in the constructor.
    /// @dev On L2, inflation depends on staking proxy, which depends on inflation.
    /// @dev As deterministic deployment addresses are affected by the constructor, we save params in storage.
    function initParams(address newRigoToken, address newStakingProxy) external onlyInitializer {
        require(rigoToken == address(0) || stakingProxy == address(0), "INFLATION_ALREADY_INIT_ERROR");
        require(newRigoToken != address(0) && newStakingProxy != address(0), "INFLATION_NULL_INPUTS_ERROR");
        rigoToken = newRigoToken;
        stakingProxy = newStakingProxy;
    }

    /// @inheritdoc IInflation
    function mintInflation() external override alreadyInitialized onlyStakingProxy returns (uint256 mintedInflation) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _epochEndTime, "INFLATION_EPOCH_END_ERROR");
        (uint256 epochDuration, , , , ) = IStaking(stakingProxy).getParams();

        // sanity check for epoch length queried from staking
        if (epochLength != epochDuration) {
            require(epochDuration >= 5 days && epochDuration <= 90 days, "INFLATION_TIME_ANOMALY_ERROR");

            // we update epoch length in storage
            epochLength = uint48(epochDuration);
        }

        uint256 epochInflation = getEpochInflation();

        // we update epoch end time in storage
        // solhint-disable-next-line not-rely-on-time
        _epochEndTime = uint48(block.timestamp + epochLength);

        // we increase slot by 1, should we upgrade inflation, we will have to start from latest slot.
        ++slot;

        uint256 tokenBalance = IRigoToken(rigoToken).balanceOf(address(this));

        // distribute rewards, we skip transfer if null amount
        if (tokenBalance == 0) {
            mintedInflation = 0;
        } else {
            mintedInflation = tokenBalance >= epochInflation ? epochInflation : tokenBalance;
            IRigoToken(rigoToken).transfer(stakingProxy, mintedInflation);
        }

        return mintedInflation;
    }

    /*
     * CONSTANT PUBLIC FUNCTIONS
     */
    /// @inheritdoc IInflation
    function epochEnded() external view override returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _epochEndTime;
    }

    /// @inheritdoc IInflation
    function getEpochInflation() public view override returns (uint256) {
        // 2% of GRG total supply
        // total supply * annual percentage inflation * time period (1 epoch)
        uint256 grgSupply = IRigoToken(rigoToken).totalSupply();
        return ((_ANNUAL_INFLATION_RATE * epochLength * grgSupply) / _PPM_DENOMINATOR / 365 days);
    }

    /// @inheritdoc IInflation
    function timeUntilNextClaim() external view override returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp < _epochEndTime ? _epochEndTime - block.timestamp : 0;
    }

    /*
     * INTERNAL METHODS
     */
    /// @dev Asserts that the caller is the Staking Proxy.
    function _assertCallerIsStakingProxy() private view {
        require(msg.sender == stakingProxy, "CALLER_NOT_STAKING_PROXY_ERROR");
    }
}