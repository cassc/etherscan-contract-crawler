// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @dev Vesting Kyoko Token for holder of kyoko pawn
 */
contract PawnVesting is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    //Each NFT can claim 100,000 tokens
    uint256 public constant TOKEN_PER_NFT = 100000 * 1e18;

    //When the user holds nft tokenId is 0-359, you can cliam
    uint256 public constant MAX_TOKEN_ID = 359;

    address public token;

    address public nftAddr;

    //Time to start claim nft
    uint64 public startTimestamp;
    uint64 public durationSecond;

    //user => cliamedAmount,The number of tokens the user has claimed
    mapping(address => uint256) public userClaimed;

    //tokenId => tokenIdClaimed
    mapping(uint256 => uint256) public tokenIdClaimed;

    event Claim(address indexed user, uint256 timestamp, uint256 indexed nftBalanceOf, uint256 totalCanCalimedAmount);

    // constructor(
    //     address _token,
    //     address _nftAddr,
    //     uint64 _startTimestamp,
    //     uint64 _durationSeconds
    // ) {
    //     token = _token;
    //     nftAddr = _nftAddr;
    //     startTimestamp = _startTimestamp;
    //     durationSecond = _durationSeconds;
    // }

    function initialize(
        address _token,
        address _nftAddr,
        uint64 _startTimestamp,
        uint64 _durationSeconds
    ) public virtual initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        token = _token;
        nftAddr = _nftAddr;
        startTimestamp = _startTimestamp;
        durationSecond = _durationSeconds;
    }

    function setStartTimestamp(uint64 _startTimestamp) public onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function setDurationSecond(uint64 _durationSecond) public onlyOwner {
        durationSecond = _durationSecond;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {TokensReleased} event.
     */
    function claim() public virtual whenNotPaused nonReentrant {
        uint256 currentTime = getCurrentTime();
        require(currentTime > startTimestamp, "too early");

        uint256 balanceOf = IERC721Upgradeable(nftAddr).balanceOf(msg.sender);
        require(balanceOf > 0, "you don't have kyoko pawn");

        uint256 totalCanCalimedAmount = 0;
        for (uint256 i = 0; i < balanceOf; i++) {
            uint256 tokenId = IERC721EnumerableUpgradeable(nftAddr).tokenOfOwnerByIndex(
                msg.sender,
                i
            );
            if (tokenId > MAX_TOKEN_ID) {
                continue;
            }
            uint256 canClaimedAmount = _vestingSchedule() -
                tokenIdClaimed[tokenId];
            if (canClaimedAmount == 0) {
                continue;
            }
            totalCanCalimedAmount += canClaimedAmount;
            tokenIdClaimed[tokenId] += canClaimedAmount;
        }
        require(totalCanCalimedAmount > 0, "amount is error");
        userClaimed[msg.sender] += totalCanCalimedAmount;
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(token),
            msg.sender,
            totalCanCalimedAmount
        );
        emit Claim(msg.sender, currentTime, balanceOf, totalCanCalimedAmount);
    }

    function _vestingSchedule() internal view returns (uint256) {
        if (getCurrentTime() <= startTimestamp) {
            return 0;
        } else if (getCurrentTime() > startTimestamp + durationSecond) {
            return TOKEN_PER_NFT;
        } else {
            return
                (TOKEN_PER_NFT * (getCurrentTime() - startTimestamp)) /
                durationSecond;
        }
    }

    /**
     * @dev Amount of token already released
     */
    function released(address user) public view virtual returns (uint256) {
        uint256 balanceOf = IERC721Upgradeable(nftAddr).balanceOf(user);
        if(balanceOf == 0) {
            return 0;
        }

        uint256 totalCanCalimedAmount = 0;
        for (uint256 i = 0; i < balanceOf; i++) {
            uint256 tokenId = IERC721EnumerableUpgradeable(nftAddr).tokenOfOwnerByIndex(
                user,
                i
            );
            if (tokenId > MAX_TOKEN_ID) {
                continue;
            }
            uint256 canClaimedAmount = _vestingSchedule() -
                tokenIdClaimed[tokenId];
            if (canClaimedAmount == 0) {
                continue;
            }
            totalCanCalimedAmount += canClaimedAmount;
        }
        return totalCanCalimedAmount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev The contract should be able to receive Eth.
     */
    receive() external payable virtual {}
}