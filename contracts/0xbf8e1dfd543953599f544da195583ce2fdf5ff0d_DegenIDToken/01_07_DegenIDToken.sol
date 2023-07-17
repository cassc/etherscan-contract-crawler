// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IDegenIDToken} from "./interfaces/IDegenIDToken.sol";

/**
* --DegenIDToken--
* --DID--
                        ..::::::::..                                            
                   .^!?J55PPGGGGGGPP55J?!^.                                      
              .~?5PDEGENIDDEGENIDDEGENIDGP5?~.                                  
           .~JPDEGENIDDEGENIDDEGENIDDEGENIDGGPJ~.                               
         :?PDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDGP?:                             
       :?DEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENID?:                           
      !PDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDGGP!                          
    .JDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDGGGGGGJ.                        
   .5DEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDG5.                       
  .YDEGENIDGGGGGPYJJ?????????PPJ???JGP??JJY5DEGENIDGGGGGY.                      
  ?DEGENIDGGGJ!:.            55     PY     .:~JPDEGENIDGG?                      
 :DEGENIDGGJ:     .:^^^^     5P^^^^~P5^^:.     .?DEGENIDGG:                     
 7DEGENIDG?     ~YPGGGGP.    5G5YYYYPGGGGPY!     7DEGENIDG7                     
 YDEGENIDP.    ?DEGENIDP.    55     YDEGENIDJ     YDEGENIDY                     
 5DEGENIDY    .PDEGENIDP.    55     YDEGENIDG:    ?DEGENID5                     
 YDEGENIDP.    ?DEGENIDP.    55     YDEGENIDJ     YDEGENIDY                     
 7DEGENIDG?     ~YPGGGGG5YYYYG5     5GGGGPY!     7DEGENIDG7                     
 :DEGENIDGGJ:     .:^^^^^^^^^55     :^^^:.     :?DEGENIDGG:                     
  ?DEGENIDGGGY!:.            Y5            .:~JPDEGENIDGG?                      
  .YDEGENIDGGGGGP5JJ?????????PPJ????????JJYPDEGENIDGGGGGY.                      
   .5DEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDG5.                       
     .JDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDGGGGGGJ.                        
      !PDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDGGP!                          
       :?DEGENIDDEGENIDDEGENIDDEGENIDDEGENIDDEGENID?:                           
         :?PDEGENIDDEGENIDDEGENIDDEGENIDDEGENIDGP?:                             
           .~JPDEGENIDDEGENIDDEGENIDDEGENIDGGPJ~.                               
              .~?5PDEGENIDDEGENIDDEGENIDGP5?~.                                  
                  .^!?J55PPGGGGGGPP55J?!^.                                      
                        ..::::::::..   
**/
contract VaultOwned is Ownable {
    
  address internal _vault;

  function setVault( address vault_ ) external onlyOwner() returns ( bool ) {
    _vault = vault_;

    return true;
  }

  function vault() public view returns (address) {
    return _vault;
  }

  modifier onlyVault() {
    require( _vault == msg.sender, "VaultOwned: caller is not the Vault" );
    _;
  }

}

contract DegenIDToken is ERC20, VaultOwned, IDegenIDToken {
    uint256 private immutable _MaxSupply;
    address public TeamVestingContract;
    address public MarketVestingContract;

    constructor(
        address _premint,
        uint256 _max
    ) ERC20("DegenID Token", "DID") {
        require(_max > 0, "Cannot be Zero");
        _mint(_premint, _max*5/100);
        _MaxSupply = _max;
    }

    function releaseToken(address _team, address _market) public onlyOwner {
        TeamVestingContract = _team;
        MarketVestingContract = _market;
        _mint(_team, _MaxSupply*10/100);
        _mint(_market, _MaxSupply*10/100);
    }

    function mint(address account, uint256 amount) external override onlyVault returns (bool status) {
        if (totalSupply() + amount <= _MaxSupply) {
            _mint(account, amount);
            return true;
        }
        return false;
    }

    function MaxSupply() external view override returns (uint256) {
        return _MaxSupply;
    }
}