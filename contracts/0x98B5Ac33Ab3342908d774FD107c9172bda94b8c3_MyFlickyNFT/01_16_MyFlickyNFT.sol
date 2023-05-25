pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract MyFlickyNFT is ERC721A, Ownable, IERC2981 {
    using Counters for Counters.Counter;

    using SafeMath for uint256;

    mapping (address => uint256) private operatorCounts;

    string public baseURI = "ipfs://QmaVXsgQAmyhGMAqpQxpqZ8mCM4vihY6zMxt5SyBDmrceS/";
    bool public revealed = false;

    bool public allowlistOnly = true;

    address private royaltyReciever;

    string private constant ALLOWLIST_MINT = "ALLOWLIST_MINT";
    string private constant GENERAL_MINT = "GENERAL_MINT";
    string private constant MAP_MINT = "MAP_MINT";
    string private constant RESERVED_MINT = "RESERVED_MINT";

    uint256 private RESERVED_TOTAL = 180;
    uint256 private MAP_TOTAL = 500;
    uint256 private ALLOWLIST_TOTAL = 3475;
    uint256 private PUBLIC_MINT_TOTAL = 1400;

    uint256 public reservedCount = 0;
    uint256 public mapCount = 0;
    uint256 public allowlistCount = 0;
    uint256 public publicMintCount = 0;

    mapping (address => uint256) private numberMintedForAddress;

    function setTotals(uint256 _RESERVED_TOTAL, uint256 _MAP_TOTAL, uint256 _ALLOWLIST_TOTAL, uint256 _PUBLIC_MINT_TOTAL)
        public
        onlyOwner
    {
        RESERVED_TOTAL = _RESERVED_TOTAL;
        MAP_TOTAL = _MAP_TOTAL;
        ALLOWLIST_TOTAL = _ALLOWLIST_TOTAL;
        PUBLIC_MINT_TOTAL = _PUBLIC_MINT_TOTAL;
    }

    function getCounts() 
        public
        view
        returns (uint256, uint256, uint256, uint256) 
    {
        return (reservedCount, mapCount, allowlistCount, publicMintCount);
    }

    function getCost()
        public view
        returns (uint256)
    {
        if (allowlistOnly) {
            return 0.07 ether;
        } else {
            return 0.075 ether;
        }
    }

    function setAllowlistOnly(bool _allowlistOnly) 
        public 
        onlyOwner 
    {
        allowlistOnly = _allowlistOnly;
    }

    function getAllowlistState()
        public view
        returns (bool)
    {
        return allowlistOnly;
    }

    function getBaseURI() 
        public 
        view 
        returns (string memory) 
    {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI) 
        public 
        onlyOwner 
    {
        baseURI = _baseURI;
    }

    function setRevealed(bool _revealed) 
        public 
        onlyOwner 
    {
        revealed = _revealed;
    }

    function getRevealed() 
        public 
        view 
        returns (bool) 
    {
        return revealed;
    }

    
    function compareStrings(string memory a, string memory b) 
        public 
        pure 
        returns (bool) 
    {
        return (keccak256(bytes(a)) == keccak256(bytes(b)));
    }

    constructor() ERC721A("Flicky", "FLKY") {}

    function tokenURI(uint256 _tokenId) 
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = getBaseURI();
        uint256 metadataId = _tokenId + 1;

        if (revealed) {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(metadataId), ".json")) : "";
        } else {
            return baseURI_;
        }
    }

    function _incrementTypeCount(string memory _nftType)
        private
    {
        if (compareStrings(_nftType, ALLOWLIST_MINT)) {
            publicMintCount = publicMintCount.add(1);
            allowlistCount = allowlistCount.add(1);
        }
        if (compareStrings(_nftType, GENERAL_MINT)) {
            publicMintCount = publicMintCount.add(1);
        }
        if (compareStrings(_nftType, MAP_MINT)) {
            mapCount = mapCount.add(1);
        }
        if (compareStrings(_nftType, RESERVED_MINT)) {
            reservedCount = reservedCount.add(1);
        }
    }

    function _canTypeBeMinted(string memory _nftType)
        private
        view
        returns (bool)
     {
        if (compareStrings(_nftType, ALLOWLIST_MINT)) {
            if (allowlistCount < ALLOWLIST_TOTAL && publicMintCount < PUBLIC_MINT_TOTAL) {
                return true;
            } else {
                return false;
            }
        }
        require(!allowlistOnly, "Only allowlisted participants may mint");
        if (compareStrings(_nftType, GENERAL_MINT)) {
            if (publicMintCount < PUBLIC_MINT_TOTAL) {
                return true;
            } else {
                return false;
            }
        }
        if (compareStrings(_nftType, MAP_MINT)) {
            if (mapCount < MAP_TOTAL) {
                return true;
            } else {
                return false;
            }
        }
        if (compareStrings(_nftType, RESERVED_MINT)) {
            if (reservedCount < RESERVED_TOTAL) {
                return true;
            } else {
                return false;
            }
        }
        return false;
    }

    function mint(string memory _nftType)
        public
        payable
        returns (uint256)
    {      
        require(numberMintedForAddress[_msgSender()] < 10, "You may not mint more than 10");
        require(_canTypeBeMinted(_nftType), "The maximum amount of that type of Flicky have already been minted");
        require(msg.value >= getCost(), "Insufficient eth was paid");

        uint256 tokenId = _currentIndex;        
        _safeMint(_msgSender(), 1);
        _incrementTypeCount(_nftType);

        numberMintedForAddress[_msgSender()] = numberMintedForAddress[_msgSender()] + 1; 
        return tokenId;
    }

    function multipleMint(string[] memory _nftTypes, uint256 _numToMint)
        public
        payable
    {
        require(numberMintedForAddress[_msgSender()] + _numToMint <= 10, "You may not mint more than 10");
        require(_numToMint <= 10 && _numToMint > 0, "You may only mint between 1 and 10");
        require(msg.value >= (getCost() * _numToMint), "Insufficient eth was paid");
        uint256 tokenId = _currentIndex;
        for (uint i = 0; i < _numToMint; i++) {
            string memory nftType = _nftTypes[i];
            require(_canTypeBeMinted(nftType), "The maximum amount of that type of Flicky have already been minted");
            tokenId.add(1);
            _incrementTypeCount(nftType);
        }

        _safeMint(_msgSender(), _numToMint);
        numberMintedForAddress[_msgSender()] = numberMintedForAddress[_msgSender()] + _numToMint; 
    }

    //TODO check this for amount we want to mint
    function efficientBulkMintMapAndReservedNfts(address to)
        public
        onlyOwner
    {
        require(mapCount == 0);
        require(reservedCount == 0);
        reservedCount = 180;
        mapCount = 500;
        _safeMint(to, 1000);
    }

    function bulkMintMap(address to)
        public
        onlyOwner
    {
        require(mapCount == 0);
        mapCount = MAP_TOTAL;
        _safeMint(to, MAP_TOTAL);
    }

    function bulkMintReserved(address to)
        public
        onlyOwner
    {
        require(reservedCount == 0);
        reservedCount = RESERVED_TOTAL;
        _safeMint(to, RESERVED_TOTAL);
    }

    function bulkMintAirdrop(address to)
        public
        onlyOwner
    {
        _safeMint(to, 340);
    }

    function setRoyalityReciever(address _royaltyReceiver)
        public
        onlyOwner
    {
        royaltyReciever = _royaltyReceiver;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        override
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 basePercent = 500;
        uint256 fivePercent = SafeMath.div(SafeMath.mul(salePrice, basePercent), 10000);
        return (royaltyReciever, fivePercent);
    }


    function setApprovalForAll(address operator, bool approved) 
        public 
        virtual 
        override 
    {
        super.setApprovalForAll(operator, approved);
        operatorCounts[_msgSender()] = operatorCounts[_msgSender()].add(1);
    }

    function resetOperatorApprovals(address[] memory _operatorsToReset) 
        public 
    {
        require(operatorCounts[_msgSender()] > 0, "Operator approvals must be greater than 0");
        for (uint256 i = 0; i < _operatorsToReset.length; i++) {
            require(super.isApprovedForAll(_msgSender(), _operatorsToReset[i]), "Operator must be approved to rest");
            super.setApprovalForAll(_operatorsToReset[i], false);
            operatorCounts[_msgSender()] = operatorCounts[_msgSender()].sub(1);
        }
    }

    function getOperatorCount() public view returns (uint256) {
        return operatorCounts[_msgSender()];
    }

    function withdraw() 
        public 
        onlyOwner 
    {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}