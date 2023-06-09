//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract VCore is AccessControl, ERC20Burnable {
    event MintingDisabled();

    // Supply cap of 8 billion tokens. 
    uint256 public constant SUPPLY_CAP = 8e9 ether;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bool public mintingEnabled;

    /**
     * Initializes the contract:
     *  - Creates the ADMIN role and grants it to `admin`
     *  - Creates the MINTER role and grants it to `minter`
     *  - Sets minting to enabled
     *  - Mints 8 Billion tokens to `initialTokenHolder`
     */
    constructor(
        address admin,
        address minter,
        address initialTokenHolder
    ) ERC20("VCORE", "VCORE") {
        require(admin != address(0), "admin address cannot be 0");
        require(minter != address(0), "minter address cannot be 0");
        require(initialTokenHolder != address(0), "initialTokenHolder address cannot be 0");
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, minter);

        mintingEnabled = true;

        _mint(initialTokenHolder, SUPPLY_CAP);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - minting must be enabled.
     * - cannot mint to the zero address.
     * - the caller must have the `MINTER_ROLE`.
     * - the amount minted cannot increase supply to more than the supply cap.
     */
    function mint(address to, uint256 amount) public virtual {
        require(mintingEnabled, "Minting is disabled");
        require(to != address(0), "to address cannot be 0");
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Must have minter role to mint"
        );
        require(totalSupply() + amount <= SUPPLY_CAP, "Amount would exceed supply cap");
        _mint(to, amount);
    }

    /**
     * Permanently disables minting.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function disableMinting() public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Must have admin role to disable minting"
        );
        mintingEnabled = false;
        emit MintingDisabled();
    }
}