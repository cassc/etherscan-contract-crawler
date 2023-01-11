// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IRegistry.sol";

abstract contract BaseController is Ownable {
    IRegistry public immutable registry;

    constructor(address _registry) Ownable() {
        registry = IRegistry(_registry);
    }

    function bindAvatar(uint256 tokenId, address registrant) internal {
        string memory emojiIndex = Strings.toHexString(tokenId & 0x7f, 2);
        registry.bind(
            tokenId,
            "avatar",
            string.concat(
                "https://3moji.opendid-ns.me/emoji/",
                emojiIndex,
                ".png"
            ),
            registrant
        );
        registry.bind(
            tokenId,
            "avatar3d",
            string.concat(
                "https://3moji.opendid-ns.me/emoji/",
                emojiIndex,
                ".gltf"
            ),
            registrant
        );
    }
}