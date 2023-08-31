// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./control/TransferLockableUpgradable.sol";
import "./control/RestrictableUpgradable.sol";

contract AdonxTokenV2 is
    Initializable,
    ERC20Upgradeable,
    ERC20CappedUpgradeable,
    ERC20BurnableUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    TransferLockableUpgradable,
    RestrictableUpgradable
{
    bytes32 public constant PAUSER_AGENT_ROLE   = keccak256("PAUSER_AGENT_ROLE");
    bytes32 public constant MINTER_AGENT_ROLE   = keccak256("MINTER_AGENT_ROLE");
    bytes32 public constant UPGRADER_AGENT_ROLE = keccak256("UPGRADER_AGENT_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, uint256 _supply) 
        public initializer 
    {
        __ERC20_init(_name, _symbol);
        __ERC20Capped_init(_supply * (10 ** decimals()));
        __ERC20Burnable_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __TransferLockableUpgradable_init();
        __RestrictableUpgradable_init();

        _grantRole(DEFAULT_ADMIN_ROLE,  _msgSender());
        _grantRole(PAUSER_AGENT_ROLE,   _msgSender());
        _grantRole(MINTER_AGENT_ROLE,   _msgSender());
        _grantRole(UPGRADER_AGENT_ROLE, _msgSender());
        _grantRole(TRASFER_AGENT_ROLE,  _msgSender());
        _grantRole(RESTRICT_AGENT_ROLE, _msgSender());
    }

    function pause() 
        public 
        onlyRole(PAUSER_AGENT_ROLE) 
    {
        _pause();
    }

    function unpause() 
        public 
        onlyRole(PAUSER_AGENT_ROLE) 
    {
        _unpause();
    }

    function mint(address to, uint256 amount) 
        public 
    {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20CappedUpgradeable)
        onlyRole(MINTER_AGENT_ROLE)
    {
        super._mint(account, amount);
    }

    function transfer(
        address _to,
        uint256 _value
    )
        public 
        override
        whenNotTransferLocked(_msgSender())
        returns (bool success)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) 
        public 
        override 
        whenNotTransferLocked(_msgSender())
        returns (bool success) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) 
        internal 
        override 
        whenNotPaused
        whenNotRestricted(from)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyRole(UPGRADER_AGENT_ROLE) 
    {}
}