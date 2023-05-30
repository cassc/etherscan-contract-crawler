// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IPolymorphRoot.sol";
import "../PolymorphsV1/Polymorph.sol";
import "../PolymorphsV1/PolymorphWithGeneChanger.sol";

contract PolymorphRoot is PolymorphWithGeneChanger, IPolymorphRoot {
    using PolymorphGeneGenerator for PolymorphGeneGenerator.Gene;

    struct Params {
        string name;
        string symbol;
        string baseURI;
        address payable _daoAddress;
        uint96 _royaltyFee;
        uint256 _baseGenomeChangePrice;
        uint256 _polymorphPrice;
        uint256 _maxSupply;
        uint256 _randomizeGenomePrice;
        uint256 _bulkBuyLimit;
        string _arweaveAssetsJSON;
        address _polymorphV1Address;
    }

    //uint256 public polymorphPrice;
    //uint256 public maxSupply;
    //uint256 public bulkBuyLimit;

    Polymorph public polymorphV1Contract;
    mapping(address => uint256) public burnCount;

    uint16 constant private STARTING_TOKEN_ID = 10000;

    //event PolymorphPriceChanged(uint256 newPolymorphPrice);
    //event MaxSupplyChanged(uint256 newMaxSupply);
    //event BulkBuyLimitChanged(uint256 newBulkBuyLimit);
    event DefaultRoyaltyChanged(address newReceiver, uint96 newDefaultRoyalty);

    constructor(Params memory params)
        PolymorphWithGeneChanger(
            params.name,
            params.symbol,
            params.baseURI,
            params._daoAddress,
            params._polymorphPrice,
            params._maxSupply,
            params._bulkBuyLimit,
            params._baseGenomeChangePrice,
            params._randomizeGenomePrice,
            params._arweaveAssetsJSON
        )
    {
        // polymorphPrice = params._polymorphPrice;
        // maxSupply = params._maxSupply;

        // bulkBuyLimit = params._bulkBuyLimit;

        polymorphV1Contract = Polymorph(params._polymorphV1Address);

        geneGenerator.random();

        _tokenId = _tokenId + STARTING_TOKEN_ID;

        _setDefaultRoyalty(params._daoAddress, params._royaltyFee);

    }

    function mint() public payable override nonReentrant {
        require(_tokenId < maxSupply, "Total supply reached");
        require(msg.value >= polymorphPrice, "Insufficient funds");

        _tokenId++;

        _genes[_tokenId] = geneGenerator.random();
        _mint(_msgSender(), _tokenId);

        (bool transferToDaoStatus, ) = daoAddress.call{value: polymorphPrice}(
            ""
        );
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        emit TokenMinted(_tokenId, _genes[_tokenId]);
        emit TokenMorphed(
            _tokenId,
            0,
            _genes[_tokenId],
            polymorphPrice,
            PolymorphEventType.MINT
        );
    }

    function burnAndMintNewPolymorph(uint256[] calldata tokenIds) external nonReentrant {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 currentIdToBurnAndMint = tokenIds[i];
            require(_msgSender() == polymorphV1Contract.ownerOf(currentIdToBurnAndMint));

            uint256 geneToTransfer = polymorphV1Contract.geneOf(currentIdToBurnAndMint);
            polymorphV1Contract.burn(currentIdToBurnAndMint);

            burnCount[_msgSender()]+=1;

            _genes[currentIdToBurnAndMint] = geneToTransfer;

            _mint(_msgSender(), currentIdToBurnAndMint);

            emit TokenMinted(currentIdToBurnAndMint, _genes[currentIdToBurnAndMint]);
            emit TokenBurnedAndMinted(currentIdToBurnAndMint, _genes[currentIdToBurnAndMint]);
        }
    }

    function bulkBuy(uint256 amount) public override(Polymorph,IPolymorphRoot) payable nonReentrant {
        require(
            amount <= bulkBuyLimit,
            "Cannot bulk buy more than the preset limit"
        );
        require(
            _tokenId + amount <= maxSupply,
            "Total supply reached"
        );
        require(msg.value >= polymorphPrice * amount, "Insufficient funds");

        for (uint256 i = 0; i < amount; i++) {
            _tokenId++;

            _genes[_tokenId] = geneGenerator.random();
            _mint(_msgSender(), _tokenId);

            emit TokenMinted(_tokenId, _genes[_tokenId]);
            emit TokenMorphed(
                _tokenId,
                0,
                _genes[_tokenId],
                polymorphPrice,
                PolymorphEventType.MINT
            );
        }

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: polymorphPrice * amount
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    // function mint(address to)
    //     public
    //     pure
    //     override
    // {
    //     revert("Should not use this one");
    // }

    function setPolymorphPrice(uint256 newPolymorphPrice)
        public
        virtual
        override
        onlyDAO
    {
        polymorphPrice = newPolymorphPrice;

        emit PolymorphPriceChanged(newPolymorphPrice);
    }

    function setMaxSupply(uint256 _maxSupply) public virtual override onlyDAO {
        maxSupply = _maxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    // function setBulkBuyLimit(uint256 _bulkBuyLimit)
    //     public
    //     virtual
    //     override
    //     onlyDAO
    // {
    //     bulkBuyLimit = _bulkBuyLimit;

    //     emit BulkBuyLimitChanged(_bulkBuyLimit);
    // }

    function setDefaultRoyalty(address receiver, uint96 royaltyFee)
        external
        onlyDAO
    {
        _setDefaultRoyalty(receiver, royaltyFee);

        emit DefaultRoyaltyChanged(receiver, royaltyFee);
    }

    receive() external payable {
        mint();
    }
}