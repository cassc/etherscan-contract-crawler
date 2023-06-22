// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './DvdShareholderPoint.sol';

/// @dev Ownable is used because solidity complain trying to deploy a contract whose code is too large when everything is added into Lord of Coin contract.
/// The only owner function is `init` which is to setup for the first time after deployment.
/// After init finished, owner will be renounced automatically. owner() function will return 0x0 address.
contract Dvd is ERC20, DvdShareholderPoint, Ownable {

    /// @notice Minter for DVD token. This value will be Lord of Coin address.
    address public minter;
    /// @notice Controller. This value will be Lord of Coin address.
    address public controller;
    /// @dev DVD pool address.
    address public dvdPool;

    constructor() public ERC20('Dvd.finance', 'DVD') {
    }

    /* ========== Modifiers ========== */

    modifier onlyMinter {
        require(msg.sender == minter, 'Minter only');
        _;
    }

    modifier onlyController {
        require(msg.sender == controller, 'Controller only');
        _;
    }

    /* ========== Owner Only ========== */

    /// @notice Setup for the first time after deploy and renounce ownership immediately
    function init(address _controller, address _dvdPool) external onlyOwner {
        controller = _controller;
        minter = _controller;
        dvdPool = _dvdPool;

        // Renounce ownership immediately after init
        renounceOwnership();
    }

    /* ========== Minter Only ========== */

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    /* ========== Controller Only ========== */

    /// @notice Increase shareholder point.
    /// @dev Can only be called by the LoC contract.
    /// @param account Account address
    /// @param amount The amount to increase.
    function increaseShareholderPoint(address account, uint256 amount) external onlyController {
        _increaseShareholderPoint(account, amount);
    }

    /// @notice Decrease shareholder point.
    /// @dev Can only be called by the LoC contract.
    /// @param account Account address
    /// @param amount The amount to decrease.
    function decreaseShareholderPoint(address account, uint256 amount) external onlyController {
        _decreaseShareholderPoint(account, amount);
    }

    /* ========== Internal ========== */

    /// @notice ERC20 Before token transfer hook
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // If transfer between two accounts
        if (from != address(0) && to != address(0)) {
            // Remove shareholder point from account
            _decreaseShareholderPoint(from, Math.min(amount, shareholderPointOf(from)));
        }
        // If transfer is from DVD pool (This occurs when user withdraw their stake, or using convenient stake ETH)
        // Give back their shareholder point.
        if (from == dvdPool) {
            _increaseShareholderPoint(to, amount);
        }
    }
}