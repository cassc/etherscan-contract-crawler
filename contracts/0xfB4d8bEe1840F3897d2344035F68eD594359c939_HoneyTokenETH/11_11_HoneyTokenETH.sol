// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @author Grizzly.fi
/// @title The Ethereum Version of the GHNY ERC20 Token.
/// @notice This Contracts initially mints 1 GHNY token to the deployer. After that, tokens will be minted and burned using a multichain.org bridge. The bridge contract receives the BRIDGE_MINTER_ROLE and will mint and burn tokens 1:1 with the BSC token. Hence, the total supply of GHNY will stay the same.
contract HoneyTokenETH is ERC20, AccessControl {
    bytes32 public constant BRIDGE_MINTER_ROLE =
        keccak256("BRIDGE_MINTER_ROLE");

    /// @notice Identifier for the multichain frontend to recognize the token
    address public constant underlying = address(0);

    /// @notice Initializes the contract
    /// @param _admin The default admin for the contract
    constructor(address _admin) ERC20("Grizzly Honey", "GHNY") {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _mint(msg.sender, 1 ether);
    }

    /// @notice Allows the bridge contract to mint tokens
    /// @param to The receiving address of the tokens minted
    /// @param amount The amount to be minted
    /// @return If the mint was successful
    function mint(address to, uint256 amount)
        external
        onlyRole(BRIDGE_MINTER_ROLE)
        returns (bool)
    {
        _mint(to, amount);
        return true;
    }

    /// @notice Allows the bridge contract to burn tokens
    /// @param from The address from where tokens are burned
    /// @param amount The amount to be burned
    /// @return If the burn was successful
    function burn(address from, uint256 amount)
        external
        onlyRole(BRIDGE_MINTER_ROLE)
        returns (bool)
    {
        require(from != address(0), "AnyswapV3ERC20: address(0x0)");
        _burn(from, amount);
        return true;
    }
}