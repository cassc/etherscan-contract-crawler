//SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract WhoopsiesDoopsies is ERC721A, Ownable, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    bool private earlySaleStatus;
    bool private publicSaleStatus;
    bool public revealed;

    uint8 private constant PRESALE_MAX = 10;
    uint8 private constant PUBLIC_MAX = 20;
    uint8 private constant FOUNDERS_RESERVE = 200;
    uint16 private constant PUBLIC_COLLECTION_SIZE = 5925;

    Counters.Counter public _tokenIds;
    Counters.Counter public _reservedTokenIds;

    uint256 public mintPrice = 0.04 ether;
    string private baseURI;
    string private notRevealedURI;
    bytes32 private root;

    mapping(address => uint256) private allowListClaimed;
    mapping(address => uint256) private founderMintCountsRemaining;

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedURI,
        bytes32 _root, 
        address[] memory _payees, 
        uint256[] memory _shares
    ) ERC721A("WhoopsiesDoopsies", "WHOOPDOOP") PaymentSplitter(_payees, _shares) payable {
        baseURI = _initBaseURI;
        root = _root;
        notRevealedURI = _initNotRevealedURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setEarlySaleStatus(bool _earlySaleStatus) external onlyOwner {
        earlySaleStatus = _earlySaleStatus;
    }

    function getEarlySaleStatus() public view returns (bool) {
        return earlySaleStatus;
    }

    function setPublicSaleStatus(bool _publicSaleStatus) external onlyOwner {
        publicSaleStatus = _publicSaleStatus;
    }

    function getPublicSaleStatus() public view returns (bool) {
        return publicSaleStatus;
    }

    function setRoot(bytes32 _root) external onlyOwner nonReentrant {
        root = _root;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseURI(string memory _BaseURI) external onlyOwner {
        baseURI = _BaseURI;
    }

    function setPrice(uint256 _price) external onlyOwner nonReentrant {
        mintPrice = _price;
    }

    function allocateFounderMint(address _addr, uint256 _count)
        public
        onlyOwner
        nonReentrant
    {
        founderMintCountsRemaining[_addr] = _count;
    }

    function verify(
        bytes32 leaf,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function earlyMint(
        bytes32 leaf,
        bytes32[] memory proof,
        uint256 _count
    ) external payable nonReentrant {
        require(earlySaleStatus, "Early Sale is Closed");
        require(verify(leaf, proof), "Validation Failed");
        require(_count <= PRESALE_MAX, "Invalid Token Count");
        require(
            _tokenIds.current() + _count <= PUBLIC_COLLECTION_SIZE,
            "All Tokens Minted"
        );
        require(
            allowListClaimed[msg.sender] + _count <= PRESALE_MAX,
            "Exceeds Max Allowed"
        );
        require(_count * mintPrice == msg.value, "Incorrect Amount of Eth");

        for (uint256 i = 0; i < _count; i++) {
            _tokenIds.increment();
        }

        allowListClaimed[msg.sender] += _count;
        mint(_count);
    }

    function publicMint(uint256 _count)
        external
        payable
        nonReentrant
    {
        require(publicSaleStatus, "Public Sale is Closed!");
        require(_count <= PUBLIC_MAX, "Invalid Token Count");
        require(
            _tokenIds.current() + _count <= PUBLIC_COLLECTION_SIZE,
            "All Tokens Minted"
        );
        require(
            allowListClaimed[msg.sender] + _count <= PUBLIC_MAX,
            "Exceeds Max Allowed"
        );
        require(_count * mintPrice == msg.value, "Incorrect Amount of Eth");

        for (uint256 i = 0; i < _count; i++) {
            _tokenIds.increment();
        }

        allowListClaimed[msg.sender] += _count;
        mint(_count);
    }

    function founderMint(uint256 _count)
        public
        nonReentrant
    {
        require(
            _reservedTokenIds.current() + _count <= FOUNDERS_RESERVE,
            "All Reserved Tokens Minted"
        );
        require(
            founderMintCountsRemaining[msg.sender] >= _count,
            "Can't Mint More Tokens"
        );

        for (uint256 i = 0; i < _count; i++) {
            _reservedTokenIds.increment();
        }

        founderMintCountsRemaining[msg.sender] -= _count;
        mint(_count);
    }

    function mint(uint256 quantity) internal {
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedURI;
        }

        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
}