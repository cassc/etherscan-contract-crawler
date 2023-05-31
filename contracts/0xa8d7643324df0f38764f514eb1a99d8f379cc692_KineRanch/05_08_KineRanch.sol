pragma solidity ^0.5.16;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./KineSafeMath.sol";
import "./Ownable.sol";

contract KineRanch is ERC20, Ownable {
    using KineSafeMath for uint256;
    using SafeERC20 for IERC20;

    uint constant public MAX_LEAVE_FEE_RATE = 2e2;

    string public name;
    string public symbol;
    uint8 public decimals;
    IERC20 public kine;
    uint public leaveFeeRate;

    constructor (string memory name_, string memory symbol_, uint8 decimals_, address kine_) public {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        kine = IERC20(kine_);
    }

    function setLeaveFeeRate(uint feeRate) external onlyOwner {
        require(feeRate <= MAX_LEAVE_FEE_RATE, 'reach max leave fee rate');
        leaveFeeRate = feeRate;
    }

    function enter(uint256 amount) external {
        uint256 totalKine = kine.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalKine == 0) {
            _mint(msg.sender, amount);
        } else {
            uint256 share = amount.mul(totalShares).div(totalKine);
            _mint(msg.sender, share);
        }
        kine.safeTransferFrom(msg.sender, address(this), amount);
    }

    function leave(uint256 share) external {
        uint256 totalShares = totalSupply();
        uint256 amount = share.mul(kine.balanceOf(address(this))).mul(1e3 - leaveFeeRate).div(totalShares).div(1e3);
        _burn(msg.sender, share);
        kine.safeTransfer(msg.sender, amount);
    }
}