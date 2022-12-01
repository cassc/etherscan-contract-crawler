// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//  ==========  INTERNAL IMPORTS    ==========

import "../interfaces/IOasisToken.sol";

/*///////////////////////////////////////
/////////╭━━━━┳╮╱╱╱╱╱╭━━━╮///////////////
/////////┃╭╮╭╮┃┃╱╱╱╱╱┃╭━╮┃///////////////
/////////╰╯┃┃╰┫╰━┳━━╮┃┃╱┃┣━━┳━━┳┳━━╮/////
/////////╱╱┃┃╱┃╭╮┃┃━┫┃┃╱┃┃╭╮┃━━╋┫━━┫/////
/////////╱╱┃┃╱┃┃┃┃┃━┫┃╰━╯┃╭╮┣━━┃┣━━┃/////
/////////╱╱╰╯╱╰╯╰┻━━╯╰━━━┻╯╰┻━━┻┻━━╯/////
///////////////////////////////////////*/

/**
 * @author  0xFirekeeper
 * @title   OasisToken - ERC20 token used within the Oasis ecosystem.
 * @notice  Standard ERC-20 for the Oasis. Mintable by assigned Minters or by burning a Crazy Camels NFT.
 */

contract OasisToken is ERC20, AccessControlEnumerable, IOasisToken {
    /*///////////////////////////////////////////////////////////////
                               STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Minter role identifier for AccessControl.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @notice Burner role identifier for AccessControl.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Address of the Oasis Graveyard.
    address public immutable oasisGraveyard;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Grants admin role to deployer and sets the Oasis Graveyard immutable address.
     * @param   _oasisGraveyard  Address of the Oasis Graveyard.
     */
    constructor(address _oasisGraveyard) ERC20("Oasis Token", "OST") {
        oasisGraveyard = _oasisGraveyard;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                                MINTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Mint `_amount` of token to `_to`.
     * @dev     Minter role only.
     * @param   _to  Address will receieve minted tokens.
     * @param   _amount  Amount of tokens to be minted.
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                                BURNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Burn `_amount` of token from `_from` - the burner address is the empty OasisGraveyard contract.
     * @dev     Burner role only.
     * @param   _from  Address `_amount` of token will be burned form.
     * @param   _amount  Amount of tokens to be burned.
     */
    function burn(address _from, uint256 _amount) external onlyRole(BURNER_ROLE) {
        transferFrom(_from, oasisGraveyard, _amount);
    }
}