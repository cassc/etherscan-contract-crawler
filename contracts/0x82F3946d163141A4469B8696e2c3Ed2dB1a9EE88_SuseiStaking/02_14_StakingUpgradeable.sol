// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ReceiverUpgradeable.sol";
import "./TrackerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract StakingUpgradeable is 
    Initializable, 
    ReceiverUpgradeable, 
    TrackerUpgradeable
{    
    event Staked(address owner, uint256 id);
    event Unstaked(address owner, uint256 id);

    function __StakingUpgradeable_init(IERC721Upgradeable nft_) internal onlyInitializing {
        __Receiver_init(nft_);
        __Tracker_init();
    }

    function _after(uint256 total) internal virtual {}

    function _stake(
        uint256[] calldata ids_,
        address owner_
    ) 
        internal
    {
        uint256 length = ids_.length;
        for(uint256 i; i < length; i++) {
            uint256 current = ids_[i];
            Token memory token = token(current);
            token.timestamp = block.timestamp;
            token.owner = owner_;
            _setToken(token, current);
            _receive(current, owner_);
        }
        _increaseBalance(owner_, length);
    }


    function _updateStake(
        uint256[] calldata ids_,
        address owner_
    ) 
        internal
    {
        uint256 length = ids_.length;
        for(uint256 i; i < length; i++) {
            uint256 current = ids_[i];
            Token memory token = token(current);
            token.timestamp = block.timestamp;
            token.owner = owner_;
            _setToken(token, current);
        }
        _increaseBalance(owner_, length);
    }


    function _claim(
        uint256[] calldata ids_,
        address owner_
    ) 
        internal
    {
        uint256 length = ids_.length;
        uint256 total = 0;
        for(uint256 i; i < length; i++) {
           uint256 current = ids_[i];
            Token memory token = token(current);
            require(token.owner == owner_, "not owner");
            uint256 accrued = token.timestamp;
            token.timestamp = 0;
            token.accrued += accrued;
            total += accrued;
        }
        _after(total);
    }

    function _unstake(
        uint256[] calldata ids_,        
        address owner_,
        bool trackTotal_
    )
        internal
    {
        uint256 length = ids_.length;
        uint256 total;
        for(uint256 i; i < length; i++) {
            uint256 current = ids_[i];
            Token memory token = token(current);
            require(token.owner == owner_, "not owner");
            uint256 accrued = block.timestamp - token.timestamp;
            token.timestamp = 0;
            token.accrued += accrued;
            if(trackTotal_) total += accrued;
            token.owner = address(0x0);
            _setToken(token, current);
            _return(current, owner_);
        }
        _decreaseBalance(msg.sender, length);
        _after(total);
    }

    function getAccrued(uint256[] calldata ids_, bool isDay) public view returns (uint256[] memory accured) {
        uint256 length = ids_.length;
        uint256[] memory accrued = new uint256[](length);
        for(uint256 i = 0; i < ids_.length; i++) {
            Token memory token = token(ids_[i]);
            uint256 accumulated = token.owner == address(0x0) ? 0 : (block.timestamp - token.timestamp);
            uint256 total = token.accrued + accumulated;
            accrued[i] = isDay ? total / 1 days : total;
        }
        return accrued;
    }
}