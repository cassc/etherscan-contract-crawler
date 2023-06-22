// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Froggie is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Where funds should be sent to
    address payable public payoutAddress;

    // Maximum supply of the NFT
    uint256 public maxSupply;

    // Maximum mints per transaction
    uint256 public maxPerTx;

    // Sale price
    uint256 public pricePer;
    uint256 public presalePricePer;

    // Is the sale enabled
    bool public sale = false;
    bool public presale = false;

    // baseURI for the metadata, eg ipfs://<cid>/
    string public baseURI;

    bytes32 public presaleRoot;

    // Presale settings
    mapping(address => uint256) private _presales;
    mapping(uint256 => bool) private _presaleWaveEnabled;
    mapping(uint256 => uint256) private _presaleWaveAllowedPer;

    constructor(address payable _payoutAddress, uint256 _maxSupply, uint256 _maxPerTx, uint256 _pricePer, uint256 _presalePricePer, string memory _uri) ERC721("Froggies", "FROGGIE") {
        payoutAddress = _payoutAddress;
        maxSupply = _maxSupply;
        maxPerTx = _maxPerTx;
        pricePer = _pricePer;
        presalePricePer = _presalePricePer;
        baseURI = _uri;
    }

    // Admin operations
    function updatePayoutAddress(address payable newPayoutAddress) external onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    function updateSale(bool _sale, bool _presale) external onlyOwner {
        sale = _sale;
        presale = _presale;
    }

    function updatePresaleWave(uint256 wave, bool enabled, uint256 allowedPer) external onlyOwner {
        _presaleWaveEnabled[wave] = enabled;
        _presaleWaveAllowedPer[wave] = allowedPer;
    }

    function updatePresaleRoot(bytes32 _presaleRoot) external onlyOwner {
        presaleRoot = _presaleRoot;
    }

    function updateBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function claimBalance() external onlyOwner {
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function preMint(address to, uint256 quantity) external onlyOwner {
        // Sale must NOT be enabled
        require(!sale, "Sale already in progress");
        require(!presale, "Presale already in progress");
        // Cannot mint zero quantity
        require(quantity != 0, "Requested quantity cannot be zero");
        // Cannot mint more than maximum supply
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    // End Admin operations

    // Presale operations
    function presaleWaveEnabled(uint256 wave) external view returns (bool) {
        return _presaleWaveEnabled[wave];
    }

    function canMintPresale(address to, uint256 quantity, uint256 wave, bytes32[] calldata proof) public view returns (bool) {
        require(presale, "Presale disabled");
        require(quantity != 0, "Requested quantity cannot be zero");
        require(_verify(_leaf(to, wave), proof), "Invalid Merkle Proof");
        require(_presaleWaveEnabled[wave], "Presale wave disabled");
        require(_presales[to] + quantity <= _presaleWaveAllowedPer[wave], "Presale limit reached");
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        return true;
    }

    function presaleMint(address to, uint256 quantity, uint256 wave, bytes32[] calldata proof) payable external {
        require(canMintPresale(to, quantity, wave, proof), "cannot mint presale");
        // Transaction must have at least quantity * price (any more is considered a tip)
        require(quantity * presalePricePer <= msg.value, "Not enough ether sent");
        // Cannot mint more than maximum supply
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        for (uint256 i = 0; i < quantity; i++) {
            _presales[to] += 1;
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function presaleMinted(address owner) external view returns (uint256) {
        return _presales[owner];
    }

    function _leaf(address account, uint256 wave) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, wave));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, presaleRoot, leaf);
    }
    // End Presale operations

    // Regular minting
    function safeMint(address to, uint256 quantity) payable external {
        // Sale must be enabled
        require(sale, "Sale disabled");
        // Cannot mint zero quantity
        require(quantity != 0, "Requested quantity cannot be zero");
        // Cannot mint more than maximum per operation
        require(quantity <= maxPerTx, "Requested quantity more than maximum");
        // Transaction must have at least quantity * price (any more is considered a tip)
        require(quantity * pricePer <= msg.value, "Not enough ether sent");
        // Cannot mint more than maximum supply
        require(_tokenIdCounter.current() + quantity <= maxSupply, "Total supply will exceed limit");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    // End Regular minting

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}