// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IStakedERC721.sol";
import "./ERC721Saver.sol";

contract ERC721Staking is ReentrancyGuard, ERC721Saver {
    using Math for uint256;

    IERC721 public immutable nft;
    IStakedERC721 public immutable stakedNFT;

    uint256 public immutable minLockDuration;
    uint256 public immutable maxLockDuration;
    uint256 public constant MIN_LOCK_DURATION_FOR_SAFETY = 10 minutes;

    event NFTStaked(address indexed staker, uint256 tokenId, uint256 duration);
    event NFTUnstaked(address indexed unstaker, uint256 tokenId);

    // Constructor function to set the rewards token and the NFT collection addresses
    constructor(
        address _nft,
        address _stakedNFT,
        uint256 _minLockDuration,
        uint256 _maxLockDuration
    ) {
        require(_nft != address(0), "ERC721Staking.constructor: nft cannot be zero address");
        require(_stakedNFT != address(0), "ERC721Staking.constructor: staked nft cannot be zero address");
        require(
            _minLockDuration >= MIN_LOCK_DURATION_FOR_SAFETY,
            "ERC721Staking.constructor: min lock duration must be greater or equal to min lock duration for safety"
        );
        require(
            _maxLockDuration >= _minLockDuration,
            "ERC721Staking.constructor: max lock duration must be greater or equal to min lock duration"
        );

        nft = IERC721(_nft);
        stakedNFT = IStakedERC721(_stakedNFT);
        minLockDuration = _minLockDuration;
        maxLockDuration = _maxLockDuration;
    }

    function stake(uint256 _tokenId, uint256 _duration) external nonReentrant {
        _stake(msg.sender, _tokenId, _duration);
    }

    function _stake(
        address _staker,
        uint256 _tokenId,
        uint256 _duration
    ) internal {
        // Wallet must own the token they are trying to stake
        require(nft.ownerOf(_tokenId) == _staker, "ERC721Staking.stake: You don't own this token!");

        require(block.timestamp + _duration <= type(uint64).max, "ERC721Staking.stake: duration too long");
        // Don't allow locking > maxLockDuration
        uint256 duration = _duration.min(maxLockDuration);
        // Enforce min lockup duration to prevent flash loan or MEV transaction ordering
        duration = duration.max(minLockDuration);

        // Transfer the token from the wallet to the Smart contract
        nft.transferFrom(_staker, address(this), _tokenId);

        stakedNFT.safeMint(
            _staker,
            _tokenId,
            IStakedERC721.StakedInfo({
                start: uint64(block.timestamp),
                duration: duration,
                end: uint64(block.timestamp) + uint64(duration)
            })
        );

        emit NFTStaked(_staker, _tokenId, _duration);
    }

    function unstake(uint256 _tokenId) external nonReentrant {
        require(stakedNFT.ownerOf(_tokenId) == msg.sender, "ERC721Staking.unstake: You don't own this token!");
        nft.transferFrom(address(this), msg.sender, _tokenId);
        stakedNFT.burn(_tokenId);

        emit NFTUnstaked(msg.sender, _tokenId);
    }

    function batchStake(uint256[] memory _tokenIds, uint256[] memory _durations) external nonReentrant {
        require(
            _tokenIds.length == _durations.length,
            "ERC721Staking.batchStake: tokenIds and durations length mismatch"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 duration = _durations[i];
            _stake(msg.sender, tokenId, duration);
        }
    }
}