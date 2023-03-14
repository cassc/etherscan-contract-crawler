// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ILVLStaking} from "../interfaces/ILVLStaking.sol";

contract LvlStakingRewardController is Ownable {
    using SafeERC20 for IERC20;

    ILVLStaking public staking;

    address public controller;

    address public cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public llp = 0xB5C42F84Ab3f786bCA9761240546AA9cEC1f8821;
    uint256 public start; // startTimestamp of previous setRewardsPerSecond
    uint256 public end;
    uint256 public duration = 1 days; // duration of the rewards
    uint256 public utilization = 1000;
    uint256 public RATIO_PRECISION = 1000;
    address[] public assets;

    uint256 public llpSaved;
    uint256 public llpDeficit;

    modifier onlyOwnerOrController() {
        require(msg.sender == controller || msg.sender == owner(), "NOT ALLOWED");
        _;
    }

    constructor(address _staking, uint256 _start, address[] memory _assets) {
        require(_staking != address(0), "invalid address");
        controller = msg.sender;
        staking = ILVLStaking(_staking);
        start = _start;
        end = _start + duration;
        _setAssets(_assets);
    }

    function setUtilization(uint256 _utilization) external onlyOwner {
        require(_utilization <= RATIO_PRECISION, "NOT ALLOWED");
        utilization = _utilization;
    }

    function setController(address _controller) external onlyOwner {
        require(_controller != address(0), "INVALID ADDRESS");
        controller = _controller;
    }

    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function setAssets(address[] memory _assets) external onlyOwner {
        _setAssets(_assets);
    }

    function convertLlpOnly() external onlyOwnerOrController {
        _convertLLP();
    }

    function run() external onlyOwnerOrController {
        _execute(duration);
    }

    function runWithDuration(uint256 _duration) external onlyOwnerOrController {
        _execute(_duration);
    }

    function overrideRewardPerSecond(uint256 _rps) external onlyOwner {
        staking.setRewardsPerSecond(_rps);
    }

    function _execute(uint256 _duration) internal {
        uint256 _llpReceived = _convertLLP();
        if (_llpReceived > 0) {
            uint256 _llpUsed = _llpReceived * utilization / RATIO_PRECISION;
            llpSaved += _llpReceived - _llpUsed;
            uint256 _now = block.timestamp;
            uint256 _current_rps = staking.rewardsPerSecond();
            uint256 _new_rps;
            bool _good = true;
            start = _now;
            if (end > _now) {
                // good case
                uint256 _leftOver = _current_rps * (end - _now);
                _new_rps = (_leftOver + _llpUsed) / (end - _now + _duration);
            } else {
                // bad case
                _good = false;
                uint256 _deficit = _current_rps * (_now - end);
                if (_deficit > _llpUsed || _duration < (_now - end)) {
                    revert("PANIC");
                }
                _new_rps = (_llpUsed - _deficit) / (_duration - (_now - end));
            }
            end = end + _duration;
            staking.setRewardsPerSecond(_new_rps);
            emit NewRewardPerSecond(_new_rps, end, _good);
        }
    }

    function _convertLLP() internal returns (uint256 _llpOut) {
        // 1: swap CAKE to USDT
        uint256 _cakeBalance = IERC20(cake).balanceOf(address(staking));
        if (_cakeBalance > 0) {
            staking.swap(cake, usdt, _cakeBalance, 0); // optimistic
        }

        // 2: loop through all assest and convert to LLP
        uint256 _llpBalanceBefore = IERC20(llp).balanceOf(address(staking));
        for (uint8 i = 0; i < assets.length; i++) {
            address _token = assets[i];
            uint256 _balance = IERC20(_token).balanceOf(address(staking));
            if (_balance > 0) {
                staking.convert(assets[i], _balance, 0); // optimistic
            }
        }
        _llpOut = IERC20(llp).balanceOf(address(staking)) - _llpBalanceBefore;
        emit LlpAdded(_llpOut);
    }

    function _setAssets(address[] memory _assets) internal {
        for (uint256 i = 0; i < _assets.length; ++i) {
            if (_assets[i] == address(0)) {
                revert("Invalid address");
            }
        }
        assets = _assets;
    }

    event LlpAdded(uint256 _amt);
    event NewRewardPerSecond(uint256 _rps, uint256 _end, bool _good);
}