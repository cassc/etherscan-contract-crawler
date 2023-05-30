// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "./IPolymorph.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC721PresetMinterPauserAutoId.sol";
import "../../lib/PolymorphGeneGenerator.sol";
import "../../modifiers/DAOControlled.sol";

contract Polymorph is IPolymorph, ERC721PresetMinterPauserAutoId, ReentrancyGuard {
    using PolymorphGeneGenerator for PolymorphGeneGenerator.Gene;

    PolymorphGeneGenerator.Gene internal geneGenerator;

    address payable public daoAddress;
    uint256 public polymorphPrice;
    uint256 public maxSupply;
    uint256 public bulkBuyLimit;
    string public arweaveAssetsJSON;

    event TokenMorphed(uint256 indexed tokenId, uint256 oldGene, uint256 newGene, uint256 price, Polymorph.PolymorphEventType eventType);
    event TokenMinted(uint256 indexed tokenId, uint256 newGene);
    event PolymorphPriceChanged(uint256 newPolymorphPrice);
    event MaxSupplyChanged(uint256 newMaxSupply);
    event BulkBuyLimitChanged(uint256 newBulkBuyLimit);
    //event BaseURIChanged(string baseURI);
    event arweaveAssetsJSONChanged(string arweaveAssetsJSON);
    event TokenBurnedAndMinted(uint256 tokenId, uint256 newGene);
    
    enum PolymorphEventType { MINT, MORPH, TRANSFER }

     // Optional mapping for token URIs
    mapping (uint256 => uint256) internal _genes;

    constructor(string memory name, string memory symbol, string memory baseURI, address payable _daoAddress, uint256 _polymorphPrice, uint256 _maxSupply, uint256 _bulkBuyLimit, string memory _arweaveAssetsJSON) ERC721PresetMinterPauserAutoId(name, symbol, baseURI) public {
        daoAddress = _daoAddress;
        polymorphPrice = _polymorphPrice;
        maxSupply = _maxSupply;
        bulkBuyLimit = _bulkBuyLimit;
        arweaveAssetsJSON = _arweaveAssetsJSON;
        geneGenerator.random();
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Not called from the dao");
        _;
    }

    function geneOf(uint256 tokenId) public view virtual override returns (uint256 gene) {
        return _genes[tokenId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721PresetMinterPauserAutoId) {
        ERC721PresetMinterPauserAutoId._beforeTokenTransfer(from, to, tokenId);
        emit TokenMorphed(tokenId, _genes[tokenId], _genes[tokenId], 0, PolymorphEventType.TRANSFER);
    }

    function bulkBuy(uint256 amount) public virtual payable nonReentrant {
        require(amount <= bulkBuyLimit, "Cannot bulk buy more than the preset limit");
        require(_tokenId + amount <= maxSupply, "Total supply reached");
        
        (bool transferToDaoStatus, ) = daoAddress.call{value:polymorphPrice * amount}("");
        require(transferToDaoStatus, "Address: unable to send value, recipient may have reverted");

        uint256 excessAmount = msg.value - (polymorphPrice * amount);
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        for (uint256 i = 0; i < amount; i++) {
           _tokenId++;
        
            _genes[_tokenId] = geneGenerator.random();
            _mint(_msgSender(), _tokenId);
            
            emit TokenMinted(_tokenId, _genes[_tokenId]);
            emit TokenMorphed(_tokenId, 0, _genes[_tokenId], polymorphPrice, PolymorphEventType.MINT); 
        }
        
    }

    function lastTokenId() public override view returns (uint256 tokenId) {
        return _tokenId;
    }

    function mint(address to) public override(ERC721PresetMinterPauserAutoId) {
        revert("Should not use this one");
    }

    function setPolymorphPrice(uint256 newPolymorphPrice) public override virtual onlyDAO {
        polymorphPrice = newPolymorphPrice;

        emit PolymorphPriceChanged(newPolymorphPrice);
    }

    function setMaxSupply(uint256 _maxSupply) public override virtual onlyDAO {
        maxSupply = _maxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    function setBulkBuyLimit(uint256 _bulkBuyLimit) public override virtual onlyDAO {
        bulkBuyLimit = _bulkBuyLimit;

        emit BulkBuyLimitChanged(_bulkBuyLimit);
    }

    function setBaseURI(string memory _baseURI) public virtual onlyDAO { 
        _setBaseURI(_baseURI);

        emit BaseURIChanged(_baseURI);
    }

    function setArweaveAssetsJSON(string memory _arweaveAssetsJSON) public virtual onlyDAO {
        arweaveAssetsJSON = _arweaveAssetsJSON;

        emit arweaveAssetsJSONChanged(_arweaveAssetsJSON);
    }
    
}