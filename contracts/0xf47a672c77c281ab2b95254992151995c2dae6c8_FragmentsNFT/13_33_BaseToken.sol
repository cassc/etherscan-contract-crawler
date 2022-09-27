// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Utils.sol";
import "../../contracts-generated/Versioned.sol";

/**
 * @dev Implementation of upgradable ERC20 contract based on the OpenZeppelin templates.
 */
contract BaseToken is ERC20PausableUpgradeable,
                      ERC20BurnableUpgradeable, 
                      AccessControlUpgradeable, 
                      ReentrancyGuardUpgradeable,
                      Versioned 
{
    /// @custom:oz-renamed-from __gap
    uint256[950] private _gap_;
    
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    /**
     * @dev Initializes the `name` and `symbol` of the contract.
     * `admin` receives {DEFAULT_ADMIN_ROLE} and {PAUSER_ROLE}, assumes msg.sender if not specified.
     */
    function __BaseToken_init(string memory tokenName, string memory tokenSymbol, address admin) 
        internal 
        onlyInitializing 
    {
        require(Utils.isKnownNetwork(), "unknown network");
        
        __ERC20_init(tokenName, tokenSymbol);
        __ERC20Pausable_init();
        __ERC20Burnable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        if (admin == address(0)) {
            admin = _msgSender();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    /**
     * @dev Pause the contract, requires `PAUSER_ROLE`
     */
    function pause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _pause();
    }

    /**
     * @dev Unpause the contract, requires `PAUSER_ROLE`
     */
    function unpause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _unpause();
    }

    /**
     * @dev Mints `amount` tokens to `to`, requires `MINTER_ROLE`
     */
    function mint(address to, uint256 amount) 
        public 
        onlyRole(MINTER_ROLE) 
    {
        _mint(to, amount);
    }

    /**
     * @dev See {ERC20Upgradeable}, {ERC20PausableUpgradeable}
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        ERC20PausableUpgradeable._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev See {ERC20BurnableUpgradeable}
     * Skips the allowance check if the caller has `BURNER_ROLE`
     */
    function burnFrom(address account, uint256 amount) 
        public 
        virtual 
        override(ERC20BurnableUpgradeable) 
    {
        // skip allowance check if the caller has BURNER_ROLE
        if (hasRole(BURNER_ROLE, _msgSender())) {
            _burn(account, amount);
            return;            
        }
        
        ERC20BurnableUpgradeable.burnFrom(account, amount);
    }
}