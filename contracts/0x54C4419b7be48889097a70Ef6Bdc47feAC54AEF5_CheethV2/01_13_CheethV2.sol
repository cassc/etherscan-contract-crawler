// SPDX-License-Identifier: MIT

/*
Copyright 2021 Anonymice

Licensed under the Anonymice License, Version 1.0 (the “License”); you may not use this code except in compliance with the License.
You may obtain a copy of the License at https://doz7mjeufimufl7fa576j6kq5aijrwezk7tvdgvzrfr3d6njqwea.arweave.net/G7P2JJQqGUKv5Qd_5PlQ6BCY2JlX51GauYljsfmphYg

Unless required by applicable law or agreed to in writing, code distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CheethV2 is ERC20Burnable, Ownable {
    /*
 _____ _               _   _
/  __ \ |             | | | |
| /  \/ |__   ___  ___| |_| |__
| |   | '_ \ / _ \/ _ \ __| '_ \
| \__/\ | | |  __/  __/ |_| | | |
 \____/_| |_|\___|\___|\__|_| |_|
*/

    struct StakedMouse {
        uint256 tokenId;
        uint256 stakedSince;
        uint256 cheethEmision;
    }

    using EnumerableSet for EnumerableSet.UintSet;
    uint256 public constant STAKE_LIMIT = 25;

    address public anonymiceAddress;
    address public cheethV1Address;
    //User to staked mice
    mapping(address => EnumerableSet.UintSet) private stakedMices;
    //Staked Mouse to timestamp staked
    mapping(uint256 => uint256) public miceStakeTimes;
    mapping(uint256 => uint256) public miceClaimTimes;
    bool public isCheethSwapEnabled;

    constructor() ERC20("Cheeth", "CHEETH") {
        isCheethSwapEnabled = true;
    }

    function stakeMiceByIds(uint256[] memory _miceIds) external {
        require(
            _miceIds.length + stakedMices[msg.sender].length() <= STAKE_LIMIT,
            "Can only have a max of 25 mice staked!"
        );
        for (uint256 i = 0; i < _miceIds.length; i++) {
            _stakeMouse(_miceIds[i]);
        }
    }

    function unstakeMiceByIds(uint256[] memory _miceIds) public {
        for (uint256 i = 0; i < _miceIds.length; i++) {
            _unstakeMouse(_miceIds[i]);
        }
    }

    function claimRewardsByIds(uint256[] memory _miceIds) external {
        uint256 runningCheethAllowance;

        for (uint256 i = 0; i < _miceIds.length; i++) {
            uint256 thisMouseId = _miceIds[i];
            require(
                stakedMices[msg.sender].contains(thisMouseId),
                "Can only claim a mice you staked!"
            );
            runningCheethAllowance += getCheethOwedToThisMouse(thisMouseId);

            miceClaimTimes[thisMouseId] = block.timestamp;
        }
        _mint(msg.sender, runningCheethAllowance);
    }

    function claimAllRewards() external {
        uint256 runningCheethAllowance;

        for (uint256 i = 0; i < stakedMices[msg.sender].length(); i++) {
            uint256 thisMouseId = stakedMices[msg.sender].at(i);
            runningCheethAllowance += getCheethOwedToThisMouse(thisMouseId);

            miceClaimTimes[thisMouseId] = block.timestamp;
        }
        _mint(msg.sender, runningCheethAllowance);
    }

    function unstakeAll() external {
        unstakeMiceByIds(stakedMices[msg.sender].values());
    }

    function swapCheethV1ForV2(uint256 _amount) external {
        require(isCheethSwapEnabled, "CheethV1 swap is disabled!");
        ERC20Burnable(cheethV1Address).burnFrom(msg.sender, _amount);
        _mint(msg.sender, _amount * 100);
    }

    function _stakeMouse(uint256 _mouseId) internal onlyMouseOwner(_mouseId) {
        //Transfer their token
        IERC721Enumerable(anonymiceAddress).transferFrom(
            msg.sender,
            address(this),
            _mouseId
        );

        // Add the mice to the owner's set
        stakedMices[msg.sender].add(_mouseId);

        //Set this mouseId timestamp to now
        miceStakeTimes[_mouseId] = block.timestamp;
        miceClaimTimes[_mouseId] = 0;
    }

    function _unstakeMouse(uint256 _mouseId)
        internal
        onlyMouseStaker(_mouseId)
    {
        uint256 cheethOwedToThisMouse = getCheethOwedToThisMouse(_mouseId);
        _mint(msg.sender, cheethOwedToThisMouse);

        IERC721(anonymiceAddress).transferFrom(
            address(this),
            msg.sender,
            _mouseId
        );

        stakedMices[msg.sender].remove(_mouseId);
    }

    // GETTERS

    function getStakedMiceData(address _address)
        external
        view
        returns (StakedMouse[] memory)
    {
        uint256[] memory ids = stakedMices[_address].values();
        StakedMouse[] memory stakedMice = new StakedMouse[](ids.length);
        for (uint256 index = 0; index < ids.length; index++) {
            uint256 _mouseId = ids[index];
            stakedMice[index] = StakedMouse(
                _mouseId,
                miceStakeTimes[_mouseId],
                getMouseCheethEmission(_mouseId)
            );
        }

        return stakedMice;
    }

    function tokensStaked(address _address)
        external
        view
        returns (uint256[] memory)
    {
        return stakedMices[_address].values();
    }

    function stakedMiceQuantity(address _address)
        external
        view
        returns (uint256)
    {
        return stakedMices[_address].length();
    }

    function getCheethOwedToThisMouse(uint256 _mouseId)
        public
        view
        returns (uint256)
    {
        uint256 elapsedTime = block.timestamp - miceStakeTimes[_mouseId];
        uint256 elapsedDays = elapsedTime < 1 days ? 0 : elapsedTime / 1 days;
        uint256 leftoverSeconds = elapsedTime - elapsedDays * 1 days;

        if (miceClaimTimes[_mouseId] == 0) {
            return _calculateCheeth(elapsedDays, leftoverSeconds);
        }

        uint256 elapsedTimeSinceClaim = miceClaimTimes[_mouseId] -
            miceStakeTimes[_mouseId];
        uint256 elapsedDaysSinceClaim = elapsedTimeSinceClaim < 1 days
            ? 0
            : elapsedTimeSinceClaim / 1 days;
        uint256 leftoverSecondsSinceClaim = elapsedTimeSinceClaim -
            elapsedDaysSinceClaim *
            1 days;

        return
            _calculateCheeth(elapsedDays, leftoverSeconds) -
            _calculateCheeth(elapsedDaysSinceClaim, leftoverSecondsSinceClaim);
    }

    function getTotalRewardsForUser(address _address)
        external
        view
        returns (uint256)
    {
        uint256 runningCheethTotal;
        uint256[] memory miceIds = stakedMices[_address].values();
        for (uint256 i = 0; i < miceIds.length; i++) {
            runningCheethTotal += getCheethOwedToThisMouse(miceIds[i]);
        }
        return runningCheethTotal;
    }

    function getMouseCheethEmission(uint256 _mouseId)
        public
        view
        returns (uint256)
    {
        uint256 elapsedTime = block.timestamp - miceStakeTimes[_mouseId];
        uint256 elapsedDays = elapsedTime < 1 days ? 0 : elapsedTime / 1 days;
        return _cheethDailyIncrement(elapsedDays);
    }

    function _calculateCheeth(uint256 _days, uint256 _leftoverSeconds)
        internal
        pure
        returns (uint256)
    {
        uint256 progressiveDays = Math.min(_days, 100);
        uint256 progressiveReward = progressiveDays == 0
            ? 0
            : (progressiveDays *
                (80.2 ether + 0.2 ether * (progressiveDays - 1) + 80.2 ether)) /
                2;

        uint256 dailyIncrement = _cheethDailyIncrement(_days);
        uint256 leftoverReward = _leftoverSeconds > 0
            ? (dailyIncrement * _leftoverSeconds) / 1 days
            : 0;

        if (_days <= 100) {
            return progressiveReward + leftoverReward;
        }
        return progressiveReward + (_days - 100) * 100 ether + leftoverReward;
    }

    function _cheethDailyIncrement(uint256 _days)
        internal
        pure
        returns (uint256)
    {
        return _days > 100 ? 100 ether : 80 ether + _days * 0.2 ether;
    }

    // OWNER FUNCTIONS

    function setAddresses(address _anonymiceAddress, address _cheethV1Address)
        public
        onlyOwner
    {
        anonymiceAddress = _anonymiceAddress;
        cheethV1Address = _cheethV1Address;
    }

    function setIsCheethSwapEnabled(bool _isCheethSwapEnabled)
        public
        onlyOwner
    {
        isCheethSwapEnabled = _isCheethSwapEnabled;
    }

    // MODIFIERS

    modifier onlyMouseOwner(uint256 _mouseId) {
        require(
            IERC721Enumerable(anonymiceAddress).ownerOf(_mouseId) == msg.sender,
            "Can only stake mice you own!"
        );
        _;
    }

    modifier onlyMouseStaker(uint256 _mouseId) {
        require(
            stakedMices[msg.sender].contains(_mouseId),
            "Can only unstake mice you staked!"
        );
        _;
    }
}