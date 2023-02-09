// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract GameERC20TreasureReciever is Ownable, Pausable {
    using SafeERC20 for IERC20;

    address public controller;
    address public token;

    // Access control
    address public timeLocker;

    event TopUp(address indexed sender, uint256 amount, uint256 nonce);

    constructor(address _token, address _controller, address _timeLocker) {
        controller = _controller;
        token = _token;
        timeLocker = _timeLocker;
    }

    receive() external payable {}

    function topUp(uint256 _amount, uint256 _nonce) public whenNotPaused {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        emit TopUp(msg.sender, _amount, _nonce);
    }

    function withdraw(uint256 _amount, address _reciever) public onlyTimelocker {
        IERC20(token).safeTransfer(_reciever, _amount);
    }

    function unLockEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function pause() public onlyController {
        _pause();
    }

    function unpause() public onlyController {
        _unpause();
    }

    function setTimeLocker(address timeLocker_) public onlyTimelocker {
        timeLocker = timeLocker_;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    modifier onlyController() {
        require(msg.sender == controller, "only controller");
        _;
    }

    modifier onlyTimelocker() {
        require(msg.sender == timeLocker, "not timelocker");
        _;
    }
}