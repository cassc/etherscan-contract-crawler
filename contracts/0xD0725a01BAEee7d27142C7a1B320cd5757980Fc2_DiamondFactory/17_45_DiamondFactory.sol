// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./Diamond.sol";

import "./libraries/DiamondLib.sol";
import "./libraries/DiamondFactoryLib.sol";

import "./interfaces/IDiamondFactory.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IControllable.sol";

import "./utilities/Controllable.sol";

/// @title Diamond Factory
/// @notice This contract is used to create new Diamond contracts.
contract DiamondFactory is Initializable, Controllable {

    using DiamondFactoryLib for DiamondFactoryStorage;

    event DiamondCreated(
        address indexed factory,
        string indexed symbol,
        DiamondSettings settings
    );

    event DiamondAdd(
        address indexed factory,
        string indexed symbol,
        address indexed diamond
    );

    event DiamondRemoved(
        address indexed factory,
        string indexed symbol,
        address indexed diamond
    );

    constructor() {
        _addController(msg.sender);
    }

    /// @notice initiiate the factory
    /// @param initData the address of the diamond init contract
    function initialize(DiamondFactoryInit memory initData) public initializer {
        DiamondFactoryLib.diamondFactoryStorage()._addFacetSet(
            initData.setName,
            initData.facetAddresses
        );
        DiamondFactoryLib
            .diamondFactoryStorage()
            .contractData
            .defaultFacetSet = initData.setName;
    }

    /// @notice get the facets for the diamond
    function getFacets(string memory facetSet)
        external
        view
        returns (IDiamondCut.FacetCut[] memory)
    {
        return
            DiamondFactoryLib.diamondFactoryStorage().contractData.facetsToAdd[
                facetSet
            ];
    }

    /// @notice set a template facet on this factory
    /// @param idx the index of the facet to set
    /// @param facetAddress the facet to set
    function setFacet(
        string memory facetSet,
        uint256 idx,
        IDiamondCut.FacetCut memory facetAddress
    ) external onlyController {
        DiamondFactoryLib.diamondFactoryStorage()._setFacet(
            facetSet,
            idx,
            facetAddress
        );
    }

    /// @notice set a number of template facets on this factory
    /// @param facetSet the index of the facet to set
    /// @param facetAddress the facet to set
    function setFacets(
        string memory facetSet,
        IDiamondCut.FacetCut[] memory facetAddress
    ) external onlyController {
        DiamondFactoryLib.diamondFactoryStorage()._addFacetSet(
            facetSet,
            facetAddress
        );
    }

    /// @notice remote a facet set from the factory
    /// @param facetSet the facet set to remove
    function removeFacets(string memory facetSet) external onlyController {
        delete DiamondFactoryLib
            .diamondFactoryStorage()
            .contractData
            .facetsToAdd[facetSet];
    }

    /// @notice get the address of the diamond
    /// @param symbol the symbol of the diamond
    /// @return the address of the diamond
    function getDiamondAddress(string memory symbol)
        public
        view
        returns (address)
    {
        return
            DiamondFactoryLib.diamondFactoryStorage()._getDiamondAddress(
                address(this),
                symbol,
                type(Diamond).creationCode
            );
    }

    /// @notice create a new diamond token with the given symbol
    /// @param params diamond init parameters
    /// @param diamondInit the diamond init contract
    /// @param _calldata the calldata to pass to the diamond init contract
    function create(
        DiamondSettings memory params,
        address diamondInit,
        bytes calldata _calldata,
        IDiamondCut.FacetCut[] memory facets
    ) public onlyController returns (address payable diamondAddress) {
        // get the factory storage context, error if token already exists
        require(
            DiamondFactoryLib
                .diamondFactoryStorage()
                .contractData
                .diamondAddresses[params.symbol] == address(0),
            "exists"
        );
        diamondAddress = DiamondFactoryLib.diamondFactoryStorage().create(
            address(this),
            params,
            diamondInit,
            _calldata,
            type(Diamond).creationCode,
            facets
        );
        emit DiamondCreated(address(this), params.symbol, params);
    }

    /// @notice create a new diamond token with the given symbol
    /// @param params diamond init parameters
    /// @param diamondInit the diamond init contract
    /// @param _calldata the calldata to pass to the diamond init contract
    function createFromSet(
        DiamondSettings memory params,
        address diamondInit,
        bytes calldata _calldata,
        string memory facets
    ) public onlyController returns (address payable diamondAddress) {
        // get the factory storage context, error if token already exists
        require(
            DiamondFactoryLib
                .diamondFactoryStorage()
                .contractData
                .diamondAddresses[params.symbol] == address(0),
            "exists"
        );
        diamondAddress = DiamondFactoryLib.diamondFactoryStorage().createFromSet(
            address(this),
            params,
            diamondInit,
            _calldata,
            type(Diamond).creationCode,
            facets
        );
        emit DiamondCreated(address(this), params.symbol, params);
    }

    /// @notice add an existing diamong to the factory. it will then be returned by the getDiamondAddress function
    /// @param symbol the symbol of the diamond
    /// @param diamondAddress the address of the diamond
    function add(string memory symbol, address payable diamondAddress)
        public
        onlyController
    {
        // get the factory storage context, error if token already exists
        require(
            DiamondFactoryLib
                .diamondFactoryStorage()
                .contractData
                .diamondAddresses[symbol] == address(0),
            "exists"
        );
        DiamondFactoryLib.diamondFactoryStorage().add(symbol, diamondAddress);
        emit DiamondAdd(address(this), symbol, diamondAddress);
    }

    /// @notice remove a diamond from this factory
    /// @param symbol the symbol of the diamond to remove
    function remove(string memory symbol) public onlyController {
        DiamondFactoryLib.diamondFactoryStorage().remove(symbol);
        emit DiamondRemoved(
            address(this),
            symbol,
            DiamondFactoryLib
                .diamondFactoryStorage()
                .contractData
                .diamondAddresses[symbol]
        );
    }

    /// @notice check if the token exists
    /// @param symbol the symbol of the diamond to check
    function exists(string memory symbol) public view returns (bool) {
        return
            DiamondFactoryLib
                .diamondFactoryStorage()
                .contractData
                .diamondAddresses[symbol] != address(0);
    }

    /// @notice get all the symbols from the factory
    /// @return the symbols
    function symbols() public view returns (string[] memory) {
        return
            DiamondFactoryLib
                .diamondFactoryStorage()
                .contractData
                .diamondSymbols;
    }
}