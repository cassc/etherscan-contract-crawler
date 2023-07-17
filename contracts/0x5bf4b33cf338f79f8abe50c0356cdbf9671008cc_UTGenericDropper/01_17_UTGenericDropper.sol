//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../interfaces/IRandomNumberProvider.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../interfaces/IECRegistry.sol";
import "../interfaces/IGenericDroppableStorage.sol";

contract UTGenericDropper {
    using Strings  for uint32; 

    uint256                         public constant     version                      = 20230622;

    bytes32                         public constant     DEFAULT_ADMIN_ROLE           = 0x00;
    string                          public constant     REGISTRY_KEY_GENERIC_DROPPER = "UT_GENERIC_DROPPER";
    string                          public constant     REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV2_SSP_TRAIT_DROPPER";
    bytes32                         public constant     TRAIT_DROPPER                = keccak256("TRAIT_DROPPER");          // For the user to access requestRandomDrop() and finalizeRandomDrop()
    bytes32                         public constant     TRAIT_DROP_ADMIN             = keccak256("TRAIT_DROP_ADMIN");       // For a contract who have generic access to write to any traits (like this contract)

    uint32                          public              currentDropCount;
    IRegistryConsumer               public              GalaxisRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

    mapping(uint32 => dropStruct)   public              drops;
    mapping(uint256 => uint32)      public              requestToDropIndex;

    struct dropStruct {
        uint256                     requestId;
        uint32                      communityId;
        uint32                      registryNum;
        uint16                      traitId;
        address                     storageImplementer;
        uint256                     randomNumber;
        uint16                      rangeStart;
        uint16                      rangeEnd;
        uint16                      traitsToDrop;
        bool                        randomReceived;
        bool                        randomProcessed;
        mapping(uint16 => bool)     selectedIdxs;
    }

    struct dropStructReturn {
        uint32                      dropIndex;
        uint256                     requestId;
        uint32                      communityId;
        uint32                      registryNum;
        uint16                      traitId;
        address                     storageImplementer;
        uint256                     randomNumber;
        uint16                      rangeStart;
        uint16                      rangeEnd;
        uint16                      traitsToDrop;
        bool                        randomReceived;
        bool                        randomProcessed;
    }

    // Events
    event genericDropRequested(uint32 index);
    event genericDropProcess(uint32 index);
    event genericDropFinalized(uint32 index);

    /**
     * @dev Admin: drop traits to the selected interval
     * - TRAIT_DROPPER
     */
    function requestRandomDrop(uint32 _communityId, uint16 _traitId, uint32 _registryNum, uint16 _rangeStart, uint16 _rangeEnd, uint16 _traitsToDrop) external {

        // Validate if this contract is the current version to be used. Else fail
        address GenericDropperAddr = GalaxisRegistry.getRegistryAddress("UT_GENERIC_DROPPER");
        require(GenericDropperAddr == address(this), "UTGenericDropper: Not current GenericDropper");

        require(_rangeStart < _rangeEnd, "UTGenericDropper: Invalid range");
        require(_rangeEnd - _rangeStart + 1 >= _traitsToDrop, "UTGenericDropper: Trait count does not fit in range");
        (address crAddress, address ECrAddress) =_getRegistries(_communityId, _registryNum);
        require(CommunityRegistry(crAddress).isUserCommunityAdmin(DEFAULT_ADMIN_ROLE, msg.sender) || CommunityRegistry(crAddress).hasRole(TRAIT_DROPPER, msg.sender), "UTGenericDropper: Unauthorised");
        require(ECrAddress != address(0), "UTGenericDropper: Invalid registry to drop into");
        require(IECRegistry(ECrAddress).traitCount() > _traitId, "UTGenericDropper: invalid trait");
        IECRegistry.traitStruct memory traitData = IECRegistry(ECrAddress).getTrait(_traitId);
        require(traitData.traitType >= 3, "UTGenericDropper: not valid for badges");
        require(traitData.storageImplementer != address(0), "UTGenericDropper: no storage found for trait");

        dropStruct storage currentDrop = drops[++currentDropCount];
        currentDrop.communityId        = _communityId;
        currentDrop.traitId            = _traitId;
        currentDrop.registryNum        = _registryNum;
        currentDrop.storageImplementer = traitData.storageImplementer;
        currentDrop.rangeStart         = _rangeStart;
        currentDrop.rangeEnd           = _rangeEnd;
        currentDrop.traitsToDrop       = _traitsToDrop;
        currentDrop.requestId          = IRandomNumberProvider(GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
        requestToDropIndex[currentDrop.requestId] = currentDropCount;

        // Add role for the this dropper contract to be able to modify traits in TraitRegistry
        CommunityRegistry(crAddress).grantRole(TRAIT_DROP_ADMIN, address(this));

        emit genericDropRequested(currentDropCount);
    }

    /**
     * @dev Chainlink VRF callback
     */
    function process(uint256 _random, uint256 _requestId) external {

        require(msg.sender == GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT), "UTGenericDropper: process() Unauthorised caller");
        drops[requestToDropIndex[_requestId]].randomNumber = _random;
        drops[requestToDropIndex[_requestId]].randomReceived = true;
        emit genericDropProcess(requestToDropIndex[_requestId]);
    }

    /**
     * @dev Process the random number and distribute trait to tokens
     * - TRAIT_DROPPER
     */
    function finalizeRandomDrop(uint32 _dropIndex) public {         // onlyAllowed(_communityId, TRAIT_DROPPER) {
        dropStruct storage drop = drops[_dropIndex];
        require(drop.randomReceived, "UTGenericDropper: random not received");
        require(!drop.randomProcessed, "UTGenericDropper: drop already processed");
        (address crAddress, address ECrAddress) =_getRegistries(drop.communityId, drop.registryNum);
        require(CommunityRegistry(crAddress).isUserCommunityAdmin(DEFAULT_ADMIN_ROLE, msg.sender) || CommunityRegistry(crAddress).hasRole(TRAIT_DROPPER, msg.sender), "UTGenericDropper: Unauthorised");
        require(ECrAddress != address(0), "UTGenericDropper: Invalid registry to drop into");
        require(IECRegistry(ECrAddress).traitCount() > drop.traitId, "UTGenericDropper: invalid trait");
        IECRegistry.traitStruct memory traitData = IECRegistry(ECrAddress).getTrait(drop.traitId);
        require(traitData.traitType >= 3, "UTGenericDropper: not valid for badges");
        require(traitData.storageImplementer != address(0), "UTGenericDropper: no storage found for trait");

        uint16 rangeStart = drop.rangeStart;
        uint16 rangeEnd = drop.rangeEnd;
        uint16 range = rangeEnd - rangeStart + 1;
        uint16 traitsToDrop = drop.traitsToDrop;

        // Optimization: different routes based on estimation how saturated the drop interval would be
        if (traitsToDrop <= range / 2) {
            _drop(rangeStart, rangeEnd, traitData.storageImplementer, traitsToDrop, drop.randomNumber);
        } else {
            traitsToDrop = range - traitsToDrop;
            _inverseDrop(_dropIndex, rangeStart, rangeEnd, traitData.storageImplementer, traitsToDrop, drop.randomNumber);
        }

        drop.randomProcessed = true;
        emit genericDropFinalized(_dropIndex);
    }

    /**
     * @dev Return all open drops for the community
     */
    function getAtiveDrops(uint32 _communityId) public view returns (dropStructReturn[] memory)
    {
        uint16 retCount;

        // Count return length
        for(uint16 i = 1; i <= currentDropCount; i++) {       
            if (drops[i].communityId == _communityId && !drops[i].randomProcessed) {
                retCount++;
            }
        }

        dropStructReturn[] memory retval = new dropStructReturn[](retCount);
        uint16 pos;

        for(uint16 i = 1; i <= currentDropCount; i++) {       
            if (drops[i].communityId == _communityId && !drops[i].randomProcessed) {
                retval[pos].dropIndex = i;
                retval[pos].requestId = drops[i].requestId;
                retval[pos].communityId = drops[i].communityId;
                retval[pos].registryNum = drops[i].registryNum;
                retval[pos].traitId = drops[i].traitId;
                retval[pos].storageImplementer = drops[i].storageImplementer;
                retval[pos].randomNumber = drops[i].randomNumber;
                retval[pos].rangeStart = drops[i].rangeStart;
                retval[pos].rangeEnd = drops[i].rangeEnd;
                retval[pos].traitsToDrop = drops[i].traitsToDrop;
                retval[pos].randomReceived = drops[i].randomReceived;
                retval[pos].randomProcessed = drops[i].randomProcessed;
                pos++;
            }
        }
        return retval;
    }

    /**
     * @dev Drop traits randomly (optimal for trait amounts less then half of the range)
     */
    function _drop(uint16 _rangeStart, uint16 _rangeEnd, address storageImplementer, uint16 _traitsToDrop, uint256 _randomNumber) internal {

        uint16  offset;
        uint16  range = _rangeEnd - _rangeStart + 1;
        uint256 initRandom = _randomNumber;
        uint256 random = initRandom;
        uint16 dropCount;
        while (dropCount < _traitsToDrop) {
            if (random > range) {
                offset = 0;
                // while (offset < range && !IECRegistry(_ECrAddress).setTrait(_traitId, uint16((random + offset) % range + _rangeStart), true)) {
                // function addTraitToToken(uint16 _tokenId) external returns(bool wasSet);
                while (offset < range && !IGenericDroppableStorage(storageImplementer).addTraitToToken(uint16((random + offset) % range + _rangeStart))) {
                    offset++;
                }
                require(offset < range, "UTGenericDropper: Range full");
                dropCount++;
                random = random >> 1;
            } else {
                initRandom = uint256(keccak256(abi.encode(initRandom)));
                random = initRandom;
            }
        }
    }

    /**
     * @dev Drop traits randomly (optimal for trait amounts more then half of the range)
     */
    function _inverseDrop(uint32 _dropIndex, uint16 _rangeStart, uint16 _rangeEnd, address storageImplementer, uint16 _traitsToDrop, uint256 _randomNumber) internal {
        uint16 offset;

        dropStruct storage drop = drops[_dropIndex];

        uint16 range = _rangeEnd - _rangeStart + 1;
        uint16[] memory selectedTokens = new uint16[](range - _traitsToDrop);
        uint256 initRandom = _randomNumber;
        uint256 random = initRandom;

        uint16 dropCount;
        while (dropCount < _traitsToDrop) {
            if (random > range) {
                offset = 0;
                // while (offset < range && (drop.selectedIdxs[uint16((random + offset) % range + _rangeStart)] || IECRegistry(_ECrAddress).hasTrait(_traitId, uint16((random + offset) % range + _rangeStart)))) {
                //     offset++;
                // }
                while(true) {
                    uint16 pos = uint16((random + offset) % range + _rangeStart);
                    if (offset < range && (drop.selectedIdxs[pos] || IGenericDroppableStorage(storageImplementer).hasTrait(pos))) {
                        offset++;
                    } else {
                        break;
                    }
                }
                require(offset < range, "UTGenericDropper: Range full");
                drop.selectedIdxs[uint16((random + offset) % range + _rangeStart)] = true;

                dropCount++;
                random = random >> 1;
            } else {
                initRandom = uint256(keccak256(abi.encode(initRandom)));
                random = initRandom;
            }           
        }

        // Book inverse results into trait registry
        uint16 j;
        for (uint16 i = _rangeStart; i <= _rangeEnd; i++) {
            if (!drop.selectedIdxs[i]) {
                selectedTokens[j++] = i;
            }
        }
        dropCount = IGenericDroppableStorage(storageImplementer).addTraitOnMultiple(selectedTokens);

        require(dropCount + _traitsToDrop == range, "UTGenericDropper: Range full");
    }

    /**
     * @dev Read community registry and ECRegistry addresses
     */
    function _getRegistries(uint32 _communityId, uint32 _registryNum) internal view returns (address crAddress, address ECrAddress) {

        CommunityList COMMUNITY_LIST = CommunityList(GalaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));
        (,crAddress,) = COMMUNITY_LIST.communities(_communityId);
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddress);

        ECrAddress = thisCommunityRegistry.getRegistryAddress(
            string(abi.encodePacked("TRAIT_REGISTRY_",
            _registryNum.toString())
        ));
    }

}