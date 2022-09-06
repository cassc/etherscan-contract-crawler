// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../base/ERC721MultiTokenStream.sol";

/**
 * @author Flair (https://flair.finance)
 */
interface IERC721StakingExtension {
    function hasERC721StakingExtension() external view returns (bool);

    function stake(uint256 tokenId) external;

    function stake(uint256[] calldata tokenIds) external;
}

/**
 * @author Flair (https://flair.finance)
 */
abstract contract ERC721StakingExtension is
    IERC721StakingExtension,
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721MultiTokenStream
{
    // Minimum seconds that token must be staked before unstaking.
    uint64 public minStakingDuration;

    // Maximum sum total of all durations staking that will be counted (across all stake/unstakes for each token). Staked durations beyond this number is ignored.
    uint64 public maxStakingTotalDurations;

    // Map of token ID to the time of last staking
    mapping(uint256 => uint64) public lastStakingTime;

    // Map of token ID to the sum total of all previous staked durations
    mapping(uint256 => uint64) public savedStakedDurations;

    /* INIT */

    function __ERC721StakingExtension_init(
        uint64 _minStakingDuration,
        uint64 _maxStakingTotalDurations
    ) internal onlyInitializing {
        __ERC721StakingExtension_init_unchained(
            _minStakingDuration,
            _maxStakingTotalDurations
        );
    }

    function __ERC721StakingExtension_init_unchained(
        uint64 _minStakingDuration,
        uint64 _maxStakingTotalDurations
    ) internal onlyInitializing {
        minStakingDuration = _minStakingDuration;
        maxStakingTotalDurations = _maxStakingTotalDurations;

        _registerInterface(type(IERC721StakingExtension).interfaceId);
    }

    /* ADMIN */

    function setMinStakingDuration(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        minStakingDuration = newValue;
    }

    function setMaxStakingTotalDurations(uint64 newValue) public onlyOwner {
        require(lockedUntilTimestamp < block.timestamp, "CONFIG_LOCKED");
        maxStakingTotalDurations = newValue;
    }

    /* PUBLIC */

    function hasERC721StakingExtension() external pure returns (bool) {
        return true;
    }

    function stake(uint256 tokenId) public virtual {
        _stake(_msgSender(), uint64(block.timestamp), tokenId);
    }

    function stake(uint256[] calldata tokenIds) public virtual {
        address operator = _msgSender();
        uint64 currentTime = uint64(block.timestamp);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(operator, currentTime, tokenIds[i]);
        }
    }

    function unstake(uint256 tokenId) public virtual {
        _unstake(_msgSender(), uint64(block.timestamp), tokenId);
    }

    function unstake(uint256[] calldata tokenIds) public virtual {
        address operator = _msgSender();
        uint64 currentTime = uint64(block.timestamp);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(operator, currentTime, tokenIds[i]);
        }
    }

    function totalStakedDuration(uint256[] calldata ticketTokenIds)
        public
        view
        virtual
        returns (uint64)
    {
        uint64 totalDurations = 0;

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            totalDurations += totalStakedDuration(ticketTokenIds[i]);
        }

        return totalDurations;
    }

    function totalStakedDuration(uint256 ticketTokenId)
        public
        view
        virtual
        returns (uint64)
    {
        uint64 total = savedStakedDurations[ticketTokenId];

        if (lastStakingTime[ticketTokenId] > 0) {
            uint64 targetTime = _stakingTimeLimit();

            if (targetTime > block.timestamp) {
                targetTime = uint64(block.timestamp);
            }

            if (lastStakingTime[ticketTokenId] > 0) {
                if (targetTime > lastStakingTime[ticketTokenId]) {
                    total += (targetTime - lastStakingTime[ticketTokenId]);
                }
            }
        }

        if (total > maxStakingTotalDurations) {
            total = maxStakingTotalDurations;
        }

        return total;
    }

    function unlockingTime(uint256 ticketTokenId)
        public
        view
        returns (uint256)
    {
        return
            lastStakingTime[ticketTokenId] > 0
                ? lastStakingTime[ticketTokenId] + minStakingDuration
                : 0;
    }

    function unlockingTime(uint256[] calldata ticketTokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory unlockedAt = new uint256[](ticketTokenIds.length);

        for (uint256 i = 0; i < ticketTokenIds.length; i++) {
            unlockedAt[i] = unlockingTime(ticketTokenIds[i]);
        }

        return unlockedAt;
    }

    /* INTERNAL */

    function _stakingTimeLimit() internal view virtual returns (uint64) {
        return 18_446_744_073_709_551_615; // max(uint64)
    }

    function _stake(
        address operator,
        uint64 currentTime,
        uint256 tokenId
    ) internal virtual {
        require(
            totalStakedDuration(tokenId) < maxStakingTotalDurations,
            "MAX_DURATION_EXCEEDED"
        );

        lastStakingTime[tokenId] = currentTime;
    }

    function _unstake(
        address operator,
        uint64 currentTime,
        uint256 tokenId
    ) internal virtual {
        operator;

        require(lastStakingTime[tokenId] > 0, "NOT_STAKED");

        require(
            currentTime >= lastStakingTime[tokenId] + minStakingDuration,
            "NOT_STAKED_LONG_ENOUGH"
        );

        savedStakedDurations[tokenId] = totalStakedDuration(tokenId);

        lastStakingTime[tokenId] = 0;
    }
}