// SPDX-License-Identifier: MIT
/// @title TAUKN Foundation Stablecoin : KCHF
/// @author TAUKN Foundation
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TauknCHF is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable {


    // Constants for various roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant DESTROYER_ROLE = keccak256("DESTROYER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BLOCKLISTER_ROLE = keccak256("BLOCKLISTER_ROLE");
    bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

    // Events
    event Issue(address to, uint256 amount);
    event Redeem(uint256 amount);
    event DestroyedBlockFunds(address blockListedAddress, uint256 dirtyFunds);


    /**
     * @dev Constructor that disables initializers.
    */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
      @dev Initializes the contract with the given admin and block lister addresses.
      @param name The name of the token.
      @param symbol The symbol of the token.
      @param admin The address to grant minter, burner, and pauser roles to.
      @param blockLister The address to grant the blocklister role to.
    */
    function initialize(
        string calldata name,
        string calldata symbol, 
        address admin,
        address blockLister
        ) initializer public{
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
	    __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init(name);

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(DESTROYER_ROLE, admin);
        _grantRole(BLOCKLISTER_ROLE, blockLister);
    }

    /**
      @dev Mints new tokens and assigns them to the given address.
      @param to The address to mint the tokens to.
      @param amount The amount of tokens to mint.
      @custom:emits Issue(to, amount) when the tokens are minted.
    */
    function mint(address to, uint256 amount) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
        emit Issue(to, amount);
    }

    /**
      @dev Burns a specified amount of tokens from the caller's balance.
      @param amount The amount of tokens to burn.
      @custom:emits Redeem(amount) when the tokens are burned.
    */
    function burn(uint256 amount) public override {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(msg.sender, amount);
        emit Redeem(amount);
    }

    /**
      @dev Grants the blocklisted role to the given address.
      @param _blockListedAddress The address to grant the blocklisted role to.
    */
    function blockList(address _blockListedAddress) external {
        require(hasRole(BLOCKLISTER_ROLE, msg.sender), "Caller is not a blocklister");
        _grantRole(BLOCKLISTED_ROLE, _blockListedAddress);
    }

    /**
      @dev Revokes the blocklisted role from the given address.
      @param _blockListedAddress The address to revoke the blocklisted role from.
    */
    function unBlockList(address _blockListedAddress) external {
        require(hasRole(BLOCKLISTER_ROLE, msg.sender), "Caller is not a blocklister");
        _revokeRole(BLOCKLISTED_ROLE, _blockListedAddress);
    }

    /**
        @dev Destroys the balance of a blocklisted address and transfers it to the contract's balance.
        @param _blockListedAddress The blocklisted address to destroy funds from.
        @custom:emit DestroyedBlockFunds(_blockListedAddress, dirtyFunds) when the funds are destroyed.
    */
    function destroyBlockFunds(address _blockListedAddress) public {
        require(hasRole(DESTROYER_ROLE, msg.sender), "Caller is not a destroyer");
        require(hasRole(BLOCKLISTED_ROLE, _blockListedAddress), "Address is not blocklisted");
        uint256 _dirtyFunds = balanceOf(_blockListedAddress);
        _burn(_blockListedAddress, _dirtyFunds);
        emit DestroyedBlockFunds(_blockListedAddress, _dirtyFunds);
    }

    /**
      @dev Pauses the contract, preventing most contract functions from being called.
      @notice Only callable by a contract function with the pauser role.
    */
    function pause() public {
        require(!hasRole(PAUSER_ROLE, msg.sender), "Caller is not a pauser");
        _pause();
    }

    /**
      @dev Unpauses the contract, allowing contract functions to be called again.
      @notice Only callable by a contract function with the pauser role.
    */
    function unpause() public {
        require(!hasRole(PAUSER_ROLE, msg.sender), "Caller is not a pauser");
        _unpause();
    }
    
    /** 
      @dev Validates that the sender of the transfer does not have the blocklisted role before allowing the transfer to occur.
      @param from The address that the tokens are being transferred from.
      @param to The address that the tokens are being transferred to.
      @param amount The amount of tokens being transferred.
      @custom:throws If the sender has the blocklisted role.
    */

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
    	require(!hasRole(BLOCKLISTED_ROLE, msg.sender), "Address is blocklisted");
        super._beforeTokenTransfer(from, to, amount);
    }

}