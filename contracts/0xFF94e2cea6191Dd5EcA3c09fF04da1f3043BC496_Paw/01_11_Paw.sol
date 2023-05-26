// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import "hardhat/console.sol";

import "./Interfaces.sol";

/// @title Paw Token contract
contract Paw is IPaw, ERC20, Ownable {

    IKumaVerse public kumaContract;
    IKumaTracker public trackerContract;

    uint40 public yieldStartTime = 1649476800;
    uint40 public yieldEndTime = 1965096000;

    // Yield Info
    uint256 public globalModulus = (10 ** 14);
    uint40 public kumaYieldRate = uint40(5 ether / globalModulus);
    uint40 public trackerYieldRate = uint40(7 ether / globalModulus);

    struct Yield {
        uint40 lastUpdatedTime;
        uint176 pendingRewards;
    }

    mapping(address => Yield) public addressToYield;

    event Claim(address to_, uint256 amount_);

    constructor() ERC20('Paw', 'PAW') {
    }

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    //// YIELD STUFF ////

    function setKumaverse(address _address) public onlyOwner {
        kumaContract = IKumaVerse(_address);
    }

    function setTracker(address _address) public onlyOwner {
        trackerContract = IKumaTracker(_address);
    }

    function _calculateYieldReward(address _address) internal view returns (uint176) {
        uint256 totalYieldRate = uint256(_getYieldRate(_address));
        if (totalYieldRate == 0) {return 0;}
        uint256 time = uint256(_getTimestamp());
        uint256 lastUpdate = uint256(addressToYield[_address].lastUpdatedTime);

        if (lastUpdate > yieldStartTime) {
            return uint176((totalYieldRate * (time - lastUpdate) / 1 days));
        } else {return 0;}
    }

    function _updateYieldReward(address _address) internal {
        uint40 time = _getTimestamp();
        uint40 lastUpdate = addressToYield[_address].lastUpdatedTime;

        if (lastUpdate > 0) {
            addressToYield[_address].pendingRewards += _calculateYieldReward(_address);
        }
        if (lastUpdate != yieldEndTime) {
            addressToYield[_address].lastUpdatedTime = time;
        }
    }

    function _claimYieldReward(address _address) internal {
        uint176 pendingRewards = addressToYield[_address].pendingRewards;

        if (pendingRewards > 0) {
            addressToYield[_address].pendingRewards = 0;

            uint256 expandedReward = uint256(uint256(pendingRewards) * globalModulus);

            _mint(_address, expandedReward);
            emit Claim(_address, expandedReward);
        }
    }

    function updateReward(address _address) public {
        _updateYieldReward(_address);
    }

    function claimTokens() public {
        _updateYieldReward(msg.sender);
        _claimYieldReward(msg.sender);
    }

    function setYieldEndTime(uint40 yieldEndTime_) external onlyOwner {
        yieldEndTime = yieldEndTime_;
    }

    // internal

    function _getSmallerValueUint40(uint40 a, uint40 b) internal pure returns (uint40) {
        return a < b ? a : b;
    }

    function _getTimestamp() internal view returns (uint40) {
        return _getSmallerValueUint40(uint40(block.timestamp), yieldEndTime);
    }

    function _getYieldRate(address _address) internal view returns (uint256) {
        uint256 kumaYield = 0;
        if (address(kumaContract) != address(0x0)) {
            kumaYield = (kumaContract.balanceOf(_address) * kumaYieldRate);
        }
        uint256 trackerYield = (trackerContract.balanceOf(_address, 1) * trackerYieldRate);
        uint256 total = kumaYield + trackerYield;

        return total;
    }

    function getStorageClaimableTokens(address _address) public view returns (uint256) {
        return uint256(uint256(addressToYield[_address].pendingRewards) * globalModulus);
    }

    function getPendingClaimableTokens(address _address) public view returns (uint256) {
        return uint256(uint256(_calculateYieldReward(_address)) * globalModulus);
    }

    function getTotalClaimableTokens(address _address) public view returns (uint256) {
        return uint256((uint256(addressToYield[_address].pendingRewards) + uint256(_calculateYieldReward(_address))) * globalModulus);
    }

    function getYieldRateOfAddress(address _address) public view returns (uint256) {
        return uint256(uint256(_getYieldRate(_address)) * globalModulus);
    }

    function raw_getStorageClaimableTokens(address _address) public view returns (uint256) {
        return uint256(addressToYield[_address].pendingRewards);
    }

    function raw_getPendingClaimableTokens(address _address) public view returns (uint256) {
        return uint256(_calculateYieldReward(_address));
    }

    function raw_getTotalClaimableTokens(address _address) public view returns (uint256) {
        return uint256(uint256(addressToYield[_address].pendingRewards) + uint256(_calculateYieldReward(_address)));
    }


}