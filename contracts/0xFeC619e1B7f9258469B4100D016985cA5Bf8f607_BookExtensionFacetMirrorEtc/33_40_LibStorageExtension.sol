// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct BookStorageExtension {
    bool bookExtensionFacetMirrorEtcInitialized;
    
    mapping(uint => string) punkIdToColorMappingItem;
    mapping(string => mapping(bytes4 => bytes4)) gameItemToColorMapping;
    mapping(string => bool) colorMappingItemToIsEnabled;
    
    mapping(uint => string) punkIdToBackgroundItem;
    mapping(string => address) gameItemToBackgroundPointer;
    
    mapping(string => string) gameItemToAttributeName;
    
    mapping(uint => bool) punkIdToIsMirrored;
    
    uint8 renderMode;
    string baseImageURI;
}

library LibStorageExtension {
    bytes32 constant BOOK_STORAGE_EXTENSION_POSITION = keccak256("c21.babylon.game.book.storage.extension");
    
    function bookStorageExtension() internal pure returns (BookStorageExtension storage gs) {
        bytes32 position = BOOK_STORAGE_EXTENSION_POSITION;
        assembly {
            gs.slot := position
        }
    }
}