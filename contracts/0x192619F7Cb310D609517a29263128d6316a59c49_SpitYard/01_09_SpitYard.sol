// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";

///@title SpitYard - A collaboration between Llamaverse and PG
///@author WhiteOakKong
///@notice Spityard handles staking and unstaking of SpitBuddies, and communicates with JIRACentral/SpitDispenser contracts.

interface IJiraCentral {
    function _increaseGeneration(address _address, uint256 dailyAmount) external;

    function _decreaseGeneration(address _address, uint256 dailyAmount) external;
}

contract SpitYard is FxBaseRootTunnel, Ownable {
    /*///////////////////////////////////////////////////////////////
    //                      STORAGE                               //
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256[]) public userStake;

    IERC721A public spitBuddies;
    IJiraCentral public jiraCentral;

    bool public stakingPaused;

    uint256 public constant JIRA_REWARD = 6 ether;

    /*///////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                           //
    //////////////////////////////////////////////////////////////*/
    constructor(
        address checkpointManager,
        address fxRoot,
        address _spitBuddiesContract
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        spitBuddies = IERC721A(_spitBuddiesContract);
    }

    /*///////////////////////////////////////////////////////////////
    //                    STAKING FUNCTIONS                       //
    //////////////////////////////////////////////////////////////*/

    ///@notice Allows user to stake a spitBuddy
    function stake(uint256[] memory tokenIds) external {
        require(!stakingPaused, "Staking is currently paused.");
        uint256 value = tokenIds.length;
        for (uint256 i; i < value; i++) {
            spitBuddies.transferFrom(msg.sender, address(this), tokenIds[i]);
            userStake[msg.sender].push(tokenIds[i]);
        }
        _sendMessageToChild(abi.encode(msg.sender, value, true));
        jiraCentral._increaseGeneration(msg.sender, value * JIRA_REWARD);
    }

    
    function unstake(uint256[] memory tokenIds) external {
        require(!stakingPaused, "Staking is currently paused.");
        uint256 value = tokenIds.length;
        for (uint256 i; i < value; i++) {
            removeToken(msg.sender, tokenIds[i]);
            spitBuddies.transferFrom(address(this), msg.sender, tokenIds[i]);
        }
        _sendMessageToChild(abi.encode(msg.sender, value, false));
        jiraCentral._decreaseGeneration(msg.sender, value * JIRA_REWARD);
    }

    function getUserStake(address _address) external view returns (uint256[] memory) {
        return userStake[_address];
    }

    /*///////////////////////////////////////////////////////////////
                    ACCESS RESTRICTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the contract address for the SpitBuddies contract.
    /// @param _spitBuddiesContract The contract address of SpitBuddies.
    function setSpitBuddies(address _spitBuddiesContract) external onlyOwner {
        spitBuddies = IERC721A(_spitBuddiesContract);
    }

    /// @notice Set the contract addresses for all contract instances.
    /// @param _jiraCentral The contract address of JiraCentral.
    function setJiraCentral(address _jiraCentral) external onlyOwner {
        jiraCentral = IJiraCentral(_jiraCentral);
    }

    /// @notice Pauses staking and unstaking, for emergency purposes
    function setStakingPaused(bool paused) external onlyOwner {
        stakingPaused = paused;
    }

    /*///////////////////////////////////////////////////////////////
                         UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns staked token count for a given address.
    function balanceOf(address owner) external view returns (uint256) {
        return userStake[owner].length;
    }

      function removeToken(address _user, uint256 tokenId) internal {
        if (userStake[_user].length == 0) revert("Caller Not Owner Of Token");
        for (uint256 i; i < userStake[_user].length; i++) {
            if (userStake[_user][i] == tokenId) {
                userStake[_user][i] = userStake[_user][userStake[_user].length - 1];
                userStake[_user].pop();
                break;
            }
            if (i == userStake[_user].length - 1 && userStake[_user][i] != tokenId) revert("Caller Not Owner Of Token");
        }
    }

    function _processMessageFromChild(bytes memory message) internal override {
        // 🐲🦙
    }
}