// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "CuratedByToken.sol";
import "FeeProcessor.sol";

contract holynet is ERC20, Ownable, CuratedByToken("1.0"), FeeProcessor{
constructor(address payable feeReceiver_) 
        payable 
        ERC20("holynet", "holy")
        FeeProcessor(feeReceiver_){
            // Tokenomics
            //Owner
            _mint(0x87FBB98F4CAbEF92817ACd07C97A46D3Df33B392,  17000000* 10 ** decimals());
            //marketing
            _mint(0xB8D7f1D94C4e1fDC7C221E6351c6281B7F4A0064,  1000000* 10 ** decimals());
            //deveploment
            _mint(0xBb00B70C3AaE147BFf0A691E09bbD1efc140bD81,  2000000* 10 ** decimals());
            //partners
            _mint(0xac34d1C1b122342172F69c3d8388E3F9e4483bCB,  1000000* 10 ** decimals());

        }
    
function _burn(address account, uint256 amount)
        internal
        override(ERC20)
    {
        super._burn(account, amount);
    }
}