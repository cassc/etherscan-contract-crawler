// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../traitregistry/ECRegistryV3c.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../implementers/UTDigitalRedeemStorage.sol";
import "../implementers/UTDigitalRedeemController.sol";
import "../extras/recovery/BlackHolePrevention.sol";

interface IRandom {
    function setAuth(address, bool) external;
}

interface IDigitalRedeemVault {
    function notifyVault(address) external;
}

/**
* @dev This factory is used to create new traits (perks) in a community
*/
contract UTDigitalRFactory is Ownable, BlackHolePrevention {
    using Strings  for uint32; 

    uint256     public constant     version              = 20230604;

    uint8       public constant     TRAIT_TYPE           = 6;            // Digital redeemables
    address     public constant     GALAXIS_REGISTRY     = 0x1e8150050A7a4715aad42b905C08df76883f396F;
    string      public constant     REGISTRY_KEY_FACTORY = "TRAIT_TYPE_6_FACTORY";
    bytes32     public constant     TRAIT_REGISTRY_ADMIN = keccak256("TRAIT_REGISTRY_ADMIN");

    struct inputTraitStruct {
        uint16  communityId;                    // Community ID
        uint16  start;                          // Validity start period of the trait
        uint16  end;                            // Validity start period of the trait
        bool    enabled;                        // Can be locked
        string  ipfsHash;                       // The desriptor file hash on IPFS
        string  name;                           // Name of the trait (perk)
        uint32  tokenNum;                       // The serial number of the token contract to use (under key TOKEN_xx where xx = tokenNum )
        uint8   maxTokensToRedeem;              // How many tokens can be claimed (in any chunks)
        address collectionToRedeemFrom;         // Token contract address (ERC721Enumerable) where the user gets a token from
                                                // If collectionToRedeemFrom == address(0) --> the user may pick the collection from the vault)
        uint8   redeemMode;                     // 0 - Random redeem from the vault (with VRF)
                                                // 1 - Nonrandom redeem from the vault (transfer first card from vault) (no VRF)
    }

    // Errors
    error UTDigitalRFactoryNotCurrent(address);
    error UTDigitalRFactoryInvalidCommunityId(uint16);
    error UTDigitalRFactoryUnauthorized(address);
    error UTDigitalRFactoryTraitRegistryNotInstalled(address);
    error UTDigitalRFactoryMaxTokensToRedeemShouldNotBe0();
    error UTDigitalRFactoryTokenNotInstalled();

    /**
     * @dev addTrait() is called from the UTC to create a new trait (perk) in a community for a specific token
     * note Tokens are marked in the Community registry with keys TOKEN_xx (where xx = 1,2,...)
     *      For each token the corresponding Trait Registry can be found under keys TRAIT_REGISTRY_xx
     *      In the input structure, tokenNum designates which community token - and thus which corresponding 
     *      Trait registry should be used.
     *      This contract must have COMMUNITY_REGISTRY_ADMIN on RoleManagerInstance - so it can update keys in
     *      any Community registry
     *      It creates one storage contract per trait and one (singleton) logic controller for the trait type.
     *      It grants access to the controller in order to be able to write into the trait storage
     *      This contract must have admin right in RANDOMV2_SSP_TRAIT_DROPPER - so it can grant role
     *      any Community registry
     *      It validates that this is the current factory according to the keys in the Galaxis Registry
     */
    function addTrait(
        inputTraitStruct calldata _inputTrait
    ) external returns (uint16 traitId) {

        // Get Galaxis registry
        IRegistryConsumer GalaxisRegistry = IRegistryConsumer(GALAXIS_REGISTRY);

        // Validate if this contract is the current version to be used. Else fail
        if(GalaxisRegistry.getRegistryAddress(REGISTRY_KEY_FACTORY) != address(this)) {
            revert UTDigitalRFactoryNotCurrent(address(this));
        }

        // Get the community_list contract
        CommunityList COMMUNITY_LIST = CommunityList(GalaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));
        // Get the community data
        (,address crAddr,) = COMMUNITY_LIST.communities(_inputTrait.communityId);

        // Check if community registry is valid
        if(crAddr == address(0)) {
            revert UTDigitalRFactoryInvalidCommunityId(_inputTrait.communityId);
        }

        // Get community registry
        CommunityRegistry thisCommunityRegistry = CommunityRegistry(crAddr);
        
        // Get trait registry
        ECRegistryV3c traitRegistry = ECRegistryV3c(thisCommunityRegistry.getRegistryAddress(string(abi.encodePacked("TRAIT_REGISTRY_", _inputTrait.tokenNum.toString()))));

        // Trait registry must exist!
        if(address(traitRegistry) == address(0)) {
            revert UTDigitalRFactoryTraitRegistryNotInstalled(address(traitRegistry));
        }

        // Check if caller is TRAIT_REGISTRY_ADMIN
        if(!traitRegistry.isAllowed(TRAIT_REGISTRY_ADMIN, msg.sender)) {
            revert UTDigitalRFactoryUnauthorized(msg.sender);
        }

        // maxTokensToRedeem should be > 0
        if(_inputTrait.maxTokensToRedeem == 0) {
            revert UTDigitalRFactoryMaxTokensToRedeemShouldNotBe0();
        }

        // Get next available ID for the new trait
        traitId = traitRegistry.traitCount();

        // Get the NFT address
        address ERC721 = thisCommunityRegistry.getRegistryAddress(string(abi.encodePacked("TOKEN_", _inputTrait.tokenNum.toString())));

        // NFT must exist!
        if(ERC721 == address(0)) {
            revert UTDigitalRFactoryTokenNotInstalled();
        }

        // Add role for this factory to write into TraitRegistry
        if(!thisCommunityRegistry.hasRole(TRAIT_REGISTRY_ADMIN, address(this))) {
            thisCommunityRegistry.grantRole(TRAIT_REGISTRY_ADMIN, address(this));
        }

        // Deploy _controller_ ONLY if not yet deployed for this TRAIT_TYPE
        UTDigitalRedeemController controllerCtr;
        address controllerAddr = traitRegistry.getDefaultTraitControllerByType(TRAIT_TYPE);
        if(controllerAddr == address(0)) {

            // Deploy _controller_
            controllerCtr = new UTDigitalRedeemController(ERC721, address(traitRegistry), 0, 0, address(thisCommunityRegistry));

            // Set this controller as default for this TRAIT_TYPE
            traitRegistry.setDefaultTraitControllerType(address(controllerCtr), TRAIT_TYPE);
        } else {
            controllerCtr = UTDigitalRedeemController(controllerAddr);
        }

        // Add the current reward token into the vault
        controllerCtr.notifyVault(_inputTrait.collectionToRedeemFrom);

        // Deploy _storage_
        UTDigitalRedeemStorage storageCtr = new UTDigitalRedeemStorage(address(traitRegistry), traitId, _inputTrait.maxTokensToRedeem, _inputTrait.redeemMode, _inputTrait.collectionToRedeemFrom);

        // Add the trait to the trait registry
        ECRegistryV3c.traitStruct[] memory traits = new ECRegistryV3c.traitStruct[](1);
        traits[0] = ECRegistryV3c.traitStruct(traitId, TRAIT_TYPE, _inputTrait.start, _inputTrait.end, _inputTrait.enabled, address(storageCtr), _inputTrait.ipfsHash, _inputTrait.name);
        traitRegistry.addTrait(traits);

        // Grant access to the Controller for this trait
        traitRegistry.setTraitControllerAccess(address(controllerCtr), traitId, true);

        // Grant access to the Controller for using the VRF (random) contract
        IRandom random = IRandom(GalaxisRegistry.getRegistryAddress("RANDOMV2_SSP_TRAIT_DROPPER"));
        random.setAuth(address(controllerCtr), true);
    }
}