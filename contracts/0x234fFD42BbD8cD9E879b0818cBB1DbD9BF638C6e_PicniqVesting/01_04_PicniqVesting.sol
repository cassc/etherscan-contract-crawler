// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./libraries/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PicniqVesting is Context {
    using Address for address;

    IERC20 public immutable SNACK;

    uint256 public totalVested;
    mapping (address => UserVest) private _vesting;

    struct UserVest {
        uint8 length;
        uint64 startTime;
        uint64 endTime;
        uint256 amount;
        uint256 withdrawn;
    }

    constructor(IERC20 token_) {
        SNACK = token_;
    }

    function vestedOfDetails(address account) external view returns (UserVest memory)
    {
        return _vesting[account];
    }

    function vestedOf(address account) public view returns (uint256)
    {
        UserVest memory userVest = _vesting[account];

        if (userVest.endTime <= block.timestamp) {
            return userVest.amount - userVest.withdrawn;    
        } else {
            uint256 timeElapsed = block.timestamp - userVest.startTime;
            uint256 length = userVest.endTime - userVest.startTime;
            uint256 percent = timeElapsed * 1e18 / length;
            return (userVest.amount * percent / 1e18) - userVest.withdrawn;
        }
    }

    function unvest() external
    {
        address sender = _msgSender();
        uint256 vested = vestedOf(sender);

        require(vested > 0, "No tokens to unvest");

        _vesting[sender].withdrawn += vested;
        totalVested -= vested;
        SNACK.transfer(sender, vested);

        emit TokensClaimed(sender, vested);
    }
    
    function vestTokens(address account, uint256 amount, uint256 length) public
    {
        require(length == 6 || length == 12, "Must choose length of 6 or 12 months");

        UserVest storage userVest = _vesting[account];

        require(userVest.amount == 0, "You are already vesting tokens");

        SNACK.transferFrom(msg.sender, address(this), amount);

        totalVested += amount;

        userVest.amount = amount;
        userVest.startTime = uint64(block.timestamp);
        userVest.endTime = uint64(block.timestamp + (2628000 * length));
        userVest.length = uint8(length);
        userVest.withdrawn = 0;

        emit TokensVested(account, amount, length);
    }

    event TokensVested(address indexed account, uint256 amount, uint256 months);
    event TokensClaimed(address indexed account, uint256 amount);
}