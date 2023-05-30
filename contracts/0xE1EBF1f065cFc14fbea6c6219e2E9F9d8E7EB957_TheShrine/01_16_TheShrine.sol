// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./FxBaseRootTunnel.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title TheShrine
/// @author rektt (https://twitter.com/rekttdoteth)

contract TheShrine is FxBaseRootTunnel, Ownable {
    /* ========== STORAGE ========== */

    mapping(address => mapping(address => uint256[]))
        private addressToContractStakedIds;
    mapping(address => mapping(uint256 => uint256)) public contractToTokenIndex;
    mapping(address => mapping(uint256 => address))
        public contractToTokenStaker;
    mapping(address => bool) public whitelistedContract;

    //contract > tokenId > lockup period in delta times
    mapping(address => mapping(uint256 => uint256)) public unlockOn;

    bool public paused = true;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address hakiERC721,
        address sekiraERC721,
        address checkpointManager,
        address fxRoot
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        whitelistedContract[hakiERC721] = true;
        whitelistedContract[sekiraERC721] = true;
    }

    /* ========== EVENTS ========== */

    //@dev Emitted when `tokenId` token is staked/N.
    event Stake(address user, address collection, uint256 tokenId, bool stake);

    /* ========== ERRORS ========== */

    error CollectionNotWhitelisted(address collection);
    error NotStaker(address attemptedStaker, address actualStaker);
    error TokenLocked(uint256 tokenId, uint256 currentTime, uint256 unlockTime);
    error Paused();

    /* ========== MODIFIERS ========== */

    modifier notPaused() {
        if (paused) revert Paused();
        _;
    }

    /* ========== OWNER FUNCTIONS ========== */

    /// @notice Set the contract address for all contract instances.
    /// @param contracts The contract address to be whitelisted.
    /// @param state The wl state.
    function setContract(address[] calldata contracts, bool state)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < contracts.length; i++) {
            whitelistedContract[contracts[i]] = state;
        }
    }

    /// @notice Pauses staking and unstaking
    function togglePause() external onlyOwner {
        paused = !paused;
    }

    /* ========== PUBLIC READ ========== */

    /// @notice For collab.land to give a role based on staking status / in wallet NFT
    function balanceOf(address owner) external view returns (uint256) {
        address hakiContract = 0x7887f40763aCe5f0e8320181FD5B42776D35B1FF;
        return
            addressToContractStakedIds[owner][hakiContract].length +
            ERC721(hakiContract).balanceOf(owner);
    }

    function getStakedIds(address user, address collection)
        external
        view
        returns (uint256[] memory stakedIds)
    {
        return (addressToContractStakedIds[user][collection]);
    }

    /* ========== PUBLIC MUTATIVE ========== */

    function stake(
        uint256 tokenId,
        address collection,
        uint256 lockupDays
    ) external notPaused {
        if (!whitelistedContract[collection])
            revert CollectionNotWhitelisted({collection: collection});

        contractToTokenStaker[collection][tokenId] = msg.sender;
        contractToTokenIndex[collection][tokenId] = addressToContractStakedIds[
            msg.sender
        ][collection].length;
        addressToContractStakedIds[msg.sender][collection].push(tokenId);

        uint256 lockupDelta = lockupDays * 1 days;
        unlockOn[collection][tokenId] = block.timestamp + lockupDelta;

        ERC721(collection).transferFrom(msg.sender, address(this), tokenId);

        _sendMessageToChild(
            abi.encode(msg.sender, collection, tokenId, lockupDelta, true)
        );

        emit Stake(msg.sender, collection, tokenId, true);
    }

    function unstake(uint256 tokenId, address collection) external notPaused {
        if (contractToTokenStaker[collection][tokenId] != msg.sender)
            revert NotStaker({
                attemptedStaker: msg.sender,
                actualStaker: contractToTokenStaker[collection][tokenId]
            });

        if (unlockOn[collection][tokenId] > block.timestamp)
            revert TokenLocked({
                tokenId: tokenId,
                currentTime: block.timestamp,
                unlockTime: unlockOn[collection][tokenId]
            });

        if (addressToContractStakedIds[msg.sender][collection].length > 1) {
            uint256 lastTokenId = addressToContractStakedIds[msg.sender][
                collection
            ][addressToContractStakedIds[msg.sender][collection].length - 1];

            uint256 lastTokenIndexNew = contractToTokenIndex[collection][
                tokenId
            ];

            addressToContractStakedIds[msg.sender][collection][
                lastTokenIndexNew
            ] = lastTokenId;
            addressToContractStakedIds[msg.sender][collection].pop();

            contractToTokenIndex[collection][lastTokenId] = lastTokenIndexNew;
        } else {
            addressToContractStakedIds[msg.sender][collection].pop();
        }

        delete contractToTokenStaker[collection][tokenId];
        delete contractToTokenIndex[collection][tokenId];

        ERC721(collection).transferFrom(address(this), msg.sender, tokenId);

        _sendMessageToChild(
            abi.encode(msg.sender, collection, tokenId, 0, false)
        );

        emit Stake(msg.sender, collection, tokenId, false);
    }

    function stakeMultiple(
        uint256[] calldata tokenIds,
        address collection,
        uint256[] calldata lockupDays
    ) external notPaused {
        if (!whitelistedContract[collection])
            revert CollectionNotWhitelisted({collection: collection});

        require(
            tokenIds.length == lockupDays.length,
            "tokenIds & lockupDays missmatch"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            contractToTokenIndex[collection][
                tokenIds[i]
            ] = addressToContractStakedIds[msg.sender][collection].length;
            contractToTokenStaker[collection][tokenIds[i]] = msg.sender;
            addressToContractStakedIds[msg.sender][collection].push(
                tokenIds[i]
            );

            uint256 lockupDelta = lockupDays[i] * 1 days;
            unlockOn[collection][tokenIds[i]] = block.timestamp + lockupDelta;

            ERC721(collection).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            _sendMessageToChild(
                abi.encode(
                    msg.sender,
                    collection,
                    tokenIds[i],
                    lockupDelta,
                    true
                )
            );

            emit Stake(msg.sender, collection, tokenIds[i], true);
        }
    }

    function unstakeMultiple(uint256[] calldata tokenIds, address collection)
        external
        notPaused
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (contractToTokenStaker[collection][tokenIds[i]] != msg.sender)
                revert NotStaker({
                    attemptedStaker: msg.sender,
                    actualStaker: contractToTokenStaker[collection][tokenIds[i]]
                });

            if (unlockOn[collection][tokenIds[i]] > block.timestamp)
                revert TokenLocked({
                    tokenId: tokenIds[i],
                    currentTime: block.timestamp,
                    unlockTime: unlockOn[collection][tokenIds[i]]
                });

            if (addressToContractStakedIds[msg.sender][collection].length > 1) {
                uint256 lastTokenId = addressToContractStakedIds[msg.sender][
                    collection
                ][
                    addressToContractStakedIds[msg.sender][collection].length -
                        1
                ];
                uint256 lastTokenIndexNew = contractToTokenIndex[collection][
                    tokenIds[i]
                ];

                addressToContractStakedIds[msg.sender][collection][
                    lastTokenIndexNew
                ] = lastTokenId;
                addressToContractStakedIds[msg.sender][collection].pop();

                contractToTokenIndex[collection][
                    lastTokenId
                ] = lastTokenIndexNew;
            } else {
                addressToContractStakedIds[msg.sender][collection].pop();
            }

            delete contractToTokenStaker[collection][tokenIds[i]];
            delete contractToTokenIndex[collection][tokenIds[i]];

            ERC721(collection).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            _sendMessageToChild(
                abi.encode(msg.sender, collection, tokenIds[i], 0, false)
            );

            emit Stake(msg.sender, collection, tokenIds[i], false);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _processMessageFromChild(bytes memory message) internal override {
        // n/a
    }
}