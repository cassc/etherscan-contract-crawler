//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { TokenDefinition } from "../interfaces/IToken.sol";

import "../interfaces/IDiamondFactory.sol";
import "../interfaces/IDiamond.sol";

interface IDiamondElement {
  function initialize(
    address, 
    DiamondSettings memory,
    IDiamondCut.FacetCut[] calldata,
    address,
    bytes calldata) external payable;
}

library DiamondFactoryLib {

  bytes32 internal constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.nextblock.bitgem.app.DiamondFactoryStorage.storage");

  /// @notice get the storage for the diamond factory
  /// @return ds DiamondFactoryStorage the storage for the diamond factory
  function diamondFactoryStorage() internal pure returns (DiamondFactoryStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  /// @notice add a set of facets to the factory and associate with a string name
  /// @param self the storage for the diamond factory
  /// @param setName the name of the set of facets
  /// @param facets the facets to add
  function _addFacetSet(DiamondFactoryStorage storage self, string memory setName, IDiamondCut.FacetCut[] memory facets) internal {
    // add the facets to the diamond
    for (uint256 i = 0; i < facets.length; i++) {
      self.contractData.facetsToAdd[setName].push(facets[i]);
    }
  }

  /// @notice get all the facets for a particular set name
  /// @param self the storage for the diamond factory
  /// @param setName the name of the set of facets
  /// @return IDiamondCut.FacetCut[] the facets for the set name
  function _getFacets(DiamondFactoryStorage storage self, string memory setName) internal view returns (IDiamondCut.FacetCut[] memory) {
    return self.contractData.facetsToAdd[setName];
  }

  /// @notice set a facet for facet set name at a particular index
  /// @param self the storage for the diamond factory
  /// @param setName the name of the set of facets
  /// @param idx the index of the facet to set
  /// @param facet the facet to set
  function _setFacet(DiamondFactoryStorage storage self, string memory setName, uint256 idx, IDiamondCut.FacetCut memory facet) internal {
    self.contractData.facetsToAdd[setName][idx] = facet;        
  }

  /// @notice get an address for the given diamond
  /// @param factoryAddress the diamond factory
  /// @param symbol the symbol of the  diamond
  /// @param creationCode the creation code for the diamond
  function _getDiamondAddress(DiamondFactoryStorage storage, address factoryAddress, string memory symbol, bytes memory creationCode)
    internal
    view
    returns (address) {
    return Create2.computeAddress(
      keccak256(abi.encodePacked(factoryAddress, symbol)),
      keccak256(creationCode)
    );
  }

    /// @notice create a new diamond token with the given symbol
    /// @param self the storage for the diamond factory
    /// @param diamondAddress the diamond address
    /// @param diamondInit the diamond init data
    /// @param _calldata  the calldata for the diamond
    /// @param _creationCode the creation code for the diamond
    function create(
        DiamondFactoryStorage storage self,
        address diamondAddress,
        DiamondSettings memory params,
        address diamondInit,
        bytes calldata _calldata,
        bytes memory _creationCode,
        IDiamondCut.FacetCut[] memory facets
    ) internal returns (address payable _diamondAddress) {
        // use create2 to create the token
        _diamondAddress = payable(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(diamondAddress, params.symbol)),
                _creationCode
            )
        );
        require(_diamondAddress != address(0), "create_failed");
        
        // update storage with the new data
        self.contractData.diamondAddresses[params.symbol] = _diamondAddress;
        self.contractData.diamondSymbols.push(params.symbol);

        // initialize the diamond contract
        IDiamondElement(_diamondAddress).initialize(
            msg.sender,
            params,
            facets,
            diamondInit,
            _calldata
        );
    }

    /// @notice create a new diamond token with the given symbol
    /// @param self the storage for the diamond factory
    /// @param diamondAddress the diamond address
    /// @param diamondInit the diamond init data
    /// @param _calldata  the calldata for the diamond
    /// @param _creationCode the creation code for the diamond
    function createFromSet(
        DiamondFactoryStorage storage self,
        address diamondAddress,
        DiamondSettings memory params,
        address diamondInit,
        bytes calldata _calldata,
        bytes memory _creationCode,
        string memory facetSet
    ) internal returns (address payable _diamondAddress) {
        // use create2 to create the token
        _diamondAddress = payable(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(diamondAddress, params.symbol)),
                _creationCode
            )
        );
        require(_diamondAddress != address(0), "create_failed");
        
        // update storage with the new data
        self.contractData.diamondAddresses[params.symbol] = _diamondAddress;
        self.contractData.diamondSymbols.push(params.symbol);

        // initialize the diamond contract
        IDiamondElement(_diamondAddress).initialize(
            msg.sender,
            params,
            self.contractData.facetsToAdd[facetSet],
            diamondInit,
            _calldata
        );
    }

    /// @notice add an existing diamond to this factory
    /// @param self the storage for the diamond factory
    /// @param symbol the symbol of the diamond
    /// @param diamondAddress the address of the diamond
    function add(
        DiamondFactoryStorage storage self,
        string memory symbol,
        address payable diamondAddress
    ) internal {
        // update storage with the new data
        self.contractData.diamondAddresses[symbol] = diamondAddress;
        self.contractData.diamondSymbols.push(symbol);
    }

    /// @notice remove a diamond from this factory
    /// @param self the storage for the diamond factory
    /// @param symbol the symbol of the diamond
    function remove(
      DiamondFactoryStorage storage self,
      string memory symbol
    ) internal {
        self.contractData.diamondAddresses[symbol] = address(0);
        for(uint256 i = 0; i < self.contractData.diamondSymbols.length; i++) {
            if ( keccak256(bytes(self.contractData.diamondSymbols[i] ) ) == keccak256(bytes(symbol)) ) {
                self.contractData.diamondSymbols[i] = self.contractData.diamondSymbols[self.contractData.diamondSymbols.length - 1];
                self.contractData.diamondSymbols.pop();
                break;
            }
        }
    }
}