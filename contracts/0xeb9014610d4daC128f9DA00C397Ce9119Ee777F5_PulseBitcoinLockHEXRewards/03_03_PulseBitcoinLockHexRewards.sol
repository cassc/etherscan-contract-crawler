// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface PulseBitcoinLockNFTInterface {
    function ownerOf(uint256 tokenId) external view returns (address);
    function lockTime(uint256 tokenId) external view returns (uint256);
    function tokenIdsToAmounts(uint256 tokenId) external view returns (uint256);
}

contract PulseBitcoinLockHEXRewards is ReentrancyGuard {
    address public HEX;
    address public immutable waatcaAddress;
    PulseBitcoinLockNFTInterface pulseBitcoinLockNftContract;
    address public pulseBitcoinLockNftContractAddress;
    mapping(uint256 => bool) public tokenIdsToRegistered; // True if they registered their NFT for rewards...will be able to withdraw rewards 1 day after registering
    mapping(uint256 => uint256) public tokenIdsToLastWithdrawalDay; // records the last day they withdrew rewards
    mapping(uint256 => uint256) public tokenIdsToDailyRewardAmount; // records their daily rewards amount
    mapping(uint256 => uint256) public tokenIdsToEndRewardsDay; // records their last day they can get rewards (max 1000 after registering)...(the smaller of 1000 or their actual end day measured from registration day)
    uint256 internal constant LAUNCH_TIME = 1680048000; // Wednesday, March 29, 2023 12:00:00 AM
    uint256 public totalFreeHexWithdrawn;
    uint256 public CARN_FEE = 369 * 1e12;
    address public immutable CARN;
    address private constant DEAD_ADDRESS = address(0x0000000000000000000000000000000000DeADca);

    address public txnFeeSendTo;
    uint public baseTxnFee;
    event TxnError(uint tokenId, string reason);
    event TxnErrorBytes(uint tokenId, bytes reason);
    event NotOwnerError(uint tokenId);

    struct NftVariables {
        uint tokenId;
        bool isRegistered;
        bool canWithdrawal;
        uint withdrawalAmount;
    }

    constructor(address _waatcaAddress, address _pulseBitcoinLockNftContractAddress, address _hexAddress, address _CARN, address _txnFeeSendTo) {
        waatcaAddress = _waatcaAddress;
        pulseBitcoinLockNftContractAddress = _pulseBitcoinLockNftContractAddress;
        pulseBitcoinLockNftContract = PulseBitcoinLockNFTInterface(pulseBitcoinLockNftContractAddress);
        HEX = _hexAddress;
        CARN = _CARN;
        txnFeeSendTo = _txnFeeSendTo;
        baseTxnFee = 0.001 ether;
    }

    receive() payable external {
        payable(txnFeeSendTo).transfer(msg.value);
    }


    function withdrawRewards(uint256 tokenId) public {
        require(msg.sender == pulseBitcoinLockNftContract.ownerOf(tokenId), "You are not the owner of this NFT, shame on you!");
        require(tokenIdsToRegistered[tokenId], "You must register your NFT for rewards first");
        require(tokenIdsToLastWithdrawalDay[tokenId] < tokenIdsToEndRewardsDay[tokenId], "You have already received all possible rewards for this NFT");
        require(_currentDay() > tokenIdsToLastWithdrawalDay[tokenId], "Cannot withdraw twice on the same day, try again tomorrow");

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


        IERC20(HEX).transfer(msg.sender, tokenIdsToDailyRewardAmount[tokenId] * numOfDaysSinceLastWithdrawal);
        IERC20(HEX).transfer(waatcaAddress, tokenIdsToDailyRewardAmount[tokenId] * numOfDaysSinceLastWithdrawal);
        totalFreeHexWithdrawn += tokenIdsToDailyRewardAmount[tokenId] * numOfDaysSinceLastWithdrawal;

        tokenIdsToLastWithdrawalDay[tokenId] = _currentDay();
    }

    function registerNftForRewards(uint256 tokenId) public {
        require(msg.sender == pulseBitcoinLockNftContract.ownerOf(tokenId), "You are not the owner of this NFT, shame on you!");
        require(!tokenIdsToRegistered[tokenId], "It seems you have already registered this NFT, go enjoy the rest of the carnival!");

        uint256 endOfLockPeriod = pulseBitcoinLockNftContract.lockTime(tokenId);
        uint256 numDaysLockedUpFromRegistration = ((endOfLockPeriod - LAUNCH_TIME) / 1 days) - _currentDay();
        uint256 numDaysLockedUpFromRegistrationForRewards = numDaysLockedUpFromRegistration;

        IERC20(CARN).transferFrom(msg.sender, DEAD_ADDRESS, CARN_FEE);
        CARN_FEE += 1e12; // increaese fee by 1 carn each time someone registers

        if (numDaysLockedUpFromRegistrationForRewards > 5000) {
            numDaysLockedUpFromRegistrationForRewards = 5000;
        }

        uint256 amountPLSBLockedUp = pulseBitcoinLockNftContract.tokenIdsToAmounts(tokenId);
        //10_000_000_000_000_000 = 10,000 * 1e12
        if (amountPLSBLockedUp > 5_000_000_000_000_000) {
            // this makes locking more than 1000 plsb for more than 1000 days, not beneficial in terms of getting rewards
            amountPLSBLockedUp = 5_000_000_000_000_000;
        }

        tokenIdsToDailyRewardAmount[tokenId] = (amountPLSBLockedUp * numDaysLockedUpFromRegistrationForRewards * 250) / (100_000_000 * 1e4);

        // set his registered value as TRUE (for that first require statement at the top of the function)
        tokenIdsToRegistered[tokenId] = true;

        // set his tokenIdsToLastWithdrawalDay to the _curentDay
        // even though this nft never had a real withdrawal, set the lastWithdrwalDay to today as a starting point to measure future withdrawals from
        tokenIdsToLastWithdrawalDay[tokenId] = _currentDay();

        IERC20(HEX).transfer(msg.sender, tokenIdsToDailyRewardAmount[tokenId]);
        IERC20(HEX).transfer(waatcaAddress, tokenIdsToDailyRewardAmount[tokenId]);
        totalFreeHexWithdrawn += tokenIdsToDailyRewardAmount[tokenId];

        // set tokenIdsToEndRewardsDay to _currentday + numDaysLockedUpFromRegistration (max 1000 days from registration)
        tokenIdsToEndRewardsDay[tokenId] = _currentDay() + numDaysLockedUpFromRegistration;
    }

    function currentDay() external view returns (uint256) {
        return _currentDay();
    }

    function _currentDay() internal view returns (uint256) {
        return (block.timestamp - LAUNCH_TIME) / 1 days;
    }



    function _txnFee(uint tokenIdLength) internal view returns(uint) {
        uint txnFee = baseTxnFee * tokenIdLength;

        if(txnFee < baseTxnFee * 10) {
            txnFee = baseTxnFee * 10;
        }

        return txnFee;
    }

    function _senderIsTokenOwner(uint tokenId) internal view returns(bool) {
        return msg.sender == pulseBitcoinLockNftContract.ownerOf(tokenId);
    }


    function bulkRegister(uint[] calldata tokenIds) public payable nonReentrant {
        uint tokenIdsLength = tokenIds.length;
        uint txnFee = _txnFee(tokenIdsLength);

        if(msg.value != txnFee) {
            revert("Txn Fee invalid");
        }

        payable(txnFeeSendTo).transfer(txnFee);

        for( uint i; i < tokenIdsLength; ) {
            if(!_senderIsTokenOwner(tokenIds[i])) {
                emit NotOwnerError(tokenIds[i]);
                continue;
            }

            registerNftForRewards(tokenIds[i]);


            unchecked {
                i++;
            }
        }

    }

    function bulkWithdraw(uint[] calldata tokenIds) public payable nonReentrant {
        uint tokenIdsLength = tokenIds.length;
        uint txnFee = _txnFee(tokenIdsLength);

        if(msg.value != txnFee) {
            revert("Txn Fee invalid");
        }

        payable(txnFeeSendTo).transfer(txnFee);

        for( uint i; i < tokenIdsLength; ) {
            if(!_senderIsTokenOwner(tokenIds[i])) {
                emit NotOwnerError(tokenIds[i]);
                continue;
            }

            withdrawRewards(tokenIds[i]);

            unchecked {
                i++;
            }
        }
    }

}