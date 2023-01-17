// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../common/BaseProxy.sol";
import "../common/BaseDAO.sol";
import "../common/IMFLocks.sol";

contract MFLocks is BaseDAO, BaseProxy, IMFLocks {
    modifier onlySwap() {
        require(msg.sender == address(mfSwap), "Only Swap");
        _;
    }

    struct Lock {
        uint256 widthdrawAmount;
        uint256 startDate;
        uint256 duration;
        uint256 amount;
    }

    uint256 public constant CBTDecimals = 10**14;

    IMFToken public mf;
    IERC20 public cbt;
    IMFSwap public mfSwap;

    mapping(address => Lock) public locks;

    function initialize(
        address _mf,
        address _cbt,
        address _mfSwap
    ) public initializer {
        mf = IMFToken(_mf);
        cbt = IERC20(_cbt);
        mfSwap = IMFSwap(_mfSwap);

        __Ownable_init();
    }

    function addLock(
        address _investor,
        uint256 _amount,
        uint256 _dateStart,
        uint256 _duration
    ) external onlySwap {
        require(locks[_investor].amount == 0, "You already have a lock");

        locks[_investor] = Lock(0, _dateStart, _duration, _amount);
    }

    function withdraw() external {
        Lock memory lock = locks[msg.sender];

        require(lock.amount != 0, "You don't have a lock");

        uint256 availableAmount = ((lock.amount *
            getProgress(lock.startDate, lock.duration)) / precision) -
            lock.widthdrawAmount;

        locks[msg.sender].widthdrawAmount += availableAmount;
        mf.transfer(msg.sender, availableAmount);
    }
}