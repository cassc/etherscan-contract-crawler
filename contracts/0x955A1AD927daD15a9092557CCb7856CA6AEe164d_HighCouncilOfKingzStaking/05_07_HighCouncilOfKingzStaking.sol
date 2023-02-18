// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.17;

/// @title: HighCouncilOfKingzStaking
/// @author: [email protected]

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICOKContracts.sol";

contract HighCouncilOfKingzStaking is Ownable {
    address public originalContract;

    // security
    address public administrator;

    struct StakedInfo {
        address owner;
        uint256 tokenId;
    }

    enum StakingPhase {
        paused,
        allowed,
        locked
    }

    // staking controls
    StakingPhase public phase = StakingPhase.paused;

    mapping(uint256 => StakedInfo) public tokenStakedInfo;
    uint256 public stakedCount;

    /////////  errors

    error InvalidAddress();
    error NotAuthorized();
    error StakingNotAllowed();
    error StakingLocked();
    error OnlyOwnerCanUnstake();

    /////////  modifiers

    /**
     * @dev Modifier to check for active staking
     */
    modifier onlyAllowedStaking() {
        validateAllowedStaking();
        _;
    }

    /**
     * @dev Modifier to check for Admin or Owner role
     */
    modifier onlyAuthorized() {
        validateAuthorized();
        _;
    }

    constructor(address administrator_, address originalContract_) {
        if (administrator_ == address(0)) revert InvalidAddress();
        if (originalContract_ == address(0)) revert InvalidAddress();
        administrator = administrator_;
        originalContract = originalContract_;
    }

    /**
     * @dev Fallback functions in case someone sends ETH to the contract
     */
    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev stake tokens
     * @notice Owners can only stake when phase is Allowed
     */
    function stake(uint256[] memory tokenIds) external onlyAllowedStaking {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            ICOKContracts(originalContract).transferFrom(
                _msgSender(),
                address(this),
                tokenId
            );
            tokenStakedInfo[tokenId] = StakedInfo(_msgSender(), tokenId);
        }
        unchecked {
            stakedCount += tokenIds.length;
        }
    }

    /**
     * @dev unstake tokens
     * @notice Owners can only unstake when phase is Allowed
     */
    function unstake(uint256[] memory tokenIds) external onlyAllowedStaking {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakedInfo memory info = tokenStakedInfo[tokenId];
            if (info.owner != _msgSender()) revert OnlyOwnerCanUnstake();
            delete tokenStakedInfo[tokenId];
            ICOKContracts(originalContract).transferFrom(
                address(this),
                _msgSender(),
                tokenId
            );
        }
        unchecked {
            stakedCount -= tokenIds.length;
        }
    }

    function setStakingPaused() external onlyAuthorized {
        if (phase == StakingPhase.locked) revert StakingLocked();
        phase = StakingPhase.paused;
    }

    function setStakingAllowed() external onlyAuthorized {
        if (phase == StakingPhase.locked) revert StakingLocked();
        phase = StakingPhase.allowed;
    }

    function setStakingLocked() external onlyAuthorized {
        phase = StakingPhase.locked;
    }

    function setOriginalContract(
        address originalContract_
    ) external onlyAuthorized {
        originalContract = originalContract_;
    }

    function setAdministrator(address administrator_) external onlyOwner {
        administrator = administrator_;
    }

    function balanceOf(address owner_) public view returns (uint256) {
        uint256 supply = ICOKContracts(originalContract).totalTokens();
        uint256 count = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (tokenStakedInfo[tokenId].owner == owner_) {
                count++;
            }
        }
        return count;
    }

    function snapshot() external view returns (StakedInfo[] memory) {
        uint256 supply = ICOKContracts(originalContract).totalTokens();
        StakedInfo[] memory currentState = new StakedInfo[](stakedCount);
        uint256 count = 0;

        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            StakedInfo memory info = tokenStakedInfo[tokenId];
            if (info.owner != address(0)) {
                currentState[count] = info;
                count++;
            }
        }
        return currentState;
    }

    /**
     * @dev Validate authorized addresses
     */
    function walletOfOwner(
        address owner_
    ) external view returns (StakedInfo[] memory) {
        uint256 supply = ICOKContracts(originalContract).totalTokens();
        uint256 balance = balanceOf(owner_);
        StakedInfo[] memory tokens = new StakedInfo[](balance);
        uint256 count = 0;

        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            StakedInfo memory token = tokenStakedInfo[tokenId];
            if (token.owner == owner_) {
                tokens[count] = token;
                count++;
            }
        }
        return tokens;
    }

    /**
     * @dev Validate authorized addresses
     */
    function validateAuthorized() private view {
        if (_msgSender() != owner() && _msgSender() != administrator)
            revert NotAuthorized();
    }

    /**
     * @dev Validate if the staking is allowed
     */
    function validateAllowedStaking() private view {
        if (phase != StakingPhase.allowed) revert StakingNotAllowed();
    }

    function withdraw() external payable onlyAuthorized {
        (bool success, ) = payable(address(owner())).call{
            value: address(this).balance
        }("");
        require(success);
    }
}