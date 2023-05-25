pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PlugDeposit {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public constant VERSION = "1.0.0";

    address private _plug;
    mapping(address => uint256) private balances;

    constructor(address plug) public {
        _plug = plug;
    }

    event PlugDeposit(address indexed caller, uint256 amount);

    function userDeposit(uint256 amount) public {
        require(amount > 0, "PlugDeposit: Amount must be > 0");

        IERC20 plugToken = IERC20(_plug);
        uint256 allowance = plugToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "PlugDeposit: Token allowance too small");

        balances[msg.sender] = balances[msg.sender].add(amount);

        plugToken.safeTransferFrom(msg.sender, address(this), amount);
        emit PlugDeposit(msg.sender, amount);
    }

    function viewDeposit(address user) public view returns (uint256) {
        return balances[user];
    }
}