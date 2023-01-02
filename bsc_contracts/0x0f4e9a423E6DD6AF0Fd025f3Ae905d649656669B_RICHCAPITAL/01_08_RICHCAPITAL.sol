// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "CuratedByToken.sol";
import "FeeProcessor.sol";


// @custom:security-contact [email protected]

contract RICHCAPITAL is ERC20, Ownable, CuratedByToken("1.0"), FeeProcessor{
constructor(address payable feeReceiver_) 
        payable 
        ERC20("RICH CAPITAL", "RCX")
        FeeProcessor(feeReceiver_){
            // Tokenomics
            //Owner
            _mint(0x6c8E71135b945d9b500fD6f69EfC8D245284C567,  52000000* 10 ** decimals());
            //Public Sale
            _mint(0x94DdEdE4e5e9c42b9273583fbd48346D79356530,  10000000* 10 ** decimals());
            //Airdrop
            _mint(0xaebB65E30c22f277B2C40743a2794f5c62da65d8,  1000000* 10 ** decimals());
            //Team & Freelancers
            _mint(0xD3d138f1f270e98d66192FBcE3bD2558D5C74B3e,  5000000* 10 ** decimals());
            //Liquidity
            _mint(0x50AeF53FF235553c698BC38024F2cc0f7760D36d,  7500000* 10 ** decimals());
            //Treasure
            _mint(0x343fC43D8E5B969144d7884de8d43C2466DE618D,  20000000* 10 ** decimals());
            //Marketing
            _mint(0xe13e3CB44D3A2FF93f7E8E6dCD39609456f475Df,  2500000* 10 ** decimals());
            //Private Sale
            _mint(0xBd909C5E9390bfc303D79D06453CDF538568093f,  2000000* 10 ** decimals());

        }
    
function _burn(address account, uint256 amount)
        internal
        override(ERC20)
    {
        super._burn(account, amount);
    }
}