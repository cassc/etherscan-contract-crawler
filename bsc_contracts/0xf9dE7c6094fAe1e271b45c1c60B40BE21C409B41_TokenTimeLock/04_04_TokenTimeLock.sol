// contracts/TokenTimeLock.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Claimable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title TokenTimeLock
 */
contract TokenTimeLock is Claimable {
    using SafeMath for uint256;
    address[] private _beneficiaryList;
    uint256 private _start;
    uint256 private _stages;
    uint256 private _interval;
    uint256 private _released;
    address private  _token;
    address private _owner;

    event Released(uint256 amount);

    fallback() external payable {

    }

    receive() external payable {

    }

    constructor(
        address[]memory beneficiaryList_,
        uint256 start_,
        uint256 stages_,
        uint256 interval_,
        address token_
    ){
        require(beneficiaryList_.length > 0, "beneficiaryList is empty");
        _beneficiaryList = beneficiaryList_;
        _start = start_;
        _stages = stages_;
        _interval = interval_;
        _token = token_;
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function token() public view virtual returns (address) {
        return _token;
    }

    function start() public view virtual returns (uint256) {
        return _start;
    }

    function stages() public view virtual returns (uint256) {
        return _stages;
    }

    function interval() public view virtual returns (uint256) {
        return _interval;
    }

    function beneficiaryList() public view virtual returns (address[] memory) {
        return _beneficiaryList;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    function releasableAmount() public view returns (uint256) {
        uint256 currentBalance = IERC20(_token).balanceOf(address(this));
        if (block.timestamp < _start) {
            return 0;
        } else if (block.timestamp >= _start.add(_stages.mul(_interval))) {
            return currentBalance;
        } else {
            uint256 totalBalance = currentBalance.add(_released);
            uint256 amountTmp = totalBalance
            .mul(block.timestamp.sub(_start).div(_interval))
            .div(_stages);
            return amountTmp.sub(_released);
        }
    }

    function release() public virtual {
        uint256 unreleased = releasableAmount();
        require(unreleased > 0, "TokenTimeLock: no to release");
        _released = _released.add(unreleased);
        uint256 averageAmount = unreleased.div(_beneficiaryList.length);
        uint256 diff = unreleased.sub(averageAmount.mul(_beneficiaryList.length));
        uint256 randomIndex = 0;
        if (diff > 0) {
            randomIndex = _random(_beneficiaryList.length);
        }
        for (uint256 i = 0; i < _beneficiaryList.length; i++) {
            uint256 amount = averageAmount;
            if (diff > 0 && i == randomIndex) {
                amount = amount.add(diff);
            }
            if (amount > 0) {
                IERC20(_token).transfer(_beneficiaryList[i], amount);
            }
        }
        emit Released(unreleased);
    }

    function _random(uint256 count_) public view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return random % count_;
    }

    function claimValues(address token_, address to_) public virtual onlyOwner {
        require(token_ != _token, "token is error");
        _claimValues(token_, to_);
    }
}