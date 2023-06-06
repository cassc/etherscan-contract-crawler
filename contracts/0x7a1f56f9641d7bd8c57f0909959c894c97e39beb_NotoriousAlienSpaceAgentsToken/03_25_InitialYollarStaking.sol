// SPDX-License-Identifier: MIT

/// @title The Notorious Alien Space Agents Utitilty Token

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {YOLLAR} from "../token/Yollar.sol";
import {IApiCaller} from "../interfaces/IApiCaller.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat/console.sol";

error OnlyApiCallerContractCanInvokeThisFunction();
error OnlyNASAContractCanInvokeThisFunction();
error NotEnoughYollarInWallet();
error NotYourAlien(uint256);
error AlienIsLocked(uint256);
error NotEnoughBalanceInTreasuary();
error InconsistentBackendSpending(
    uint128 backendNewValue,
    uint128 backendOldValue
);
error NegativeEarning(
    uint128 totalPositiveEarning,
    int128 currentAdjustedBalance,
    uint128 newTotalWonOnBackend,
    uint128 newTotalSpentOnBackend
);


contract InitialYollarStaking is
    AccessControl,
    Ownable,
    IERC721Receiver,
    Pausable
{
    struct StakeInfo {
        uint256 since;
        // until has value, only if lock duration matches the requirements, otherwise it is zero.
        uint256 until;
        bool lockedBeforeReveal;
    }
    struct RateInfo {
        uint256 rewardRate;
        uint256 beforeRevealBonusRate;
        uint256 afterRevealBonusRate;
        uint256 lockPeriod;
    }

    IERC721 private stakingToken;
    YOLLAR private yollarContract;

    uint256 public capTime;
    uint256 public revealTime;

    RateInfo private rates;
    address private gameEarningsAddress;
    address private gameTreasuaryAddress;
    IApiCaller private apiCaller;

    mapping(address => mapping(uint256 => StakeInfo)) public userTokenStakeInfo; // tokenStakeInfo[userAddress][tokenId] = StakeInfo
    mapping(address => uint256[]) private userTokenOwnershipList; // used to iterate over `userTokenStakeInfo`

    mapping(address => int128) private earningAdjustment;
    mapping(address => uint128) public totalSpentBackend;
    mapping(bytes32 => address) public requests;

    modifier onlyApiCaller() {
        if (msg.sender != address(apiCaller)) {
            revert OnlyApiCallerContractCanInvokeThisFunction();
        }
        _;
    }

    modifier onlyMinter() {
        if (msg.sender != address(stakingToken)) {
            revert OnlyNASAContractCanInvokeThisFunction();
        }
        _;
    }

    constructor(
        address nasaContractAddress_,
        address yollarAddress_,
        address gameEarningAddress_,
        address gameTreasuaryAddress_,
        uint256 revealTime_,
        uint256 capTime_,
        uint256 rewardPerDay_
    ) {
        stakingToken = IERC721(nasaContractAddress_);
        yollarContract = YOLLAR(yollarAddress_);
        gameTreasuaryAddress = gameTreasuaryAddress_;
        setTimes(revealTime_, capTime_);
        setGameEarningAddress(gameEarningAddress_);
        uint256 rewardRate = rewardPerDay_ / (24 hours);
        rates = RateInfo({
            rewardRate: rewardRate, // rewards per second
            beforeRevealBonusRate: rewardRate * 2, // 2X rewards per second
            afterRevealBonusRate: (rewardRate * 3) >> 1, // 1.5 rewards per second
            lockPeriod: 2 * 30 * 24 hours // 2 months
        });
    }

    function stake(uint256[] calldata tokenIds_, uint256 duration_)
        external
        whenNotPaused
    {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (stakingToken.ownerOf(tokenIds_[i]) != msg.sender) {
                revert NotYourAlien(tokenIds_[i]);
            }
        }

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            storeAlien(msg.sender, tokenIds_[i], duration_);
            stakingToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds_[i]
            );
        }
    }

    function stakeDuringMint(
        uint256 tokenId_,
        uint256 duration_,
        address owner_
    ) external onlyMinter {
        storeAlien(owner_, tokenId_, duration_);
    }

    function rewardAuctionYollar(address owner_, uint128 amount_)
        external
        onlyMinter
    {
        earningAdjustment[owner_] += int128(amount_);
    }

    function unstake(uint256[] calldata tokenIds_) external {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            StakeInfo storage info = userTokenStakeInfo[msg.sender][
                tokenIds_[i]
            ];
            if (isLocked(info)) {
                revert AlienIsLocked(tokenIds_[i]);
            }
        }

        uint128 earnings = uint128(stakingEarningsFor(msg.sender, tokenIds_));
        earningAdjustment[msg.sender] += int128(earnings);

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            removeAlien(msg.sender, tokenIds_[i]);
        }

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            stakingToken.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds_[i]
            );
        }
    }

    function deposit(uint128 amount_) public whenNotPaused {
        if (yollarContract.balanceOf(msg.sender) < amount_) {
            revert NotEnoughYollarInWallet();
        }
        earningAdjustment[msg.sender] =
            earningAdjustment[msg.sender] +
            int128(amount_);
        yollarContract.transferFrom(msg.sender, gameTreasuaryAddress, amount_);
    }

    /**
     * @notice WARNING: Do not call this directly. Your withdrawal fee will be lost if you call this when your total balance between the contart and the backend is negative.
     * The withdrawal fee tracks the 2*LINK price since it will be used to pay for the API call.
     */
    function withdrawRequest() public payable {
        bytes32 requestId = apiCaller.callBackend{value: msg.value}(msg.sender);
        requests[requestId] = msg.sender;
    }

    function withdrawFinalize(
        bytes32 requestId_,
        uint128 totalWonOnBackend_,
        uint128 totalSpentOnBackend_
    ) public onlyApiCaller {
        address owner_ = requests[requestId_];
        delete requests[requestId_];

        // Part 1: Convert the game spending to actual YOLLAR for the game developers.
        if (totalSpentOnBackend_ < totalSpentBackend[owner_]) {
            revert InconsistentBackendSpending(
                totalSpentOnBackend_,
                totalSpentBackend[owner_]
            );
        }
        // The actual transfer of YOLLAR, with the amount of `netNewSpending` happens at the end of the function.
        uint128 netNewSpending = totalSpentOnBackend_ -
            totalSpentBackend[owner_];
        totalSpentBackend[owner_] = totalSpentOnBackend_;

        // Part 2: calculate earnings from backend, staking, and deposited yollar.
        int128 backendNet = int128(totalWonOnBackend_) -
            int128(totalSpentOnBackend_);
        int128 adjustedBalance = earningAdjustment[owner_] + backendNet;

        uint128 earnedFromStaking = uint128(
            stakingEarningsFor(owner_, userTokenOwnershipList[owner_])
        );

        uint128 totalPositiveEarning = earnedFromStaking;

        // The actual transfer of YOLLAR, with the amount of `totalEarning` happens at the end of the function.
        uint128 totalEarning = 0;
        if (adjustedBalance >= 0) {
            totalEarning = totalPositiveEarning + uint128(adjustedBalance);
        } else {
            int128 remaining = int128(totalPositiveEarning) + adjustedBalance; // adjustedBalance is negative
            if (remaining < 0) {
                revert NegativeEarning(
                    totalPositiveEarning,
                    earningAdjustment[owner_],
                    totalWonOnBackend_,
                    totalSpentOnBackend_
                );
            }
            totalEarning = uint128(remaining);
        }

        // Part 3: change the state and get ready for YOLLAR transfer
        // Set the internal state to cancel out the backend state so that subsequent withdrawal requests would result in zero net value.
        earningAdjustment[owner_] = -backendNet;

        uint256 tokensOwnedCount = userTokenOwnershipList[owner_].length;
        for (uint256 i = 0; i < tokensOwnedCount; i++) {
            uint256 tokenId = userTokenOwnershipList[owner_][i];

            userTokenStakeInfo[owner_][tokenId].since = block.timestamp; // solhint-disable-line
        }

        // Part 4, now that all the internal states are properly updated, tranfer YOLLAR from treasuary.

        if (netNewSpending > 0) {
            yollarContract.transferFrom(
                gameTreasuaryAddress,
                gameEarningsAddress,
                netNewSpending
            );
        }
        if (totalEarning > 0) {
            yollarContract.transferFrom(
                gameTreasuaryAddress,
                owner_,
                totalEarning
            );
        }
    }

    function stakingEarningsFor(address owner_, uint256[] memory tokenIds_)
        public
        view
        returns (uint256)
    {
        uint256 reward = 0;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 tokenId = tokenIds_[i];
            uint256 stakedSince = userTokenStakeInfo[owner_][tokenId].since;
            uint256 stakedUntil = userTokenStakeInfo[owner_][tokenId].until;
            bool isLockedBeforeReveal = userTokenStakeInfo[owner_][tokenId]
                .lockedBeforeReveal;

            uint256 current = block.timestamp; // solhint-disable-line
            if (current > capTime) {
                current = capTime;
            }

            // If stakedUntil is zero, it means that the lock period was not elligible for boosting.
            if (stakedUntil != 0) {
                uint256 bonusUnits = 0;
                if (current <= stakedUntil) {
                    bonusUnits = current - stakedSince;
                } else {
                    bonusUnits = stakedUntil - stakedSince;
                }

                if (isLockedBeforeReveal) {
                    reward =
                        reward +
                        (bonusUnits * rates.beforeRevealBonusRate);
                } else {
                    reward = reward + (bonusUnits * rates.afterRevealBonusRate);
                }

                uint256 normalUnits = 0;
                if (current > stakedUntil) {
                    normalUnits = current - stakedUntil;
                }
                reward = reward + (normalUnits * rates.rewardRate);
            } else {
                uint256 units = (current - stakedSince);
                reward = reward + units * rates.rewardRate;
            }
        }

        return reward;
    }

    function tokenOfOwnerByIndex(address owner_, uint256 index_)
        public
        view
        returns (uint256)
    {
        return userTokenOwnershipList[owner_][index_];
    }

    function getEarningAdjustment(address owner_) public view returns (int128) {
        return earningAdjustment[owner_];
    }

    function isLocked(StakeInfo memory info) internal view returns (bool) {
        if (info.until == 0) {
            return false;
        }
        return block.timestamp < info.until; // solhint-disable-line
    }

    function storeAlien(
        address owner_,
        uint256 tokenId_,
        uint256 duration_
    ) internal {
        bool isLockDurationEligible = duration_ >= rates.lockPeriod;
        uint256 now_ = block.timestamp; // solhint-disable-line
        userTokenStakeInfo[owner_][tokenId_] = StakeInfo({
            since: now_,
            until: isLockDurationEligible ? now_ + rates.lockPeriod : 0,
            lockedBeforeReveal: now_ < revealTime
        });
        userTokenOwnershipList[owner_].push(tokenId_);
    }

    function removeAlien(address owner_, uint256 tokenId_) internal {
        delete userTokenStakeInfo[owner_][tokenId_];

        uint256 tokensOwnedCount = userTokenOwnershipList[owner_].length;
        for (uint256 i = 0; i < tokensOwnedCount; i++) {
            if (userTokenOwnershipList[owner_][i] == tokenId_) {
                uint256 length = userTokenOwnershipList[owner_].length;
                userTokenOwnershipList[owner_][i] = userTokenOwnershipList[
                    owner_
                ][length - 1];
                userTokenOwnershipList[owner_].pop();
                break;
            }
        }
    }

    function setTimes(uint256 revealTime_, uint256 capTime_) public onlyOwner {
        revealTime = revealTime_;
        capTime = capTime_;
    }

    function setGameEarningAddress(address address_) public onlyOwner {
        gameEarningsAddress = address_;
    }

    function setApiCaller(address address_) public onlyOwner {
        apiCaller = IApiCaller(address_);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}