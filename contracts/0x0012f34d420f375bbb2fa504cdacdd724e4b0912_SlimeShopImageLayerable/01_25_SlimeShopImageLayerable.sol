// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ImageLayerable} from "bound-layerable/metadata/ImageLayerable.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Attribute} from "bound-layerable/interface/Structs.sol";

contract SlimeShopImageLayerable is ImageLayerable {
    using LibString for uint256;
    string baseName;

    constructor(
        address _owner,
        string memory _defaultURI,
        uint256 _width,
        uint256 _height,
        string memory _externalLink,
        string memory _description
    )
        ImageLayerable(
            _owner,
            _defaultURI,
            _width,
            _height,
            _externalLink,
            _description
        )
    {}

    function _getName(
        uint256 tokenId,
        uint256 layerId,
        uint256 bindings
    ) internal view override returns (string memory) {
        uint256 adjustedTokenId = tokenId + 1;
        if (layerId == 0 || bindings != 0) {
            return string.concat("SLIMESHOP - #", adjustedTokenId.toString());
        }
        Attribute memory layerAttribute = traitAttributes[layerId];
        return
            string.concat(
                "SLIMESHOP - ",
                layerAttribute.value,
                " - #",
                adjustedTokenId.toString()
            );
    }
}