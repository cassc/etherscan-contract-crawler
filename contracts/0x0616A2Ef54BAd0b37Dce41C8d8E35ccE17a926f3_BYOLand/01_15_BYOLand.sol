// SPDX-License-Identifier: MIT
// ,,,,,,................ THE BYOPILL RESEARCH FACILITY ,,,,,,.....................
// ,,,,,,................                                       ................,.,
// ,,..............                                                 . .............
// .............                                                        ...........
// ...........                                                            .........
// ........ .                                                               .......
// ........         (#////*(#(/#/#                                          .......
// ......         ###(((((.((////////*(/,/&/(((*                             ......
// ....         ,######((((.(*******(&&&&###........,,,..//%                  .....
//              (######(#####((****(((((((((,*,,,*/(//(,..,,*/(                 ...
//              *((((((((,### .##(&&&&&&&&**,***,**,/*/*/%,,***/               ....
//               ,(((((((((((.((((%%%&&&&#((((//(/(#%#*(##,,***/*               ...
//                . (/(((*((/((((/#%####%(//(///(#%######(,******                ..
//               ..,**/////(/(///.(#######//(//(/(((/((((,******,                ..
//                     ....,,**//////%/((((((**//////////////(/....             ...
//                               ....,,,**//////(#(####((((/,,,,,........       ...
//                                         ...,,****////////***,,......          ..
//                                                   ............                 .
//                                                                                .
// ,,,,,,.............................,,,,.....,,,,,,...,,,,,,.....................
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interface/IBYOVape.sol";
import "./interface/IBYOPill.sol";

contract BYOLand is ERC721, Ownable {
    using Counters for Counters.Counter;

    // Constant
    uint256 public constant MAX_LAND = 10056;

    // Private sale properties
    bool public m_privateSale = false;
    uint256 public m_privateMaxPerTx;
    uint256 public m_privateSalePrice;
    mapping(address => uint256) public m_claims;
    bytes32 private m_merkleRoot;

    // Public sale properties
    bool public m_publicSale = false;
    uint256 public m_publicPriceMax;
    uint256 public m_publicPriceMin;
    uint256 public m_publicMaxPerTx;
    uint256 public m_publicSaleDuration;
    uint256 public m_publicSaleStartTime;

    // Data storage
    Counters.Counter private m_landIdCounter;
    string private m_baseURI;
    mapping (uint256 => uint256) m_landForPill;
    mapping (uint256 => uint256) m_publicBucketForLand;

    // Interfaces
    IBYOPill public m_pillContract;
    IBYOVape public m_vapeContract;

    constructor(string memory _name, string memory _symbol, 
        address _pillContract, address _vapeContract) ERC721(_name, _symbol) {
        m_pillContract = IBYOPill(_pillContract);
        m_vapeContract = IBYOVape(_vapeContract);
    }

    // PUBLIC

    function privateMint(uint256[] calldata _pillIds,
        uint256 _merkleIdx,
        uint256 _maxAmount,
        bytes32[] calldata merkleProof) public payable privateSaleActive {

        uint256 amount = _pillIds.length;
        require (amount > 0, "One at least.");
        require (amount <= m_privateMaxPerTx, "More than max per transaction.");
        require (m_landIdCounter.current() + amount <= MAX_LAND, "Max supply.");
        require (m_privateSalePrice * amount <= msg.value, "Ethereum sent is not sufficient.");

        bytes32 nHash = keccak256(abi.encodePacked(_merkleIdx, msg.sender, _maxAmount));
            require(
                MerkleProof.verify(merkleProof, m_merkleRoot, nHash),
                "Invalid merkle proof !"
        );
        require(m_claims[msg.sender] + amount <= _maxAmount, "Minting more than available mints.");
        checkPrivateSaleData (amount, _pillIds);

        for (uint256 i = 0; i < amount; i++) {
            require (m_landForPill[_pillIds[i]] == 0, "Pill used already to mint land.");  
            uint256 tokenId = m_landIdCounter.current();
           
            m_landForPill[_pillIds[i]] = tokenId + 1;   
            m_landIdCounter.increment();  

            _safeMint(msg.sender, tokenId);
        }

        m_claims[msg.sender] = m_claims[msg.sender] + amount;
    }

    function publicMint(uint256 _amount) public payable publicSaleActive {
        require (_amount > 0, "One at least.");
        require (m_publicSale, "Public sale is not active.");
        require (_amount <= m_publicMaxPerTx, "More than max per transaction.");
        require (m_landIdCounter.current() + _amount <= MAX_LAND, "Max supply.");

        uint256 mintPrice = getMintPrice() * _amount;
        require (mintPrice <= msg.value, "Ethereum sent is not sufficient.");

        uint256 publicSaleBucket = getPublicSaleBucket (mintPrice);

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = m_landIdCounter.current();

            m_publicBucketForLand[tokenId] = publicSaleBucket;
            m_landIdCounter.increment();
            
            _safeMint(msg.sender, tokenId);
        }

        // Refund any additional eth sent during dutch auction
        if (msg.value > mintPrice) { 
            Address.sendValue(payable(msg.sender), msg.value - mintPrice);
        }
    }

    // OWNER

    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI (string memory _uri) public onlyOwner {
        m_baseURI = _uri;
    }

    function ownerReserve (uint256 _amount) public onlyOwner {
        require (m_landIdCounter.current() + _amount <= MAX_LAND, "Max supply.");
        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = m_landIdCounter.current();
            m_landIdCounter.increment();  
            _safeMint(msg.sender, tokenId);
        }
    }

    function startPrivateSale (uint256 salePrice, uint256 maxPerTx) public onlyOwner {
        m_privateSale = true;
        m_privateSalePrice = salePrice;
        m_privateMaxPerTx = maxPerTx;
    } 

    function pausePrivateSale () public onlyOwner privateSaleActive {
        m_privateSale = false;
    }

    function setPrivateMerkle (bytes32 _merkle) public onlyOwner {
        m_merkleRoot = _merkle;
    }

    function startPublicSale(uint256 saleDuration, uint256 maxPrice, uint256 minPrice, uint256 maxPerTx) public onlyOwner
    {
        require(!m_publicSale, "Public sale has already started.");
        m_publicSaleDuration = saleDuration;
        m_publicPriceMax = maxPrice;
        m_publicPriceMin = minPrice;
        m_publicMaxPerTx = maxPerTx;
        m_publicSaleStartTime = block.timestamp;
        m_privateSale = false;
        m_publicSale = true;
    }

    function pausePublicSale() public onlyOwner publicSaleActive {
        m_publicSale = false;
    }

    // MODIFIERS

    modifier publicSaleActive {
        require (m_publicSale, "Public sale not active.");
        _;
    }

    modifier privateSaleActive {
        require (m_privateSale, "Private sale not active.");
        _;
    }

    // PUBLIC VIEW

    function totalSupply () public view returns (uint256) {
        return m_landIdCounter.current();
    }

    function landForPill (uint256 _pillId) public view returns (int256) {
        if (m_landForPill[_pillId] == 0) { return -1; }
        return int256(m_landForPill[_pillId] - 1);
    }

    function bucketForLand(uint256 _landId) public view returns (uint256) {
        return m_publicBucketForLand[_landId];
    }

    function getRemainingSaleTime() public view returns (uint256) {
        require(m_publicSaleStartTime > 0, "Public sale hasn't started yet");
        if (getElapsedSaleTime() >= m_publicSaleDuration) { return 0; }
        return (m_publicSaleStartTime + m_publicSaleDuration) - block.timestamp;
    }

    function getMintPrice() public view publicSaleActive returns (uint256) {
        uint256 elapsed = getElapsedSaleTime();
        if (elapsed >= m_publicSaleDuration) {
            return m_publicPriceMin;
        } 
        else {
            uint256 currentPrice = ((m_publicSaleDuration - elapsed) *
                m_publicPriceMax) / m_publicSaleDuration;
            return
                currentPrice > m_publicPriceMin
                    ? currentPrice
                    : m_publicPriceMin;
        }
    }

    // INTERNALS

    function checkPrivateSaleData (uint _amount, uint[] calldata pills) internal view {
        require (m_vapeContract.balanceOf(msg.sender, 0) >= _amount, "Not enough vapes for mint.");
        for (uint256 i = 0; i < pills.length; i++) {
           require (m_pillContract.ownerOf(pills[i]) == msg.sender, "Not your pill.");
        }
    }

    function getElapsedSaleTime() internal view returns (uint256) {
        return m_publicSaleStartTime > 0 ? block.timestamp - m_publicSaleStartTime : 0;
    }

    function getPublicSaleBucket (uint256 _price) internal pure returns (uint256) {
        if (_price >= 0.2 ether && _price < 0.3 ether) { return 1; }
        else if (_price >= 0.3 ether && _price < 0.4 ether) { return 2; }
        else if (_price >= 0.4 ether && _price < 0.5 ether) { return 3; }
        else if (_price >= 0.5 ether && _price < 0.6 ether) { return 4; }
        else if (_price >= 0.6 ether && _price < 0.7 ether) { return 5; }
        else if (_price >= 0.7 ether && _price < 0.8 ether) { return 6; }
        else if (_price >= 0.8 ether && _price < 0.9 ether) { return 7; }
        else if (_price >= 0.9 ether && _price <= 1 ether) { return 8; }
        else { return 0; }
    }
    
    function _baseURI() internal view override returns (string memory) {
        return m_baseURI;
    }

}