// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BidsVesting is Ownable {
    using SafeERC20 for IERC20;

    event UserMonth(address user, uint256 startEpoch, uint256 endEpoch, uint256 veBids, uint256 lpBids);
    event AnnounceInitiation(uint256 total);
    event Release(address entity, uint256 amount);
    event UserDataTransferred(address from, address to);

    uint256 constant MONTH = 2592000;
    uint256 public constant MONTH_COUNT = 25; //Note if you change this value to a number which is too high, there will be a gas limit deadlock

    //Token
    IERC20 public immutable bids;

    //User claimed amount
    mapping(address => uint256) public claimedAmount;

    //User => month (starting a 0) => month data
    mapping(address => mapping(uint256 => MonthData)) public vestingInfo;

    //The t=0 of the first month
    uint256 public immutable genesisStamp;

    ////Vested amounts used for sanity check
    //The total amount of funds
    uint256 public totalVested;
    //The current amount of funds
    uint256 public vested;

    //The data of a user in a specific month.
    struct MonthData {
        uint256 totalVeBids; //The amount of theoretical VeBids of a user
        uint256 totalPseudoLP; //The amount of BIDS respected as LP (represents "100%" of the lp components, not 80%)
        uint256 totalWithdrawable; //The withdrawable amount of a user
    }

    constructor(IERC20 _bids, uint256 _genesisStamp) {
        bids = _bids;
        genesisStamp = _genesisStamp;
    }

    //declare rules for each user
    //i.e _totalVeBids[i][x] is for _users[i] at month x
    function notifyUsersRules(
        address[] calldata _users,
        uint256[][] calldata _totalVeBids,
        uint256[][] calldata _totalPseudoLP,
        uint256[][] calldata _totalWithdrawable
    ) public onlyOwner {
        require(totalVested == 0, "Fully initiated");
        uint256 lastMonthIndex = MONTH_COUNT - 1; //related to small gas optimization regarding "_totalWithdrawable" require and loop condition
        uint256 j;
        uint256 _currentEpoch;
        uint256 _tempVestedAddtion;
        for (uint256 i; i < _users.length; ++i) {
            require(
                _totalPseudoLP[i].length == MONTH_COUNT &&
                    _totalWithdrawable[i].length == MONTH_COUNT &&
                    _totalVeBids[i].length == MONTH_COUNT,
                "Array length error"
            );
            _currentEpoch = genesisStamp;
            for (j = 0; j < lastMonthIndex; ++j) {
                require(_totalWithdrawable[i][j + 1] >= _totalWithdrawable[i][j], "Nonsensical release amounts");
                vestingInfo[_users[i]][j] = MonthData(_totalVeBids[i][j], _totalPseudoLP[i][j], _totalWithdrawable[i][j]);
                emit UserMonth(_users[i], _currentEpoch, _currentEpoch + MONTH, _totalVeBids[i][j], _totalPseudoLP[i][j]);
                _currentEpoch = _currentEpoch + MONTH;
            }
            //Save a little gas dwindling withdrawable require by handling the last month here (thus lastMonthIndex got -1)
            vestingInfo[_users[i]][lastMonthIndex] = MonthData(
                _totalVeBids[i][lastMonthIndex],
                _totalPseudoLP[i][lastMonthIndex],
                _totalWithdrawable[i][lastMonthIndex]
            );
            emit UserMonth(
                _users[i],
                _currentEpoch,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff,
                _totalVeBids[i][lastMonthIndex],
                _totalPseudoLP[i][lastMonthIndex]
            );

            _tempVestedAddtion += _totalWithdrawable[i][lastMonthIndex];
        }
        vested += _tempVestedAddtion;
    }

    //shout out that all the rules have been set for all users
    function announceInitiation(uint256 _expectedTotalVested) public onlyOwner {
        uint256 contractBal = bids.balanceOf(address(this));
        require(contractBal >= _expectedTotalVested, "Funds lack");
        require(vested == _expectedTotalVested, "Amounts mismatch");
        require(totalVested == 0, "Fully initiated");
        totalVested = _expectedTotalVested;

        //precaution
        if (contractBal > _expectedTotalVested) {
            bids.safeTransfer(msg.sender, contractBal - _expectedTotalVested);
        }
        emit AnnounceInitiation(_expectedTotalVested);
    }

    //withdraw tradeable amount
    function release(uint256 _amount) external {
        require(totalVested > 0, "Not fully initiated");
        uint256 _month = getMonth(block.timestamp, genesisStamp);
        uint256 _claimable = vestingInfo[msg.sender][_month].totalWithdrawable - claimedAmount[msg.sender];

        if (_amount <= _claimable) {
            claimedAmount[msg.sender] += _amount;
            vested -= _amount;
            bids.safeTransfer(msg.sender, _amount);
        } else {
            revert("Not enough claimable");
        }
        emit Release(msg.sender, _amount);
    }

    //Allows a user to transfer his entire vest info to a different wallet
    function transferUserData(address _new) external {
        require(totalVested > 0, "Not fully initiated");
        uint256 lastMonthIndex = MONTH_COUNT - 1;
        require(vestingInfo[msg.sender][lastMonthIndex].totalWithdrawable != 0, "Caller has no values");
        require(vestingInfo[_new][lastMonthIndex].totalWithdrawable == 0, "Receiver has values");
        for (uint256 i; i <= lastMonthIndex; i++) {
            vestingInfo[_new][i] = vestingInfo[msg.sender][i];
            delete vestingInfo[msg.sender][i];
        }
        claimedAmount[_new] = claimedAmount[msg.sender];
        delete claimedAmount[msg.sender];
        emit UserDataTransferred(msg.sender, _new);
    }

    //Shows the the withdrawn and withdrawable amount of a user
    function withdrawableDetails(address _user) external view returns (uint256 _claimable, uint256 _claimed) {
        if (block.timestamp < genesisStamp) {
            return (0, 0);
        }
        return (
            vestingInfo[_user][getMonth(block.timestamp, genesisStamp)].totalWithdrawable - claimedAmount[_user],
            claimedAmount[_user]
        );
    }

    //Get the month. If month is higher then total months, get the last one
    function getMonth(uint256 _blockTimestamp, uint256 _genesisStamp) public pure returns (uint256 _month) {
        require(_blockTimestamp >= _genesisStamp, "Vesting period not yet started");
        uint256 _delta = _blockTimestamp - _genesisStamp; //revert if month <0
        _month = _delta / MONTH;
        if (_month >= MONTH_COUNT) {
            _month = MONTH_COUNT - 1;
        }
    }

    //Get the current month
    function getCurrentMonth() external view returns (uint256 _currentMonth) {
        return getMonth(block.timestamp, genesisStamp);
    }
}