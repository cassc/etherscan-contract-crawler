// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Single LP/token Lock Smart Contract 
/// @author @m3tamorphTECH

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract KiwiLock {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    address public owner;
    uint public ids = 0;
    address public LPAddy = 0x3Cd26c1E33eC2e690380640CBDBF91178541674E; // address of the KIWI-WBNB LP token

    struct Lock {
        uint id;
        uint amount;
        uint lockDate;
        uint unlockDate;
        address owner;
    }

    mapping(uint => Lock) private locks;

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }

    function lockLP(address _token, uint _amount, uint _duration) external {
        require(_token == LPAddy, "Invalid token");
        require(_amount > 0, "Amount should be greater than 0");

        ids++;
        uint id = ids;

        Lock memory lock = Lock({
            id: id,
            amount: _amount,
            lockDate: block.timestamp,
            unlockDate: block.timestamp + _duration,
            owner: owner
        });

        locks[id] = lock;

        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function addToLockedLP(uint _id, address _token, uint _amount) external {
        Lock memory lock = locks[_id];

        require(lock.id == _id, "Invalid lock id");
        require(_token == LPAddy, "Invalid token");

        locks[_id].amount += _amount;

        IERC20(_token).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    function unlockLP(uint _id) external {
        Lock memory lock = locks[_id];

        require(lock.id == _id, "Invalid lock id");
        require(lock.owner == msg.sender, "Invalid owner");
        require(block.timestamp >= lock.unlockDate, "Lock is still active");

        IERC20(LPAddy).safeTransfer(
            msg.sender,
            lock.amount
        );
    }

    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }

    function recoverERC20Token(address _token) external onlyOwner {
        require(_token != LPAddy, "Cannot recover LP token");
        IERC20(_token).safeTransfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function recoverNativeBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}