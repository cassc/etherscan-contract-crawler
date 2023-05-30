// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./IPolymorphicFacesRoot.sol";
import "../base/PolymorphsV2/PolymorphRoot.sol";
import "../base/PolymorphicFacesWithGeneChanger.sol";

contract PolymorphicFacesRoot is
    PolymorphicFacesWithGeneChanger,
    IPolymorphicFacesRoot
{
    using PolymorphicFacesGeneGenerator for PolymorphicFacesGeneGenerator.Gene;

    struct Params {
        string name;
        string symbol;
        string baseURI;
        address payable _daoAddress;
        uint96 _royaltyFee;
        uint256 _baseGenomeChangePrice;
        uint256 _maxSupply;
        uint256 _randomizeGenomePrice;
        string _arweaveAssetsJSON;
        address _polymorphV2Address;
    }

    uint256 public maxSupply;

    PolymorphRoot public polymorphV2Contract;

    mapping(address => uint256) public numClaimed;

    event MaxSupplyChanged(uint256 newMaxSupply);
    event PolyV2AddressChanged(address newPolyV2Address);
    event DefaultRoyaltyChanged(address newReceiver, uint96 newDefaultRoyalty);

    constructor(Params memory params)
        PolymorphicFacesWithGeneChanger(
            params.name,
            params.symbol,
            params.baseURI,
            params._daoAddress,
            params._baseGenomeChangePrice,
            params._randomizeGenomePrice,
            params._arweaveAssetsJSON
        )
    {
        maxSupply = params._maxSupply;
        arweaveAssetsJSON = params._arweaveAssetsJSON;
        polymorphV2Contract = PolymorphRoot(
            payable(params._polymorphV2Address)
        );
        geneGenerator.random();
        _setDefaultRoyalty(params._daoAddress, params._royaltyFee);
    }

    function claim(uint256 amount) public nonReentrant {
        require(amount <= 20, "Can't claim more than 20 faces in one tx");
        require(_tokenId + amount <= maxSupply, "Total supply reached");

        for (uint256 i = 0; i < amount; i++) {
            require(
                polymorphV2Contract.burnCount(msg.sender) >
                    numClaimed[msg.sender],
                "User already claimed all allowed faces"
            );
            numClaimed[msg.sender]++;

            _tokenId++;

            _genes[_tokenId] = geneGenerator.random();

            _mint(_msgSender(), _tokenId);

            emit TokenMinted(_tokenId, _genes[_tokenId]);
            emit TokenMorphed(
                _tokenId,
                0,
                _genes[_tokenId],
                0,
                FacesEventType.MINT
            );
        }
    }

    function daoMint(uint256 _amount) external onlyDAO {
        require(_amount <= 25, "DAO can mint at most 25 faces per transaction");
        require(_tokenId + _amount <= maxSupply, "Total supply reached");
        for (uint256 i = 0; i < _amount; i++) {
            _tokenId++;
            _genes[_tokenId] = geneGenerator.random();
            _mint(_msgSender(), _tokenId);

            emit TokenMinted(_tokenId, _genes[_tokenId]);
            emit TokenMorphed(
                _tokenId,
                0,
                _genes[_tokenId],
                0,
                FacesEventType.MINT
            );
        }
    }

    function mint(address to) public override(ERC721PresetMinterPauserAutoId) {
        revert("Should not use this one");
    }

    function setDefaultRoyalty(address receiver, uint96 royaltyFee)
        external
        onlyDAO
    {
        _setDefaultRoyalty(receiver, royaltyFee);

        emit DefaultRoyaltyChanged(receiver, royaltyFee);
    }

    function setMaxSupply(uint256 _maxSupply) public virtual override onlyDAO {
        maxSupply = _maxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    function setPolyV2Address(address payable newPolyV2Address)
        external
        onlyDAO
    {
        polymorphV2Contract = PolymorphRoot(newPolyV2Address);

        emit PolyV2AddressChanged(newPolyV2Address);
    }
}