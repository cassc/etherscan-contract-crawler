// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "releasemanager/contracts/CostManagerFactoryHelper.sol";
import "releasemanager/contracts/ReleaseManagerHelper.sol";

import "./INFTInstanceContract.sol";
import "./NFTState.sol";
import "./NFTView.sol";


contract NFTFactory is Ownable, CostManagerFactoryHelper, ReleaseManagerHelper {
    using Clones for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    address public implementation;
    mapping(bytes32 => address) public getInstance; // keccak256("name", "symbol") => instance address
    mapping(address => InstanceInfo) private _instanceInfos;
    address[] public instances;
    EnumerableSet.AddressSet private _renouncedOverrideCostManager;
       
    struct InstanceInfo {
        string name;
        string symbol;
        address creator;
    }
    
    event InstanceCreated(string name, string symbol, address instance, uint256 length);
    
    address public implementationNFTView;
    address public implementationNFTState;

    constructor (
        address instance, 
        address implState, 
        address implView, 
        address costManager_
    ) CostManagerFactoryHelper(costManager_) {
        implementation = instance;
        costManager = costManager_;

        implementationNFTState = implState;
        implementationNFTView = implView;
    }

    /**
    * @dev returns the count of instances
    */
    function instancesCount() external view returns (uint256) {
        return instances.length;
    }
    
    /**
    * @dev produces new instance with defined name and symbol
    * @param name name of new token
    * @param symbol symbol of new token
    * @param contractURI contract URI
    * @return instance address of new contract
    */
    function produce(
        string memory name,
        string memory symbol,
        string memory contractURI
    ) 
        public 
        returns (address instance) 
    {
        return _produce(
            name,
            symbol,
            contractURI,
            "",
            ""
        );
    }

    /**
    * @dev produces new instance with defined name and symbol
    * @param name name of new token
    * @param symbol symbol of new token
    * @param contractURI contract URI
    * @param baseURI base URI
    * @param suffixURI suffix URI
    * @return instance address of new contract
    */
    function produce(
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory baseURI,
        string memory suffixURI
    ) 
        public 
        returns (address instance) 
    {
        return _produce(
            name,
            symbol,
            contractURI,
            baseURI,
            suffixURI
        );
    }

    function _produce(
        string memory name,
        string memory symbol,
        string memory contractURI,
        string memory baseURI,
        string memory suffixURI

    ) 
        internal 
        returns (address instance) 
    {
        _createInstanceValidate(name, symbol);
        instance = _createInstance(name, symbol);
        require(instance != address(0), "StakingFactory: INSTANCE_CREATION_FAILED");
        address ms = _msgSender();
        INFTInstanceContract(instance).initialize(
            implementationNFTState,
            implementationNFTView,
            name, 
            symbol, 
            contractURI, 
            baseURI,
            suffixURI,
            costManager, 
            ms
        );
        Ownable(instance).transferOwnership(ms);
        
        // register instance in release manager
        registerInstance(instance);
    }

    
     /**
    * @dev returns instance info
    * @param instanceId instance ID
    */
    function getInstanceInfo(
        uint256 instanceId
    ) public view returns(InstanceInfo memory) {
        
        address instance = instances[instanceId];
        return _instanceInfos[instance];
    }
    
    
    function _createInstanceValidate(
        string memory name,
        string memory symbol
    ) internal view {
        require((bytes(name)).length != 0, "Factory: EMPTY NAME");
        require((bytes(symbol)).length != 0, "Factory: EMPTY SYMBOL");
        address instance = getInstance[keccak256(abi.encodePacked(name, symbol))];
        require(instance == address(0), "Factory: ALREADY_EXISTS");
    }

    function _createInstance(
        string memory name,
        string memory symbol
    ) internal returns (address instance) {
        
        instance = address(implementation).clone();
        
        getInstance[keccak256(abi.encodePacked(name, symbol))] = instance;
        instances.push(instance);
        _instanceInfos[instance] = InstanceInfo(
            name,
            symbol,
            _msgSender()
        );
        emit InstanceCreated(name, symbol, instance, instances.length);
    }
        
}