// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title The Mycelium Token
 * @author raymogg
 */
contract MYCToken is AccessControl, ERC20, ERC20Burnable {
    // access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINTING_PAUSER = keccak256("MINTING_PAUSER");
    bool public mintingPaused;

    /**
     * @notice Emits when the minting state is changed.
     * @param newValue The new boolean value indicating if minting is paused.
     */
    event MintingStateChange(bool newValue);

    /**
     * @dev Sets up the `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `MINTING_PAUSER` roles.
     * @dev Initiates ERC20 data.
     * @param admin The address to whom all three roles will be assigned.
     * @param name The ERC20 token name.
     * @param symbol The ERC20 token symbol.
     */
    constructor(
        address admin,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        _setupRole(MINTING_PAUSER, admin);
    }

    /**
     * @notice allows the `MINTING_PAUSER` or `ADMIN` to pause token minting.
     * @dev If set to `true`, prevents all members of the `MINTER_ROLE` role from calling the mint function.
     * @dev Emits a `MintingStateChange` event.
     * @param value whether or not minting should be paused.
     */
    function setMintingPaused(bool value) external {
        require(
            hasRole(MINTING_PAUSER, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "MYC:NOT_PAUSER"
        );
        mintingPaused = value;
        emit MintingStateChange(value);
    }

    /**
     * @notice Mints MYC tokens and assigns them to a set address.
     * @param to The receiver of tokens.
     * @param amount The amount of tokens to be minted.
     * @custom:requirement `msg.sender` is a member of the `MINTER_ROLE` role.
     * @custom:requirement `mintingPaused == false`.
     */
    function mint(address to, uint256 amount) external {
        require(!mintingPaused, "MYC:MINTING_PAUSED");
        require(hasRole(MINTER_ROLE, msg.sender), "MYC:NOT_MINTER");
        _mint(to, amount);
    }
}