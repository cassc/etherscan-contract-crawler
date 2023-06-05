//SPDX-License-Identifier: MIT

/***
 *            ██    ██  █████  ██      ██           ██████   ██████  ████████      █████  ███    ██ ██    ██ 
 *             ██  ██  ██   ██ ██      ██          ██       ██    ██    ██        ██   ██ ████   ██  ██  ██  
 *              ████   ███████ ██      ██          ██   ███ ██    ██    ██        ███████ ██ ██  ██   ████   
 *               ██    ██   ██ ██      ██          ██    ██ ██    ██    ██        ██   ██ ██  ██ ██    ██    
 *               ██    ██   ██ ███████ ███████      ██████   ██████     ██        ██   ██ ██   ████    ██    
 *                                                                                                           
 *                                                                                                           
 *            ███    ███  ██████  ██████  ███████      ██████  ███████     ████████ ██   ██  █████  ████████ 
 *            ████  ████ ██    ██ ██   ██ ██          ██    ██ ██             ██    ██   ██ ██   ██    ██    
 *            ██ ████ ██ ██    ██ ██████  █████       ██    ██ █████          ██    ███████ ███████    ██    
 *            ██  ██  ██ ██    ██ ██   ██ ██          ██    ██ ██             ██    ██   ██ ██   ██    ██    
 *            ██      ██  ██████  ██   ██ ███████      ██████  ██             ██    ██   ██ ██   ██    ██    
 *                                                                                                           
 *                                                                                                           
 *                            ██████  ██    ██ ███████ ████████     ██████                                   
 *                            ██   ██ ██    ██ ██         ██             ██                                  
 *                            ██   ██ ██    ██ ███████    ██          ▄███                                   
 *                            ██   ██ ██    ██      ██    ██          ▀▀                                     
 *                            ██████   ██████  ███████    ██          ██                                     
 *                                                                                                           
 * 
 *
 *    ETHER.CARDS - DUST TOKEN
 *                                                                                                          
 */

pragma solidity >=0.6.0 <0.8.0;

import "./openzeppelin/ERC777.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DustToken is ERC777, Ownable {

    constructor(
        string memory name,
        string memory symbol,
        address[] memory _defaultOperators,
        uint256 _initialSupply
    )
    ERC777(name, symbol, _defaultOperators) {
        _mint(msg.sender, _initialSupply, "", "");
    }

   /**
     * @dev update {IERC777-name} {IERC777-symbol}. 
     */
    function updateTokenInfo(string calldata _newName, string calldata _newSymbol) public onlyOwner {
        super._setName(_newName);
        super._setSymbol(_newSymbol);
    }
}