// SPDX-License-Identifier: MIT

/**  vesting Contract */
/** Author : Aceson ( Vesting Contract 2022.8) */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IVestingV2.sol";
import "./libraries/DateTime.sol";

contract VestingV2 is IVestingV2, OwnableUpgradeable, DateTime {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  VestingPool[] public vestingPools;

  IERC20Upgradeable public token;
  address public icoContract;

  modifier optionExists(uint256 _option) {
    require(_option < vestingPools.length, "Vesting option does not exist");
    _;
  }

  modifier userInWhitelist(uint256 _option, address _wallet) {
    require(_option < vestingPools.length, "Vesting option does not exist");
    require(vestingPools[_option].hasWhitelist[_wallet].active, "User is not in whitelist");
    _;
  }

  function initialize(address _token, address _ico) external initializer {
    require(_token != address(0), "Zero address");
    require(_ico != address(0), "Zero address");
    __Ownable_init();
    __dateTimeInit();
    token = IERC20Upgradeable(_token);
    icoContract = _ico;
  }

  function addVestingStrategy(
    string memory _name, // Name of the vesting
    uint256 _cliff, // start time of the reward distribution
    uint256 _start, // start time of vesting
    uint256 _duration, // For linear vesting duration
    uint256 _initialUnlockPercent, // how much will be realease on initial launch
    bool _revocable, // owner can revoke any user or not
    uint256 _interval, // interval in inverval type of vesting
    uint16 _unlockPerInterval, // how wiill unlock per interval
    uint8 _monthGap, // month gap for monthly vestingh
    Type _type // type of vesting (linear, interval, monthly)
  ) external override onlyOwner returns (bool) {
    VestingPool storage newStrategy = vestingPools.push();
    require(_initialUnlockPercent <= 1000, "Value exceeds max");

    newStrategy.cliff = _start + _cliff;
    newStrategy.name = _name;
    newStrategy.start = _start;
    newStrategy.duration = _duration;
    newStrategy.initialUnlockPercent = _initialUnlockPercent;
    newStrategy.revocable = _revocable;
    newStrategy.vestType = _type;

    if (_type == Type.Interval) {
      require(_interval > 0, "Invalid interval");
      require(_unlockPerInterval > 0 && _unlockPerInterval <= 1000, "Invalid unlock per interval");

      newStrategy.interval = _interval;
      newStrategy.unlockPerInterval = _unlockPerInterval;
    } else if (_type == Type.Monthly) {
      require(_unlockPerInterval > 0 && _unlockPerInterval <= 1000, "Invalid unlock per interval");
      require(_monthGap > 0, "Invalid month gap");

      newStrategy.unlockPerInterval = _unlockPerInterval;

      uint8 day = getDay(newStrategy.cliff);
      uint8 month = getMonth(newStrategy.cliff);
      uint16 year = getYear(newStrategy.cliff);
      uint8 hour = getHour(newStrategy.cliff);
      uint8 minute = getMinute(newStrategy.cliff);
      uint8 second = getSecond(newStrategy.cliff);

      for (uint16 i = 0; i <= 1000; i += _unlockPerInterval) {
        month += _monthGap;

        while (month > 12) {
          month = month - 12;
          year++;
        }

        uint256 time = toTimestamp(year, month, day, hour, minute, second);
        newStrategy.timestamps.push(time);
      }
    }

    return true;
  }

  function setVestingStrategy(
    uint256 _strategy,
    string memory _name,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    uint256 _initialUnlockPercent,
    bool _revocable,
    uint256 _interval,
    uint16 _unlockPerInterval
  ) external override onlyOwner returns (bool) {
    require(_strategy < vestingPools.length, "Strategy does not exist");

    VestingPool storage vest = vestingPools[_strategy];

    require(vest.vestType != Type.Monthly, "Changing monthly not supported");
    require(_initialUnlockPercent <= 1000, "Value exceeds max");

    vest.cliff = _start + _cliff;
    vest.name = _name;
    vest.start = _start;
    vest.duration = _duration;
    vest.initialUnlockPercent = _initialUnlockPercent;
    vest.revocable = _revocable;

    if (vest.vestType == Type.Interval) {
      require(_unlockPerInterval > 0 && _unlockPerInterval <= 1000, "Invalid unlock per interval");
      vest.interval = _interval;
      vest.unlockPerInterval = _unlockPerInterval;
    }

    return true;
  }

  function setToken(address _addr) external onlyOwner returns (bool) {
    require(_addr != address(0), "Zero address");
    token = IERC20Upgradeable(_addr);
    return true;
  }

  function setIcoContract(address _ico) external onlyOwner returns (bool) {
    require(_ico != address(0), "Zero address");
    icoContract = _ico;
    return true;
  }

  function batchAddWhitelist(
    address[] memory wallets,
    uint256[] memory amounts,
    uint256 option
  ) external onlyOwner returns (bool) {
    require(wallets.length == amounts.length, "Sizes of inputs do not match");

    for (uint256 i = 0; i < wallets.length; i++) {
      addWhitelist(wallets[i], amounts[i], option);
    }

    return true;
  }

  /**
   *
   * @dev set the address as whitelist user address
   *
   * @param {address} address of the user
   *
   * @return {bool} return status of the whitelist
   *
   */
  function setWhitelist(
    address _wallet,
    uint256 _amount,
    uint256 _option
  ) external onlyOwner userInWhitelist(_option, _wallet) returns (bool) {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo storage info = vestingPools[_option].whitelistPool[idx];
    info.amount = _amount;

    return true;
  }

  function revoke(
    uint256 _option,
    address _wallet
  ) external onlyOwner userInWhitelist(_option, _wallet) {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo storage whitelist = vestingPools[_option].whitelistPool[idx];

    require(vestingPools[_option].revocable, "Strategy is not revocable");
    require(!whitelist.revoke, "already revoked");

    if (calculateReleasableAmount(_option, _wallet) > 0) {
      claimDistribution(_option, _wallet);
    }

    whitelist.revoke = true;
    whitelist.revokeDate = block.timestamp;

    emit Revoked(_wallet);
  }

  function setVesting(
    uint256 _option,
    address _wallet,
    bool _status
  ) external onlyOwner userInWhitelist(_option, _wallet) {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo storage whitelist = vestingPools[_option].whitelistPool[idx];

    whitelist.disabled = _status;

    emit StatusChanged(_wallet, _status);
  }

  function transferToken(address _addr, uint256 _amount) external onlyOwner returns (bool) {
    IERC20Upgradeable _token = IERC20Upgradeable(_addr);
    bool success = _token.transfer(address(owner()), _amount);
    return success;
  }

  function getWhitelist(
    uint256 _option,
    address _wallet
  ) external view userInWhitelist(_option, _wallet) returns (WhitelistInfo memory) {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    return vestingPools[_option].whitelistPool[idx];
  }

  function getAllVestingPools() external view returns (VestingInfo[] memory) {
    VestingInfo[] memory infoArr = new VestingInfo[](vestingPools.length);

    for (uint256 i = 0; i < vestingPools.length; i++) {
      infoArr[i] = getVestingInfo(i);
    }

    return infoArr;
  }

  function getTotalToken(address _addr) external view returns (uint256) {
    IERC20Upgradeable _token = IERC20Upgradeable(_addr);
    return _token.balanceOf(address(this));
  }

  function hasWhitelist(uint256 _option, address _wallet) external view returns (bool) {
    return vestingPools[_option].hasWhitelist[_wallet].active;
  }

  function getVestAmount(uint256 _option, address _wallet) external view returns (uint256) {
    return calculateVestAmount(_option, _wallet);
  }

  function getReleasableAmount(uint256 _option, address _wallet) external view returns (uint256) {
    return calculateReleasableAmount(_option, _wallet);
  }

  function getWhitelistPool(
    uint256 _option
  ) external view optionExists(_option) returns (WhitelistInfo[] memory) {
    return vestingPools[_option].whitelistPool;
  }

  function claimDistribution(uint256 _option, address _wallet) public returns (bool) {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo storage whitelist = vestingPools[_option].whitelistPool[idx];

    require(!whitelist.disabled, "User is disabled from claiming token");

    uint256 releaseAmount = calculateReleasableAmount(_option, _wallet);

    require(releaseAmount > 0, "Zero amount to claim");

    whitelist.distributedAmount = whitelist.distributedAmount + releaseAmount;

    token.safeTransfer(_wallet, releaseAmount);

    emit Claim(_wallet, releaseAmount, _option, block.timestamp);

    return true;
  }

  function addWhitelist(
    address _wallet,
    uint256 _amount,
    uint256 _option
  ) public optionExists(_option) returns (bool) {
    require(msg.sender == owner() || msg.sender == icoContract, "Incorrect access");
    HasWhitelist storage whitelist = vestingPools[_option].hasWhitelist[_wallet];
    require(msg.sender == icoContract || !whitelist.active, "Use setWhitelist Function");
    WhitelistInfo[] storage pool = vestingPools[_option].whitelistPool;

    if (whitelist.active) {
      pool[whitelist.arrIdx].amount = _amount;
    } else {
      whitelist.active = true;
      whitelist.arrIdx = pool.length;

      pool.push(
        WhitelistInfo({
          wallet: _wallet,
          amount: _amount,
          distributedAmount: 0,
          joinDate: block.timestamp,
          revokeDate: 0,
          revoke: false,
          disabled: false
        })
      );

      emit AddWhitelist(_wallet);
    }

    return true;
  }

  function getVestingInfo(
    uint256 _strategy
  ) public view optionExists(_strategy) returns (VestingInfo memory) {
    return
      VestingInfo({
        name: vestingPools[_strategy].name,
        cliff: vestingPools[_strategy].cliff,
        start: vestingPools[_strategy].start,
        duration: vestingPools[_strategy].duration,
        initialUnlockPercent: vestingPools[_strategy].initialUnlockPercent,
        revocable: vestingPools[_strategy].revocable,
        vestType: vestingPools[_strategy].vestType,
        interval: vestingPools[_strategy].interval,
        unlockPerInterval: vestingPools[_strategy].unlockPerInterval,
        timestamps: vestingPools[_strategy].timestamps
      });
  }

  function calculateVestAmount(
    uint256 _option,
    address _wallet
  ) internal view userInWhitelist(_option, _wallet) returns (uint256 amount) {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo memory whitelist = vestingPools[_option].whitelistPool[idx];
    VestingPool storage vest = vestingPools[_option];

    // initial unlock
    uint256 initial = (whitelist.amount * vest.initialUnlockPercent) / 1000;

    if (whitelist.revoke) {
      return whitelist.distributedAmount;
    }

    if (block.timestamp < vest.start) {
      return 0;
    } else if (block.timestamp >= vest.start && block.timestamp < vest.cliff) {
      return initial;
    } else if (block.timestamp >= vest.cliff) {
      if (vestingPools[_option].vestType == Type.Interval) {
        return calculateVestAmountForInterval(whitelist, vest);
      } else if (vestingPools[_option].vestType == Type.Linear) {
        return calculateVestAmountForLinear(whitelist, vest);
      } else {
        return calculateVestAmountForMonthly(whitelist, vest);
      }
    }
  }

  function calculateVestAmountForLinear(
    WhitelistInfo memory whitelist,
    VestingPool storage vest
  ) internal view returns (uint256) {
    uint256 initial = (whitelist.amount * vest.initialUnlockPercent) / 1000;

    uint256 remaining = whitelist.amount - initial;

    if (block.timestamp >= vest.cliff + vest.duration) {
      return whitelist.amount;
    } else {
      return initial + ((remaining * (block.timestamp - vest.cliff)) / vest.duration);
    }
  }

  function calculateVestAmountForInterval(
    WhitelistInfo memory whitelist,
    VestingPool storage vest
  ) internal view returns (uint256) {
    uint256 initial = (whitelist.amount * vest.initialUnlockPercent) / 1000;
    uint256 remaining = whitelist.amount - initial;

    uint256 totalUnlocked = ((block.timestamp - vest.cliff) * vest.unlockPerInterval) /
      vest.interval;

    if (totalUnlocked >= 1000) {
      return whitelist.amount;
    } else {
      return initial + ((remaining * totalUnlocked) / 1000);
    }
  }

  function calculateVestAmountForMonthly(
    WhitelistInfo memory whitelist,
    VestingPool storage vest
  ) internal view returns (uint256) {
    uint256 initial = (whitelist.amount * vest.initialUnlockPercent) / 1000;
    uint256 remaining = whitelist.amount - initial;

    if (block.timestamp > vest.timestamps[vest.timestamps.length - 1]) {
      return whitelist.amount;
    } else {
      uint256 multi = findCurrentTimestamp(vest.timestamps, block.timestamp);
      uint256 totalUnlocked = multi * vest.unlockPerInterval;

      return initial + ((remaining * totalUnlocked) / 1000);
    }
  }

  function calculateReleasableAmount(
    uint256 _option,
    address _wallet
  ) internal view userInWhitelist(_option, _wallet) returns (uint256) {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    return
      calculateVestAmount(_option, _wallet) -
      vestingPools[_option].whitelistPool[idx].distributedAmount;
  }

  function findCurrentTimestamp(
    uint256[] memory timestamps,
    uint256 target
  ) internal pure returns (uint256 pos) {
    uint256 last = timestamps.length;
    uint256 first = 0;
    uint256 mid = 0;

    if (target < timestamps[first]) {
      return 0;
    }

    if (target >= timestamps[last - 1]) {
      return last - 1;
    }

    while (first < last) {
      mid = (first + last) / 2;

      if (timestamps[mid] == target) {
        return mid + 1;
      }

      if (target < timestamps[mid]) {
        if (mid > 0 && target > timestamps[mid - 1]) {
          return mid;
        }

        last = mid;
      } else {
        if (mid < last - 1 && target < timestamps[mid + 1]) {
          return mid + 1;
        }

        first = mid + 1;
      }
    }
    return mid + 1;
  }
}