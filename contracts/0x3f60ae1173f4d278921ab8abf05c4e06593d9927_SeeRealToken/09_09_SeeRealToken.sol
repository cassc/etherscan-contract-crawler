pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";

/**
 *  @title The SeeRealToken contract complies with the ERC20 standard 
 *  (see https://github.com/ethereum/EIPs/issues/20).
 */
contract SeeRealToken is ERC20Pausable, ERC20Detailed, ERC20Burnable {


    string constant private _name = "SeeRealToken";
    string constant private _symbol = "SRT";
    uint8 constant private _decimals = 18;
    
    uint constant private _initialSupply    = 100000000e18; // Initial supply of SeeRealToken

    
    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor () public ERC20Detailed(_name, _symbol, _decimals) {
        _mint( msg.sender, _initialSupply);
    }
}