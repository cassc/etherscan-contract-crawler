// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LibStorage.sol";

import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

contract BookInternalFacetV2 is WithStorage, AccessControlInternal {
    using EnumerableSet for EnumerableSet.UintSet;
    
    event MetadataUpdate(uint256 _tokenId);
    event UpgradePunk(uint indexed punkId, uint newLevel);
    event PunkTakeDamage(uint indexed punkId);
    event MintPunkWithKey(address indexed user, uint indexed punkId, string keySlug, uint32 themeVersion);
    event SetPunkName(address indexed owner, uint indexed punkId, string name);
    
    bytes32 constant ADMIN = keccak256("admin");
    
    modifier onlyRoleStr(string memory role) {
        if (!_hasRole(ADMIN, msg.sender)) {
            _checkRole(_strToRole(role));
        }
        _;
    }
    
    function _grantRoleStr(string memory role, address account) internal {
        _grantRole(_strToRole(role), account);
    }
    
    function _setRoleAdminStr(string memory role, string memory adminRole) internal {
        _setRoleAdmin(_strToRole(role), _strToRole(adminRole));
    }
    
    function _strToRole(string memory role) internal pure returns (bytes32) {
        return keccak256(bytes(role));
    }
    
    struct UnpackedPunk {
        Attribute base;
        Attribute mouthOrLips;
        Attribute face;
        Attribute neck;
        Attribute beard;
        Attribute ears;
        Attribute hair;
        Attribute mouth;
        Attribute eyes;
        Attribute nose;
    }
    
    struct ThemeInfo {
        uint[][10] allowedAttributes;
        uint[] allowedAttributeCounts;
        uint64 activatedAt;
        uint64 duration;
    }
    
    function getThemeFromVersion(uint version) internal view returns (ThemeStorage storage) {
        return bk().versionedThemes[version];
    }
    
    function getAllowedAttributes() internal view returns (uint[][10] memory allowedAttributes) {
        for (uint8 i; i < 10; i++) {
            allowedAttributes[i] = currentTheme().allowedAttributes[i].toArray();
        }
    }
    
    function getThemeByVersion(uint version) internal view returns (ThemeInfo memory) {
        return ThemeInfo({
            allowedAttributes: getAllowedAttributes(),
            allowedAttributeCounts: getAllowedAttributeCounts(),
            activatedAt: getThemeFromVersion(version).activatedAt,
            duration: getThemeFromVersion(version).duration
        });
    }
    
    function getAllowedAttributeCounts() internal view returns (uint[] memory allowedAttributeCounts) {
        allowedAttributeCounts = currentTheme().allowedAttributeCounts.toArray();
    }
    
    function currentTheme() internal view returns (ThemeStorage storage) {
        return getThemeFromVersion(bk().currentThemeVersion);
    }
    
    function _punkConformsToTheme(uint80 assets) internal view returns (bool) {
        if (currentTheme().activatedAt == 0) return false;
        
        if (currentTheme().activatedAt > 0 && currentTheme().duration > 0) {
            if (block.timestamp > currentTheme().activatedAt + currentTheme().duration) {
                return false;
            }
        }
        
        return _punkAdheresToAllowedAttributes(assets);
    }
    
    function _punkAdheresToAllowedAttributes(
        uint80 assets
    ) internal view returns (bool) {
        uint8[10] memory assetsArr = unpackAssets(assets);
        
        uint8 countedAttributes;
        
        for (uint8 slotIndex = 0; slotIndex < 10; slotIndex++) {
            uint8 currentAttribute = assetsArr[slotIndex];
            
            if (currentAttribute > 0) countedAttributes++;

            if (currentTheme().allowedAttributes[slotIndex].length() == 0) continue;
            
            if (!currentTheme().allowedAttributes[slotIndex].contains(currentAttribute)) {
                return false;
            }
        }
        
        if (
            currentTheme().allowedAttributeCounts.length() > 0 &&
            !currentTheme().allowedAttributeCounts.contains(countedAttributes)
        ) {
            return false;
        }
        
        return true;
    }
    
    function getGenderToBases(Gender gender) internal view returns (uint[] memory) {
        return ps().genderToBases[gender];
    }
    
    function packedAssetsToUnpackedPunkStruct(uint80 packedAssets) internal pure returns (UnpackedPunk memory) {
        return UnpackedPunk({
            base: Attribute(uint8(packedAssets >> 72)),
            mouthOrLips: Attribute(uint8(packedAssets >> 64)),
            face: Attribute(uint8(packedAssets >> 56)),
            neck: Attribute(uint8(packedAssets >> 48)),
            beard: Attribute(uint8(packedAssets >> 40)),
            ears: Attribute(uint8(packedAssets >> 32)),
            hair: Attribute(uint8(packedAssets >> 24)),
            mouth: Attribute(uint8(packedAssets >> 16)),
            eyes: Attribute(uint8(packedAssets >> 8)),
            nose: Attribute(uint8(packedAssets))
        });
    }

    function composite(
        bytes1 index
    ) internal view returns (bytes4 rgba) {
        uint256 x = uint256(uint8(index)) * 4;
        uint8 xAlpha = uint8(ps().palette[x + 3]);
        
        return bytes4(
                    uint32(
                        (uint256(uint8(ps().palette[x])) << 24) |
                            (uint256(uint8(ps().palette[x + 1])) << 16) |
                            (uint256(uint8(ps().palette[x + 2])) << 8) |
                            xAlpha
                    )
                );
    }

    function packAssets(uint8[10] memory assetsArr)
        internal
        pure
        returns (uint80 ret)
    {
        for (uint8 i = 0; i < 10; i++) {
            ret = ret | (uint80(assetsArr[i]) << (8 * (9 - i)));
        }
    }
    
    function unpackAssets(uint80 assetsPacked)
        internal
        pure
        returns (uint8[10] memory ret)
    {
        for (uint8 i = 0; i < 10; i++) {
            ret[i] = uint8(assetsPacked >> (8 * (9 - i)));
        }
    }
    
    function attributeValidInSlot(Gender gender, uint8 attribute, uint8 slotIndex) internal view returns (bool) {
        return ps().genderedAttributes[uint8(gender)][slotIndex].contains(attribute);
    }
    
    function punkHasHiddenAttribute(uint80 packedAssets) internal pure returns (bool) {
        UnpackedPunk memory punk = packedAssetsToUnpackedPunkStruct(packedAssets);
        
        if (
            punk.hair == Attribute.WildHair_f ||
            punk.hair == Attribute.DarkHair_f ||
            punk.hair == Attribute.FrumpyHair_f ||
            punk.hair == Attribute.BlondeBob_f ||
            punk.hair == Attribute.StraightHairDark_f ||
            punk.hair == Attribute.StraightHair_f ||
            punk.hair == Attribute.StraightHairBlonde_f ||
            punk.hair == Attribute.WildWhiteHair_f ||
            punk.hair == Attribute.HalfShaved_f ||
            punk.hair == Attribute.PinkWithHat_f
        ) {
            if (punk.ears == Attribute.Earring_f) return true;
        }
        
        if (punk.mouth == Attribute.MedicalMask_f) {
            if (
                punk.mouthOrLips == Attribute.PurpleLipstick_f ||
                punk.mouthOrLips == Attribute.BlackLipstick_f ||
                punk.mouthOrLips == Attribute.HotLipstick_f ||
                punk.face == Attribute.Mole_f
            ) {
                return true;
            }
        }
        
        if (punk.eyes == Attribute.VR_f) {
            if (punk.face == Attribute.Mole_f || punk.face == Attribute.RosyCheeks_f) return true;
        }
        
        if (punk.eyes == Attribute.BigShades_f && punk.face == Attribute.RosyCheeks_f) return true;
        
        if (punk.mouthOrLips == Attribute.Smile_m || punk.mouthOrLips == Attribute.Frown_m) {
            if (
                punk.face == Attribute.MedicalMask_m ||
                punk.beard == Attribute.NormalBeard_m ||
                punk.beard == Attribute.NormalBeardBlack_m ||
                punk.beard == Attribute.FrontBeardDark_m ||
                punk.beard == Attribute.FrontBeard_m ||
                punk.beard == Attribute.LuxuriousBeard_m ||
                punk.beard == Attribute.BigBeard_m ||
                punk.beard == Attribute.Handlebars_m
            ) return true;
        }
        
        if (punk.mouth == Attribute.MedicalMask_m) {
            if (
                punk.beard == Attribute.Mustache_m ||
                punk.beard == Attribute.Handlebars_m ||
                punk.mouthOrLips == Attribute.BuckTeeth_m
            ) return true;
        }
        
        if (
            punk.hair == Attribute.PurpleHair_m ||
            punk.hair == Attribute.Hoodie_m
        ) {
            if (punk.ears == Attribute.Earring_m) return true;
        }
        
        if (punk.face == Attribute.Mole_m) {
            if (
                punk.beard == Attribute.NormalBeard_m ||
                punk.beard == Attribute.NormalBeardBlack_m ||
                punk.beard == Attribute.LuxuriousBeard_m ||
                punk.beard == Attribute.Chinstrap_m ||
                punk.beard == Attribute.Muttonchops_m
            ) return true;
        }
        
        if (punk.mouthOrLips == Attribute.BuckTeeth_m) {
            if (
                punk.beard == Attribute.NormalBeard_m ||
                punk.beard == Attribute.NormalBeardBlack_m ||
                punk.beard == Attribute.LuxuriousBeard_m
            ) return true;
        }
        
        if (punk.beard == Attribute.BigBeard_m && punk.neck == Attribute.GoldChain_m) return true;
        
        return false;
    }
    
    function punkIsValid(uint80 packedAssets) internal view returns (bool) {
        if (punkHasHiddenAttribute(packedAssets)) return false;
        
        uint8[10] memory assetsArr = unpackAssets(packedAssets);
        
        if (!ps().validBases.contains(assetsArr[0])) return false;
        
        Gender gender = Gender(ps().baseToGender[assetsArr[0]]);

        uint8[9] memory selected;

        for (uint8 slotIndex = 0; slotIndex < 9; slotIndex++) {
            uint8 attributeToTest = assetsArr[slotIndex + 1];
            
            if (!attributeValidInSlot(gender, attributeToTest, slotIndex)) {
                return false;
            }
            
            if (
                attributeToTest == uint8(Attribute.WeldingGoggles_f) &&
                ps().isHat[selected[uint8(AttributeSlot.Hair)]]
                
            ) {
                return false;
            }
            
            if (
                (
                    (slotIndex == uint8(AttributeSlot.Eyes)) && (attributeToTest != uint8(Attribute.None))
                ) &&
                selected[uint8(AttributeSlot.Hair)] == uint8(Attribute.PilotHelmet_f)
            ) {
                return false;
            }

            selected[slotIndex] = attributeToTest;
        }
        return true;
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
}