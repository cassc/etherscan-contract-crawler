pragma solidity 0.8.16;
import {Denominations} from "chainlink/Denominations.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract SimpleRevenueContract {
    address owner;
    IERC20 revenueToken;

    constructor(address _owner, address token) {
        owner = _owner;
        revenueToken = IERC20(token);
    }

    function claimPullPayment() external returns (bool) {
        require(msg.sender == owner, "Revenue: Only owner can claim");
        if (address(revenueToken) != Denominations.ETH) {
            require(revenueToken.transfer(owner, revenueToken.balanceOf(address(this))), "Revenue: bad transfer");
        } else {
            payable(owner).transfer(address(this).balance);
        }
        return true;
    }

    function sendPushPayment() external returns (bool) {
        if (address(revenueToken) != Denominations.ETH) {
            require(revenueToken.transfer(owner, revenueToken.balanceOf(address(this))), "Revenue: bad transfer");
        } else {
            payable(owner).transfer(address(this).balance);
        }
        return true;
    }

    function doAnOperationsThing() external returns (bool) {
        require(msg.sender == owner, "Revenue: Only owner can operate");
        return true;
    }

    function doAnOperationsThingWithArgs(uint256 val) external returns (bool) {
        require(val > 10, "too small");
        if (val % 2 == 0) return true;
        else return false;
    }

    function transferOwnership(address newOwner) external returns (bool) {
        require(msg.sender == owner, "Revenue: Only owner can transfer");
        owner = newOwner;
        return true;
    }

    receive() external payable {}
}