// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondLoupe.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";

import { ERC721DInternal } from "./ERC721D/ERC721DInternal.sol";

import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";

import {ERC2981} from "@solidstate/contracts/token/common/ERC2981/ERC2981.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";

import {ERC2981Storage} from "@solidstate/contracts/token/common/ERC2981/ERC2981Storage.sol";

import "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

import "hardhat-deploy/solc_0.8/diamond/UsingDiamondOwner.sol";

import {LibBitmap} from "solady/src/utils/LibBitmap.sol";

struct PosterStorage {
    bool isInitialized;
    bool operatorFilteringEnabled;
    uint16 maxBooksPerPoster;
    uint16 activeExhibition;
    uint64 nextTokenId;
    
    address fontDeclarationPointer;
    address wordmarkPointer;
    address defaultQrCodePointer;
    
    address dataContract;
    address gameContract;
    address withdrawAddress;
    
    string nameSingular;
    string defaultExternalLink;
    
    mapping (uint16 => Exhibition) exhibitions;
    mapping (address => LibBitmap.Bitmap) userToMintedInExhibition;
}

struct Exhibition {
    uint16 number;
    address qrCodePointer;
    address representativeBooksPointer;
    string name;
    string externalLink;
}

contract PosterInternalFacet is ERC721DInternal, AccessControlInternal, UsingDiamondOwner {
    bytes32 constant ADMIN = keccak256("admin");
    
    function s() internal pure returns (PosterStorage storage gs) {
        bytes32 position = keccak256("c21.babylon.game.poster.storage.BabylonExhibitionPoster");
        assembly {
            gs.slot := position
        }
    }
    
    function ds() internal pure returns (LibDiamond.DiamondStorage storage) {
        return LibDiamond.diamondStorage();
    }
    
    function get80BitNumberInBytesAtIndex(bytes memory idsBytes, uint idx) internal pure returns (uint80) {
        return uint80(uintByteArrayValueAtIndex(idsBytes, 10, idx));
    }
    
    function uintByteArrayValueAtIndex(bytes memory uintByteArray, uint bytesPerUint, uint index) internal pure returns (uint) {
        uint value;
        
        for (uint i; i < bytesPerUint; ) {
            value <<= 8;
            value |= uint(uint8(uintByteArray[index * bytesPerUint + i]));
            unchecked {++i;}
        }
        
        return value;
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
    
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}