// SPDX-License-Identifier: Unlicense
// Version 0.0.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IEve.sol";
import "./utils.sol";

contract GenesisStoneEveStaking is AccessControl {
    // Using
    using EnumerableSet for EnumerableSet.UintSet;

    // Struct
    struct StakedNFTInfo {
        address stakedBy; // Address of the staker. Once set, never changes. If never staked, the value is zero address.
        uint64 stakedTime; // Staked time. 0 if not currently staked
        bool minted; // whether the nft has been used to min an Eve
    }

    struct StakerInfo {
        EnumerableSet.UintSet stakedNFTs; // The CURRENTLY staked tokenIds
        EnumerableSet.UintSet mintedNFTs; // minted tokenIds
        bool fiveStonesMinted; // whether the staker has minted the five stones reward
        bool tenStonesMinted; // whether the staker has minted the ten stones reward
    }

    // Events
    event EveMinted(uint256 indexed tokenId, uint8 indexed mintType); // mintType defined in constants

    // Constants
    uint8 public constant MINT_TYPE_NORMAL = 0;
    uint8 public constant MINT_TYPE_MYTHIC = 1;
    uint8 public constant MINT_TYPE_FIVE = 2;
    uint8 public constant MINT_TYPE_TEN = 3;
    uint16 public constant MAX_GENESISSTONE_NFTS = 1000;
    IERC721 public immutable GENESIS_STONE_CONTRACT;
    IEve public immutable EVE_CONTRACT;

    // Public variables
    uint256 public stakingPeriod;

    // Private variables
    mapping(uint256 => StakedNFTInfo) private _stakedNFTInfos; // tokenId => StakedNFTInfo
    mapping(address => StakerInfo) private _stakerInfos; // staker => StakerInfo

    /// @notice Initializes a new instance of the GenesisStoneStaking contract.
    /// @dev Grants the DEFAULT_ADMIN_ROLE to the defaultAdmin_ address
    /// @param defaultAdmin_ The address to be granted the DEFAULT_ADMIN_ROLE.
    /// @param genesisStoneContract_ The address of the deployed GenesisStone contract.
    /// @param eveContract_ The address of the deployed Eve contract.
    /// @param stakingPeriod_ The staking period in seconds.
    constructor(
        address defaultAdmin_,
        address genesisStoneContract_,
        address eveContract_,
        uint256 stakingPeriod_
    ) {
        if (defaultAdmin_ == address(0)) {
            revert Utils.AdminIsZeroAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin_);

        if (!Utils.contractExists(genesisStoneContract_)) {
            revert Utils.ContractDoesNotExist();
        }
        GENESIS_STONE_CONTRACT = IERC721(genesisStoneContract_);

        if (!Utils.contractExists(eveContract_)) {
            revert Utils.ContractDoesNotExist();
        }
        EVE_CONTRACT = IEve(eveContract_);

        if (stakingPeriod_ == 0) {
            revert Utils.StakingPeriodIsZero();
        }
        stakingPeriod = stakingPeriod_;
    }

    /// @notice Stakes multiple GenesisStone NFTs
    /// @param tokenIds_ An array of GenesisStone NFT tokenIds that will be staked
    function stake(uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; ) {
            uint256 tokenId = tokenIds_[i];

            if (_stakedNFTInfos[tokenId].stakedBy != address(0)) {
                revert Utils.TokenAlreadyStaked();
            }

            if (GENESIS_STONE_CONTRACT.ownerOf(tokenId) != msg.sender) {
                revert Utils.NotTheOwnerOfTheToken();
            }

            _stakedNFTInfos[tokenId].stakedBy = msg.sender;
            _stakedNFTInfos[tokenId].stakedTime = uint64(block.timestamp);
            _stakerInfos[msg.sender].stakedNFTs.add(tokenId);
            GENESIS_STONE_CONTRACT.transferFrom(
                msg.sender,
                address(this),
                tokenId
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Sets the staking period
    /// @param stakingPeriod_ The new staking period
    function setStakingPeriod(
        uint256 stakingPeriod_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingPeriod = stakingPeriod_;
    }

    /// @notice Checks if the given GenesisStone NFTs are already staked
    /// @param tokenIds_ An array of GenesisStone NFT tokenIds
    /// @return An array of bool values indicating the staking status of each tokenId
    function isAlreadyStaked(
        uint256[] calldata tokenIds_
    ) external view returns (bool[] memory) {
        bool[] memory results = new bool[](tokenIds_.length);

        for (uint256 i = 0; i < tokenIds_.length; ) {
            results[i] = _stakedNFTInfos[tokenIds_[i]].stakedBy != address(0);

            unchecked {
                ++i;
            }
        }

        return results;
    }

    /// @notice Returns the staker of the given GenesisStone NFTs
    /// @param tokenIds_ An array of GenesisStone NFT tokenIds
    /// @return An array of addresses, where each address is the staker of the corresponding tokenId
    function stakerOf(
        uint256[] calldata tokenIds_
    ) external view returns (address[] memory) {
        address[] memory results = new address[](tokenIds_.length);

        for (uint256 i = 0; i < tokenIds_.length; ) {
            results[i] = _stakedNFTInfos[tokenIds_[i]].stakedBy;
            unchecked {
                ++i;
            }
        }

        return results;
    }

    /// @notice Returns the staked GenesisStone NFTs of the given user
    /// @param user_ The address of the user
    /// @return An array of GenesisStone NFT tokenIds staked by the user
    function stakedNFTOf(
        address user_
    ) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage stakedTokens = _stakerInfos[user_]
            .stakedNFTs;
        uint256 stakedCount = stakedTokens.length();

        uint256[] memory results = new uint256[](stakedCount);
        for (uint256 i = 0; i < stakedCount; ) {
            results[i] = stakedTokens.at(i);
            unchecked {
                ++i;
            }
        }

        return results;
    }

    /// @notice Returns all staked GenesisStone NFTs.
    /// This function should only be called off-chain. An on-chain call to this function will be extremely expensive.
    /// @return An array of staked GenesisStone NFT tokenIds
    function getAllStakedNFTs() external view returns (uint256[] memory) {
        // Figure out how many NFTs are currently staked and create the results array
        uint256[] memory results = new uint256[](
            GENESIS_STONE_CONTRACT.balanceOf(address(this))
        );

        // Scan through all the NFT ids of GenesisStone
        uint256 count = 0;
        for (uint256 i = 0; i < MAX_GENESISSTONE_NFTS; ) {
            unchecked {
                if (_stakedNFTInfos[i].stakedTime != 0) {
                    results[count++] = i;
                }
                ++i;
            }
        }
        return results;
    }

    /// @dev Checks if staking is complete for each tokenId in the provided array.
    /// @param tokenIds_ An array of tokenIds for which the staking completion status will be checked.
    /// @return results An array of bool values indicating staking completion status for each corresponding tokenId.
    /// Each value in the results array is 'true' if staking is complete for the tokenId, and 'false' otherwise.
    function isStakingComplete(
        uint256[] calldata tokenIds_
    ) external view returns (bool[] memory) {
        bool[] memory results = new bool[](tokenIds_.length);

        for (uint256 i = 0; i < tokenIds_.length; ) {
            results[i] = _stakingComplete(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }

        return results;
    }

    /// @dev Checks if staking is complete for the given tokenId.
    /// @param tokenId_ The tokenId for which the staking completion status will be checked.
    /// @return True if staking is complete for the tokenId
    function _stakingComplete(uint256 tokenId_) private view returns (bool) {
        unchecked {
            return
                _stakedNFTInfos[tokenId_].stakedTime != 0 &&
                block.timestamp >=
                _stakedNFTInfos[tokenId_].stakedTime + stakingPeriod;
        }
    }

    /// @notice Returns the staking timestamps of the given GenesisStone NFTs
    /// @param tokenIds_ An array of GenesisStone NFT tokenIds
    /// @return results An array of timestamps, where each timestamp corresponds to the staking time of the tokenId
    function stakedNFTTime(
        uint256[] calldata tokenIds_
    ) external view returns (uint64[] memory) {
        uint64[] memory results = new uint64[](tokenIds_.length);

        for (uint256 i = 0; i < tokenIds_.length; ) {
            results[i] = _stakedNFTInfos[tokenIds_[i]].stakedTime;
            unchecked {
                ++i;
            }
        }

        return results;
    }

    /// @dev Returns the number of currently staked GenesisStone NFTs
    /// @return result The number of currently staked GenesisStone NFTs
    function _completedStakes(
        address user_
    ) private view returns (uint256 result) {
        EnumerableSet.UintSet storage stakedTokens = _stakerInfos[user_]
            .stakedNFTs;
        uint256 stakedCount = stakedTokens.length();
        for (uint256 i = 0; i < stakedCount; ) {
            uint256 tokenId = stakedTokens.at(i);
            unchecked {
                if (_stakingComplete(tokenId)) {
                    ++result;
                }
                ++i;
            }
        }
        return result;
    }

    /// @notice Returns the number of currently completed stakes for a user
    /// @param user_ The address of the user
    /// @return result The number of completed stakes for the user
    function completedStakes(address user_) external view returns (uint256) {
        return _completedStakes(user_);
    }

    /// @dev Checks if the given tokenId is a mythic GenesisStone NFT
    /// @param tokenId_ The tokenId of the GenesisStone NFT
    function _isMythicStone(uint256 tokenId_) private pure returns (bool) {
        return tokenId_ < 9 || tokenId_ == 999;
    }

    /// @dev Checks if the given tokenId has been used to mint a Eve
    /// @param tokenId_ The tokenId of the GenesisStone NFT
    function _isMinted(uint256 tokenId_) internal view returns (bool) {
        return _stakedNFTInfos[tokenId_].minted;
    }

    /// @notice Checks if the given tokenIds have been used for Eve minting
    /// @param tokenIds_ An array of GenesisStone NFT tokenIds
    /// @return results An array of bool values indicating whether each tokenId has been used for Eve minting
    function hasBeenUsedForMinting(
        uint256[] calldata tokenIds_
    ) external view returns (bool[] memory) {
        bool[] memory usedForMinting = new bool[](tokenIds_.length);

        for (uint256 i = 0; i < tokenIds_.length; ) {
            usedForMinting[i] = _isMinted(tokenIds_[i]);
            unchecked {
                ++i;
            }
        }

        return usedForMinting;
    }

    /// @notice Returns the minted Eve NFTs for the given user
    /// @param user_ The address of the user
    /// @return results An array of Eve NFT tokenIds
    function getMintedNFTs(
        address user_
    ) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage mintedTokens = _stakerInfos[user_]
            .mintedNFTs;
        uint256 mintedCount = mintedTokens.length();

        uint256[] memory results = new uint256[](mintedCount);
        for (uint256 i = 0; i < mintedCount; ) {
            results[i] = mintedTokens.at(i);
            unchecked {
                ++i;
            }
        }

        return results;
    }

    /// @notice Returns the number of normal Eve NFTs that can be minted for the given user
    /// @param user_ The address of the user
    /// @return result The number of normal Eve NFTs that can be minted for the user
    function numOfNormalEveMintable(
        address user_
    ) external view returns (uint256 result) {
        EnumerableSet.UintSet storage stakedTokens = _stakerInfos[user_]
            .stakedNFTs;
        uint256 stakedCount = stakedTokens.length();
        for (uint256 i = 0; i < stakedCount; ) {
            uint256 tokenId = stakedTokens.at(i);
            unchecked {
                if (
                    !_isMythicStone(tokenId) &&
                    _stakingComplete(tokenId) &&
                    !_isMinted(tokenId)
                ) {
                    ++result;
                }
                ++i;
            }
        }

        return result;
    }

    /// @notice Returns the number of mythic Eve NFTs that can be minted for the given user
    /// @param user_ The address of the user
    /// @return result The number of mythic Eve NFTs that can be minted for the user
    function numOfMythicEveMintable(
        address user_
    ) external view returns (uint256 result) {
        EnumerableSet.UintSet storage stakedTokens = _stakerInfos[user_]
            .stakedNFTs;
        uint256 stakedCount = stakedTokens.length();
        for (uint256 i = 0; i < stakedCount; ) {
            uint256 tokenId = stakedTokens.at(i);
            unchecked {
                if (
                    _isMythicStone(tokenId) &&
                    _stakingComplete(tokenId) &&
                    !_isMinted(tokenId)
                ) {
                    ++result;
                }

                ++i;
            }
        }

        return result;
    }

    /// @notice Mints a number of Eve NFTs for the caller
    /// @param tokenIds_ An array of GenesisStone NFT tokenIds
    function mintEve(uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; ) {
            if (_stakedNFTInfos[tokenIds_[i]].stakedBy != msg.sender) {
                revert Utils.NotTheOwnerOfTheToken();
            }

            if (_isMinted(tokenIds_[i])) {
                revert Utils.AlreadyMinted();
            }

            if (!_stakingComplete(tokenIds_[i])) {
                revert Utils.StakingNotCompleted();
            }

            bool isMythic = _isMythicStone(tokenIds_[i]);

            // Transfer the staked NFT back to the user
            _stakedNFTInfos[tokenIds_[i]].stakedTime = 0;
            _stakerInfos[msg.sender].stakedNFTs.remove(tokenIds_[i]);
            GENESIS_STONE_CONTRACT.transferFrom(
                address(this),
                msg.sender,
                tokenIds_[i]
            );

            // Mint the NFT
            _stakedNFTInfos[tokenIds_[i]].minted = true;
            uint256[] memory tokenIds = isMythic
                ? EVE_CONTRACT.mintMythic(msg.sender, 1)
                : EVE_CONTRACT.mintNormal(msg.sender, 1);

            // Emit event for the minted Eve tokenId
            _stakerInfos[msg.sender].mintedNFTs.add(tokenIds[0]);
            emit EveMinted(
                tokenIds[0],
                isMythic ? MINT_TYPE_MYTHIC : MINT_TYPE_NORMAL
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns if the user can mint a normal Eve using five staked Genesis Stones
    /// @param user_ The address of the user
    /// @return True if the user can mint a normal Eve using five staked Genesis Stones
    function fiveStonesMintable(address user_) external view returns (bool) {
        return
            !_stakerInfos[user_].fiveStonesMinted &&
            _completedStakes(user_) > 4;
    }

    /// @notice Checks whether the specified user has minted Eve with five stones.
    /// @param user_ The address of the user to check.
    /// @return A boolean value indicating whether the user has minted Eve with five stones.
    function hasMintedEveWithFiveStones(
        address user_
    ) external view returns (bool) {
        return _stakerInfos[user_].fiveStonesMinted;
    }

    /// @notice Mint a normal Eve using five staked Genesis Stones
    function mintEveWithFiveStones() external {
        if (_stakerInfos[msg.sender].fiveStonesMinted) {
            revert Utils.AlreadyMinted();
        }

        if (_completedStakes(msg.sender) < 5) {
            revert Utils.NotEnoughStakedGenesisStones();
        }

        // Mint the NFT
        _stakerInfos[msg.sender].fiveStonesMinted = true;
        uint256[] memory tokenIds = EVE_CONTRACT.mintNormal(msg.sender, 1);

        // Record and Emit events for each of the tokenIds
        _stakerInfos[msg.sender].mintedNFTs.add(tokenIds[0]);
        emit EveMinted(tokenIds[0], MINT_TYPE_FIVE);
    }

    /// @notice Returns if the user can mint a mythic Eve using ten staked Genesis Stones
    /// @param user_ The address of the user
    /// @return True if the user can mint a mythic Eve using ten staked Genesis Stones
    function tenStonesMintable(address user_) external view returns (bool) {
        return
            !_stakerInfos[user_].tenStonesMinted && _completedStakes(user_) > 9;
    }

    /// @notice Checks whether the specified user has minted Eve with ten stones.
    /// @param user_ The address of the user to check.
    /// @return A boolean value indicating whether the user has minted Eve with ten stones.
    function hasMintedEveWithTenStones(
        address user_
    ) external view returns (bool) {
        return _stakerInfos[user_].tenStonesMinted;
    }

    /// @notice Mint a mythic Eve using ten staked Genesis Stones
    function mintEveWithTenStones() external {
        if (_stakerInfos[msg.sender].tenStonesMinted) {
            revert Utils.AlreadyMinted();
        }

        if (_completedStakes(msg.sender) < 10) {
            revert Utils.NotEnoughStakedGenesisStones();
        }

        // Mint the NFT
        _stakerInfos[msg.sender].tenStonesMinted = true;
        uint256[] memory tokenIds = EVE_CONTRACT.mintMythic(msg.sender, 1);

        // Record and Emit events for each of the tokenIds
        _stakerInfos[msg.sender].mintedNFTs.add(tokenIds[0]);
        emit EveMinted(tokenIds[0], MINT_TYPE_TEN);
    }

    /// @dev Performs an emergency transfer of the specified token to the specified address.
    /// Only the account with the DEFAULT_ADMIN_ROLE can invoke this function.
    /// @param tokenId_ The ID of the token to be transferred.
    /// @param to_ The address to which the token will be transferred.
    function emergencyTransfer(
        uint256 tokenId_,
        address to_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_stakedNFTInfos[tokenId_].stakedTime != 0) {
            revert Utils.TokenIsStaked();
        }

        GENESIS_STONE_CONTRACT.transferFrom(address(this), to_, tokenId_);
    }
}