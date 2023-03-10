// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ILockedStakingrewards {
    function exit() external;
    function getReward() external;
    function getUserLockTime(address user) external view returns(uint);
    function withdraw(uint256 amount) external;
    function stake(uint256 amount) external;
    function earned(address account) external view returns (uint256);
    function reStake() external;
}

contract VestingStaker {
    using SafeERC20 for IERC20;
    IERC20 public token;
    ILockedStakingrewards public stakingContract;
    address public recipient;
    bool public started;

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == recipient, "Only the contract owner may perform this action");
    }

    constructor() {
        // Don't allow implementation to be initialized.
        recipient = address(1);
    }

    function initialize(IERC20 _token, ILockedStakingrewards _stakingContract, address _recipient) external
    {
        require(recipient == address(0), "already initialized");
        require(_recipient != address(0), "recipient cannot be null");

        recipient = _recipient;
        token = _token;
        stakingContract = _stakingContract;
    }

    function startStaking() public {
        require(started == false, "already staked");
        token.approve(address(stakingContract), token.balanceOf(address(this)));
        started = true;
        stakingContract.stake(token.balanceOf(address(this)));
    }

    function withdrawStaking(uint amount) public onlyOwner {
        stakingContract.withdraw(amount);
        token.transfer(msg.sender, amount);
    }

    function getReward() public onlyOwner {
        stakingContract.getReward();
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function reStake() public onlyOwner {
        stakingContract.reStake();
    }

    function withdrawToRecipient(uint amount) public onlyOwner {
        require(started == true, "not started");
        token.transfer(msg.sender, amount);
    }

    function changeOwner(address newOwner) public onlyOwner {
        recipient = newOwner;
    }

    function getUserLockTime() public view returns(uint) {
        return stakingContract.getUserLockTime(address(this));
    }

    function earned() public view returns(uint) {
        return stakingContract.earned(address(this));
    }

}