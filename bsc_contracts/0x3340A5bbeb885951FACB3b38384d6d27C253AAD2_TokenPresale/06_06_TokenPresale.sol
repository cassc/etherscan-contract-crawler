// contracts/TokenPresale.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract TokenVesting {
    
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) virtual public;
    
    function transferOwnership(address) virtual public;
}

/**
 * @title TokenPresale
 */
contract TokenPresale is Ownable {

    using SafeERC20 for IERC20;

    uint256 constant SEED_PRICE = 20000000000000000; // 0.02 USDT
    uint256 constant SEED_TGE_CLIFF = 3600;
    uint256 constant SEED_TGE_LOCK_COUNT = 50000000000000000000000; //4.00% - 50000, 4% Unlocked at TGE
    uint256 constant SEED_VESTING_CLIFF = 259200; // 3 month cliff
    uint256 constant SEED_VESTING_DURATION = 1036800; // Linear vesting 12 months
    uint256 constant SEED_VESTING_PERIOD = 86400;
    uint256 constant SEED_LOCK_COUNT = 1200000000000000000000000; // 96.00% - 1200000

    uint256 constant PRIVATE_PRICE = 10000000000000000; // 0.01 USDT
    uint256 constant PRIVATE_TGE_CLIFF = 3600;
    uint256 constant PRIVATE_TGE_LOCK_COUNT = 12500000000000000000000; //50.00% - 12500, 50% Unlocked at TGE
    uint256 constant PRIVATE_VESTING_CLIFF = 86400;
    uint256 constant PRIVATE_VESTING_DURATION = 172800; // 25% released after Month 1, and 25% after Month 2
    uint256 constant PRIVATE_VESTING_PERIOD = 86400;
    uint256 constant PRIVATE_LOCK_COUNT = 12500000000000000000000; // 50.00% - 12500

    uint256 constant TEST_PRICE = 10000000000000000; // 0.01 USDT


    IERC20 immutable private liquidityToken;
    TokenVesting immutable private tokenVesting;
    address private masterWallet;
    uint256 public startTime;
    uint public remainingSeedCount;
    uint public remainingPrivateCount;
    uint256 public seedStart;
    uint256 public seedEnd;
    uint256 public privateStart;
    uint256 public privateEnd;

    constructor(
        address liquidityToken_,
        address tokenVesting_,
        address masterWallet_,
        uint256 startTime_,
        uint remainingSeedCount_,
        uint remainingPrivateCount_,
        uint256 seedStart_,
        uint256 seedEnd_,
        uint256 privateStart_,
        uint256 privateEnd_
        ) {
        require(liquidityToken_ != address(0x0), "Liquidity token can't be null");
        require(tokenVesting_ != address(0x0), "Token vesting can't be null");
        liquidityToken = IERC20(liquidityToken_);
        tokenVesting = TokenVesting(tokenVesting_);
        masterWallet = masterWallet_;
        startTime = startTime_;
        remainingSeedCount = remainingSeedCount_;
        remainingPrivateCount = remainingPrivateCount_;
        seedStart = seedStart_;
        seedEnd = seedEnd_;
        privateStart = privateStart_;
        privateEnd = privateEnd_;
    }

    function getLiquidityToken()
    external
    view
    returns(address){
        return address(liquidityToken);
    }

    function getLockerAddress()
    external
    view
    returns(address){
        return address(tokenVesting);
    }

    function buySeed() public {
        require(remainingSeedCount > 0, "Seed locations are over");
        uint256 currentTime = getCurrentTime();
        require(currentTime > seedStart && currentTime < seedEnd, "The Seed round is closed");
        require(
            liquidityToken.transferFrom(msg.sender, masterWallet, SEED_PRICE), // pay 10000 USDT
            "Failed to transfer to master wallet"
        );
        require(
            makeLock(
                msg.sender,
                startTime,
                SEED_TGE_CLIFF,
                1,
                1,
                SEED_TGE_LOCK_COUNT
            ), "Failed to create TGE lock"
        );
        require(
            makeLock(
                msg.sender,
                startTime,
                SEED_VESTING_CLIFF,
                SEED_VESTING_DURATION,
                SEED_VESTING_PERIOD,
                SEED_LOCK_COUNT
            ), "Failed to create vesting lock"
        );
        remainingSeedCount -= 1;
    }

    function buyPrivate() public {
        require(remainingPrivateCount > 0, "Private locations are over");
        uint256 currentTime = getCurrentTime();
        require(currentTime > privateStart && currentTime < privateEnd, "The Private round is closed");
        require(
            liquidityToken.transferFrom(msg.sender, masterWallet, PRIVATE_PRICE), // pay 250 USDT
            "Failed to transfer to master wallet"
        );
        require(
            makeLock(
                msg.sender,
                startTime,
                PRIVATE_TGE_CLIFF,
                1,
                1,
                PRIVATE_TGE_LOCK_COUNT //50.00% - 12500, 50% Unlocked at TGE
            ), "Failed to create TGE lock"
        );
        require(
            makeLock(
                msg.sender,
                startTime,
                PRIVATE_VESTING_CLIFF,
                PRIVATE_VESTING_DURATION, // 25% released after Month 1, and 25% after Month 2
                PRIVATE_VESTING_PERIOD,
                PRIVATE_LOCK_COUNT // 50.00% - 12500
            ), "Failed to create vesting lock"
        );
        remainingPrivateCount -= 1;
    }

    function buyTest() public {
        require(
            liquidityToken.transferFrom(msg.sender, masterWallet, TEST_PRICE), // pay 0.01 USDT
            "Failed to transfer to master wallet"
        );
    }

    function makeLock(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        uint256 _amount
    ) private returns (bool) {
        tokenVesting.createVestingSchedule(
            _beneficiary,
            _start,
            _cliff,
            _duration,
            _slicePeriodSeconds,
            false, // not revocable
            _amount
        );
        return true;
    }

    function transferLockerOwnership(
        address _to
    ) public onlyOwner {
        tokenVesting.transferOwnership(_to);
    }

    function withdrawBalanceAfterPrivate(
        address _to,
        uint256 _amount
    ) public onlyOwner {
        uint256 currentTime = getCurrentTime();
        require(currentTime > privateEnd, "It is impossible to withdraw tokens until all rounds are closed");
        makeLock(
            _to,
            startTime,
            0,
            1,
            1,
            _amount
        );
    }

    function getCurrentTime()
        internal
        virtual
        view
        returns(uint256){
        return block.timestamp;
    }
}