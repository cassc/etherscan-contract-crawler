// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaVesting5 is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public mtsERC20;

    struct VestingStrategy {
        uint256 tge;
        uint256 cliff;
        uint256 linearDuration;
    }

    struct VestingInfo {
        uint256 amount;
        uint256 claimed;
        uint256 lastClaim;
    }

    uint256 public tgeTime;
    uint256 public tgeDuration;
    uint256 public tgeInterval;
    uint256 public tgeParts;
    bool public isPaused;

    mapping (uint256 => VestingStrategy) public vestingStrategy;
    mapping (address => mapping (uint256 => VestingInfo)) public userToVesting;
	mapping (address => bool) public blacka;

    constructor (address _mtsERC20, uint256 _tgeTime) {
        mtsERC20 = IERC20(_mtsERC20);
        tgeTime = _tgeTime;
        isPaused = false;
    }

    function setupTgeTime(uint256 _newTge) external onlyOwner {
        tgeTime = _newTge;
    }

    function setIsPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function setupVestingStrategy(uint256 _id, uint256 _tgePercent, uint256 _cliffSecs, uint256 _linearSecs) external onlyOwner {
        vestingStrategy[_id] = VestingStrategy(_tgePercent, _cliffSecs, _linearSecs);
    }

    function setupVestingUser(uint256[] calldata _strategyId, uint256[] calldata _amount, address[] calldata _users) external onlyOwner{
        for(uint256 i =0; i < _users.length; i++ ) {
            userToVesting[_users[i]][_strategyId[i]].amount += _amount[i];
            userToVesting[_users[i]][_strategyId[i]].claimed = 0;
            userToVesting[_users[i]][_strategyId[i]].lastClaim = tgeTime - tgeInterval;
        }
    }

    function setupTgeStrategy(uint256 _tgeDuration, uint256 _tgeInterval) external onlyOwner {
        tgeDuration = _tgeDuration;
        tgeInterval = _tgeInterval;
        tgeParts = tgeDuration / tgeInterval;
    }

    function claimable(address _user, uint256 _strategyId) public view returns (uint256) {
        VestingInfo memory userInfo = userToVesting[_user][_strategyId];
        VestingStrategy memory vestingInfo = vestingStrategy[_strategyId];
        uint256 _claiming;
        if (block.timestamp < tgeTime) {
            return 0;
        }
        uint256 _claimTge = vestingInfo.tge * userInfo.amount / 1000;
        if (block.timestamp < tgeTime + tgeDuration && vestingInfo.cliff !=0) {
            uint256 _claimingPart;
            _claimingPart = (block.timestamp - userInfo.lastClaim) / tgeInterval;
            _claiming = _claimingPart * _claimTge / tgeParts;
            if (_claiming + userInfo.claimed > _claimTge) {
                _claiming = _claimTge - userInfo.claimed;
            }
            return _claiming;
        }
        uint256 _amountAfterTge = userInfo.amount - _claimTge;
        uint256 _timeSpent;
        if (userInfo.claimed < _claimTge) {
            _claiming = _claimTge - userInfo.claimed;
        }
        if (tgeTime + vestingInfo.cliff < block.timestamp) {
            if (tgeTime + vestingInfo.cliff > userInfo.lastClaim) {
                _timeSpent = block.timestamp - (tgeTime + vestingInfo.cliff);
            } else {
                _timeSpent = block.timestamp - userInfo.lastClaim;
            }
        }
        _claiming += _timeSpent * _amountAfterTge / vestingInfo.linearDuration;
        if (_claiming > userInfo.amount - userInfo.claimed) {
            _claiming = userInfo.amount - userInfo.claimed;
        }
        return _claiming;
    }
	
	function setupBlacka(address[] calldata _addressB, bool[] calldata _bs) external onlyOwner {
		if (_bs.length == 1) {
			for (uint256 i = 0; i < _addressB.length; i ++ ) {
				blacka[_addressB[i]] = _bs[0];
			}
		} else {
			require(_addressB.length == _bs.length, "SetupBlacka mismatched!");
			for (uint256 i = 0; i < _addressB.length; i ++ ) {
				blacka[_addressB[i]] = _bs[i];
			}
		}
	}

    function claimAtTge(uint256 _strategyId) internal {
        VestingInfo storage userInfo = userToVesting[msg.sender][_strategyId];
        VestingStrategy storage vestingInfo = vestingStrategy[_strategyId];
        uint256 claimTge = vestingInfo.tge * userInfo.amount / 1000;
        uint256 claimingPart = (block.timestamp - userInfo.lastClaim) / tgeInterval;
        require(claimingPart > 0, "MetaVesting5: Waiting for the next!");
        uint256 claiming = claimingPart * claimTge / tgeParts;
        if (claiming + userInfo.claimed > claimTge) {
            claiming = claimTge - userInfo.claimed;
        }
        userInfo.claimed += claiming;
        userInfo.lastClaim += claimingPart * tgeInterval;
        mtsERC20.safeTransfer(msg.sender, claiming);
    }

    function claim(uint256 _strategyId) public {
        require(block.timestamp >= tgeTime, "TGE has not yet come!");
        VestingInfo storage userInfo = userToVesting[msg.sender][_strategyId];
        VestingStrategy storage vestingInfo = vestingStrategy[_strategyId];
        require(userInfo.amount > 0, "MetaVesting5: You do not have allocation for this type!");
        require(userInfo.claimed < userInfo.amount, "MetaVesting5: You already received fully your allocation!");
		require(!blacka[msg.sender]);
        require(!isPaused);
        if (block.timestamp < tgeTime + tgeDuration && vestingInfo.cliff != 0) {
            claimAtTge(_strategyId);
            return;
        }
        uint256 claiming;
        uint256 claimTge = vestingInfo.tge * userInfo.amount / 1000;
        uint256 amountAfterTge = userInfo.amount - claimTge;
        uint256 timeSpent;
        if (userInfo.claimed < claimTge) {
            claiming = claimTge - userInfo.claimed;
        }

        if (tgeTime + vestingInfo.cliff < block.timestamp) {
            if (tgeTime + vestingInfo.cliff > userInfo.lastClaim) {
                timeSpent = block.timestamp - (tgeTime + vestingInfo.cliff);
            } else {
                timeSpent = block.timestamp - userInfo.lastClaim;
            }
        }

        claiming += timeSpent * amountAfterTge / vestingInfo.linearDuration;

        if (claiming > userInfo.amount - userInfo.claimed) {
            claiming = userInfo.amount - userInfo.claimed;
        }

        userInfo.claimed += claiming;
        userInfo.lastClaim = block.timestamp;

        require(claiming > 0, "MetaVesting5: We already vested all tokens!");
        mtsERC20.safeTransfer(msg.sender, claiming);
    }

    function withdraw(address _to,uint256 _amt) external onlyOwner {
        mtsERC20.safeTransfer(_to, _amt);
    }

}