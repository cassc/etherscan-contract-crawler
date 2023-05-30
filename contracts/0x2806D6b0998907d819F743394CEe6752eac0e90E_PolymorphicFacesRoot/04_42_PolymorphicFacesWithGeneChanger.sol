// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Address.sol";
import "../lib/PolymorphicFacesGeneGenerator.sol";
import "../modifiers/TunnelEnabled.sol";
import "./PolymorphicFaces.sol";
import "./IPolymorphicFacesWithGeneChanger.sol";

abstract contract PolymorphicFacesWithGeneChanger is
    IPolymorphicFacesWithGeneChanger,
    PolymorphicFaces,
    TunnelEnabled
{
    using PolymorphicFacesGeneGenerator for PolymorphicFacesGeneGenerator.Gene;
    using Address for address;

    uint256 constant private TOTAL_ATTRIBUTES = 38;

    mapping(uint256 => uint256) internal _genomeChanges;
    mapping(uint256 => bool) public isNotVirgin;
    uint256 public baseGenomeChangePrice;
    uint256 public randomizeGenomePrice;

    event BaseGenomeChangePriceChanged(uint256 newGenomeChange);
    event RandomizeGenomePriceChanged(uint256 newRandomizeGenomePriceChange);

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address payable _daoAddress,
        uint256 _baseGenomeChangePrice,
        uint256 _randomizeGenomePrice,
        string memory _arweaveAssetsJSON
    ) PolymorphicFaces(name, symbol, baseURI, _daoAddress, _arweaveAssetsJSON) {
        baseGenomeChangePrice = _baseGenomeChangePrice;
        randomizeGenomePrice = _randomizeGenomePrice;
    }

    function changeBaseGenomeChangePrice(uint256 newGenomeChangePrice)
        public
        virtual
        override
        onlyDAO
    {
        baseGenomeChangePrice = newGenomeChangePrice;
        emit BaseGenomeChangePriceChanged(newGenomeChangePrice);
    }

    function changeRandomizeGenomePrice(uint256 newRandomizeGenomePrice)
        public
        virtual
        override
        onlyDAO
    {
        randomizeGenomePrice = newRandomizeGenomePrice;
        emit RandomizeGenomePriceChanged(newRandomizeGenomePrice);
    }

    function morphGene(uint256 tokenId, uint256 genePosition)
        public
        payable
        virtual
        override
        nonReentrant
    {
        _beforeGenomeChange(tokenId);
        uint256 price = priceForGenomeChange(tokenId);

        (bool transferToDaoStatus, ) = daoAddress.call{value: price}("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value - price;
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        uint256 oldGene = _genes[tokenId];
        uint256 newTrait = geneGenerator.random() % 100;
        _genes[tokenId] = replaceGene(oldGene, newTrait, genePosition);
        _genomeChanges[tokenId]++;
        isNotVirgin[tokenId] = true;
        emit TokenMorphed(
            tokenId,
            oldGene,
            _genes[tokenId],
            price,
            FacesEventType.MORPH
        );
    }

    function replaceGene(
        uint256 genome,
        uint256 replacement,
        uint256 genePosition
    ) internal pure virtual returns (uint256 newGene) {
        require(genePosition < TOTAL_ATTRIBUTES, "Bad gene position");
        uint256 mod = 0;
        if (genePosition >= 0) {
            mod = genome % (10**(genePosition * 2)); // Each gene is 2 digits long
        }

        uint256 div = (genome / (10**((genePosition + 1) * 2))) *
            (10**((genePosition + 1) * 2));

        uint256 insert = replacement * (10**(genePosition * 2));
        newGene = div + insert + mod;
        return newGene;
    }

    function randomizeGenome(uint256 tokenId)
        public
        payable
        virtual
        override
        nonReentrant
    {
        _beforeGenomeChange(tokenId);

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: randomizeGenomePrice
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value - randomizeGenomePrice;
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        uint256 oldGene = _genes[tokenId];
        _genes[tokenId] = geneGenerator.random();
        _genomeChanges[tokenId] = 0;
        isNotVirgin[tokenId] = true;
        emit TokenMorphed(
            tokenId,
            oldGene,
            _genes[tokenId],
            randomizeGenomePrice,
            FacesEventType.MORPH
        );
    }

    function whitelistBridgeAddress(address bridgeAddress, bool status)
        external
        override
        onlyDAO
    {
        whitelistTunnelAddresses[bridgeAddress] = status;
    }

    function priceForGenomeChange(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256 price)
    {
        uint256 pastChanges = _genomeChanges[tokenId];

        return baseGenomeChangePrice * (1 << pastChanges);
    }

    function genomeChanges(uint256 tokenId)
        public
        view
        override
        returns (uint256 genomeChnages)
    {
        return _genomeChanges[tokenId];
    }

    function _beforeGenomeChange(uint256 tokenId) internal view {
        require(
            !address(_msgSender()).isContract(),
            "Caller cannot be a contract"
        );
        require(
            _msgSender() == tx.origin,
            "Msg sender should be original caller"
        );

        beforeTransfer(tokenId, _msgSender());
    }

    function beforeTransfer(uint256 tokenId, address owner) internal view {
        require(
            ownerOf(tokenId) == owner,
            "FacesWithGeneChanger: cannot change genome of token that is not own"
        );
    }

    function wormholeUpdateGene(
        uint256 tokenId,
        uint256 gene,
        bool isVirgin,
        uint256 genomeChangesCount
    ) external nonReentrant onlyTunnel {
        uint256 oldGene = _genes[tokenId];
        _genes[tokenId] = gene;
        isNotVirgin[tokenId] = isVirgin;
        _genomeChanges[tokenId] = genomeChangesCount;

        emit TokenMorphed(
            tokenId,
            oldGene,
            _genes[tokenId],
            priceForGenomeChange(tokenId),
            FacesEventType.MORPH
        );
    }
}