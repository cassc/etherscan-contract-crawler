// contracts/LUNI.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LUNI is ERC20, ERC20Burnable, Ownable {
    constructor(
        uint256 _lockdownPeriod,
        uint8 _lpFee)
        ERC20("Terra Infinite", "LUNI") payable {
        require(lpFee < 100, "LUNI: lpFee must be under 100 (percent)");
        lockdownPeriod = _lockdownPeriod;
        lpFee = _lpFee;
        liquidityPool = msg.value;
        _whitelisted.add(address(0x141E701d67a7D61d9b0B9c78719a4446e6693a9f)); // Mitchel
        _whitelisted.add(address(0xE48C4Bb5EdEE5C49dB61B34Dd158829BBc76Ee49)); // Lucas
        _whitelisted.add(address(0xA1F30671CB8Ea9A31abCDCA2a7755B384241D216)); // Alex
        _whitelisted.add(address(0xB91Af4FA08a679C99A3C24Bb10bd2c8ef2d99547)); // Taras
        _mint(0x141E701d67a7D61d9b0B9c78719a4446e6693a9f, 600000000000000);
        _mint(0xE48C4Bb5EdEE5C49dB61B34Dd158829BBc76Ee49, 600000000000000);
        _mint(0xA1F30671CB8Ea9A31abCDCA2a7755B384241D216, 600000000000000);
        _mint(0xB91Af4FA08a679C99A3C24Bb10bd2c8ef2d99547, 600000000000000);
    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    EnumerableSet.AddressSet private _whitelisted;
    EnumerableSet.AddressSet private _holders;
    mapping(uint256 => EnumerableMap.AddressToUintMap) private _rewards;
    mapping(uint256 => mapping(address => bool)) public rewardsWithdrawn;

    uint256[] public rewardsTimestamps;
    uint256 public lockdownPeriod;
    uint8 public lpFee;
    uint256 public liquidityPool;

    event Invested(address, uint256, uint256);
    event WithdrawnReward(address, uint256);
    event ReinvestedReward(address, uint256, uint256);



    /*========== overriden functions ==========*/

    function decimals() public view virtual override returns (uint8) {
        return 14;
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if(from != address(0) && balanceOf(from) == 0) {
            _holders.remove(from);
        }
        if(to != address(0) && balanceOf(to) > 0) {
            _holders.add(to);
        }
    }



    /*========== internal functions ==========*/

    function _distributeReward(uint256 amount) internal {
        uint256 supply = totalSupply();
        if(supply == 0) {
            liquidityPool += amount;
            return;
        }
        uint256 rewardsDistributed;
        uint256 length = _holders.length();
        for(uint256 i; i < length; i++) {
            address investor = _holders.at(i);
            uint256 reward = amount * balanceOf(investor) / supply;
            if(reward > 0) {
                if(!_whitelisted.contains(investor)) {
                    reward = reward * (100 - lpFee) / 100;
                }
                _rewards[block.timestamp].set(investor, reward);
                rewardsDistributed += reward;
            }
        }
        rewardsTimestamps.push(block.timestamp);
        liquidityPool += amount - rewardsDistributed;
    }

    function _toTokenAmount(uint256 amount) internal pure returns (uint256) {
        return amount;
    }

    function _invest(address account, uint256 amount) internal {
        require(account != address(0), "LUNI: account cannot be null");
        require(amount > 0, "LUNI: investment amount must be greater than zero");
        _distributeReward(amount);
        uint256 tokenAmount = _toTokenAmount(amount);
        _mint(account, tokenAmount);
        emit Invested(account, amount, tokenAmount);
    }

    function _reward(address account) internal view returns (uint256) {
        require(account != address(0), "LUNI: account cannot be null");
        uint256 reward;
        for (uint256 i; i < rewardsTimestamps.length; i++) {
            if(_rewards[rewardsTimestamps[i]].contains(account)) {
                reward += _rewards[rewardsTimestamps[i]].get(account);
            }
        }
        return reward;
    }

    function _withdrawnReward(address account) internal view returns (uint256) {
        require(account != address(0), "LUNI: account cannot be null");
        uint256 amount;
        for (uint256 i; i < rewardsTimestamps.length; i++) {
            if(rewardsWithdrawn[rewardsTimestamps[i]][account]
                && _rewards[rewardsTimestamps[i]].contains(account)) {
                amount += _rewards[rewardsTimestamps[i]].get(account);
            }
        }
        return amount;
    }

    function _remainingReward(address account) internal view returns (uint256) {
        require(account != address(0), "LUNI: account cannot be null");
        uint256 reward;
        for (uint256 i; i < rewardsTimestamps.length; i++) {
            if(!rewardsWithdrawn[rewardsTimestamps[i]][account]
                && _rewards[rewardsTimestamps[i]].contains(account)) {
                reward += _rewards[rewardsTimestamps[i]].get(account);
            }
        }
        return reward;
    }

    function _lockedReward(address account) internal view returns (uint256) {
        require(account != address(0), "LUNI: account cannot be null");
        uint256 amount;
        for (uint256 i; i < rewardsTimestamps.length; i++) {
            if(!rewardsWithdrawn[rewardsTimestamps[i]][account]
                && rewardsTimestamps[i] + lockdownPeriod > block.timestamp
                && _rewards[rewardsTimestamps[i]].contains(account)) {
                amount += _rewards[rewardsTimestamps[i]].get(account);
            }
        }
        return amount;
    }

    function _availableReward(address account) internal view returns (uint256) {
        require(account != address(0), "LUNI: account cannot be null");
        uint256 amount;
        for (uint256 i; i < rewardsTimestamps.length; i++) {
            if(!rewardsWithdrawn[rewardsTimestamps[i]][account]
                && rewardsTimestamps[i] + lockdownPeriod <= block.timestamp
                && _rewards[rewardsTimestamps[i]].contains(account)) {
                amount += _rewards[rewardsTimestamps[i]].get(account);
            }
        }
        return amount;
    }

    function _nextRewardUnlock(address account) internal view returns (uint256) {
        require(account != address(0), "LUNI: account cannot be null");
        for (uint256 i; i < rewardsTimestamps.length; i++) {
            if(rewardsTimestamps[i] + lockdownPeriod > block.timestamp
                && _rewards[rewardsTimestamps[i]].contains(account)) {
                return rewardsTimestamps[i];
            }
        }
        return 0;
    }

    function _withdrawReward(address account) internal {
        require(account != address(0), "LUNI: account cannot be null");
        uint256 amount;
        for (uint256 i; i < rewardsTimestamps.length; i++) {
            if(!rewardsWithdrawn[rewardsTimestamps[i]][account]
                && rewardsTimestamps[i] + lockdownPeriod <= block.timestamp
                && _rewards[rewardsTimestamps[i]].contains(account)) {
                amount += _rewards[rewardsTimestamps[i]].get(account);
                rewardsWithdrawn[rewardsTimestamps[i]][account] = true;
            }
        }
        payable(account).transfer(amount);
        emit WithdrawnReward(account, amount);
    }

    function _reinvestReward(address account) internal {
        require(account != address(0), "LUNI: account cannot be null");
        uint256 amount;
        for (uint256 i; i < rewardsTimestamps.length; i++) {
            if(!rewardsWithdrawn[rewardsTimestamps[i]][account]
                && _rewards[rewardsTimestamps[i]].contains(account)) {
                amount += _rewards[rewardsTimestamps[i]].get(account);
                rewardsWithdrawn[rewardsTimestamps[i]][account] = true;
            }
        }
        _distributeReward(amount);
        uint256 tokenAmount = _toTokenAmount(amount);
        _mint(account, tokenAmount);
        emit ReinvestedReward(account, amount, tokenAmount);
    }



    /*========== whitelisted functions ==========*/

    function whitelisted(uint256 i) external view returns (address) {
        return _whitelisted.at(i);
    }

    function whitelistedLength() external view returns (uint256) {
        return _whitelisted.length();
    }

    function isWhitelisted(address account) external view returns (bool) {
        return _whitelisted.contains(account);
    }

    function addWhitelisted(address account) external onlyOwner returns (bool) {
        return _whitelisted.add(account);
    }

    function removeWhitelisted(address account) external onlyOwner returns (bool) {
        return _whitelisted.remove(account);
    }



    /*========== holders functions ==========*/

    function holders(uint256 i) external view returns (address) {
        if (i < _holders.length()) {
            return _holders.at(i);
        }
        return address(0);
    }

    function holdersLength() external view returns (uint256) {
        return _holders.length();
    }

    function isHolder(address account) external view returns (bool) {
        return _holders.contains(account);
    }



    /*========== rewards functions ==========*/

    function rewardsTimestampsLength() external view returns (uint256) {
        return rewardsTimestamps.length;
    }

    function rewardsLength(uint256 timestamp) external view returns (uint256) {
        return _rewards[timestamp].length();
    }

    function rewards(uint256 timestamp, uint256 i) external view returns (address account, uint256 amount) {
        if(i < _rewards[timestamp].length()) {
            return _rewards[timestamp].at(i);
        }
        return (address(0), 0);
    }




    /*========== protocol functions ==========*/

    function invest() external payable returns (bool) {
        _invest(msg.sender, msg.value);
        return true;
    }

    function investFor(address account) external payable returns (bool) {
        _invest(account, msg.value);
        return true;
    }

    function rewardFor(address account) external view returns (uint256) {
        return _reward(account);
    }

    function withdrawnRewardFor(address account) external view returns (uint256) {
        return _withdrawnReward(account);
    }

    function remainingRewardFor(address account) external view returns (uint256) {
        return _remainingReward(account);
    }

    function lockedRewardFor(address account) external view returns (uint256) {
        return _lockedReward(account);
    }

    function availableRewardFor(address account) external view returns (uint256) {
        return _availableReward(account);
    }

    function nextRewardUnlockFor(address account) external view returns (uint256) {
        return _nextRewardUnlock(account);
    }

    function withdrawReward() external returns (bool) {
        _withdrawReward(msg.sender);
        return true;
    }

    function reinvestReward() external returns (bool) {
        _reinvestReward(msg.sender);
        return true;
    }



    /*========== funds functions (disabled for production) ==========*/

    receive() external payable {}

    function funds() external view returns (uint256) {
        return address(this).balance;
    }

    function addFunds() external payable onlyOwner returns (bool) {}

    function removeFunds(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }



    /*========== control functions (disabled for production) ==========*/

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function setLockdownPeriod(uint256 _lockdownPeriod) external onlyOwner returns (bool) {
        lockdownPeriod = _lockdownPeriod;
        return true;
    }

    function setlpFee(uint8 _lpFee) external onlyOwner returns (bool) {
        lpFee = _lpFee;
        return true;
    }

    function setLiquidityPool(uint256 _liquidityPool) external onlyOwner returns (bool) {
        liquidityPool = _liquidityPool;
        return true;
    }
}