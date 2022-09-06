// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import {INFTEnhancement} from "src/interfaces/INFTEnhancement.sol";
import {IERC721Metadata} from "src/interfaces/IERC721.sol";
import {IERC1155MetadataURI} from "src/interfaces/IERC1155MetadataURI.sol";
import {IRenderer} from "src/interfaces/IRenderer.sol";
import {ERC721} from "./ERC721.sol";
import "./Base64.sol";

contract NFTEnhancement is INFTEnhancement, ERC721 {
    /*//////////////////////////////////////////////////////////////
                            STORAGE & ERRORS
    //////////////////////////////////////////////////////////////*/
    address public owner;
    /// tokenId => token name
    mapping(uint256 => string) internal names;

    /// tokenId => underlying token contract
    mapping(uint256 => address) internal _underlyingTokenContract;
    /// tokenId => underlying token id
    mapping(uint256 => uint256) internal _underlyingTokenId;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        address underlyingTokenContract = _underlyingTokenContract[tokenId];
        uint256 underlyingTokenId = _underlyingTokenId[tokenId];
        return _getMetadata(tokenId, underlyingTokenContract, underlyingTokenId);
    }

    /*//////////////////////////////////////////////////////////////
                              NFTENHANCEMENT LOGIC
    //////////////////////////////////////////////////////////////*/
    function setUnderlyingToken(
        uint256 tokenId,
        address underlyingContract,
        uint256 underlyingTokenId
    )
        external
        override
    {
        _requireAuthorized(tokenId);
        _underlyingTokenId[tokenId] = underlyingTokenId;
        _underlyingTokenContract[tokenId] = underlyingContract;
    }

    function getUnderlyingToken(uint256 tokenId)
        external
        view
        returns (address underlyingContract, uint256 underlyingTokenId)
    {
        underlyingContract = _underlyingTokenContract[tokenId];
        underlyingTokenId = _underlyingTokenId[tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                              OTHER PUBLIC LOGIC
    //////////////////////////////////////////////////////////////*/
    function mint(
        address to,
        address renderer,
        uint96 counter,
        string calldata name
    )
        external
    {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        uint256 id = composeTokenId(renderer, counter);
        names[id] = name;
        // checks if tokenId has already been minted by checking if ownerOf[id] != 0. works because we cannot burn & transfer reverts to 0
        _mint(to, id);
    }

    function previewTokenURI(
        uint256 tokenId,
        address underlyingTokenContract,
        uint256 underlyingTokenId
    )
        external
        view
        returns (string memory)
    {
        return _getMetadata(tokenId, underlyingTokenContract, underlyingTokenId);
    }

    function composeTokenId(address renderer, uint96 counter)
        public
        pure
        returns (uint256 tokenId)
    {
        tokenId = (uint256(counter) << 160) | uint256(uint160(renderer));
    }

    function decomposeTokenId(uint256 tokenId)
        public
        pure
        returns (address renderer, uint96 counter)
    {
        renderer = address(uint160(tokenId & type(uint160).max));
        counter = uint96(tokenId >> 160);
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function _getMetadata(
        uint256 id,
        address underlyingTokenContract,
        uint256 underlyingTokenId
    )
        internal
        view
        returns (string memory)
    {
        string memory name = names[id];
        string memory underlyingTokenContractName;
        string memory underlyingTokenContractSymbol;

        // possible XSS but it would just break the token uri
        try IERC721Metadata(underlyingTokenContract).name() returns (
            string memory contractName
        ) {
            underlyingTokenContractName = contractName;
        } catch {}
        try IERC721Metadata(underlyingTokenContract).symbol() returns (
            string memory contractSymbol
        ) {
            underlyingTokenContractSymbol = contractSymbol;
        } catch {}
        string memory description = string(
            abi.encodePacked(
                "Applied to ",
                bytes(underlyingTokenContractSymbol).length > 0
                    ? underlyingTokenContractSymbol
                    :
                        bytes(underlyingTokenContractName).length > 0
                        ? underlyingTokenContractName
                        : "NA",
                "#",
                Strings.toString(underlyingTokenId),
                " (",
                Strings.toHexString(underlyingTokenContract),
                ")"
            )
        );

        string memory html;
        (address renderer,) = decomposeTokenId(id);
        bool ownsUnderlying = false;

        try IERC721Metadata(underlyingTokenContract).ownerOf(underlyingTokenId)
        returns (address underlyingOwner) {
            ownsUnderlying = underlyingOwner == _ownerOf[id];
        } catch {}

        try IERC721Metadata(underlyingTokenContract).tokenURI(underlyingTokenId)
        returns (string memory underlyingTokenURI) {
            html = IRenderer(renderer).render(
                id,
                underlyingTokenContract,
                underlyingTokenId,
                underlyingTokenURI,
                ownsUnderlying
            );
        } catch {
            // try it as an ERC1155
            try IERC1155MetadataURI(underlyingTokenContract).uri(underlyingTokenId)
            returns (string memory underlyingTokenURI) {
                html = IRenderer(renderer).render(
                    id,
                    underlyingTokenContract,
                    underlyingTokenId,
                    underlyingTokenURI,
                    ownsUnderlying
                );
            } catch {}
        }

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '","description":"',
                        description,
                        '","animation_url":"data:text/html;base64,',
                        Base64.encode(bytes(html)),
                        '","attributes":[]}'
                    )
                )
            )
        );
    }
}