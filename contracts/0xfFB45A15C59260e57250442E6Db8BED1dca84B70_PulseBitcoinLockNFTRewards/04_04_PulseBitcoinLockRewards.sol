// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface PulseBitcoinLockNFTInterface {
    function ownerOf(uint256 tokenId) external view returns (address);

    function lockTime(uint256 tokenId) external view returns (uint256);

    function tokenIdsToAmounts(uint256 tokenId) external view returns (uint256);
}

contract PulseBitcoinLockNFTRewards is Ownable {
    address public CARN;
    address public immutable waatcaAddress;
    address public immutable bulkClaimer;
    PulseBitcoinLockNFTInterface pulseBitcoinLockNftContract;
    address public pulseBitcoinLockNftContractAddress;
    mapping(uint256 => bool) public tokenIdsToRegistered; // True if they registered their NFT for rewards...will be able to withdraw rewards 1 day after registering
    mapping(uint256 => uint256) public tokenIdsToLastWithdrawalDay; // records the last day they withdrew rewards
    mapping(uint256 => uint256) public tokenIdsToDailyRewardAmount; // records their daily rewards amount
    mapping(uint256 => uint256) public tokenIdsToEndRewardsDay; // records their last day they can get rewards (max 1000 after registering)...(the smaller of 1000 or their actual end day measured from registration day)
    uint256 internal constant LAUNCH_TIME = 1680048000; // Wednesday, March 29, 2023 12:00:00 AM
    uint256 public totalFreeCarnWithdrawn;

    constructor(address _waatcaAddress, address _pulseBitcoinLockNftContractAddress, address _bulkClaimer) {
        waatcaAddress = _waatcaAddress;
        pulseBitcoinLockNftContractAddress = _pulseBitcoinLockNftContractAddress;
        pulseBitcoinLockNftContract = PulseBitcoinLockNFTInterface(pulseBitcoinLockNftContractAddress);
        bulkClaimer = _bulkClaimer;
    }

    function setCarnAddress(address _rewardTokenCARN) public onlyOwner {
        CARN = _rewardTokenCARN;
    }

    function withdrawRewards(uint256 tokenId) public {
        address tokenOwner = pulseBitcoinLockNftContract.ownerOf(tokenId);

        require(
            msg.sender == tokenOwner || msg.sender == bulkClaimer,
            "You are not the owner of this NFT, or the bulk claimer address"
        );
        require(
            tokenIdsToRegistered[tokenId],
            "You must register your NFT for rewards first"
        );
        require(
            tokenIdsToLastWithdrawalDay[tokenId] < tokenIdsToEndRewardsDay[tokenId],
            "You have already received all possible rewards for this NFT"
        );
        require(
            _currentDay() > tokenIdsToLastWithdrawalDay[tokenId],
            "Cannot withdraw twice on the same day, try again tomorrow"
        );

        uint256 totalDaysOfRewardsLeft = tokenIdsToEndRewardsDay[tokenId] - tokenIdsToLastWithdrawalDay[tokenId];
        uint256 numOfDaysSinceLastWithdrawal = _currentDay() - tokenIdsToLastWithdrawalDay[tokenId];

        // if numOfDaysSinceLastWithdrawal is greater than (their EndRewardsDay-LastWithdrawalDay) then set numOfDaysSinceLastWithdrawal to (their EndRewardsDay-LastWithdrawalDay)
        if (numOfDaysSinceLastWithdrawal > totalDaysOfRewardsLeft) {
            // in this scenario they are past the end of their lock up period.
            // meaning they locked up for 500 days, and its now day 540 for example (or 501)
            // in that case we only want to give them rewards from their last withdrawal day, up until the last day they are eligible for rewards (day 500)
            // so if their last withdrawal day was day 400, we would only give them 100 days worth of rewards and not 140
            numOfDaysSinceLastWithdrawal = totalDaysOfRewardsLeft;
        }


        IERC20(CARN).transfer(tokenOwner, tokenIdsToDailyRewardAmount[tokenId] * numOfDaysSinceLastWithdrawal);
        IERC20(CARN).transfer(waatcaAddress, tokenIdsToDailyRewardAmount[tokenId] * numOfDaysSinceLastWithdrawal);
        totalFreeCarnWithdrawn += tokenIdsToDailyRewardAmount[tokenId] * numOfDaysSinceLastWithdrawal;

        tokenIdsToLastWithdrawalDay[tokenId] = _currentDay();
    }

    function registerNftForRewards(uint256 tokenId) public {
        address tokenOwner = pulseBitcoinLockNftContract.ownerOf(tokenId);

        require(
            msg.sender == tokenOwner || msg.sender == bulkClaimer,
            "You are not the owner of this NFT, shame on you!"
        );

        require(!tokenIdsToRegistered[tokenId], "It seems you have already registered this NFT, go enjoy the rest of the carnival!");

        // get the '(the end day of their lock period)' for this tokenId
        uint256 endOfLockPeriod = pulseBitcoinLockNftContract.lockTime(tokenId);

        // calculate numDaysLockedUpFromRegistration (the end day of their lock period) - (the day they are registering...today) // set this to 1000 if its greater than 1000
        uint256 numDaysLockedUpFromRegistration = ((endOfLockPeriod - LAUNCH_TIME) / 1 days) - _currentDay();
        uint256 numDaysLockedUpFromRegistrationForRewards = numDaysLockedUpFromRegistration;

        if (numDaysLockedUpFromRegistrationForRewards > 1000) {
            // this makes locking more than 1000 PLSB for more than 1000 days, not beneficial in terms of getting rewards
            // we still want to let the user collect rewards everyday throughout their whole lock period, we keep the value of numDaysLockedUpFromRegistration
            // for the calculation of tokenIdsToEndRewardsDay later in this function
            numDaysLockedUpFromRegistrationForRewards = 1000;
        }

        uint256 amountPLSBLockedUp = pulseBitcoinLockNftContract.tokenIdsToAmounts(tokenId);

        if (amountPLSBLockedUp > 1000) {
            // this makes locking more than 1000 plsb for more than 1000 days, not beneficial in terms of getting rewards
            amountPLSBLockedUp = 1000;
        }

        // calculate this nft's tokenIdsToDailyRewardAmount (amount of PLSB locked * (numDaysLockedUpSinceRegistration / 1000) * 0.0015)
        tokenIdsToDailyRewardAmount[tokenId] =
        1_000_000_000_000 * (amountPLSBLockedUp * numDaysLockedUpFromRegistrationForRewards * 15) / 10_000_000;

        // set his registered value as TRUE (for that first require statement at the top of the function)
        tokenIdsToRegistered[tokenId] = true;

        // set his tokenIdsToLastWithdrawalDay to the _curentDay
        // even though this nft never had a real withdrawal, set the lastWithdrwalDay to today as a starting point to measure future withdrawals from
        tokenIdsToLastWithdrawalDay[tokenId] = _currentDay();

        // send the user his daily allotement of reward token for 1 days worth
        // as 1) a reward for registering, also it informs the user how much theyll be recieving per day
        if (tokenId < 1343){
            // give a bonus to the first 500 NFT's created
            // partially beneveolent and partially because people lost out who locked up earlier before the launch of this project
            IERC20(CARN).transfer(tokenOwner, tokenIdsToDailyRewardAmount[tokenId] * (1350-tokenId)/10 );
            IERC20(CARN).transfer(waatcaAddress, tokenIdsToDailyRewardAmount[tokenId] * (1350-tokenId)/10 );
            totalFreeCarnWithdrawn += tokenIdsToDailyRewardAmount[tokenId] * (1350-tokenId)/10;
        } else {
            IERC20(CARN).transfer(tokenOwner, tokenIdsToDailyRewardAmount[tokenId] * 7);
            IERC20(CARN).transfer(waatcaAddress, tokenIdsToDailyRewardAmount[tokenId] * 7);
            totalFreeCarnWithdrawn += tokenIdsToDailyRewardAmount[tokenId];
        }

        // set tokenIdsToEndRewardsDay to currentday + numDaysLockedUpFromRegistration (max 1000 days from registration)
        tokenIdsToEndRewardsDay[tokenId] = _currentDay() + numDaysLockedUpFromRegistration;
    }

    function currentDay() external view returns (uint256) {
        return _currentDay();
    }

    function _currentDay() internal view returns (uint256) {
        return (block.timestamp - LAUNCH_TIME) / 1 days;
    }
}