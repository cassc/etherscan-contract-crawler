//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../interfaces/IRegistryConsumer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "hardhat/console.sol";

abstract contract ProxyProtection {
    address                                 placeholder1;                // Allocate space for the proxy
    bool                                    placeholder2;                // Allocate space for the proxy
}

contract ECRegistryV3c is ProxyProtection, Ownable {

    uint256                 public constant version              = 20230625;

    bytes32                 public constant TRAIT_REGISTRY_ADMIN = keccak256("TRAIT_REGISTRY_ADMIN");
    bytes32                 public constant TRAIT_DROP_ADMIN     = keccak256("TRAIT_DROP_ADMIN");

    IRegistryConsumer       public          GalaxisRegistry;
    CommunityRegistry       public          myCommunityRegistry;
    bool                                    initialised;

    struct traitStruct {
        uint16  id;
        uint8   traitType;              // 0 normal (1bit), 1 range, 2 inverted range, >=3 with storageImplementer
        uint16  start;                  // Range start for type 1/2 traits               
        uint16  end;                    // Range end for type 1/2 traits               
        bool    enabled;                // Frontend is responsible to hide disabled traits
        address storageImplementer;     // address of the smart contract that will implement the storage for the trait
        string  ipfsHash;               // IPFS address to store trait data (icon, etc.)
        string  name;
    }

    uint16 public traitCount;
    mapping(uint16 => traitStruct) public traits;

    // token data
    mapping(uint16 => mapping(uint16 => uint8) ) public tokenData;

    // trait controller access designates sub contracts that can affect 1 or more traits
    mapping(uint16 => address ) public traitControllerById;
    mapping(address => uint16 ) public traitControllerByAddress;
    uint16 public traitControllerCount = 0;
    mapping(address => mapping(uint8 => uint8) ) public traitControllerAccess;
    mapping( uint8 => address ) public defaultTraitControllerAddressByType;

    /*
    *   Events
    */
    event traitControllerEvent(address _address);

    // Traits master data change
    event newTraitMasterEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);
    event updateTraitMasterEvent(uint16 indexed _id, string _name, address _address, uint8 _traitType, uint16 _start, uint16 _end);
    // Tokens
    event updateTraitDataEvent(uint16 indexed _id);
    event tokenTraitChangeEvent(uint16 indexed _traitId, uint16 indexed _tokenId, bool mode);


    constructor () {
        initialised = true;                 // GOLDEN protection
    }

    function init(uint32  _communityId, address _owner) external {
        _init(_communityId, _owner);
    }

    function _init(uint32  _communityId, address _owner) internal virtual {
        require(!initialised,"TraitRegistry: Already initialised");
        initialised = true;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        // Get Galaxis registry
        if(chainId == 1 || chainId == 5 || chainId == 137 || chainId == 80001 || chainId == 1337 || chainId == 31337 || chainId == 80001) {
            GalaxisRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
        } else {
            require(false, "TraitRegistry: invalid chainId");
        }

        // Needed to handle owner behind proxy
        _transferOwnership(_owner);

        // Get the community_list contract
        CommunityList COMMUNITY_LIST = CommunityList(GalaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));
        // Get the community data
        (,address crAddr,) = COMMUNITY_LIST.communities(_communityId);
        myCommunityRegistry = CommunityRegistry(crAddr);

        // Only the GOLDEN version can exist without valid community ID
        address GoldenECRegistryAddr = GalaxisRegistry.getRegistryAddress("GOLDEN_TRAIT_REGISTRY");
        if( GoldenECRegistryAddr != address(this) ) {
            require(crAddr != address(0), "TraitRegistry: Invalid community ID");
        }
    }

    function getTrait(uint16 id) public view returns (traitStruct memory)
    {
        return traits[id];
    }

    function getTraits() public view returns (traitStruct[] memory)
    {
        traitStruct[] memory retval = new traitStruct[](traitCount);
        for(uint16 i = 0; i < traitCount; i++) {
            retval[i] = traits[i];
        }
        return retval;
    }

    function addTrait(
        traitStruct[] calldata _newTraits
    ) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {

        for (uint8 i = 0; i < _newTraits.length; i++) {

            uint16 newTraitId = traitCount++;
            traitStruct storage newT = traits[newTraitId];
            newT.id =           newTraitId;
            newT.name =         _newTraits[i].name;
            newT.traitType =    _newTraits[i].traitType;
            newT.start =        _newTraits[i].start;
            newT.end =          _newTraits[i].end;
            newT.enabled =      _newTraits[i].enabled;
            newT.ipfsHash =    _newTraits[i].ipfsHash;
            newT.storageImplementer = _newTraits[i].storageImplementer;

            emit newTraitMasterEvent(newTraitId, newT.name, newT.storageImplementer, newT.traitType, newT.start, newT.end );
        }
    }

    function updateTrait(
        uint16 _index,
        string memory _name,
        address _storageImplementer,
        uint8   _traitType,
        uint16  _start,
        uint16  _end,
        bool    _enabled,
        string memory _ipfsHash
    ) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        traits[_index].name = _name;
        traits[_index].storageImplementer = _storageImplementer;
        traits[_index].ipfsHash = _ipfsHash;
        traits[_index].enabled = _enabled;
        traits[_index].traitType = _traitType;
        traits[_index].start = _start;
        traits[_index].end = _end;

        emit updateTraitMasterEvent(traits[_index].id, _name, _storageImplementer, _traitType, _start, _end);
    }

    function setTraitUnchecked(uint16 traitID, uint16 tokenId, bool _value) external onlyTraitController(traitID) {
        _setTraitUnchecked(traitID, tokenId, _value);
    }

    function setTrait(uint16 traitID, uint16 tokenId, bool _value) external onlyTraitController(traitID) returns(bool) {
        return _setTrait(traitID, tokenId, _value);
    }

    function setTraitOnMultipleUnchecked(uint16 traitID, uint16[] memory tokenIds, bool[] memory _value) public onlyTraitController(traitID) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            _setTraitUnchecked(traitID, tokenIds[i], _value[i]);
        }
    }

    function setTraitOnMultiple(uint16 traitID, uint16[] memory tokenIds, bool _value) public onlyTraitController(traitID) returns(uint16 changes) {
        for (uint16 i = 0; i < tokenIds.length; i++) {
            if(_setTrait(traitID, tokenIds[i], _value)) {
                changes++;
            }
        }
    }

    function _setTraitUnchecked(uint16 traitID, uint16 tokenId, bool _value) internal {
        bool emitvalue = _value;
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        if(traits[traitID].traitType == 1 || traits[traitID].traitType == 2) {
            _value = !_value; 
        }
        if(_value) {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] | 2**bitPos);
        } else {
            tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] & ~(2**bitPos));
        }
        emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
    }

    // This will only emit event if there was actually a state change!
    // Returns: wasSet - was there any state change
    // Reason: this is being called many times from the various random trait dropper contracts
    function _setTrait(uint16 traitID, uint16 tokenId, bool _value) internal returns(bool wasSet) {
        bool emitvalue = _value;
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        if(traits[traitID].traitType == 1 || traits[traitID].traitType == 2) {
            _value = !_value; 
        }
        if(_value) {
            wasSet = uint8(tokenData[traitID][byteNum] & 2**bitPos) == 0;
            if (wasSet) {
                tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] | 2**bitPos);
                emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
            }
        } else {
            wasSet = uint8(tokenData[traitID][byteNum] & 2**bitPos) != 0;
            if (wasSet) {
                tokenData[traitID][byteNum] = uint8(tokenData[traitID][byteNum] & ~(2**bitPos));
                emit tokenTraitChangeEvent(traitID, tokenId, emitvalue);
            }
        }
    }

    // set trait data
    function setData(uint16 traitId, uint16[] memory _ids, uint8[] memory _data) public onlyTraitController(traitId) {
        for (uint16 i = 0; i < _data.length; i++) {
            tokenData[traitId][_ids[i]] = _data[i];
        }
        emit updateTraitDataEvent(traitId);
    }

    /*
    *   View Methods
    */

    /*
    * _perPage = 1250 in order to load 10000 tokens ( 10000 / 8; starting from 0 )
    */
    function getData(uint16 traitId, uint8 _page, uint16 _perPage) public view returns (uint8[] memory) {
        uint16 i = _perPage * _page;
        uint16 max = i + (_perPage);
        uint16 j = 0;
        uint8[] memory retValues = new uint8[](max);
        while(i < max) {
            retValues[j] = tokenData[traitId][i];
            j++;
            i++;
        }
        return retValues;
    }

    function getTokenData(uint16 tokenId) public view returns (uint8[] memory) {
        uint8[] memory retValues = new uint8[](getByteCountToStoreTraitData());
        // calculate positions for our token
        for(uint16 i = 0; i < traitCount; i++) {
            if(hasTrait(i, tokenId)) {
                uint8 byteNum = uint8(i / 8);
                retValues[byteNum] = uint8(retValues[byteNum] | 2 ** uint8(i - byteNum * 8));
            }
        }
        return retValues;
    }

    function getTraitControllerAccessData(address _addr) public view returns (uint8[] memory) {
        uint16 _returnCount = getByteCountToStoreTraitData();
        uint8[] memory retValues = new uint8[](_returnCount);
        for(uint8 i = 0; i < _returnCount; i++) {
            retValues[i] = traitControllerAccess[_addr][i];
        }
        return retValues;
    }

    function getByteCountToStoreTraitData() internal view returns (uint16) {
        uint16 _returnCount = traitCount/8;
        if(_returnCount * 8 < traitCount) {
            _returnCount++;
        }
        return _returnCount;
    }

    function getByteAndBit(uint16 _offset) public pure returns (uint16 _byte, uint8 _bit)
    {
        // find byte storig our bit
        _byte = uint16(_offset / 8);
        _bit = uint8(_offset - _byte * 8);
    }

    function getImplementer(uint16 traitID) public view returns (address implementer)
    {
        return traits[traitID].storageImplementer;
    }

    function hasTrait(uint16 traitID, uint16 tokenId) public view returns (bool result)
    {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(tokenId);
        bool _result = tokenData[traitID][byteNum] & (0x01 * 2**bitPos) != 0;
        bool _returnVal = (traits[traitID].traitType == 1) ? !_result: _result;
        if(traits[traitID].traitType == 2) {
            // range trait
            if(traits[traitID].start <= tokenId && tokenId <= traits[traitID].end) {
                _returnVal = !_result;
            }
        }
        return _returnVal;
    }

    /*
    *   Admin Stuff
    */

    function setDefaultTraitControllerType(address _addr, uint8 _traitType) external onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        defaultTraitControllerAddressByType[_traitType] = _addr;
        emit traitControllerEvent(_addr);
    }

    function getDefaultTraitControllerByType(uint8 _traitType) external view returns (address) {
        return defaultTraitControllerAddressByType[_traitType];
    }

    /*
    *   Trait Controllers
    */

    function indexTraitController(address _addr) internal {
        if(traitControllerByAddress[_addr] == 0) {
            uint16 controllerId = ++traitControllerCount;
            traitControllerByAddress[_addr] = controllerId;
            traitControllerById[controllerId] = _addr;
        }
    }

    function setTraitControllerAccessData(address _addr, uint8[] calldata _data) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        indexTraitController(_addr);
        for (uint8 i = 0; i < _data.length; i++) {
            traitControllerAccess[_addr][i] = _data[i];
        }
        emit traitControllerEvent(_addr);
    }

    function setTraitControllerAccess(address _addr, uint16 traitID, bool _value) public onlyAllowed(TRAIT_REGISTRY_ADMIN) {
        indexTraitController(_addr);
        if(_addr != address(0)) {
            (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
            if(_value) {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] | 2**bitPos);
            } else {
                traitControllerAccess[_addr][uint8(byteNum)] = uint8(traitControllerAccess[_addr][uint8(byteNum)] & ~(2**bitPos));
            }
        }
        emit traitControllerEvent(_addr);
    }
 
    function addressCanModifyTrait(address _addr, uint16 traitID) public view returns (bool result) {
        (uint16 byteNum, uint8 bitPos) = getByteAndBit(traitID);
        return hasRole(TRAIT_DROP_ADMIN, _addr) || _addr == owner() || traitControllerAccess[_addr][uint8(byteNum)] & (0x01 * 2**bitPos) != 0;
    }

    function addressCanModifyTraits(address _addr, uint16[] memory traitIDs) public view returns (bool result) {
        for(uint16 i = 0; i < traitIDs.length; i++) {
            if(!addressCanModifyTrait(_addr, traitIDs[i])) {
                return false;
            }
        }
        return true;
    }

    modifier onlyAllowed(bytes32 role) { 
        require(isAllowed(role, msg.sender), "TraitRegistry: Unauthorised");
        _;
    }

    function isAllowed(bytes32 role, address user) public view returns (bool) {
        return( user == owner() || hasRole(role, user));
    }

    function hasRole(bytes32 key, address user) public view returns (bool) {
        return myCommunityRegistry.hasRole(key, user);
    }

    modifier onlyTraitController(uint16 traitID) {
        require(
            addressCanModifyTrait(msg.sender, traitID),
            "TraitRegistry: Not Authorised"
        );
        _;
    }

}