// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/**
 * @notice a base contract for logic extensions that use the diamond pattern storage
 * to map the functions when looking up the extension contract to delegate to.
 */
abstract contract DiamondExtension {
  /**
   * @return a list of all the function selectors that this logic extension exposes
   */
  function _getExtensionFunctions() external pure virtual returns (bytes4[] memory);
}

// When no function exists for function called
error FunctionNotFound(bytes4 _functionSelector);

// When no extension exists for function called
error ExtensionNotFound(bytes4 _functionSelector);

// When the function is already added
error FunctionAlreadyAdded(bytes4 _functionSelector, address _currentImpl);

abstract contract DiamondBase {
  /**
   * @dev register a logic extension
   * @param extensionToAdd the extension whose functions are to be added
   * @param extensionToReplace the extension whose functions are to be removed/replaced
   */
  function _registerExtension(DiamondExtension extensionToAdd, DiamondExtension extensionToReplace) external virtual;

  function _listExtensions() public view returns (address[] memory) {
    return LibDiamond.listExtensions();
  }

  fallback() external {
    address extension = LibDiamond.getExtensionForFunction(msg.sig);
    if (extension == address(0)) revert FunctionNotFound(msg.sig);
    // Execute external function from extension using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the extension
      let result := delegatecall(gas(), extension, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

/**
 * @notice a library to use in a contract, whose logic is extended with diamond extension
 */
library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct Function {
    address implementation;
    uint16 index; // used to remove functions without looping
  }

  struct LogicStorage {
    mapping(bytes4 => Function) functions;
    bytes4[] selectorAtIndex;
    address[] extensions;
  }

  function getExtensionForFunction(bytes4 msgSig) internal view returns (address) {
    LibDiamond.LogicStorage storage ds = diamondStorage();
    address extension = ds.functions[msgSig].implementation;
    if (extension == address(0)) revert ExtensionNotFound(msgSig);
    return extension;
  }

  function diamondStorage() internal pure returns (LogicStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function listExtensions() internal view returns (address[] memory) {
    return diamondStorage().extensions;
  }

  function registerExtension(DiamondExtension extensionToAdd, DiamondExtension extensionToReplace) internal {
    if (address(extensionToReplace) != address(0)) {
      removeExtension(extensionToReplace);
    }
    addExtension(extensionToAdd);
  }

  function removeExtension(DiamondExtension extension) internal {
    LogicStorage storage ds = diamondStorage();
    // remove all functions of the extension to replace
    removeExtensionFunctions(extension);
    for (uint8 i = 0; i < ds.extensions.length; i++) {
      if (ds.extensions[i] == address(extension)) {
        ds.extensions[i] = ds.extensions[ds.extensions.length - 1];
        ds.extensions.pop();
      }
    }
  }

  function addExtension(DiamondExtension extension) internal {
    LogicStorage storage ds = diamondStorage();
    for (uint8 i = 0; i < ds.extensions.length; i++) {
      require(ds.extensions[i] != address(extension), "extension already added");
    }
    addExtensionFunctions(extension);
    ds.extensions.push(address(extension));
  }

  function removeExtensionFunctions(DiamondExtension extension) internal {
    bytes4[] memory fnsToRemove = extension._getExtensionFunctions();
    LogicStorage storage ds = diamondStorage();
    for (uint16 i = 0; i < fnsToRemove.length; i++) {
      bytes4 selectorToRemove = fnsToRemove[i];
      // must never fail
      assert(address(extension) == ds.functions[selectorToRemove].implementation);
      // swap with the last element in the selectorAtIndex array and remove the last element
      uint16 indexToKeep = ds.functions[selectorToRemove].index;
      ds.selectorAtIndex[indexToKeep] = ds.selectorAtIndex[ds.selectorAtIndex.length - 1];
      ds.functions[ds.selectorAtIndex[indexToKeep]].index = indexToKeep;
      ds.selectorAtIndex.pop();
      delete ds.functions[selectorToRemove];
    }
  }

  function addExtensionFunctions(DiamondExtension extension) internal {
    bytes4[] memory fnsToAdd = extension._getExtensionFunctions();
    LogicStorage storage ds = diamondStorage();
    uint16 selectorCount = uint16(ds.selectorAtIndex.length);
    for (uint256 selectorIndex = 0; selectorIndex < fnsToAdd.length; selectorIndex++) {
      bytes4 selector = fnsToAdd[selectorIndex];
      address oldImplementation = ds.functions[selector].implementation;
      if (oldImplementation != address(0)) revert FunctionAlreadyAdded(selector, oldImplementation);
      ds.functions[selector] = Function(address(extension), selectorCount);
      ds.selectorAtIndex.push(selector);
      selectorCount++;
    }
  }
}