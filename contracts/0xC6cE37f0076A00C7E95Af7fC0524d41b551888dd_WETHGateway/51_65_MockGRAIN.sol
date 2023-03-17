// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract MockGRAIN is Initializable, ERC20Upgradeable, ERC20CappedUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant RESCUER_ROLE = keccak256("RESCUER_ROLE");
    uint256 public constant MAX_SUPPLY = 800_000_000 ether;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 public constant UPGRADE_TIMELOCK = 48 hours;
    uint256 public upgradeProposalTime;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // @param lge: granting minting rights to the Liquidity Generation Event contract for initial distribution  
    function initialize(address admin) initializer public { 
        __ERC20_init("Granary Token", "GRAIN");
        __ERC20Capped_init(MAX_SUPPLY); 
        __AccessControl_init(); 
        __Pausable_init();  
        __ERC20Permit_init("Granary Token");   
        __UUPSUpgradeable_init();   
        _grantRole(DEFAULT_ADMIN_ROLE, admin);  
        _grantRole(PAUSER_ROLE, admin); 
        _grantRole(MINTER_ROLE, admin); 
        _grantRole(UPGRADER_ROLE, admin);   
        _grantRole(RESCUER_ROLE, admin);    
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) returns (bool) {
        _mint(to, amount);
        return true;
    }
    function _mint(address account, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20CappedUpgradeable) {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20Upgradeable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function rescueLostTokens(address token, address to, uint256 amount) public onlyRole(RESCUER_ROLE){
    	IERC20Upgradeable(token).transfer(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) returns (bool) {
        _burn(from, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20Upgradeable){
        super._burn(account, amount);
    }

    /**
     * @dev DEFAULT_ADMIN_ROLE must call this function prior to upgrading the implementation
     *      and wait UPGRADE_TIMELOCK seconds before executing the upgrade.
     */
    function initiateUpgradeCooldown() external onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeProposalTime = block.timestamp;
    }

    /**
     * @dev This function is called:
     *      - as part of a successful upgrade
     *      - manually by DEFAULT_ADMIN_ROLE to clear the upgrade cooldown.a
     */
    function clearUpgradeCooldown() public onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeProposalTime = block.timestamp + (100 * 365 days);
    }

    /**
     * @dev This function must be overriden simply for access control purposes.
     *      Only DEFAULT_ADMIN_ROLE can upgrade the implementation once the timelock
     *      has passed.
     */
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(upgradeProposalTime + UPGRADE_TIMELOCK < block.timestamp, "cooldown not initiated or still active");
        clearUpgradeCooldown();
    }
}