// SPDX-License-Identifier: CC0-1.0

/// @title ENS Avatar Mirror Token Descriptor

/**
 *        ><<    ><<<<< ><<    ><<      ><<
 *      > ><<          ><<      ><<      ><<
 *     >< ><<         ><<       ><<      ><<
 *   ><<  ><<        ><<        ><<      ><<
 *  ><<<< >< ><<     ><<        ><<      ><<
 *        ><<        ><<       ><<<<    ><<<<
 */

pragma solidity ^0.8.17;

import {IENSAvatarMirrorDataReader} from "./interfaces/IENSAvatarMirrorDataReader.sol";
import {IENSAvatarMirrorNodeResolver} from "./interfaces/IENSAvatarMirrorNodeResolver.sol";
import {IENSAvatarMirrorDescriptorDefault} from "./interfaces/IENSAvatarMirrorDescriptorDefault.sol";

interface IENSAvatarMirror {
    function dataReader() external view returns (IENSAvatarMirrorDataReader);
    function nodeResolver() external view returns (IENSAvatarMirrorNodeResolver);
}

contract ENSAvatarMirrorDescriptor {
    IENSAvatarMirrorDescriptorDefault internal descriptorDefault;

    constructor(address _descriptorDefault) {
        descriptorDefault = IENSAvatarMirrorDescriptorDefault(_descriptorDefault);
    }

    function tokenURI(string memory domain, bytes32 node) external view returns (string memory) {
        IENSAvatarMirrorDataReader dataReader = IENSAvatarMirror(msg.sender).dataReader();
        IENSAvatarMirrorNodeResolver nodeResolver = IENSAvatarMirror(msg.sender).nodeResolver();

        string memory avatarURI = nodeResolver.resolveText(node, "avatar");

        if (bytes(avatarURI).length == 0) {
            return descriptorDefault.buildTokenURI(domain, descriptorDefault.IMAGE_UNINITIALIZED());
        }

        (, uint256 len, bytes32 root) = dataReader.uriScheme(avatarURI);
        if (root == "eip155") {
            address nftContract = dataReader.parseAddrString(dataReader.substring(avatarURI, len + 1, len + 43));
            uint256 nftContractTokenId =
                dataReader.parseIntString(dataReader.substring(avatarURI, len + 44, bytes(avatarURI).length));

            (bool success, bytes memory data) =
                nftContract.staticcall(abi.encodeWithSignature("tokenURI(uint256)", nftContractTokenId));

            if (!success) {
                (success, data) = nftContract.staticcall(abi.encodeWithSignature("uri(uint256)", nftContractTokenId));

                if (!success) {
                    return descriptorDefault.buildTokenURI(domain, descriptorDefault.IMAGE_ERROR());
                }
            }

            return abi.decode(data, (string));
        }

        if (len > 1) {
            return descriptorDefault.buildTokenURI(domain, avatarURI);
        }

        return descriptorDefault.buildTokenURI(domain, descriptorDefault.IMAGE_UNINITIALIZED());
    }
}