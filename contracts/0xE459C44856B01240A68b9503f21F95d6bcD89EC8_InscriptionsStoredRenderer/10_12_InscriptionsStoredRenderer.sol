// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {MetadataRenderAdminCheck} from "zora-drops-contracts/metadata/MetadataRenderAdminCheck.sol";
import {MetadataBuilder} from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import {MetadataJSONKeys} from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SSTORE2} from "./SStore2.sol";

import {StringsBytes32} from "./StringsBytes32.sol";

/// @author @isiain
/// @notice Inscriptions Metadata on-chain renderer
contract InscriptionsStoredRenderer is
    IMetadataRenderer,
    MetadataRenderAdminCheck
{
    /// @notice Stores address => tokenId => bytes32 btc txn id
    mapping(address => InscriptionChunk[]) inscriptionChunks;

    struct InscriptionChunk {
        // inclusive, fromToken starts at 0
        uint256 fromToken;
        uint256 size;
        address dataContract;
    }

    struct Inscription {
        bytes32 btc_txn;
        string properties;
    }

    /// @notice Stores address => numberInscribedTokens
    mapping(address => uint256) numberInscribedTokens;

    /// @notice Stores address => string base, string postfix, string contractURI for urls
    mapping(address => ContractInfo) contractInfos;

    struct ContractInfo {
        string animationBase;
        string animationPostfix;
        string imageBase;
        string imagePostfix;
        string title;
        string description;
        string contractURI;
    }

    event BaseURIsUpdated(address target, ContractInfo info);

    event NewChunk(InscriptionChunk, uint256);

    function addInscriptions(
        address inscriptionsContract,
        Inscription[] calldata newInscriptions
    ) external requireSenderAdmin(inscriptionsContract) {
        unchecked {
            // get count
            uint256 count = numberInscribedTokens[inscriptionsContract];
            address data = SSTORE2.write(abi.encode(newInscriptions));
            InscriptionChunk memory newChunk = InscriptionChunk({
                fromToken: count + 1,
                size: newInscriptions.length,
                dataContract: data
            });
            inscriptionChunks[inscriptionsContract].push(newChunk);

            // update count
            numberInscribedTokens[inscriptionsContract] =
                count +
                newInscriptions.length;

            emit NewChunk(newChunk, numberInscribedTokens[inscriptionsContract]);
        }
    }

    error NoChunkFound();

    error InvalidToken();

    function _findInscriptionChunk(
        address inscriptionsContract,
        uint256 tokenId
    ) internal view returns (InscriptionChunk memory) {
        if (tokenId == 0) {
            revert InvalidToken();
        }
        InscriptionChunk memory thisChunk;
        uint256 size = inscriptionChunks[inscriptionsContract].length;
        unchecked {
            for (uint256 i = 0; i < size; ++i) {
                thisChunk = inscriptionChunks[inscriptionsContract][i];
                if (
                    thisChunk.fromToken <= tokenId &&
                    thisChunk.fromToken + thisChunk.size > tokenId
                ) {
                    return thisChunk;
                }
            }
            revert NoChunkFound();
        }
    }

    function getInscriptionForTokenId(
        address inscriptionsContract,
        uint256 tokenId
    ) public view returns (Inscription memory) {
        InscriptionChunk memory thisChunk = _findInscriptionChunk(
            inscriptionsContract,
            tokenId
        );
        Inscription[] memory inscriptions = abi.decode(
            SSTORE2.read(thisChunk.dataContract),
            (Inscription[])
        );
        return inscriptions[tokenId - thisChunk.fromToken];
    }

    function setBaseURIs(address target, ContractInfo memory info)
        external
        requireSenderAdmin(target)
    {
        _setBaseURIs(target, info);
        emit BaseURIsUpdated(target, info);
    }

    function _setBaseURIs(address target, ContractInfo memory info) internal {
        contractInfos[target] = info;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        Inscription memory inscription = getInscriptionForTokenId(
            msg.sender,
            tokenId
        );

        string memory animationURI = string.concat(
            contractInfos[msg.sender].animationBase,
            StringsBytes32.toHexString(inscription.btc_txn),
            contractInfos[msg.sender].animationPostfix
        );

        string memory btcHash = StringsBytes32.toHexString(inscription.btc_txn);

        string memory imageURI = string.concat(
            contractInfos[msg.sender].imageBase,
            btcHash,
            contractInfos[msg.sender].imagePostfix
        );

        ContractInfo memory info = contractInfos[msg.sender];

        MetadataBuilder.JSONItem[]
            memory items = new MetadataBuilder.JSONItem[](6);
        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat(
            info.title,
            " #",
            Strings.toString(tokenId)
        );
        items[0].quote = true;

        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(info.description, " \\n ", animationURI);
        items[1].quote = true;

        items[2].key = MetadataJSONKeys.keyImage;
        items[2].value = imageURI;
        items[2].quote = true;

        items[3].key = MetadataJSONKeys.keyAnimationURL;
        items[3].value = animationURI;
        items[3].quote = true;

        items[4].key = "external_url";
        items[4].value = animationURI;
        items[4].quote = true;

        items[4].key = "external_url";
        items[4].value = animationURI;
        items[4].quote = true;

        items[5].key = MetadataJSONKeys.keyProperties;
        items[5].quote = false;
        items[5].value = string.concat(
            '{"btc transaction hash": "',
            btcHash,
            '", ',
            inscription.properties,
            "}"
        );

        return MetadataBuilder.generateEncodedJSON(items);
    }

    function contractURI() external view returns (string memory) {
        ContractInfo memory info = contractInfos[msg.sender];
        return info.contractURI;
    }

    function initializeWithData(bytes memory initData) external {
        ContractInfo memory info = abi.decode(initData, (ContractInfo));
        _setBaseURIs(msg.sender, info);
    }
}