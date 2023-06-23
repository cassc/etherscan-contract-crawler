// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * EnvoyToken contract
 * This contract implements a continuous minting function. The minting function is protected with MINTER_ROLE.
 * Each minting operation requires the unique complementary Corda transaction SecureHash as a reference for provenance.
 * We leverage the use of Open Zeppelin contracts for Context, AccessControl, and ERC20.
 */
contract EnvoyToken is Context, AccessControl, ERC20 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * Event emitted with each minting, referencing back to the Corda transaction
     */
    event EnvoyProvenance(
        bytes32 indexed cordaTxHash,
        address indexed to,
        uint256 amount 
    );

    /**
     * account - the account that will control this contract
     */
    constructor(address account) ERC20("Envoy Token", "VOY") {
        _setupRole(MINTER_ROLE, account);
    }

    /**
     * to - receiver address of minted tokens
     * amount - total number of VOY tokens
     * cordaTxHash - the corda transaction securehash that this minting event has provenance to. 
     */
    function mint(address to, uint256 amount, bytes32 cordaTxHash) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "EnvoyToken: must have minter role to mint");
        _mint(to, amount);
        emit EnvoyProvenance(cordaTxHash, to, amount);
    }
}