// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {ERC721BridgeBRCTokenMapping} from "../ERC721BridgeBRCTokenMapping.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";

contract ERC721ABridgeBRC is ERC721BridgeBRCTokenMapping, ERC721A {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    string private _baseMetadataURI = "";
    mapping(uint256 => string) private _metadataURI;
    string private constant _BASE_EXTENSION = ".json";

    constructor(
        string memory _name,
        string memory _symbol,
        address _original
    ) ERC721A(_name, _symbol) {
        _registOriginalContractAddress(_original);

        // BRC-721E Bridge Contract Address
        _registBridgeContractAddress(
            0x000000000000000000000000000000000000dEaD
        );
    }

    function bridge(
        address from,
        uint256 tokenId,
        string memory _btcAddress
    ) public virtual {
        require(
            bridgeContract != address(0),
            "Bridge Contract is Zero Address"
        );
        safeTransferFrom(from, bridgeContract, tokenId, bytes(_btcAddress));
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert("This token has not minted");
        if (bytes(_metadataURI[tokenId]).length != 0) {
            return _metadataURI[tokenId];
        } else {
            return
                string(
                    abi.encodePacked(
                        _baseMetadataURI,
                        _toString(originalTokenId(tokenId)),
                        _BASE_EXTENSION
                    )
                );
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return _startId() + 1;
    }

    function _setTokenMetadataURI(
        uint256 tokenId,
        string memory metadata
    ) internal virtual {
        _metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _emergencyWithdraw(address to, uint256 tokenId) internal virtual {
        ERC721A(originalContract).safeTransferFrom(address(this), to, tokenId);
    }

    function _setBaseURI(string memory metadata) internal virtual {
        _baseMetadataURI = metadata;
        emit BatchMetadataUpdate(_startId(), registCount);
    }
}