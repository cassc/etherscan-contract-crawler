// contracts/TokenBridge.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TokenBridge is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    mapping(uint256 => bool) private _fulfilments;

    event Deposit(address indexed src, uint256 amount, address indexed token);
    event Withdrawal(address indexed src, uint256 amount, address indexed token, uint256 fulfilmentId);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice Function to deposit token
     * @param amount Amount of tokens
     * @param token Address of token
     */
    function deposit(uint256 amount, IERC20 token) public {
        require (amount > 0, "!amount");
        token.safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposit(_msgSender(), amount, address(token));
    }

    /**
     * @notice Function to withdraw token
     * Caller is assumed to be governance
     * @param to Address of reciever
     * @param amount Amount of tokens
     * @param token Address of token
     * @param fulfilmentId Id of fulfilment
     */
    function withdraw(address to, uint256 amount, IERC20 token, uint256 fulfilmentId) public onlyRole(GOVERNOR_ROLE) {
        require (amount > 0, "!amount");
        require (!_fulfilments[fulfilmentId], "fulfilled");
        token.safeTransfer(to, amount);
        _fulfilments[fulfilmentId] = true;
        emit Withdrawal(to, amount, address(token), fulfilmentId);
    }

    function fulfilled(uint256 fulfilmentId) public view returns(bool fulfilmentStatus) {
        return _fulfilments[fulfilmentId];
    }
}