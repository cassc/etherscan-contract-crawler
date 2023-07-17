// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../../@galaxis/registries/contracts/TheProxy.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../traitregistry/ECRegistryV3c.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TraitRegistryFactory is Ownable, BlackHolePrevention {
    using Strings  for uint32; 

    uint256     public constant     version                  = 20230619;

    address     public constant     GALAXIS_REGISTRY         = 0x1e8150050A7a4715aad42b905C08df76883f396F;
    string      public constant     REGISTRY_KEY_FACTORY     = "TRAIT_REGISTRY_FACTORY";
    bytes32     public constant     COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");

    // Errors
    error TraitRegistryFactoryNotCurrent(address);
    error TraitRegistryFactoryInvalidCommunityId(uint32);
    error TraitRegistryFactoryUnauthorized();
    error TraitRegistryFactoryInvalidTokenNumber(uint32);

    event TraitRegistryAdded(uint32 _communityId, address _traitRegistry, uint32 _tokenNum);

    /**
     * @dev deploy() is called from the UTC to create a new Trait Registry in a community for a specific token
     * note Tokens are marked in the Community registry with keys TOKEN_xx (where xx = 1,2,...)
     *      For each token the corresponding Trait Registry can be found under keys TRAIT_REGISTRY_xx
     *      This contract must have COMMUNITY_REGISTRY_ADMIN on RoleManagerInstance - so it can update keys in
     *      any Community registry
     *      The caller must be the community owner, DEFAULT_ADMIN or COMMUNITY_REGISTRY_ADMIN on Community Rewgistry
     *      It validates that this is the current factory according to the keys in the Galaxis Registry
     * @param _communityId - the community Id where the registry will be created.
     * @param _tokenNum - designates for which community token the Trait Registry should be created
     */
    function deploy(
        uint32 _communityId,
        uint32 _tokenNum
    ) external returns (address) {

        // Get Galaxis registry
        IRegistryConsumer GalaxisRegistry = IRegistryConsumer(GALAXIS_REGISTRY);

        // Validate if this contract is the current version to be used. Else fail
        if(GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_FACTORY) != address(this)) {
            revert TraitRegistryFactoryNotCurrent(address(this));
        }

        // Get the community_list contract
        CommunityList COMMUNITY_LIST = CommunityList(GalaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));

        // Get the community data
        (,address crAddr,) = COMMUNITY_LIST.communities(_communityId);

        if(crAddr == address(0)) {
            revert TraitRegistryFactoryInvalidCommunityId(_communityId);
        }

        // Get community registry
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddr);

        // Check if caller is the community owner
        if(!thisCommunityRegistry.isUserCommunityAdmin(COMMUNITY_REGISTRY_ADMIN, msg.sender)) {
            revert TraitRegistryFactoryUnauthorized();
        }

        // Check if the token contract we link this trait registry is valid
        if(thisCommunityRegistry.getRegistryAddress(string(abi.encodePacked("TOKEN_", _tokenNum.toString()))) == address(0)) {
            revert TraitRegistryFactoryInvalidTokenNumber(_tokenNum);
        }

        // Launch new registry contract via proxy
        address LOOKUPAddr = GalaxisRegistry.getRegistryAddress("LOOKUP");
        TheProxy trait_proxy = new TheProxy("GOLDEN_TRAIT_REGISTRY", LOOKUPAddr);   // All golden contracts should start with `GOLDEN_`
        ECRegistryV3c traitRegistry = ECRegistryV3c(address(trait_proxy));
        traitRegistry.init(_communityId, msg.sender);                // To initialise owner

        // Write trait registry address to community registry
        thisCommunityRegistry.setRegistryAddress(
            string(abi.encodePacked("TRAIT_REGISTRY_", _tokenNum.toString())),
            address(traitRegistry)
        );

        emit TraitRegistryAdded(_communityId, address(traitRegistry), _tokenNum);

        return address(traitRegistry);
    }
}