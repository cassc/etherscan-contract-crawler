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

import { IDiamond } from "../interfaces/IDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
  uint8 constant INNER_STRUCT = 0;

  struct FacetAddressAndSelectorPosition {
    address facetAddress;
    uint16 selectorPosition;
  }

  struct ProjectConfig {
    string name;    
    string symbol;    
    uint256 maxSupply;    
    uint256 price;    
    uint256 maxTotalMints;    
    uint256 maxMintTxns;    
    uint256 privateSaleTimestamp;     
    uint256 publicSaleTimestamp;             
    address superAdmin;    
    address[] primaryDistRecipients;    
    uint256[] primaryDistShares;    
    address royaltyReceiver;    
    uint96 royaltyFraction;    
    bytes32 merkleroot;            
    string _baseURI;    
    uint256 closeDate;    
    uint256 minMint;
  }

  struct DiamondStorage {
    // function selector => facet address and selector position in selectors array
    mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
    bytes4[] selectors;
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;  
    // mapping constant for avoiding future issues when adding new ProjectConfig vars
    uint8 INNER_STRUCT;
    mapping(uint8 => ProjectConfig) project;
  }

  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address contractOwner_) {
    contractOwner_ = diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    if(msg.sender != diamondStorage().contractOwner && msg.sender != diamondStorage().project[INNER_STRUCT].superAdmin) {
      revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
    }        
  }

  event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  // Internal function version of diamondCut
  function diamondCut(
    IDiamondCut.FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
      address facetAddress = _diamondCut[facetIndex].facetAddress;
      if(functionSelectors.length == 0) {
        revert NoSelectorsProvidedForFacetForCut(facetAddress);
      }
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamond.FacetCutAction.Add) {
        addFunctions(facetAddress, functionSelectors);
      } else if (action == IDiamond.FacetCutAction.Replace) {
        replaceFunctions(facetAddress, functionSelectors);
      } else if (action == IDiamond.FacetCutAction.Remove) {
        removeFunctions(facetAddress, functionSelectors);
      } else {
        revert IncorrectFacetCutAction(uint8(action));
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
    if(_facetAddress == address(0)) {
      revert CannotAddSelectorsToZeroAddress(_functionSelectors);
    }
    DiamondStorage storage ds = diamondStorage();
    uint16 selectorCount = uint16(ds.selectors.length);                
    enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
      if(oldFacetAddress != address(0)) {
        revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
      }            
      ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
      ds.selectors.push(selector);
      selectorCount++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
    DiamondStorage storage ds = diamondStorage();
    if(_facetAddress == address(0)) {
      revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
    }
    enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
      // can't replace immutable functions -- functions defined directly in the diamond in this case
      if(oldFacetAddress == address(this)) {
        revert CannotReplaceImmutableFunction(selector);
      }
      if(oldFacetAddress == _facetAddress) {
        revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
      }
      if(oldFacetAddress == address(0)) {
        revert CannotReplaceFunctionThatDoesNotExists(selector);
      }
      // replace old facet address
      ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
    DiamondStorage storage ds = diamondStorage();
    uint256 selectorCount = ds.selectors.length;
    if(_facetAddress != address(0)) {
      revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
    }        
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
      if(oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
        revert CannotRemoveFunctionThatDoesNotExist(selector);
      }            
      // can't remove immutable functions -- functions defined directly in the diamond
      if(oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
        revert CannotRemoveImmutableFunction(selector);
      }
      // replace selector with last selector
      selectorCount--;
      if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
        bytes4 lastSelector = ds.selectors[selectorCount];
        ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
        ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
      }
      // delete last selector
      ds.selectors.pop();
      delete ds.facetAddressAndSelectorPosition[selector];
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      return;
    }
    enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
    (bool success, bytes memory error) = _init.delegatecall(_calldata);
    if (!success) {
      if (error.length > 0) {
      // bubble up error
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(error)
        revert(add(32, error), returndata_size)
      }
    } else {
      revert InitializationFunctionReverted(_init, _calldata);
    }
    }        
  }

  function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    if(contractSize == 0) {
      revert NoBytecodeAtAddress(_contract, _errorMessage);
    }        
  }    
}

contract Modifiers {     

  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }
}