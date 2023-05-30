// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./IPolymorphicFaces.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../base/ERC721PresetMinterPauserAutoId.sol";
import "../lib/PolymorphicFacesGeneGenerator.sol";
import "../modifiers/DAOControlled.sol";

contract PolymorphicFaces is
    IPolymorphicFaces,
    ERC721PresetMinterPauserAutoId,
    ReentrancyGuard,
    DAOControlled,
    Ownable
{
    using PolymorphicFacesGeneGenerator for PolymorphicFacesGeneGenerator.Gene;

    PolymorphicFacesGeneGenerator.Gene internal geneGenerator;
    mapping(uint256 => uint256) internal _genes;
    string public arweaveAssetsJSON;


    event TokenMorphed(
        uint256 indexed tokenId,
        uint256 oldGene,        
        uint256 newGene,
        uint256 price,
        FacesEventType eventType
    );
    event TokenMinted(uint256 indexed tokenId, uint256 newGene);

    event ArweaveAssetsJSONChanged(string arweaveAssetsJSON);
    
    enum FacesEventType {
        MINT,
        MORPH,
        TRANSFER
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address payable _daoAddress,
        string memory _arweaveAssetsJSON
    )
        DAOControlled(_daoAddress)
        ERC721PresetMinterPauserAutoId(name, symbol, baseURI)
    {
        arweaveAssetsJSON = _arweaveAssetsJSON;
    }

    function geneOf(uint256 tokenId) 
        public
        view
        virtual
        override
        returns (uint256 gene)
    {
        return _genes[tokenId];
    }

    function lastTokenId() public view override(ERC721PresetMinterPauserAutoId) returns (uint256 tokenId) {
        return _tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721PresetMinterPauserAutoId) {
        ERC721PresetMinterPauserAutoId._beforeTokenTransfer(from, to, tokenId);
        emit TokenMorphed(
            tokenId,
            _genes[tokenId],
            _genes[tokenId],
            0,
            FacesEventType.TRANSFER
        );
    }

    function setBaseURI(string memory _baseURI)
        public
        virtual
        override
        onlyDAO
    {
        _setBaseURI(_baseURI);

        emit BaseURIChanged(_baseURI);
    }

    function setArweaveAssetsJSON(string memory _arweaveAssetsJSON)
        public
        virtual
        override
        onlyDAO
    {
        arweaveAssetsJSON = _arweaveAssetsJSON;

        emit ArweaveAssetsJSONChanged(_arweaveAssetsJSON);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721PresetMinterPauserAutoId, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}