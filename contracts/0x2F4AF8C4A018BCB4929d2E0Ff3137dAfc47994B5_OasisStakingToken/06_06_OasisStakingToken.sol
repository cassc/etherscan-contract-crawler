// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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
 * @title   OasisStakingToken - Placeholder token used by OasisStake.
 * @notice  Conditionally transferrable ERC-20 awarded 1:1 for each Evolved Camels staked in the Oasis.
 */

contract OasisStakingToken is ERC20, Ownable {
    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice OasisStake contract address.
    address public oasisStake;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Basic ERC20 Token - Oasis Staking Token (OSST).
    constructor() ERC20("Oasis Staking Token", "OSST") {}

    /*///////////////////////////////////////////////////////////////
                                TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Only allow transfers if Zero Address or OasisStake contract.
     * @param   _from  Address to transfer '_amount' from.
     * @param   _to  Address to transfer '_amount' to.
     * @param   _amount  Amount of tokens to transfer.
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if (_from == address(0) || _from == oasisStake || _to == oasisStake)
            super._beforeTokenTransfer(_from, _to, _amount);
        else revert("Soulbound");
    }

    /*///////////////////////////////////////////////////////////////
                                OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Mint any amount to any address.
     * @dev     Owner only.
     * @param   _to  Address to mint '_amount' to.
     * @param   _amount  Amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /**
     * @notice  Sets the OasisStake contract address.
     * @param   _oasisStake  OasisStake contract address.
     */
    function setOasisStake(address _oasisStake) public onlyOwner {
        oasisStake = _oasisStake;
    }
}