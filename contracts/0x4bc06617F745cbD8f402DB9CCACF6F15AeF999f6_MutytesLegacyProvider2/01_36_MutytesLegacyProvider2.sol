// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMutytesLegacyProvider } from "./IMutytesLegacyProvider.sol";
import { IERC721TokenURIProvider } from "../../core/token/ERC721/tokenURI/IERC721TokenURIProvider.sol";
import { IERC721Enumerable } from "../../core/token/ERC721/enumerable/IERC721Enumerable.sol";
import { LabArchiveController } from "../../ethernia/lab/archive/LabArchiveController.sol";
import { ERC721EnumerableController } from "../../core/token/ERC721/enumerable/ERC721EnumerableController.sol";
import { ERC165Controller } from "../../core/introspection/ERC165Controller.sol";
import { StringUtils } from "../../core/utils/StringUtils.sol";

/**
 * @title Mutytes legacy token URI provider implementation
 */
contract MutytesLegacyProvider2 is
    IERC721TokenURIProvider,
    LabArchiveController,
    ERC721EnumerableController,
    ERC165Controller
{
    using StringUtils for uint256;

    /**
     * @inheritdoc IERC721TokenURIProvider
     */
    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        IMutytesLegacyProvider interpreter = IMutytesLegacyProvider(
            address(0x583473cc07fE026b65f9Dc8aDD96F59bF4d22A32)
        );
        IMutytesLegacyProvider.TokenData memory token;
        IMutytesLegacyProvider.MutationData memory mutation;

        token.id = tokenId;
        token.name = _mutyteName(tokenId);
        token.info = _mutyteDescription(tokenId);
        token.dna = new uint256[](1);
        token.dna[0] = uint256(keccak256(abi.encode(tokenId)));

        if (
            bytes(token.name).length == 0 &&
            _supportsInterface(type(IERC721Enumerable).interfaceId)
        ) {
            token.name = string.concat("Mutyte #", _indexOfToken(tokenId).toString());
        }

        if (bytes(token.info).length == 0) {
            token
                .info = "The Mutytes are a collection of 1,721 severely mutated creatures that invaded Ethernia. Completely decentralized, every Mutyte is generated, stored and rendered 100% on-chain. Once acquired, a Mutyte grants its owner access to the lab and its facilities.";
        }

        mutation.name = _mutationName(0);
        mutation.info = _mutationDescription(0);
        mutation.count = 1;

        return interpreter.tokenURI(token, mutation, "https://www.mutytes.com/mutyte/");
    }

    function _indexOfToken(uint256 tokenId) internal view virtual returns (uint256 i) {
        unchecked {
            for (; i < _initialSupply(); i++) {
                if (_tokenByIndex(i) == tokenId) {
                    break;
                }
            }
        }
    }
}