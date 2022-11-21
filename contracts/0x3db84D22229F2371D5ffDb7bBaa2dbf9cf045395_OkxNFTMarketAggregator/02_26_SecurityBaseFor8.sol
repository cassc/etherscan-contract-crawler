pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Main functions:
 */
abstract contract SecurityBaseFor8 is Ownable {

    using SafeERC20 for IERC20;
    using Address for address payable;
    using Address for address;

    event EmergencyWithdraw(address token, address to, uint256 amount);
    event SetWhitelist(address account, bool knob);

    // whitelist
    mapping(address => bool) public whitelist;

    constructor() {}

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "SecurityBase::onlyWhitelist: isn't in the whitelist");
        _;
    }

    function setWhitelist(address account, bool knob) external onlyOwner {
        whitelist[account] = knob;
        emit SetWhitelist(account, knob);
    }

    function withdraw(address token, address to, uint256 amount) external onlyOwner {
        if (token.isContract()) {
            IERC20(token).safeTransfer(to, amount);
        } else {
            payable(to).sendValue(amount);
        }
        emit EmergencyWithdraw(token, to, amount);
    }
}