// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title: NYB Pickle Point
/// @author: niftykit.com

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {StakingStorage} from "./libraries/StakingStorage.sol";
import {StakingRewardsStorage} from "./libraries/StakingRewardsStorage.sol";
import {PresaleStorage} from "./libraries/PresaleStorage.sol";

/// @custom:security-contact [email protected]
contract PicklePoint is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using StakingStorage for StakingStorage.Layout;
    using StakingRewardsStorage for StakingRewardsStorage.Layout;
    using PresaleStorage for PresaleStorage.Layout;
    using MerkleProof for bytes32[];

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address[] memory collections_,
        uint256[] memory pointsPerDay_
    ) ERC20(name_, symbol_) {
        require(
            collections_.length == pointsPerDay_.length,
            "Invalid input length"
        );
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());

        uint256 length = collections_.length;
        StakingStorage.layout().collectionsCount = length;
        StakingStorage.layout().decimals = decimals_;
        for (uint256 i = 0; i < length; ) {
            address collection = collections_[i];
            StakingStorage.layout().collections[collection] = IERC721(
                collection
            );
            StakingRewardsStorage.layout().pointsPerDay[
                collection
            ] = pointsPerDay_[i];
            StakingStorage.layout().collectionsByIndex[i] = collection;
            unchecked {
                i++;
            }
        }
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setMerkleRoot(bytes32 newRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PresaleStorage.layout().merkleRoot = newRoot;
    }

    function addCollection(address collection, uint256 pointsPerDay_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            address(StakingStorage.layout().collections[collection]) ==
                address(0),
            "Collection already exists"
        );
        uint256 newIndex = StakingStorage.layout().collectionsCount;
        StakingStorage.layout().collectionsByIndex[newIndex] = collection;
        StakingStorage.layout().collections[collection] = IERC721(collection);
        StakingRewardsStorage.layout().pointsPerDay[collection] = pointsPerDay_;
        unchecked {
            StakingStorage.layout().collectionsCount++;
        }
    }

    function updateCollection(address collection, uint256 newPointsPerDay)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            address(StakingStorage.layout().collections[collection]) !=
                address(0),
            "Invalid collection"
        );
        StakingRewardsStorage.layout().pointsPerDay[
            collection
        ] = newPointsPerDay;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function batchMint(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) {
        require(recipients.length == amounts.length, "Invalid input length");
        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; ) {
            _mint(recipients[i], amounts[i]);
            unchecked {
                i++;
            }
        }
    }

    function adminUnstake(
        address user,
        address[] calldata collections,
        uint256[][] calldata tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _batchUnstake(user, collections, tokens);
    }

    function stake(address[] calldata collections, uint256[][] calldata tokens)
        external
        whenNotPaused
    {
        require(collections.length == tokens.length, "Invalid input length");
        uint256 collectionsLength = tokens.length;
        for (uint256 i = 0; i < collectionsLength; ) {
            uint256 tokensLength = tokens[i].length;
            for (uint256 j = 0; j < tokensLength; ) {
                _stake(collections[i], tokens[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function unstake(
        address[] calldata collections,
        uint256[][] calldata tokens
    ) external {
        _batchUnstake(_msgSender(), collections, tokens);
    }

    function presaleClaimRewards(uint256 allowed, bytes32[] calldata proof)
        external
    {
        require(
            PresaleStorage.layout().merkleRoot != "",
            "Presale is not active"
        );
        require(
            MerkleProof.verify(
                proof,
                PresaleStorage.layout().merkleRoot,
                keccak256(abi.encodePacked(_msgSender(), allowed))
            ),
            "Presale invalid"
        );
        require(
            !PresaleStorage.layout().claimed[_msgSender()],
            "Already claimed"
        );
        PresaleStorage.layout().claimed[_msgSender()] = true;
        _mint(_msgSender(), allowed);
    }

    function claimRewards() external {
        uint256 rewards = getClaimableRewards(_msgSender());
        require(rewards > 0, "No rewards to claim");
        _mint(_msgSender(), rewards);
        unchecked {
            StakingRewardsStorage.layout().claimedByUser[
                _msgSender()
            ] += rewards;
        }
    }

    function getClaimableRewards(address user) public view returns (uint256) {
        uint256 pending = 0;
        uint256 length = StakingStorage.layout().collectionsCount;
        for (uint256 i = 0; i < length; ) {
            unchecked {
                pending += _getPendingRewardsPerUser(
                    StakingStorage.layout().collectionsByIndex[i],
                    user
                );
                i++;
            }
        }
        return
            StakingRewardsStorage.layout().claimableByUser[user] +
            pending -
            StakingRewardsStorage.layout().claimedByUser[user];
    }

    function getClaimedRewards(address user) public view returns (uint256) {
        return StakingRewardsStorage.layout().claimedByUser[user];
    }

    function stakingCount(address collection, address user)
        external
        view
        returns (uint256)
    {
        return StakingStorage.layout().stakingCount[collection][user];
    }

    function tokenByIndex(
        address collection,
        address user,
        uint256 index
    ) external view returns (uint256) {
        return StakingStorage.layout().tokensByIndex[collection][user][index];
    }

    function staking(
        address collection,
        address user,
        uint256 tokenId
    ) external view returns (bool) {
        return StakingStorage.layout().staking[collection][user][tokenId];
    }

    function pointsPerDay(address collection) external view returns (uint256) {
        return StakingRewardsStorage.layout().pointsPerDay[collection];
    }

    function collectionsCount() external view returns (uint256) {
        return StakingStorage.layout().collectionsCount;
    }

    function collectionByIndex(uint256 index) external view returns (address) {
        return StakingStorage.layout().collectionsByIndex[index];
    }

    function presaleClaimed(address user) external view returns (bool) {
        return PresaleStorage.layout().claimed[user];
    }

    function decimals() public view override returns (uint8) {
        return StakingStorage.layout().decimals;
    }

    function _stake(address collection, uint256 tokenId) internal {
        require(
            address(StakingStorage.layout().collections[collection]) !=
                address(0),
            "Invalid collection"
        );
        StakingStorage.layout().collections[collection].transferFrom(
            _msgSender(),
            address(this),
            tokenId
        );
        if (
            StakingStorage.layout().stakingStart[collection][_msgSender()][
                tokenId
            ] == 0
        ) {
            uint256 lastIndex = StakingStorage.layout().stakingCount[
                collection
            ][_msgSender()];
            StakingStorage.layout().tokensByIndex[collection][_msgSender()][
                    lastIndex
                ] = tokenId;
            unchecked {
                StakingStorage.layout().stakingCount[collection][
                    _msgSender()
                ]++;
            }
        }
        StakingStorage.layout().stakingStart[collection][_msgSender()][
            tokenId
        ] = block.timestamp;
        StakingStorage.layout().staking[collection][_msgSender()][
            tokenId
        ] = true;
    }

    function _unstake(
        address user,
        address collection,
        uint256 tokenId
    ) internal {
        require(
            address(StakingStorage.layout().collections[collection]) !=
                address(0),
            "Invalid collection"
        );
        require(
            StakingStorage.layout().staking[collection][user][tokenId],
            "Token is not staked"
        );
        StakingStorage.layout().collections[collection].transferFrom(
            address(this),
            user,
            tokenId
        );
        unchecked {
            StakingRewardsStorage.layout().claimableByUser[
                    user
                ] += _getPendingRewardsPerToken(collection, user, tokenId);
        }

        StakingStorage.layout().staking[collection][user][tokenId] = false;
    }

    function _batchUnstake(
        address user,
        address[] calldata collections,
        uint256[][] calldata tokens
    ) internal {
        require(collections.length == tokens.length, "Invalid input length");
        uint256 collectionsLength = tokens.length;
        for (uint256 i = 0; i < collectionsLength; ) {
            uint256 tokensLength = tokens[i].length;
            for (uint256 j = 0; j < tokensLength; ) {
                _unstake(user, collections[i], tokens[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function _getPendingRewardsPerUser(address collection, address user)
        internal
        view
        returns (uint256)
    {
        uint256 length = StakingStorage.layout().stakingCount[collection][user];

        uint256 total = 0;

        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = StakingStorage.layout().tokensByIndex[collection][
                user
            ][i];

            uint256 tokenRewards = _getPendingRewardsPerToken(
                collection,
                user,
                tokenId
            );
            unchecked {
                i++;
                total += tokenRewards;
            }
        }

        return total;
    }

    function _getPendingRewardsPerToken(
        address collection,
        address user,
        uint256 tokenId
    ) internal view returns (uint256) {
        if (!StakingStorage.layout().staking[collection][user][tokenId]) {
            return 0;
        }
        uint256 duration = block.timestamp -
            StakingStorage.layout().stakingStart[collection][user][tokenId];
        if (duration > 0) {
            return
                (StakingRewardsStorage.layout().pointsPerDay[collection] *
                    duration) / 86400;
        }

        return 0;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}