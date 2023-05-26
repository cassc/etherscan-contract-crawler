// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./ERC20/ERC20.sol";
import "./ERC20/ERC20Detailed.sol";
import "./utils/TokenRecover.sol";
import "./features/ERC20Pausable.sol";

contract XNOToken is ERC20Detailed, TokenRecover, ERC20Pausable {
    
    uint256 private constant _initialSupply = 2100000000;
    
    constructor () public ERC20Detailed ( "XENO NFT HUB", "XNO", 18 ) 
    { _mint(_msgSender(), _initialSupply * (10 ** uint256(decimals()))); }

    function initialSupply() public pure returns ( uint256 ){
        return _initialSupply;
    }
}