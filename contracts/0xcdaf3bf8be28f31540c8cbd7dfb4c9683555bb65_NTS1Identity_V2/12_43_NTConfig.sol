// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";

interface ICitizen {
    function getGenderOfTokenId(uint256 citizenId) external view returns (bool);
}

enum NTComponent {
    S1_IDENTITY,
    S1_BOUGHT_IDENTITY,
    S1_VAULT,
    S1_ITEM,
    S1_LAND,
    S1_CITIZEN,
    S2_IDENTITY,
    S2_ITEM,
    S2_LAND,
    S2_CITIZEN,
    CHAMPION_CHIP
}

enum NTSecondaryComponent {
    S1_IDENTITY_RARE_MINT,
    S1_IDENTITY_HAND_MINT,
    S1_CITIZEN_FEMALE,
    S2_CITIZEN_FEMALE
}

enum NTSeason {
    INVALID,
    NO_SEASON,
    SEASON_1,
    SEASON_2
}

struct NTComponents {
    address s1Identity;
    address s1BoughtIdentity;
    address s1Vault;
    address s1Item;
    address s1Land;
    address s1Citizen;
    address s2Identity;
    address s2Item;
    address s2Land;
    address s2Citizen;
    address championChips;
}

struct NTSecondaryComponents {
    address s1IdentityRareMint;
    address s1IdentityHandMint;
    address s1CitizenFemale;
    address s2CitizenFemale;
}

struct FallbackThresholds {
    uint16 s1Identity;
    uint16 s1BoughtIdentity;
    uint16 s1Vault;
    uint16 s1Item;
    uint16 s1Land;
    uint16 s1Citizen;
    uint16 s2Identity;
    uint16 s2Item;
    uint16 s2Land;
    uint16 s2Citizen;
    uint16 championChips;
}

error ComponentNotFound();
error AddressNotConfigured();
error TokenNotFound();

contract NTConfig is OwnableUpgradeable {
    bool constant V1 = false;
    bool constant V2 = true;

    address public migrator;
    address public bytesContract;

    FallbackThresholds fallbackThresholds;

    // maps `isV2` => `addresses`
    mapping(bool => NTComponents) _components;

    NTComponents _metadataContracts;
    NTSecondaryComponents _secondaryMetadataContracts;

    function initialize() external initializer {
        __Ownable_init();
    } 

    function findMigrator(
        NTComponent component
    ) external view returns (address) {
        return findComponent(component, true);
    }

    /**
     * @notice Finds the `component` in the version defined by `isV2`.
     *
     * @param component `NTComponent`encoding of the component
     * @param isV2 defines whether V1 or V2 addresses are to be overridden
     */
    function findComponent(
        NTComponent component,
        bool isV2
    ) public view returns (address) {
        NTComponents storage components = _components[isV2];
        if (component == NTComponent.S1_IDENTITY) {
            return components.s1Identity;
        } else if (component == NTComponent.S1_BOUGHT_IDENTITY) {
            return components.s1BoughtIdentity;
        } else if (component == NTComponent.S1_VAULT) {
            return components.s1Vault;
        } else if (component == NTComponent.S1_ITEM) {
            return components.s1Item;
        } else if (component == NTComponent.S1_LAND) {
            return components.s1Land;
        } else if (component == NTComponent.S1_CITIZEN) {
            return components.s1Citizen;
        } else if (component == NTComponent.S2_IDENTITY) {
            return components.s2Identity;
        } else if (component == NTComponent.S2_ITEM) {
            return components.s2Item;
        } else if (component == NTComponent.S2_LAND) {
            return components.s2Land;
        } else if (component == NTComponent.S2_CITIZEN) {
            return components.s2Citizen;
        } else if (component == NTComponent.CHAMPION_CHIP) {
            return components.championChips;
        }
        revert ComponentNotFound();
    }

    /**
     * @notice Decodes the `components` into a `NTComponents` struct and
     * overrides all the fields relating to the provided version defined by
     * `isV2`.
     *
     * @param components encoded struct of addresses to each NT component
     * @param isV2 defines whether V1 or V2 addresses are to be overridden
     */
    function enlist(bytes calldata components, bool isV2) public onlyOwner {
        NTComponents memory components_ = abi.decode(
            components,
            (NTComponents)
        );
        _components[isV2] = components_;
    }

    /**
     * @notice Sets the provided `component` to `addr`. `isV2` defines
     * which version is being overridden.
     *
     * @param component enum encoding from `NTComponent`
     * @param addr address to `component`
     * @param isV2 defines whether V1 or V2 addresses are to be overridden
     */
    function enlist(
        NTComponent component,
        address addr,
        bool isV2
    ) external onlyOwner {
        NTComponents storage components = _components[isV2];
        if (component == NTComponent.S1_IDENTITY) {
            components.s1Identity = addr;
        } else if (component == NTComponent.S1_BOUGHT_IDENTITY) {
            components.s1BoughtIdentity = addr;
        } else if (component == NTComponent.S1_VAULT) {
            components.s1Vault = addr;
        } else if (component == NTComponent.S1_ITEM) {
            components.s1Item = addr;
        } else if (component == NTComponent.S1_LAND) {
            components.s1Land = addr;
        } else if (component == NTComponent.S1_CITIZEN) {
            components.s1Citizen = addr;
        } else if (component == NTComponent.S2_IDENTITY) {
            components.s2Identity = addr;
        } else if (component == NTComponent.S2_ITEM) {
            components.s2Item = addr;
        } else if (component == NTComponent.S2_LAND) {
            components.s2Land = addr;
        } else if (component == NTComponent.S2_CITIZEN) {
            components.s2Citizen = addr;
        } else if (component == NTComponent.CHAMPION_CHIP) {
            components.championChips = addr;
        }
    }

    /**
     * @notice Decodes the `metadata` into a `NTComponents` struct
     *
     * @param metadata encoded struct of addresses to each NT metadata contract
     */
    function enlistMetadata(bytes calldata metadata) public onlyOwner {
        NTComponents memory metadataContracts = abi.decode(
            metadata,
            (NTComponents)
        );
        _metadataContracts = metadataContracts;
    }

    function enlistMetadata(
        NTComponent metadata,
        address addr
    ) external onlyOwner {
        if (metadata == NTComponent.S1_IDENTITY) {
            _metadataContracts.s1Identity = addr;
        } else if (metadata == NTComponent.S1_BOUGHT_IDENTITY) {
            _metadataContracts.s1BoughtIdentity = addr;
        } else if (metadata == NTComponent.S1_VAULT) {
            _metadataContracts.s1Vault = addr;
        } else if (metadata == NTComponent.S1_ITEM) {
            _metadataContracts.s1Item = addr;
        } else if (metadata == NTComponent.S1_LAND) {
            _metadataContracts.s1Land = addr;
        } else if (metadata == NTComponent.S1_CITIZEN) {
            _metadataContracts.s1Citizen = addr;
        } else if (metadata == NTComponent.S2_IDENTITY) {
            _metadataContracts.s2Identity = addr;
        } else if (metadata == NTComponent.S2_ITEM) {
            _metadataContracts.s2Item = addr;
        } else if (metadata == NTComponent.S2_LAND) {
            _metadataContracts.s2Land = addr;
        } else if (metadata == NTComponent.S2_CITIZEN) {
            _metadataContracts.s2Citizen = addr;
        } else if (metadata == NTComponent.CHAMPION_CHIP) {
            _metadataContracts.championChips = addr;
        }
    }

    /**
     * @notice Decodes the `metadata` into a `NTSecondaryMetadata` struct
     *
     * @param metadata encoded struct of addresses to each NT secondary metadata contract
     */
    function enlistSecondaryMetadata(bytes calldata metadata) public onlyOwner {
        NTSecondaryComponents memory metadataContracts = abi.decode(
            metadata,
            (NTSecondaryComponents)
        );
        _secondaryMetadataContracts = metadataContracts;
    }

    function enlistSecondaryMetadata(
        NTSecondaryComponent metadata,
        address addr
    ) external onlyOwner {
        if (metadata == NTSecondaryComponent.S1_IDENTITY_RARE_MINT) {
            _secondaryMetadataContracts.s1IdentityRareMint = addr;
        } else if (metadata == NTSecondaryComponent.S1_IDENTITY_HAND_MINT) {
            _secondaryMetadataContracts.s1IdentityHandMint = addr;
        } else if (metadata == NTSecondaryComponent.S1_CITIZEN_FEMALE) {
            _secondaryMetadataContracts.s1CitizenFemale = addr;
        } else if (metadata == NTSecondaryComponent.S2_CITIZEN_FEMALE) {
            _secondaryMetadataContracts.s2CitizenFemale = addr;
        }
    }

    function setBytesContract(address addr) external onlyOwner {
        bytesContract = addr;
    }

    function setFallbackThreshold(
        NTComponent component,
        uint16 threshold
    ) external onlyOwner {
        if (component == NTComponent.S1_IDENTITY) {
            fallbackThresholds.s1Identity = threshold;
        } else if (component == NTComponent.S1_BOUGHT_IDENTITY) {
            fallbackThresholds.s1BoughtIdentity = threshold;
        } else if (component == NTComponent.S1_VAULT) {
            fallbackThresholds.s1Vault = threshold;
        } else if (component == NTComponent.S1_ITEM) {
            fallbackThresholds.s1Item = threshold;
        } else if (component == NTComponent.S1_LAND) {
            fallbackThresholds.s1Land = threshold;
        } else if (component == NTComponent.S1_CITIZEN) {
            fallbackThresholds.s1Citizen = threshold;
        } else if (component == NTComponent.S2_IDENTITY) {
            fallbackThresholds.s2Identity = threshold;
        } else if (component == NTComponent.S2_ITEM) {
            fallbackThresholds.s2Item = threshold;
        } else if (component == NTComponent.S2_LAND) {
            fallbackThresholds.s2Land = threshold;
        } else if (component == NTComponent.S2_CITIZEN) {
            fallbackThresholds.s2Citizen = threshold;
        } else if (component == NTComponent.CHAMPION_CHIP) {
            fallbackThresholds.championChips = threshold;
        }
    }

    function setMigrator(address addr) external onlyOwner {
        migrator = addr;
    }

    function tokenExists(uint256 tokenId) external view returns (bool) {
        if (msg.sender == _metadataContracts.s1BoughtIdentity) {
            if (tokenId > fallbackThresholds.s1BoughtIdentity) {
                try
                    IERC721(_components[V2].s1Identity).ownerOf(tokenId)
                returns (address) {
                    return true;
                } catch {
                    return false;
                }
            } else if (
                IERC721(_components[V1].s1BoughtIdentity).ownerOf(tokenId) !=
                address(0)
            ) {
                return true;
            }
            return false;
        }
        revert TokenNotFound();
    }

    /**
     * @notice metadata contract will call parent to see who owns the token.
     * Based on metadata contract that's calling we will look at v1 and v2 a specific nft collection
     * if it exists in v2 we return v2 ownerOf else we return v1 ownerOf
     */
    function ownerOf(uint256 tokenId) external view returns (address) {
        if (msg.sender == _metadataContracts.s1Identity) {
            return
                IERC721(
                    _components[tokenId > fallbackThresholds.s1Identity]
                        .s1Identity
                ).ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s1Item) {
            return
                IERC721(_components[tokenId > fallbackThresholds.s1Item].s1Item)
                    .ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s1Land) {
            return
                IERC721(_components[tokenId > fallbackThresholds.s1Land].s1Land)
                    .ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s2Identity) {
            return
                IERC721(
                    _components[tokenId > fallbackThresholds.s2Identity]
                        .s2Identity
                ).ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s2Item) {
            return
                IERC721(_components[tokenId > fallbackThresholds.s2Item].s2Item)
                    .ownerOf(tokenId);
        } else if (msg.sender == _metadataContracts.s2Land) {
            return
                IERC721(_components[tokenId > fallbackThresholds.s2Land].s2Land)
                    .ownerOf(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getAbility(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getAbility(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getAbility(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getAllocation(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_2) {
            return
                NTConfig(_metadataContracts.s2Identity).getAllocation(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getApparel(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Item).getApparel(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Item).getApparel(tokenId);
        } else {
            revert AddressNotConfigured();
        }
    }

    function getClass(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getClass(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getClass(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getExpression(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_2) {
            return
                NTConfig(_metadataContracts.s2Identity).getExpression(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getEyes(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getEyes(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getEyes(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getGender(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getGender(
                    tokenId
                );
        }
        revert AddressNotConfigured();
    }

    function getHair(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getHair(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getHelm(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Item).getHelm(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Item).getHelm(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getLocation(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Land).getLocation(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Land).getLocation(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getNose(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getNose(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getRace(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getRace(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getRace(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getVehicle(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Item).getVehicle(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Item).getVehicle(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return NTConfig(_metadataContracts.s1Item).getWeapon(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Item).getWeapon(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getAdditionalItem(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_metadataContracts.s1Vault).getAdditionalItem(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getAttractiveness(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId))
                    .getAttractiveness(tokenId);
        } else if (season == NTSeason.SEASON_2) {
            return
                NTConfig(_metadataContracts.s2Identity).getAttractiveness(
                    tokenId
                );
        }
        revert AddressNotConfigured();
    }

    function getCool(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getCool(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getCool(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getIntelligence(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId))
                    .getIntelligence(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getStrength(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getStrength(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return NTConfig(_metadataContracts.s2Identity).getStrength(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getTechSkill(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getTechSkill(
                    tokenId
                );
        } else if (season == NTSeason.SEASON_2) {
            return
                NTConfig(_metadataContracts.s2Identity).getTechSkill(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getCreditYield(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId))
                    .getCreditYield(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getCredits(uint256 tokenId) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_findS1IdentityMetadataContract(tokenId)).getCredits(
                    tokenId
                );
        }
        revert AddressNotConfigured();
    }

    function getCreditProportionOfTotalSupply(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_metadataContracts.s1Vault)
                    .getCreditProportionOfTotalSupply(tokenId);
        }
        revert AddressNotConfigured();
    }

    function getCreditMultiplier(
        uint256 tokenId
    ) public view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            return
                NTConfig(_metadataContracts.s1Vault).getCreditMultiplier(
                    tokenId
                );
        }
        revert AddressNotConfigured();
    }

    function getIdentityIdOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getIdentityIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getIdentityIdOfTokenId(
                        citizenId
                    );
            }
        } else if (season == NTSeason.SEASON_2) {
            if (citizenId > fallbackThresholds.s2Citizen) {
                return
                    NTConfig(_components[V2].s2Citizen).getIdentityIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s2Citizen).getIdentityIdOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getVaultIdOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getVaultIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getVaultIdOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getItemCacheIdOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getItemCacheIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getItemCacheIdOfTokenId(
                        citizenId
                    );
            }
        } else if (season == NTSeason.SEASON_2) {
            if (citizenId > fallbackThresholds.s2Citizen) {
                return
                    NTConfig(_components[V2].s2Citizen).getItemCacheIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s2Citizen).getItemCacheIdOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getLandDeedIdOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getLandDeedIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getLandDeedIdOfTokenId(
                        citizenId
                    );
            }
        } else if (season == NTSeason.SEASON_2) {
            if (citizenId > fallbackThresholds.s2Citizen) {
                return
                    NTConfig(_components[V2].s2Citizen).getLandDeedIdOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s2Citizen).getLandDeedIdOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getRewardRateOfTokenId(
        uint256 citizenId
    ) external view returns (uint256) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen).getRewardRateOfTokenId(
                        citizenId
                    );
            } else {
                return
                    NTConfig(_components[V1].s1Citizen).getRewardRateOfTokenId(
                        citizenId
                    );
            }
        }
        revert AddressNotConfigured();
    }

    function getSpecialMessageOfTokenId(
        uint256 citizenId
    ) external view returns (string memory) {
        NTSeason season = _seasonChecker(msg.sender);
        if (season == NTSeason.SEASON_1) {
            if (citizenId > fallbackThresholds.s1Citizen) {
                return
                    NTConfig(_components[V2].s1Citizen)
                        .getSpecialMessageOfTokenId(citizenId);
            } else {
                return
                    NTConfig(_components[V1].s1Citizen)
                        .getSpecialMessageOfTokenId(citizenId);
            }
        } else if (season == NTSeason.SEASON_2) {
            if (citizenId > fallbackThresholds.s2Citizen) {
                return
                    NTConfig(_components[V2].s2Citizen)
                        .getSpecialMessageOfTokenId(citizenId);
            } else {
                return
                    NTConfig(_components[V1].s2Citizen)
                        .getSpecialMessageOfTokenId(citizenId);
            }
        }
        revert AddressNotConfigured();
    }

    function calculateRewardRate(
        uint256 identityId,
        uint256 vaultId
    ) external returns (uint256) {
        return
            NTConfig(_metadataContracts.s1Citizen).calculateRewardRate(
                identityId,
                vaultId
            );
    }

    function checkSpecialItems(uint256 tokenId) external view returns (string memory) {
        return NTConfig(_components[V1].s1Item).checkSpecialItems(tokenId);
    }

    function generateURI(
        uint256 tokenId
    ) external view returns (string memory) {
        (bool isValid, , ) = _validateCaller(msg.sender);
        require(isValid, "generateURI: not configured address");
        NTConfig tokenContract = NTConfig(
            _selectTokenContract(msg.sender, tokenId)
        );
        return tokenContract.generateURI(tokenId);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        (bool isValid, , ) = _validateCaller(msg.sender);
        require(isValid, "tokenURI: not configured address");
        NTConfig tokenContract = NTConfig(
            _selectTokenContract(msg.sender, tokenId)
        );
        if (
            msg.sender == _components[V1].s1Citizen ||
            msg.sender == _components[V2].s1Citizen ||
            msg.sender == _components[V1].s2Citizen ||
            msg.sender == _components[V2].s2Citizen
        ) {
            return tokenContract.generateURI(tokenId);
        }
        return tokenContract.tokenURI(tokenId);
    }

    function _findThreshold(
        NTComponent component
    ) internal view returns (uint256) {
        if (component == NTComponent.S1_IDENTITY) {
            return fallbackThresholds.s1Identity;
        } else if (component == NTComponent.S1_BOUGHT_IDENTITY) {
            return fallbackThresholds.s1BoughtIdentity;
        } else if (component == NTComponent.S1_VAULT) {
            return fallbackThresholds.s1Vault;
        } else if (component == NTComponent.S1_ITEM) {
            return fallbackThresholds.s1Item;
        } else if (component == NTComponent.S1_LAND) {
            return fallbackThresholds.s1Land;
        } else if (component == NTComponent.S1_CITIZEN) {
            return fallbackThresholds.s1Citizen;
        } else if (component == NTComponent.S2_IDENTITY) {
            return fallbackThresholds.s2Identity;
        } else if (component == NTComponent.S2_ITEM) {
            return fallbackThresholds.s2Item;
        } else if (component == NTComponent.S2_LAND) {
            return fallbackThresholds.s2Land;
        } else if (component == NTComponent.S2_CITIZEN) {
            return fallbackThresholds.s2Citizen;
        } else if (component == NTComponent.CHAMPION_CHIP) {
            return fallbackThresholds.championChips;
        }
        revert ComponentNotFound();
    }

    function _seasonChecker(address addr) internal view returns (NTSeason) {
        if (
            addr == _components[V1].s1Identity ||
            addr == _components[V2].s1Identity ||
            addr == _metadataContracts.s1Identity ||
            addr == _secondaryMetadataContracts.s1IdentityRareMint ||
            addr == _secondaryMetadataContracts.s1IdentityHandMint
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1BoughtIdentity ||
            addr == _components[V2].s1BoughtIdentity ||
            addr == _metadataContracts.s1BoughtIdentity
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1Vault ||
            addr == _components[V2].s1Vault ||
            addr == _metadataContracts.s1Vault
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1Item ||
            addr == _components[V2].s1Item ||
            addr == _metadataContracts.s1Item
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1Land ||
            addr == _components[V2].s1Land ||
            addr == _metadataContracts.s1Land
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s1Citizen ||
            addr == _components[V2].s1Citizen ||
            addr == _metadataContracts.s1Citizen ||
            addr == _secondaryMetadataContracts.s1CitizenFemale
        ) {
            return NTSeason.SEASON_1;
        } else if (
            addr == _components[V1].s2Identity ||
            addr == _components[V2].s2Identity ||
            addr == _metadataContracts.s2Identity
        ) {
            return NTSeason.SEASON_2;
        } else if (
            addr == _components[V1].s2Item ||
            addr == _components[V2].s2Item ||
            addr == _metadataContracts.s2Item
        ) {
            return NTSeason.SEASON_2;
        } else if (
            addr == _components[V1].s2Land ||
            addr == _components[V2].s2Land ||
            addr == _metadataContracts.s2Land
        ) {
            return NTSeason.SEASON_2;
        } else if (
            addr == _components[V1].s2Citizen ||
            addr == _components[V2].s2Citizen ||
            addr == _metadataContracts.s2Citizen ||
            addr == _secondaryMetadataContracts.s2CitizenFemale
        ) {
            return NTSeason.SEASON_2;
        } else if (
            addr == _components[V1].championChips ||
            addr == _components[V2].championChips ||
            addr == _metadataContracts.championChips
        ) {
            return NTSeason.NO_SEASON;
        } else {
            return NTSeason.INVALID;
        }
    }

    function _findS1IdentityMetadataContract(
        uint256 tokenId
    ) internal view returns (address) {
        if (tokenId < 2251) {
            return _metadataContracts.s1Identity;
        } else if (tokenId < 2281) {
            return _secondaryMetadataContracts.s1IdentityRareMint;
        } else if (tokenId < 2288) {
            return _secondaryMetadataContracts.s1IdentityHandMint;
        } else {
            return _metadataContracts.s1BoughtIdentity;
        }
    }

    function _validateAddress(
        address addr,
        bool isV2
    ) internal view returns (bool) {
        NTComponents storage components = _components[isV2];
        if (addr == components.s1Identity) {
            return true;
        } else if (addr == components.s1BoughtIdentity) {
            return true;
        } else if (addr == components.s1Vault) {
            return true;
        } else if (addr == components.s1Vault) {
            return true;
        } else if (addr == components.s1Item) {
            return true;
        } else if (addr == components.s1Land) {
            return true;
        } else if (addr == components.s1Citizen) {
            return true;
        } else if (addr == components.s2Identity) {
            return true;
        } else if (addr == components.s2Item) {
            return true;
        } else if (addr == components.s2Land) {
            return true;
        } else if (addr == components.s2Citizen) {
            return true;
        } else if (addr == components.championChips) {
            return true;
        }
        revert ComponentNotFound();
    }

    /**
     * @notice Validates the `caller` address under the assumption
     * of it being from the `V2` set of addresses. If no address is found,
     * it gracefully returns a `false` success-state and all following tuple
     * arguments are invalid.
     *
     * @param caller the address of the caller (usually `msg.sender`)
     */
    function _validateCaller(
        address caller
    ) internal view returns (bool, address, NTComponent) {
        NTComponents storage v1Components = _components[V1];
        NTComponents storage v2Components = _components[V2];
        address fallbackAddr;
        NTComponent callingComponent;

        if (caller == v2Components.s1Identity || caller == v1Components.s1Identity) {
            fallbackAddr = v1Components.s1Identity;
            callingComponent = NTComponent.S1_IDENTITY;
        } else if (caller == v1Components.s1BoughtIdentity) {
            fallbackAddr = v1Components.s1BoughtIdentity;
            callingComponent = NTComponent.S1_BOUGHT_IDENTITY;
        } else if (caller == v2Components.s1Vault || caller == v1Components.s1Vault) {
            fallbackAddr = v1Components.s1Vault;
            callingComponent = NTComponent.S1_VAULT;
        } else if (caller == v2Components.s1Item || caller == v1Components.s1Item) {
            fallbackAddr = v1Components.s1Item;
            callingComponent = NTComponent.S1_ITEM;
        } else if (caller == v2Components.s1Land || caller == v1Components.s1Land) {
            fallbackAddr = v1Components.s1Land;
            callingComponent = NTComponent.S1_LAND;
        } else if (caller == v2Components.s1Citizen || caller == v1Components.s1Citizen) {
            fallbackAddr = v1Components.s1Citizen;
            callingComponent = NTComponent.S1_CITIZEN;
        } else if (caller == v2Components.s2Identity || caller == v1Components.s2Identity) {
            fallbackAddr = v1Components.s2Identity;
            callingComponent = NTComponent.S2_IDENTITY;
        } else if (caller == v2Components.s2Item || caller == v1Components.s2Item) {
            fallbackAddr = v1Components.s2Item;
            callingComponent = NTComponent.S2_ITEM;
        } else if (caller == v2Components.s2Land || caller == v1Components.s2Land) {
            fallbackAddr = v1Components.s2Land;
            callingComponent = NTComponent.S2_LAND;
        } else if (caller == v2Components.s2Citizen || caller == v1Components.s2Citizen) {
            fallbackAddr = v1Components.s2Citizen;
            callingComponent = NTComponent.S2_CITIZEN;
        } else if (caller == v2Components.championChips) {
            fallbackAddr = v1Components.championChips;
            callingComponent = NTComponent.CHAMPION_CHIP;
        } else {
            return (false, fallbackAddr, callingComponent);
        }
        return (true, fallbackAddr, callingComponent);
    }

    function _selectTokenContract(
        address component,
        uint256 tokenId
    ) internal view returns (address) {
        if (component == _components[V2].s1Identity) {
            if (tokenId > fallbackThresholds.s1Identity) {
                return _metadataContracts.s1BoughtIdentity;
            } else {
                //TODO: remove magic numbers probably with some new thresholds mapping
                if (tokenId < 2251) {
                    return _metadataContracts.s1Identity;
                } else if (tokenId < 2281) {
                    return _secondaryMetadataContracts.s1IdentityRareMint;
                } else {
                    return _secondaryMetadataContracts.s1IdentityHandMint;
                }
            }
        } else if (component == _components[V1].s1Identity) {
            return _metadataContracts.s1Identity;
        } else if (component == _components[V1].s1BoughtIdentity) {
            return _metadataContracts.s1BoughtIdentity;
        } else if (
            component == _components[V2].s1Vault ||
            component == _components[V1].s1Vault
        ) {
            return _metadataContracts.s1Vault;
        } else if (
            component == _components[V2].s1Item ||
            component == _components[V1].s1Item
        ) {
            return _metadataContracts.s1Item;
        } else if (
            component == _components[V2].s1Land ||
            component == _components[V1].s1Land
        ) {
            return _metadataContracts.s1Land;
        } else if (
            component == _components[V2].s1Citizen ||
            component == _components[V1].s1Citizen
        ) {
            if (ICitizen(component).getGenderOfTokenId(tokenId)) {
                return _secondaryMetadataContracts.s1CitizenFemale;
            }
            return _metadataContracts.s1Citizen;
        } else if (
            component == _components[V2].s2Identity ||
            component == _components[V1].s2Identity
        ) {
            return _metadataContracts.s2Identity;
        } else if (
            component == _components[V2].s2Item ||
            component == _components[V1].s2Item
        ) {
            return _metadataContracts.s2Item;
        } else if (
            component == _components[V2].s2Land ||
            component == _components[V1].s2Land
        ) {
            return _metadataContracts.s2Land;
        } else if (
            component == _components[V2].s2Citizen ||
            component == _components[V1].s2Citizen
        ) {
            if (ICitizen(component).getGenderOfTokenId(tokenId)) {
                return _secondaryMetadataContracts.s2CitizenFemale;
            }
            return _metadataContracts.s2Citizen;
        } else if (
            component == _components[V2].championChips ||
            component == _components[V1].championChips
        ) {
            return _metadataContracts.championChips;
        }
        revert ComponentNotFound();
    }
}