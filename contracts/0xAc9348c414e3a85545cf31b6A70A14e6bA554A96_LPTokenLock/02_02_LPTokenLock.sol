pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LPTokenLock {
    IERC20 public lpToken;
    address public beneficiary;
    uint256 public releaseTime;

    constructor(IERC20 _lpToken, address _beneficiary, uint256 _lockDuration) {
        require(_lockDuration > 0, "Lock duration must be a positive value.");
        lpToken = _lpToken;
        beneficiary = _beneficiary;
        releaseTime = block.timestamp + _lockDuration;
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount should be greater than 0.");
        require(
            lpToken.transferFrom(msg.sender, address(this), amount),
            "Token transfer failed."
        );
    }

    function release() external {
        require(block.timestamp >= releaseTime, "Tokens are still locked.");
        uint256 balance = lpToken.balanceOf(address(this));
        require(balance > 0, "No tokens to release.");
        lpToken.transfer(beneficiary, balance);
    }
}