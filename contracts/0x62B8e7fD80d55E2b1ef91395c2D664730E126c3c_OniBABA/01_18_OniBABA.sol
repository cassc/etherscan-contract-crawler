// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OniBABA is ERC721, ERC721Enumerable, Pausable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PER_MINT = 5;

    uint256 public price = 0.0 ether;
    uint256 public preSalePrice = 0.0 ether;

    string public baseTokenURI;
    uint256 public startTokenURIID;

    bytes32 private _whitelistMerkleRoot;

    // keep track of those on whitelist who have claimed their NFT
    mapping(address => bool) public claimed;

    address public moderator;

    // Starting and stopping sale, presale and whitelist
    bool public saleActive = false;
    bool public presaleActive = false;

    constructor() ERC721("Oni-babaNFT", "onibaba") {}

    modifier onlyModerator() {
        require(msg.sender == moderator || msg.sender == owner());
        _;
    }

    function pause() public onlyModerator {
        _pause();
    }

    function unpause() public onlyModerator {
        _unpause();
    }

    function safeMint(address to) public onlyModerator {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyModerator {
        baseTokenURI = _baseTokenURI;
    }

    function setStartURIID(uint256 _startTokenURIID) public onlyModerator {
        startTokenURIID = _startTokenURIID;
    }

    function setModerator(address _moderator) public onlyOwner {
        moderator = _moderator;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        uint256 id = startTokenURIID + tokenId;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, id.toString()))
                : "";
    }

    // The following functions are used for minting

    function setPrice(uint256 newPrice) public onlyModerator {
        price = newPrice;
    }

    function setPresalePrice(uint256 newPrice) public onlyModerator {
        preSalePrice = newPrice;
    }

    // Start and stop presale
    function setPresaleActive(bool val) public onlyModerator {
        presaleActive = val;
        if (val) saleActive = false;
    }

    // Start and stop sale
    function setSaleActive(bool val) public onlyModerator {
        saleActive = val;
        if (val) presaleActive = false;
    }

    function setWhitelistMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyModerator
    {
        _whitelistMerkleRoot = _newMerkleRoot;
    }

    function _mintSingleNFT() private {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();
    }

    function preSale(bytes32[] memory proof, uint256 amount) external payable {
        uint256 totalMinted = _tokenIdCounter.current();
        uint256 preSaleMaxMint = 5;

        require(presaleActive, "Presale isn't active");
        require(totalMinted.add(amount) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(
            amount > 0 && amount <= preSaleMaxMint,
            "Cannot mint specified number of NFTs."
        );
        require(
            msg.value >= preSalePrice.mul(amount),
            "Not enough ether to purchase NFTs."
        );

        // merkle tree list related
        require(_whitelistMerkleRoot != "", "Merkle tree root not set");
        require(
            MerkleProof.verify(
                proof,
                _whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, amount))
            ),
            "Presale validation failed"
        );
        require(!claimed[msg.sender], "NFT is already claimed by this wallet");

        for (uint256 i = 0; i < amount; i++) {
            _mintSingleNFT();
        }

        claimed[msg.sender] = true;
    }

    function mintNFTs(uint256 amount) public payable {
        uint256 totalMinted = _tokenIdCounter.current();

        require(saleActive, "Sale isn't active");
        require(totalMinted.add(amount) <= MAX_SUPPLY, "Not enough NFTs left!");
        require(
            amount > 0 && amount <= MAX_PER_MINT,
            "Cannot mint specified number of NFTs."
        );
        require(
            msg.value >= price.mul(amount),
            "Not enough ether to purchase NFTs."
        );

        for (uint256 i = 0; i < amount; i++) {
            _mintSingleNFT();
        }
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        require(payable(msg.sender).send(balance));
    }
}