// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./Diamond.sol";

import "./interfaces/IDiamondFactory.sol";
import "./interfaces/IEventReporter.sol";
import "./interfaces/IMetadata.sol";

import "./libraries/LibAppStorage.sol";
import "./libraries/DiamondFactoryLib.sol";
import "./libraries/EventReporterLib.sol";

contract DiamondFactory is Ownable, Initializable {

    using DiamondFactoryLib for DiamondFactoryContract;

    event DiamondCreated(
        address indexed factory,
        address indexed token,
        string symbol
    );

    /// @notice initiiate the factory
    function initialize(
        DiamondFactoryInit memory initData
    ) public initializer {

        // get the data storage structs
        DiamondFactoryContract storage ds = LibAppStorage
            .diamondStorage()
            .factory;

        address[] memory allowed = new address[](2);
        allowed[0] = msg.sender;
        allowed[1] = address(this);
        EventReporterLib.createEventReportingContract(allowed);

        // initialize the diamond factory
        ds.initialize(initData);
    }

    /// @notice get the address of the token
    function getDiamondAddress(string memory symbol)
        public
        view
        returns (address) {
            
        return DiamondFactoryLib.getDiamondAddress(symbol);
    }

    /// @notice get a reference to the global event reporter contract
    function eventReporter() external view returns (address){
        return EventReporterLib.getEventReportingContract();
    }

    /// @notice create a new diamond token with the given symbol 
    function create(
         BitGemSettings memory params,
        address diamondInit, 
        bytes calldata _calldata
        ) 
        public
        onlyOwner
        returns (address payable tokenAddress) {

        // get the data storage structs
        DiamondFactoryContract storage ds = LibAppStorage
            .diamondStorage()
            .factory;        
        tokenAddress = payable(ds.create(params, diamondInit, _calldata));

        // add the new diamond as an allowed reporter of the event dispatcher
        EventReportingContract(EventReporterLib.getEventReportingContract()).addAllowed(tokenAddress);

        // emit the event
        EventReporterLib.emitEvent(ApplicationEventStruct(
            0,
            "DiamondCreated", 
            abi.encode(address(this), tokenAddress, params.symbol)
            )
        );
    }

    /// @notice check if the token exists
    function exists(string memory symbol) public view returns (bool) {

        DiamondFactoryContract storage ds = LibAppStorage
            .diamondStorage()
            .factory;
        return ds.tokenAddresses[symbol] != address(0);
    }

    /// @notice get all the symbols from the factory
    function symbols() public view returns (string[] memory) {

        DiamondFactoryContract storage ds = LibAppStorage
            .diamondStorage()
            .factory;
        return ds.tokenSymbols;
    }
}