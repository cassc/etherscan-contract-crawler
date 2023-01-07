// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./interfaces/ILudicrous.sol";

import "./libs/ERC4626Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

// todo custom deposit instead of transfer moSOLID => override totalAssets to avoid reading from contract balance

contract elmoSOLID is
    ERC4626Upgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

    ILudicrous public ludicrous;

    function initialize(
        IERC20Upgradeable _moSOLID,
        address admin,
        address setter,
        address pauser
    ) public initializer {
        __ERC4626_init(_moSOLID, "elmo SOLID", "elmoSOLID");
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UNPAUSER_ROLE, admin);
        _grantRole(SETTER_ROLE, setter);
        _grantRole(PAUSER_ROLE, pauser);

        _pause();
    }

    function setAddresses(address _ludicrous) external onlyRole(SETTER_ROLE) {
        ludicrous = ILudicrous(_ludicrous);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        ludicrous.withdraw(from, amount);
        super._transfer(from, to, amount);
        ludicrous.deposit(amount, to);
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        require(block.timestamp < 1673020800, "Pausable: paused");

        super._deposit(caller, receiver, assets, shares);
        ludicrous.deposit(shares, receiver);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override whenNotPaused {
        super._withdraw(caller, receiver, owner, assets, shares);
        ludicrous.withdraw(owner, shares);
    }

    function name()
        public
        view
        virtual
        override(ERC20Upgradeable, IERC20MetadataUpgradeable)
        returns (string memory)
    {
        return "elmo SOLID";
    }
}