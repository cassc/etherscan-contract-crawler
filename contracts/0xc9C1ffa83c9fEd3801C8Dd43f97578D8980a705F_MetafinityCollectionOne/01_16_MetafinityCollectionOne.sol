/****************************************************************************************************
 * @notice - This contract implements Role-Based Access Control to allow "admins" to call certain
 *           functions on the metafinity blockchain ecosystem.
 * @dev - Use this contract to inherit the RBAC system into another smart contract.
 *
 * ███╗░░░███╗███████╗████████╗░█████╗░███████╗██╗███╗░░██╗██╗████████╗██╗░░░██╗
 * ████╗░████║██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║████╗░██║██║╚══██╔══╝╚██╗░██╔╝
 * ██╔████╔██║█████╗░░░░░██║░░░███████║█████╗░░██║██╔██╗██║██║░░░██║░░░░╚████╔╝░
 * ██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██║██║╚████║██║░░░██║░░░░░╚██╔╝░░
 * ██║░╚═╝░██║███████╗░░░██║░░░██║░░██║██║░░░░░██║██║░╚███║██║░░░██║░░░░░░██║░░░
 * ╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░░╚═╝░░░░░░╚═╝░░░
 *
 * ░█████╗░░█████╗░██╗░░░░░██╗░░░░░███████╗░█████╗░████████╗██╗░█████╗░███╗░░██╗
 * ██╔══██╗██╔══██╗██║░░░░░██║░░░░░██╔════╝██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
 * ██║░░╚═╝██║░░██║██║░░░░░██║░░░░░█████╗░░██║░░╚═╝░░░██║░░░██║██║░░██║██╔██╗██║
 * ██║░░██╗██║░░██║██║░░░░░██║░░░░░██╔══╝░░██║░░██╗░░░██║░░░██║██║░░██║██║╚████║
 * ╚█████╔╝╚█████╔╝███████╗███████╗███████╗╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
 * ░╚════╝░░╚════╝░╚══════╝╚══════╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝
 *
 * ░█████╗░███╗░░██╗███████╗
 * ██╔══██╗████╗░██║██╔════╝
 * ██║░░██║██╔██╗██║█████╗░░
 * ██║░░██║██║╚████║██╔══╝░░
 * ╚█████╔╝██║░╚███║███████╗
 * ░╚════╝░╚═╝░░╚══╝╚══════╝
 ****************************************************************************************************/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../utils/AccessProtected.sol";
import {DefaultOperatorFilterer} from "../utils/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MetafinityCollectionOne is
    ERC721("Metafinity Collection One", "MCO"),
    AccessProtected,
    DefaultOperatorFilterer
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    event TokenMinted(uint256 tokenId, address recepient);
    event ChangedURI(uint256 tokenId, string uri);

    mapping(uint256 => string) private _tokenURIs;
    string[] private _baseURIs;
    uint256[] private _maxTokenIds;

    Counters.Counter internal numTokens;

    function setBaseURI(
        string memory baseURI_,
        uint256 index,
        uint256 newMax
    ) external onlyOwner {
        _baseURIs[index] = baseURI_;
        _maxTokenIds[index] = newMax;
    }

    function addBaseURI(string memory baseURI_, uint256 newMax)
        external
        onlyOwner
    {
        require(
            _maxTokenIds.length == 0 ||
                newMax > _maxTokenIds[_maxTokenIds.length - 1],
            "New Max less than previous"
        );
        _baseURIs.push(baseURI_);
        _maxTokenIds.push(newMax);
    }

    function getMaxTokenIds() external view returns (uint256[] memory) {
        return _maxTokenIds;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _getBaseURI(uint256 tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        require(
            tokenId <= _maxTokenIds[_maxTokenIds.length - 1],
            "tokenId invalid"
        );
        uint256 index = 0;
        for (uint256 i = 0; i < _maxTokenIds.length; i++) {
            if (tokenId <= _maxTokenIds[i]) {
                index = i;
                break;
            }
        }
        return _baseURIs[index];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _getBaseURI(tokenId);

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If there is no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), ".json"));
    }

    function mint(address recepient, uint256 tokenId) external onlyAdmin {
        require(!_exists(tokenId), "Token already exists");
        numTokens.increment();
        _mint(recepient, tokenId);
        emit TokenMinted(tokenId, recepient);
    }

    function setTokenURI(uint256 tokenId, string memory uri)
        external
        onlyAdmin
    {
        _setTokenURI(tokenId, uri);
        emit ChangedURI(tokenId, uri);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}