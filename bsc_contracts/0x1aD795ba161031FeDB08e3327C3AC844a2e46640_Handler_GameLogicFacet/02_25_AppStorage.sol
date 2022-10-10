// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "../INodeType.sol";
import "../ISpringNode.sol";
import "../ISpringLuckyBox.sol";
import "../ISwapper.sol";
import "../ISpringPlot.sol";

struct NodeType {
    string[] keys; // nodeTypeName to address
    mapping(string => address) values;
    mapping(string => uint256) indexOf;
    mapping(string => bool) inserted;
}

struct Token {
    uint256[] keys; // token ids to nodeTypeName
    mapping(uint256 => string) values;
    mapping(uint256 => uint256) indexOf;
    mapping(uint256 => bool) inserted;
}

struct AppStorage {
    NodeType mapNt;
    Token mapToken;
    address nft;
    ISpringLuckyBox lucky;
    ISwapper swapper;
    ISpringPlot plot;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    function getTokenIdNodeTypeName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.mapToken.inserted[tokenId], "TokenId doesnt exist");
        return s.mapToken.values[tokenId];
    }

    function nft() internal view returns (IERC721) {
        AppStorage storage s = LibAppStorage.appStorage();
        return IERC721(s.nft);
    }
}