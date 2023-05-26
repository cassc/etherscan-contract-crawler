// SPDX-License-Identifier: MIT

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./../../common/interfaces/IThePixelsIncExtensionStorageV2.sol";
import "./../../common/interfaces/ICoreRewarder.sol";

interface IMetro {
    function ownerOf(uint256 tokenId) external view returns (bool);

    function tokensOfOwner(
        address _owner
    ) external view returns (uint256[] memory);
}

contract ThePixelsIncMetroExtension is Ownable {
    uint256 public constant EXTENSION_ID = 3;

    address public immutable extensionStorageAddress;
    address public immutable rewarderAddress;
    address public immutable metroAddress;

    mapping(uint256 => bool) public usedMetros;

    constructor(
        address _extensionStorageAddress,
        address _rewarderAddress,
        address _metroAddress
    ) {
        extensionStorageAddress = _extensionStorageAddress;
        rewarderAddress = _rewarderAddress;
        metroAddress = _metroAddress;
    }

    function extend(
        uint256[] memory metroTokenIds,
        uint256[] memory tokenIds
    ) public {
        uint256 length = metroTokenIds.length;
        uint256[] memory variants = new uint256[](length);
        bool[] memory useCollection = new bool[](length);
        uint256[] memory collectionTokenIds = new uint256[](length);

        address _extensionStorageAddress = extensionStorageAddress;
        for (uint256 i = 0; i < length; i++) {
            uint256 currentVariant = IThePixelsIncExtensionStorageV2(
                _extensionStorageAddress
            ).currentVariantIdOf(EXTENSION_ID, tokenIds[i]);

            require(currentVariant == 0, "Token has already metro extension");
            require(
                !usedMetros[metroTokenIds[i]],
                "This metro is already used"
            );

            require(
                IERC721(metroAddress).ownerOf(metroTokenIds[i]) == msg.sender,
                "Invalid metro owner"
            );

            uint256 rnd = _rnd(metroTokenIds[i], tokenIds[i]) % 100;
            uint256 variant;

            if (rnd >= 80) {
                variant = 3;
            } else if (rnd >= 50 && rnd < 80) {
                variant = 2;
            } else {
                variant = 1;
            }

            variants[i] = variant;
            usedMetros[metroTokenIds[i]] = true;
        }

        IThePixelsIncExtensionStorageV2(_extensionStorageAddress)
            .extendMultipleWithVariants(
                msg.sender,
                EXTENSION_ID,
                tokenIds,
                variants,
                useCollection,
                collectionTokenIds
            );
    }

    function metroTokenStatus(address _owner)
        public
        view
        returns (uint256[] memory, bool[] memory)
    {
        uint256[] memory tokensOfOwner = IMetro(metroAddress).tokensOfOwner(
            _owner
        );
        bool[] memory tokenStatus = new bool[](tokensOfOwner.length);
        for (uint256 i = 0; i < tokensOfOwner.length; i++) {
            tokenStatus[i] = usedMetros[tokensOfOwner[i]];
        }
        return (tokensOfOwner, tokenStatus);
    }

    function _rnd(
        uint256 _metroTokenId,
        uint256 _pixelTokenId
    ) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        _metroTokenId,
                        _pixelTokenId
                    )
                )
            );
    }
}