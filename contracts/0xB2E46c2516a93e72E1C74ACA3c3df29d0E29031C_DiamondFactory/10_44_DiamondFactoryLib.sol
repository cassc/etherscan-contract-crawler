//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../Diamond.sol";

import "../interfaces/IDiamondFactory.sol";
import "../interfaces/IEventReporter.sol";
import "../interfaces/IMetadata.sol";
import "../interfaces/IDiamondInit.sol";

import "../libraries/LibAppStorage.sol";


library DiamondFactoryLib {
    
    event DiamondCreated(
        address indexed factory,
        address indexed token,
        string symbol
    );

    /// @notice initiiate the factory
    function initialize(
        DiamondFactoryContract storage ds,
        DiamondFactoryInit memory initData
    ) internal {

        // set the wrapped token and event reporter and diamond init
        ds.wrappedToken_ = initData._wrappedToken;

        // add the facets to the diamond
        for (uint256 i = 0; i < initData.facetAddresses.length; i++) {
            ds.facetsToAdd.push(initData.facetAddresses[i]);
        }
    }

    /// @notice get the address of the token
    function getDiamondAddress(string memory symbol)
        internal
        view
        returns (address)
    {
        return
            Create2.computeAddress(
                keccak256(abi.encodePacked(address(this), symbol)),
                keccak256(type(Diamond).creationCode)
            );
    }

    /// @notice create a new diamond token with the given symbol 
    function create(
        DiamondFactoryContract storage self,
        BitGemSettings memory params,
        address diamondInit,
        bytes calldata _calldata
        )
        internal
        returns (address payable tokenAddress)
    {
        // get the factory storage context, error if token already exists
        require(self.tokenAddresses[params.symbol] == address(0), "Diamond already exists");

        // use create2 to create the token
        tokenAddress = payable(
            Create2.deploy(
                0,
                keccak256(abi.encodePacked(address(this), params.symbol)),
                type(Diamond).creationCode
            )
        );
        require(tokenAddress != address(0), "Create2: Failed on deploy");

        // initialize the diamond contract
        Diamond(tokenAddress).initialize(
            msg.sender, 
            params, 
            self.facetsToAdd, 
            diamondInit, 
            _calldata);

        // update storage with the new data
        self.tokenAddresses[params.symbol] = tokenAddress;
        self.tokenSymbols.push(params.symbol);
    }

    /// @notice check if the token exists
    function exists( DiamondFactoryContract storage ds, string memory symbol) public view returns (bool) {
        return ds.tokenAddresses[symbol] != address(0);
    }

    /// @notice get all the symbols from the factory
    function symbols( DiamondFactoryContract storage ds) public view returns (string[] memory) {
        return ds.tokenSymbols;
    }
}