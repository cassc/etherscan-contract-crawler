// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "./IPolymorph.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../base/ERC721PresetMinterPauserAutoId.sol";
import "../lib/PolymorphGeneGenerator.sol";
import "../modifiers/DAOControlled.sol";

abstract contract Polymorph is
    IPolymorph,
    ERC721PresetMinterPauserAutoId,
    ReentrancyGuard,
    DAOControlled,
    Ownable
{
    using PolymorphGeneGenerator for PolymorphGeneGenerator.Gene;

    PolymorphGeneGenerator.Gene internal geneGenerator;
    mapping(uint256 => uint256) internal _genes;
    string public arweaveAssetsJSON;

    event TokenMorphed(
        uint256 indexed tokenId,
        uint256 oldGene,
        uint256 newGene,
        uint256 price,
        PolymorphEventType eventType
    );
    event TokenMinted(uint256 indexed tokenId, uint256 newGene);
    event TokenBurnedAndMinted(
        uint256 indexed tokenId,
        uint256 gene
    );
    event ArweaveAssetsJSONChanged(string arweaveAssetsJSON);

    enum PolymorphEventType {
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
            PolymorphEventType.TRANSFER
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
}