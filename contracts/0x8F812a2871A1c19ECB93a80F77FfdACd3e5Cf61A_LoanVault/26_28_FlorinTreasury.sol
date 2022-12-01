// SPDX-License-Identifier: GPL-2.0-or-later
// (C) Florence Finance, 2022 - https://florence.finance/
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./FlorinToken.sol";
import "./Util.sol";

contract FlorinTreasury is AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public constant LOAN_VAULT_ROLE = keccak256("LOAN_VAULT_ROLE");

    event Mint(address sender, address receiver, uint256 florinTokens);
    event Redeem(address redeemer, uint256 florinTokens, uint256 eurTokens);
    event DepositEUR(address sender, address from, uint256 eurTokens);

    FlorinToken public florinToken;

    IERC20Upgradeable public eurToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line

    function initialize(FlorinToken florinToken_, IERC20Upgradeable eurToken_) external initializer {
        __AccessControl_init_unchained();
        __Pausable_init_unchained();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        florinToken = florinToken_;
        eurToken = eurToken_;

        _pause();
    }

    /// @dev Pauses the Florin Treasury (only by DEFAULT_ADMIN_ROLE)
    function pause() external {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _pause();
    }

    /// @dev Unpauses the Florin Treasury (only by DEFAULT_ADMIN_ROLE)
    function unpause() external {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _unpause();
    }

    /// @dev Mint Florin Token to receiver address (only by LOAN_VAULT_ROLE && when not paused)
    /// @param receiver receiver address
    /// @param florinTokens amount of Florin Token to be minted
    function mint(address receiver, uint256 florinTokens) public whenNotPaused {
        _checkRole(LOAN_VAULT_ROLE, _msgSender());
        florinToken.mint(receiver, florinTokens);
        emit Mint(_msgSender(), receiver, florinTokens);
    }

    /// @dev Redeem (burn) Florin Token to Florin Treasury and receive eurToken (only when not paused)
    /// @param florinTokens amount of Florin Token to be burned
    function redeem(uint256 florinTokens) public whenNotPaused {
        florinToken.burnFrom(_msgSender(), florinTokens);
        uint256 eurTokens = Util.convertDecimalsERC20(florinTokens, florinToken, eurToken);
        eurToken.transfer(_msgSender(), eurTokens);
        emit Redeem(_msgSender(), florinTokens, eurTokens);
    }

    /// @dev Deposit eurToken to Florin Treasury (requires a previous approval by 'from')
    /// @param from address which owns the eurToken
    /// @param eurTokens amount of eurToken to be deposited [18 decimals]
    function depositEUR(address from, uint256 eurTokens) public whenNotPaused {
        eurTokens = Util.convertDecimals(eurTokens, 18, Util.getERC20Decimals(eurToken));
        eurToken.transferFrom(from, address(this), eurTokens);
        emit DepositEUR(_msgSender(), from, eurTokens);
    }

    function transferFlorinTokenOwnership(address newOwner) external {
        _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());
        florinToken.transferOwnership(newOwner);
    }
}