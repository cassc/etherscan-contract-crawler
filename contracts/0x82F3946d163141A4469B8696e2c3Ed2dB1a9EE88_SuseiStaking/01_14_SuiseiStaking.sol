// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./staking/StakingUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./admin-manager/AdminManagerUpgradable.sol";

contract SuseiStaking is 
    Initializable, 
    StakingUpgradeable,
    ReentrancyGuardUpgradeable, 
    PausableUpgradeable,
    AdminManagerUpgradable
{
    function initialize(IERC721Upgradeable nft_) public initializer {
       __StakingUpgradeable_init(nft_);
       __AdminManager_init_unchained();
       __ReentrancyGuard_init();
       __Pausable_init();
    }

    function stake(
        uint256[] calldata ids_
    ) 
        external 
        nonReentrant 
        whenNotPaused 
    {
        _stake(ids_, msg.sender);        
    }

    function stakeFor(
        uint256[] calldata ids_,
        address owner_
    )
        external
        nonReentrant
        whenNotPaused
    {
        require(msg.sender == address(nft), "only NFT address can call this");
        _updateStake(ids_, owner_);
    }

    function unstake(
        uint256[] calldata ids_
    )
        external 
        nonReentrant
        whenNotPaused 
    {
        _unstake(ids_, msg.sender, false);
    }
}