// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./FxBaseRootTunnel.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SkyFarm
/// @author aceplxx (https://twitter.com/aceplxx)

contract SkyFarm is FxBaseRootTunnel, Ownable {

    /* ========== STORAGE ========== */

    /// @notice ERC721 instance of the Skyverse contract.
    /// non-immutable for emergency purpose
    ERC721 public skyverseContract;

    mapping(address => uint256[]) private stakedIds;
    mapping(uint256 => uint256) public tokenIndex;
    mapping(uint256 => address) public stakedBy;

    bool public paused = true;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address skyverseERC721,
        address checkpointManager,
        address fxRoot
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        skyverseContract = ERC721(skyverseERC721);
    }

    /* ========== MODIFIERS ========== */

    modifier notPaused(){
        require(!paused, "Staking paused.");
        _;
    }

    /* ========== EVENTS ========== */

    //@dev Emitted when `tokenId` token is staked/N.
    event Stake(address user, uint256 tokenId, bool stake);

    /* ========== OWNER FUNCTIONS ========== */

    /// @notice Set the contract address for all contract instances.
    /// @param skyverseERC721 The contract address of Skyverse.
    function setContract(address skyverseERC721) external onlyOwner{
        skyverseContract = ERC721(skyverseERC721);
    }

    /// @notice Pauses staking and unstaking
    function togglePause() public onlyOwner {
        paused = !paused;
    }

    /* ========== PUBLIC READ ========== */

    /// @notice For collab.land to give a role based on staking status / in wallet NFT
    function balanceOf(address owner) external view returns (uint256) {
        uint256[] memory skyverses = stakedIds[owner];
        uint256 balances = 0;
        return balances + skyverses.length + skyverseContract.balanceOf(owner);
    }

    function getStakedIds(address user)
        external
        view
        returns (
            uint256[] memory skyverses
        )
    {
        return (
            stakedIds[user]
        );
    }

    /* ========== PUBLIC MUTATIVE ========== */

    function stake(uint256 tokenId) external notPaused {
        stakedBy[tokenId] = msg.sender;
        tokenIndex[tokenId] = stakedIds[msg.sender].length;
        stakedIds[msg.sender].push(tokenId);

        skyverseContract.transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        _sendMessageToChild(
            abi.encode(
                msg.sender,
                tokenId,
                true
            )
        );

        emit Stake(msg.sender, tokenId, true);
    }

    function unstake(uint256 tokenId) external notPaused {
        require(stakedBy[tokenId] == msg.sender, "Not staker!");

        if(stakedIds[msg.sender].length > 1){
            uint256 lastTokenId = stakedIds[msg.sender][stakedIds[msg.sender].length - 1];
            uint256 lastTokenIndexNew = tokenIndex[tokenId];

            stakedIds[msg.sender][lastTokenIndexNew] = lastTokenId;
            stakedIds[msg.sender].pop();

            tokenIndex[lastTokenId] = lastTokenIndexNew;
        } else {
            stakedIds[msg.sender].pop();
        }

        delete stakedBy[tokenId];
        delete tokenIndex[tokenId];

        skyverseContract.transferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        _sendMessageToChild(
            abi.encode(
                msg.sender,
                tokenId,
                false
            )
        );

        emit Stake(msg.sender, tokenId, false);
    }

    function stakeMultiple(uint256[] calldata tokenIds) external notPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenIndex[tokenIds[i]] = stakedIds[msg.sender].length;
            stakedBy[tokenIds[i]] = msg.sender;
            stakedIds[msg.sender].push(tokenIds[i]);

            skyverseContract.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            _sendMessageToChild(
                abi.encode(
                    msg.sender,
                    tokenIds[i],
                    true
                )
            );

            emit Stake(msg.sender, tokenIds[i], true);
        }
    }

    function unstakeMultiple(uint256[] calldata tokenIds) external notPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(stakedBy[tokenIds[i]] == msg.sender, "Not staker!");
            
            if(stakedIds[msg.sender].length > 1){
                uint256 lastTokenId = stakedIds[msg.sender][stakedIds[msg.sender].length - 1];
                uint256 lastTokenIndexNew = tokenIndex[tokenIds[i]];

                stakedIds[msg.sender][lastTokenIndexNew] = lastTokenId;
                stakedIds[msg.sender].pop();

                tokenIndex[lastTokenId] = lastTokenIndexNew;
            } else {
                stakedIds[msg.sender].pop();
            }

            delete stakedBy[tokenIds[i]];
            delete tokenIndex[tokenIds[i]];

            skyverseContract.transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            _sendMessageToChild(
                abi.encode(
                    msg.sender,
                    tokenIds[i],
                    false
                )
            );

            emit Stake(msg.sender, tokenIds[i], false);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _processMessageFromChild(bytes memory message) internal override {
        // n/a
    }

}