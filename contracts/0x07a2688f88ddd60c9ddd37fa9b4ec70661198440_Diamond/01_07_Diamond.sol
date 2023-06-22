// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************\
 .    . . . . . . .... .. ...................... . . . .  .   .+
   ..  .   . .. . ............................ ... ....  . .. .+
 .   .  .. .. ....... ..;@@@@@@@@@@@@@@@@@@@;........ ... .  . +
  .   .  .. ...........X [email protected]@ 8  ....... .. .. .+
.  .. . . ... ... .:..% 8 [email protected] [email protected]%..8  .:...... . .  +
 .  . ... . ........:t:[email protected]@[email protected] ;  @......... .. ..+
.  . . . ........::.% 8 [email protected]  .   88:;:.:....... .+
.   . .. . .....:.:; [email protected]@88      S.88:.:........ .+
 . . .. .......:.:;88 @[email protected]@[email protected]@88888.   .888 88;.:..:..... +
.  .. .......:..:; [email protected] :  :Xt8 8 :S:.:........+
 .  .......:..:.;:8 8888888%8888888888 :. .888 8 88:;::::..... +
 . .. .......:::[email protected]@88%88888X ;. [email protected] 8  %:  8:..:.....+
. .........:..::[email protected] ;. :88SS 8t8.    @::......+
 . . .....:.::[email protected] 88 @88 @8 [email protected] 88 @::  8.8 8 [email protected]     88:.:.....v
. . .......:.:;t8 :8 8 88.8 8:8.:8 t8..88 8 8 @ 8   88;::.:....+
.. .......:.:::;.%8 @ 8 @ .8:@.8 ;8;8t8:[email protected] 8:8X    88t::::.....+
. .. ......:..:::t88 8 8 8 t8 %88 [email protected] @ 888 X 8 XX;::::.::...+
..........:::::::;:X:8 :8 8 ;8.8.8 @ :88 8:@ @   8X;::::::.:...+
  . .......:.:::::; 8 8.:8 8 t8:8 8 8.;88 XX  8 88t;:::::......+
.. .......:.:.:::::; @:8.;8 8.t8 8 tt8.%[email protected] 8  88t;:;::::.:....+
 ... ....:.:.:.::;::; 8:8 ;8 8 t8 8:8 8.t8S. 888;;:;::::.:..:..+
.  ........::::::::;:;.t 8 ;8 8 ;88:;8.8 ;88 88S:::::::.:.:....+
 .. .. .....:.:.:::::;; 888X8S8 [email protected] 888X:t;;;::::::.:.....+
 .. ........:..:::::;::;%;:   .t. ;ttS:;t. .  :;;:;:::.::......+
 . . ......:.:..::::::;;;t;;:;;;;;;;;t;;;;;:: :;:;:::.:........+
/***************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from  "./interfaces/IDiamondLoupe.sol";
import { IERC173 } from "./interfaces/IERC173.sol";
import { IERC165} from "./interfaces/IERC165.sol";

error FunctionNotFound(bytes4 _functionSelector);

struct DiamondArgs {
  address owner;
  address init;
  bytes initCalldata;
}

contract Diamond {    

  constructor(IDiamondCut.FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable {
    LibDiamond.setContractOwner(_args.owner);
    LibDiamond.diamondCut(_diamondCut, _args.init, _args.initCalldata);        
  }
  
  fallback() external payable {
    LibDiamond.DiamondStorage storage ds;
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    
    assembly {
      ds.slot := position
    }
    
    address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
    if(facet == address(0)) {
      revert FunctionNotFound(msg.sig);
    }
    
    assembly {        
      calldatacopy(0, 0, calldatasize())             
      let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)            
      returndatacopy(0, 0, returndatasize())            
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  receive() external payable {}
}