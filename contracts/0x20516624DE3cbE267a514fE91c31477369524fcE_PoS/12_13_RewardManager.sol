// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title RewardManager
/// @author Felipe Argento


pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardManager {
    using SafeMath for uint256;

    uint256 immutable minReward;
    uint256 immutable maxReward;
    uint256 immutable distNumerator;
    uint256 immutable distDenominator;
    address immutable operator;
    IERC20 immutable ctsi;

    /// @notice Creates contract
    /// @param _operator address of the operator
    /// @param _ctsiAddress address of token instance being used
    /// @param _maxReward maximum reward that this contract pays
    /// @param _minReward minimum reward that this contract pays
    /// @param _distNumerator multiplier factor to define reward amount
    /// @param _distDenominator dividing factor to define reward amount
    constructor(
        address _operator,
        address _ctsiAddress,
        uint256 _maxReward,
        uint256 _minReward,
        uint256 _distNumerator,
        uint256 _distDenominator
    ) {

        operator = _operator;
        ctsi = IERC20(_ctsiAddress);

        minReward = _minReward;
        maxReward = _maxReward;
        distNumerator = _distNumerator;
        distDenominator = _distDenominator;
    }

    /// @notice Rewards address
    /// @param _address address be rewarded
    /// @param _amount reward
    /// @dev only the pos contract can call this
    function reward(address _address, uint256 _amount) public {
        require(msg.sender == operator, "Only the operator contract can call this function");

        ctsi.transfer(_address, _amount);
    }

    /// @notice Get RewardManager's balance
    function getBalance() public view returns (uint256) {
        return ctsi.balanceOf(address(this));
    }

    /// @notice Get current reward amount
    function getCurrentReward() public view returns (uint256) {
        uint256 cReward = (getBalance().mul(distNumerator)).div(distDenominator);
        cReward = cReward > minReward? cReward : minReward;
        cReward = cReward > maxReward? maxReward : cReward;

        return cReward > getBalance()? getBalance() : cReward;
    }
}