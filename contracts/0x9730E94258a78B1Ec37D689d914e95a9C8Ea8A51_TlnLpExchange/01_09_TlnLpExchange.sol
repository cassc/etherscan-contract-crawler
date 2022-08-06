// contracts/VowLpExchange.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BurnableIERC20.sol";

contract TlnLpExchange is AccessControl {
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    address private _lpToken;
    address private _tlnToken;
    uint256 private _totalExchanged = 0;

    event Exchange(address indexed src, uint256 amount);
    event WithdrawToken(address indexed token, address indexed dest, uint256 amount);

    constructor(address lpTokenAddress, address tlnTokenAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(GOVERNOR_ROLE, _msgSender());
        _lpToken = lpTokenAddress;
        _tlnToken = tlnTokenAddress;
    }

    /**
     * @notice Function to exchange token
     * @param amount Amount of tokens
     */
    function exchange(
        uint256 amount
    ) external {
        require (amount >= 0, "!zero");
        uint256 tlnBalance = IERC20(_tlnToken).balanceOf(_msgSender());
        BurnableIERC20(_tlnToken).burnFrom(_msgSender(), amount);
        require((tlnBalance - amount) == IERC20(_tlnToken).balanceOf(_msgSender()), "!burn");
        require (IERC20(_lpToken).transfer(_msgSender(), amount), "!transfer");
        _totalExchanged += amount;
        emit Exchange(_msgSender(), amount);
    }

    /**
     * @notice Function to withdraw token
     * Owner is assumed to be governance
     * @param token Address of token to be rescued
     * @param destination User address
     * @param amount Amount of tokens
     */
    function withdrawToken(
        address token,
        address destination,
        uint256 amount
    ) external onlyRole(GOVERNOR_ROLE) {
        require(address(0) != destination, "!zero");
        require(token != destination, "token == destination");
        require(amount > 0, "!zero");
        require(IERC20(token).transfer(destination, amount), "!transfer");
        emit WithdrawToken(token, destination, amount);
    }

    /**
     * @dev Returns the _lpToken.
     */
    function lpToken() public view virtual returns (address) {
        return _lpToken;
    }

    /**
     * @dev Returns the tlnToken.
     */
    function tlnToken() public view virtual returns (address) {
        return _tlnToken;
    }

    /**
     * @dev Returns the _totalExchanged.
     */
    function totalExchanged() public view virtual returns (uint256) {
        return _totalExchanged;
    }
}