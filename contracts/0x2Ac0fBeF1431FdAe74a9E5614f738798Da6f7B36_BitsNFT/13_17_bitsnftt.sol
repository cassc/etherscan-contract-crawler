// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract BitsNFT is ERC721AQueryable, Ownable, ReentrancyGuard {
    /* 011000100110100101110100011100110110111001100110011101000110001001101111011100100110111001101001011011100110010101110100011010000111001001100101011000100110111101110010011011100110100101101110011000100111010001100011
     011101110110010101101100011010010110101101100101011101000110111101110000011000010111100101100111011000010111001101100110011011110111001001101101011001010111001101110011011000010110011101100101011100110111010001101000011000010111010001101110011011110110111101101110011001010111001001100101011000010110010001110011
     01100010011101010111010001101001011001100111100101101111011101010110001101110010011000010110001101101011011101000110100001101001011100110110001101101111011011100110011101110010011000010111010001111010011100110110010101101110011001000111010101110011011000010110010001101101011011110111001001110011011011110110110101100101011101000110100001101001011011100110011101110100011011110110001101101100011000010110100101101101011110010110111101110101011100100110100101101110011100110110001101110010011010010111000001110100011010010110111101101110
     01110011011011110111001101101001011011010111000001101100011001010111100101100101011101000111001101101111011001010110011001100110011001010110001101110100011010010111011001100101 */
    using Strings for uint256;
    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(address => bool) public freeMintClaimed;
    string public uriPrefix = '';
    string public uriSuffix = '.json';
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    bool public paused = true;
    bool public whitelistMintEnabled = false;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
    }

    // Modifiers
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        _;
    }

    modifier mintPriceComplianceBitlist(uint256 _mintAmount) {
        uint256 requiredValue = cost * _mintAmount;

        if (!freeMintClaimed[_msgSender()]) {
            requiredValue -= cost;
        }

        require(msg.value >= requiredValue, 'Insufficient funds!');
        _;
    }

    function whitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable mintCompliance(_mintAmount) mintPriceComplianceBitlist(_mintAmount) {
        require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
        require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        if (freeMintClaimed[_msgSender()] == false && _mintAmount <= 3) {
            freeMintClaimed[_msgSender()] = true;
            _safeMint(_msgSender(), 1);
            _mintAmount -= 1;
        }

        if (_mintAmount == 0) {
            return;
        }

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        require(!paused, 'The contract is paused!');

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : '';
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}