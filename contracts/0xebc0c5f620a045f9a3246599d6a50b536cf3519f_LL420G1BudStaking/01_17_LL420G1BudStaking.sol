//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game G1 Bud Staking
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./interfaces/ILL420Wallet.sol";

error InvalidAddress();
error InvalidLength();
error InvalidOwner();
error InvalidWithdraw();
error SeasonEnded();

/**
 * @title LL420G1BudStaking
 */
contract LL420G1BudStaking is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    IERC721Upgradeable public g1BudContract;

    uint256 public constant SECONDS_IN_DAY = 1 days;
    uint256 public rewardPerDay;
    uint256 public totalStaked;
    uint256 public seasonEndTime;
    address public walletContractAddress;

    mapping(address => Staker) public stakers;
    mapping(address => EnumerableSetUpgradeable.UintSet) private _buds;

    struct Staker {
        uint256 reward;
        uint256 checkpoint;
        uint256 budCount;
    }

    /* ==================== EVENTS ==================== */

    event Stake(address indexed user, uint256 id);
    event Unstake(address indexed user, uint256 id);
    event WithdrawToWallet(address indexed user, uint256 amount);
    event WithdrawToPoint(address indexed user, uint256 amount, uint256 timestamp);

    /* ==================== MODIFIERS ==================== */

    modifier whenInSeason() {
        if (seasonEndTime != 0 && block.timestamp > seasonEndTime) revert SeasonEnded();
        _;
    }

    /* ==================== METHODS ==================== */

    /**
     * @dev Initializes a staking contract.
     * @param _g1BudContract address of the bud contract.
     */
    function initialize(address _g1BudContract, address _walletAddress) external initializer {
        __Context_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        if (_g1BudContract == address(0) || _walletAddress == address(0)) revert InvalidAddress();

        walletContractAddress = _walletAddress;
        g1BudContract = IERC721Upgradeable(_g1BudContract);
        rewardPerDay = 1420;

        _pause();
    }

    /**
     * @dev stake g1 buds
     * @param _ids g1 bud id array
     */
    function stake(uint256[] memory _ids) external nonReentrant whenNotPaused whenInSeason {
        uint256 length = _ids.length;
        if (length == 0) revert InvalidLength();

        Staker storage staker = stakers[_msgSender()];

        uint256 pending = _pendingReward(_msgSender());
        staker.reward += pending;

        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = _ids[i];
            g1BudContract.transferFrom(_msgSender(), address(this), tokenId);
            _buds[_msgSender()].add(_ids[i]);

            emit Stake(_msgSender(), tokenId);
            unchecked {
                ++i;
            }
        }

        totalStaked += length;
        staker.budCount += length;
        staker.checkpoint = block.timestamp;
    }

    /**
     * @dev unstake g1 buds
     * @param _ids g1 bud id array
     */
    function unstake(uint256[] memory _ids) external nonReentrant whenNotPaused {
        uint256 length = _ids.length;
        if (length == 0) revert InvalidLength();

        Staker storage staker = stakers[_msgSender()];
        if (length > staker.budCount) revert InvalidLength();

        uint256 pending = _pendingReward(_msgSender());
        staker.reward += pending;

        for (uint256 i = 0; i < length; ) {
            uint256 tokenId = _ids[i];
            if (!_buds[_msgSender()].contains(tokenId)) revert InvalidOwner();
            g1BudContract.transferFrom(address(this), _msgSender(), tokenId);
            _buds[_msgSender()].remove(tokenId);

            emit Unstake(_msgSender(), tokenId);
            unchecked {
                ++i;
            }
        }

        totalStaked -= length;
        staker.budCount -= length;
        staker.checkpoint = block.timestamp;
    }

    /**
     * @dev Withdraw balance to in-game wallet
     */
    function withdrawToWallet(uint256 _amount) external nonReentrant {
        Staker storage staker = stakers[_msgSender()];
        uint256 pending = _pendingReward(_msgSender());
        staker.reward += pending;

        if (staker.reward == 0 || staker.reward < _amount) revert InvalidWithdraw();

        ILL420Wallet WALLET_CONTRACT = ILL420Wallet(walletContractAddress);
        WALLET_CONTRACT.deposit(_msgSender(), _amount);

        emit WithdrawToWallet(_msgSender(), _amount);

        staker.reward -= _amount;
        staker.checkpoint = block.timestamp;
    }

    /**
     * @dev Withdraw balance to in-game breeding points.
     *
     * @param _amount Withdrawal amount
     */
    function withdrawToPoint(uint256 _amount) external nonReentrant {
        Staker storage staker = stakers[_msgSender()];
        uint256 pending = _pendingReward(_msgSender());
        staker.reward += pending;

        if (staker.reward == 0 || staker.reward < _amount) revert InvalidWithdraw();

        emit WithdrawToPoint(_msgSender(), _amount, block.timestamp);

        staker.reward -= _amount;
        staker.checkpoint = block.timestamp;
    }

    /* ==================== VIEW METHODS ==================== */

    function getBuds(address _who) external view returns (uint256[] memory) {
        Staker memory staker = stakers[_who];
        uint256[] memory userBud = new uint256[](staker.budCount);
        uint256 length = _buds[_who].length();
        for (uint256 i; i < length; i++) {
            userBud[i] = _buds[_who].at(i);
        }
        return userBud;
    }

    function getReward(address _who) external view returns (uint256) {
        return stakers[_who].reward + _pendingReward(_who);
    }

    function getDailyReward(address _who) external view returns (uint256) {
        return stakers[_who].budCount * rewardPerDay;
    }

    /* ==================== INTERNAL METHODS ==================== */

    /**
     * @dev returns pending reward
     * @param _who staker address
     */
    function _pendingReward(address _who) internal view returns (uint256) {
        Staker memory staker = stakers[_who];
        if (staker.checkpoint == 0) return 0;

        uint256 duration;
        if (seasonEndTime == 0) {
            duration = block.timestamp - staker.checkpoint;
        } else {
            if (seasonEndTime < staker.checkpoint) {
                duration = 0;
            } else {
                duration = block.timestamp > seasonEndTime
                    ? seasonEndTime - staker.checkpoint
                    : block.timestamp - staker.checkpoint;
            }
        }
        return (staker.budCount * rewardPerDay * duration) / SECONDS_IN_DAY;
    }

    /* ==================== OWNER METHODS ==================== */

    /**
     * @dev owner can pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev owner can unapuse the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Function allows to set HIGH token address.
     *
     * @param _address address of HIGH token address.
     */
    function setWalletContractAddress(address _address) external onlyOwner {
        if (_address == address(0)) revert InvalidAddress();
        walletContractAddress = _address;
    }

    function setSeasonEndTime(uint256 _when) external onlyOwner {
        seasonEndTime = _when;
    }
}