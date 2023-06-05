// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "./IShardedMinds.sol";
import "./ShardedMindsGeneGenerator.sol";
import "./ERC2981Royalties.sol";

contract ShardedMinds is
    IShardedMinds,
    ERC721PresetMinterPauserAutoId,
    ReentrancyGuard,
    ERC2981Royalties,
    Ownable
{
    using ShardedMindsGeneGenerator for ShardedMindsGeneGenerator.Gene;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter internal _tokenIdTracker;
    string private _baseTokenURI;

    ShardedMindsGeneGenerator.Gene internal geneGenerator;

    address payable public daoAddress;
    uint256 public shardedMindsPrice;
    uint256 public maxSupply;
    uint256 public bulkBuyLimit;
    uint256 public maxNFTsPerWallet;
    uint256 public maxNFTsPerWalletPresale;

    uint256 public immutable reservedNFTsCount = 50;
    uint256 public immutable uniquesCount = 7;
    uint256 public immutable royaltyFeeBps = 250;

    event TokenMorphed(
        uint256 indexed tokenId,
        uint256 oldGene,
        uint256 newGene,
        uint256 price,
        ShardedMinds.ShardedMindsEventType eventType
    );
    event TokenMinted(uint256 indexed tokenId, uint256 newGene);
    event ShardedMindsPriceChanged(uint256 newShardedMindsPrice);
    event MaxSupplyChanged(uint256 newMaxSupply);
    event BulkBuyLimitChanged(uint256 newBulkBuyLimit);
    event BaseURIChanged(string baseURI);

    enum ShardedMindsEventType {
        MINT,
        TRANSFER
    }

    // Optional mapping for token URIs
    mapping(uint256 => uint256) internal _genes;
    mapping(uint256 => uint256) internal _uniqueGenes;

    // Presale configs
    uint256 public presaleStart;
    uint256 public officialSaleStart;
    mapping(address => bool) public presaleList;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address payable _daoAddress,
        uint256 _shardedMindsPrice,
        uint256 _maxSupply,
        uint256 _bulkBuyLimit,
        uint256 _maxNFTsPerWallet,
        uint256 _maxNFTsPerWalletPresale,
        uint256 _presaleStart,
        uint256 _officialSaleStart
    ) ERC721PresetMinterPauserAutoId(name, symbol, baseURI) {
        daoAddress = _daoAddress;
        shardedMindsPrice = _shardedMindsPrice;
        maxSupply = _maxSupply;
        bulkBuyLimit = _bulkBuyLimit;
        maxNFTsPerWallet = _maxNFTsPerWallet;
        maxNFTsPerWalletPresale = _maxNFTsPerWalletPresale;
        presaleStart = _presaleStart;
        officialSaleStart = _officialSaleStart;
        geneGenerator.random();
        generateUniques();
    }

    modifier onlyDAO() {
        require(_msgSender() == daoAddress, "Not called from the dao");
        _;
    }

    function generateUniques() internal virtual {
        for (uint256 i = 1; i <= uniquesCount; i++) {
            uint256 selectedToken = (geneGenerator.random() % (maxSupply - 1)) + 1;
            _uniqueGenes[selectedToken] = i;
        }
    }

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            require(entries[i] != address(0), "Null address");
            require(!presaleList[entries[i]], "Duplicate entry");
            presaleList[entries[i]] = true;
        }
    }

    function isPresale() public view returns (bool) {
        return (block.timestamp > presaleStart && block.timestamp < officialSaleStart);
    }

    function isSale() public view returns (bool) {
        return (block.timestamp > officialSaleStart);
    }

    function isInPresaleWhitelist(address _address) public view returns (bool) {
        return presaleList[_address];
    }

    function isTokenUnique(uint256 tokenId)
        public
        view
        returns (bool, uint256)
    {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        bool isUnique;
        uint256 index;
        if (_uniqueGenes[tokenId] != 0) {
            isUnique = true;
            index = _uniqueGenes[tokenId];
        }
        return (isUnique, index);
    }

    function setGene() internal returns (uint256) {
        return geneGenerator.random();
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
            ShardedMindsEventType.TRANSFER
        );
    }

    function reserveMint(uint256 amount) external override onlyOwner {
        require(
            _tokenIdTracker.current().add(amount) <= maxSupply,
            "Total supply reached"
        );
        require(
            balanceOf(_msgSender()).add(amount) <= reservedNFTsCount,
            "Mint limit exceeded"
        );
        require(isPresale(), "Presale not started/already finished");

        _mint(amount);
    }

    function mint() public payable override nonReentrant {
        require(_tokenIdTracker.current() < maxSupply, "Total supply reached");
        require(!isPresale() && isSale(), "Official sale not started");

        if (isInPresaleWhitelist(_msgSender())) {
            require(
                balanceOf(_msgSender()) <
                    maxNFTsPerWallet.add(maxNFTsPerWalletPresale),
                "Mint limit exceeded"
            );
        } else {
            require(
                balanceOf(_msgSender()) < maxNFTsPerWallet,
                "Mint limit exceeded"
            );
        }
        (bool transferToDaoStatus, ) = daoAddress.call{value: shardedMindsPrice}(
            ""
        );
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(shardedMindsPrice);
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }
        _mint(1);
    }

    function presaleMint(uint256 amount) public payable override nonReentrant {
        require(
            amount <= maxNFTsPerWalletPresale,
            "Cannot bulk buy more than the preset limit"
        );
        require(
            _tokenIdTracker.current().add(amount) <= maxSupply,
            "Total supply reached"
        );
        require(isPresale(), "Presale not started/already finished");
        require(isInPresaleWhitelist(_msgSender()), "Not in presale list");
        require(
            balanceOf(_msgSender()).add(amount) <= maxNFTsPerWalletPresale,
            "Presale mint limit exceeded"
        );

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: shardedMindsPrice.mul(amount)
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(shardedMindsPrice.mul(amount));
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }
        _mint(amount);
    }

    function bulkBuy(uint256 amount) public payable override nonReentrant {
        require(
            amount <= bulkBuyLimit,
            "Cannot bulk buy more than the preset limit"
        );
        require(
            _tokenIdTracker.current().add(amount) <= maxSupply,
            "Total supply reached"
        );
        require(!isPresale() && isSale(), "Official sale not started");

        if (isInPresaleWhitelist(_msgSender())) {
            require(
                balanceOf(_msgSender()).add(amount) <=
                    maxNFTsPerWallet.add(maxNFTsPerWalletPresale),
                "Mint limit exceeded"
            );
        } else {
            require(
                balanceOf(_msgSender()).add(amount) <= maxNFTsPerWallet,
                "Mint limit exceeded"
            );
        }

        (bool transferToDaoStatus, ) = daoAddress.call{
            value: shardedMindsPrice.mul(amount)
        }("");
        require(
            transferToDaoStatus,
            "Address: unable to send value, recipient may have reverted"
        );

        uint256 excessAmount = msg.value.sub(shardedMindsPrice.mul(amount));
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{
                value: excessAmount
            }("");
            require(returnExcessStatus, "Failed to return excess.");
        }
        _mint(amount);
    }

    function lastTokenId() public view override returns (uint256 tokenId) {
        return _tokenIdTracker.current();
    }

    function mint(address to)
        public
        pure
        override(ERC721PresetMinterPauserAutoId)
    {
        revert("Should not use this one");
    }

    function _mint(uint256 amount) internal {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIdTracker.increment();

            uint256 tokenId = _tokenIdTracker.current();
            _genes[tokenId] = setGene();
            _mint(_msgSender(), tokenId);
            _setTokenRoyalty(tokenId, daoAddress, royaltyFeeBps);

            emit TokenMinted(tokenId, _genes[tokenId]);
            emit TokenMorphed(
                tokenId,
                0,
                _genes[tokenId],
                shardedMindsPrice,
                ShardedMindsEventType.MINT
            );
        }
    }

    function setShardedMindsPrice(uint256 newShardedMindsPrice)
        public
        virtual
        override
        onlyDAO
    {
        shardedMindsPrice = newShardedMindsPrice;

        emit ShardedMindsPriceChanged(newShardedMindsPrice);
    }

    function setMaxSupply(uint256 _maxSupply) public virtual override onlyDAO {
        maxSupply = _maxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    function setBulkBuyLimit(uint256 _bulkBuyLimit)
        public
        virtual
        override
        onlyDAO
    {
        bulkBuyLimit = _bulkBuyLimit;

        emit BulkBuyLimitChanged(_bulkBuyLimit);
    }

    function setBaseURI(string memory _baseURI)
        public
        virtual
        override
        onlyDAO
    {
        _baseTokenURI = _baseURI;

        emit BaseURIChanged(_baseURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721PresetMinterPauserAutoId, ERC165Storage, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {
        mint();
    }
}