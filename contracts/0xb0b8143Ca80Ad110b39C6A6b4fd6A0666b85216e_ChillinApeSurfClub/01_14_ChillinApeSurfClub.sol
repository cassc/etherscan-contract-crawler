// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChillinApeSurfClub is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;

    Counters.Counter private _tokenIdCounter;
    uint public constant MAX_TOKENS = 2500;

    bool public revealed = false;
    string public notRevealedURI = 'https://api.chillinapesurfclub.com/tokens/0.json';
    string public baseURI = 'https://api.chillinapesurfclub.com/tokens/';
    string public baseExtension = '.json';

    bool public freeMintActive = false;
    mapping(address => uint) public freeWhitelist;

    bool public presaleMintActive = false;
    uint public presalePrice = 0.05 ether;
    uint public presaleMaxMint = 3;
    bytes32 public presaleWhitelist = 0x06cc5af35f40ebf87b2e70c0c7430a0ab2335be9ecd995b7cbef0c95337257ea;
    mapping(address => uint) public presaleClaimed;

    bool public publicMintActive = false;
    uint public publicPrice = 0.08 ether;
    uint public publicMaxMint = 5;

    mapping(address => bool) public owners;
    address[4] public withdrawAddresses = [
        0xE5D63D77E908Bf91F49C75A14F4437EA9c80d33c,
        0x391E02C23a04B59110Af9f0Cc446DF406A813934,
        0x62082343631C4aaED61FFEE138DE6750A5995e37,
        0xf1a314DB5e8361311624eb957042D82e2d4911c0
    ];
    uint[4] public withdrawPercentages = [2500, 2500, 2500, 2500];

    constructor() ERC721('Chillin Ape Surf Club', 'CASC') {
        owners[msg.sender] = true;
        owners[0xE5D63D77E908Bf91F49C75A14F4437EA9c80d33c] = true;
        owners[0x391E02C23a04B59110Af9f0Cc446DF406A813934] = true;
        owners[0x62082343631C4aaED61FFEE138DE6750A5995e37] = true;
    }


    // Owner methods.
    function safeMint(address to, uint _mintAmount) public onlyOwner {
        require(_mintAmount > 0, 'Invalid mint amount.');
        require(_mintAmount <= 50, 'Mint amount exceeded.');
        require(_tokenIdCounter.current() + _mintAmount < MAX_TOKENS, 'Max amount reached.');
        for (uint i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }


    // Sales status methods.
    function setMintStatus(bool _freeMintActive, bool _presaleMintActive, bool _publicMintActive) public onlyOwners {
        freeMintActive = _freeMintActive;
        presaleMintActive = _presaleMintActive;
        publicMintActive = _publicMintActive;
    }

    function getMintStatus() external view returns (bool[3] memory) {
        return [freeMintActive, presaleMintActive, publicMintActive];
    }

    function setMintConditions(uint _presalePrice, uint _presaleMaxMint, uint _publicPrice, uint _publicMaxMint) public onlyOwner {
        presalePrice = _presalePrice;
        presaleMaxMint = _presaleMaxMint;
        publicPrice = _publicPrice;
        publicMaxMint = _publicMaxMint;
    }

    function getMintConditions() external view returns (uint[4] memory) {
        return [presalePrice, presaleMaxMint, publicPrice, publicMaxMint];
    }


    // Mint methods.
    function freeMint(uint _mintAmount) external {
        require(freeMintActive, 'Free mint is not active.');
        require(_mintAmount > 0, 'Invalid mint amount.');
        require(_mintAmount <= freeWhitelist[msg.sender], 'Mint amount exceeded.');
        require(_tokenIdCounter.current() + _mintAmount <= MAX_TOKENS, 'Max amount reached.');

        freeWhitelist[msg.sender] -= _mintAmount;
        for (uint i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function presaleMint(bytes32[] calldata _proof, uint _mintAmount) external payable {
        require(presaleMintActive, 'Presale mint is not active.');
        require(_mintAmount > 0, 'Invalid mint amount.');
        require(_mintAmount + presaleClaimed[msg.sender] <= presaleMaxMint, 'Mint amount exceeded.');
        require(MerkleProof.verify(_proof, presaleWhitelist, keccak256(abi.encodePacked(msg.sender))), 'Invalid proof.');
        require(msg.value >= presalePrice * _mintAmount, 'Invalid price.');
        require(_tokenIdCounter.current() + _mintAmount <= MAX_TOKENS, 'Max amount reached.');

        presaleClaimed[msg.sender] += _mintAmount;
        for (uint i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function publicMint(uint _mintAmount) external payable {
        require(publicMintActive, 'Public mint is not active.');
        require(_mintAmount > 0, 'Invalid mint amount.');
        require(_mintAmount <= publicMaxMint, 'Mint amount exceeded.');
        require(msg.value >= publicPrice * _mintAmount, 'Invalid price.');
        require(_tokenIdCounter.current() + _mintAmount <= MAX_TOKENS, 'Max amount reached.');

        for (uint i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }

    function totalSupply() external view returns (uint) {
        return _tokenIdCounter.current();
    }

    // Lists methods.
    function addFreeWhitelist(address[] memory _users, uint[] memory _mints) external onlyOwner {
        require(_users.length > 0 && _users.length == _mints.length);
        for (uint i = 0; i < _users.length; i++) {
            freeWhitelist[_users[i]] = _mints[i];
        }
    }

    function removeFreeWhitelist(address[] memory _users) external onlyOwner {
        for (uint i = 0; i < _users.length; i++) {
            freeWhitelist[_users[i]] = 0;
        }
    }

    function availableFreeMints() external view returns (uint) {
        return freeWhitelist[msg.sender];
    }

    function setPresaleWhitelist(bytes32 _presaleWhitelist) external onlyOwner {
        presaleWhitelist = _presaleWhitelist;
    }

    function availablePresaleMints() external view returns (uint) {
        if (presaleClaimed[msg.sender] > presaleMaxMint) {
            return 0;
        }

        return presaleMaxMint - presaleClaimed[msg.sender];
    }

    // Token methods.
    function setRevealed(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setNotRevealedURI(string calldata _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function setBaseURI(string calldata _baseURI, string calldata _baseExtension) external onlyOwner {
        baseURI = _baseURI;
        baseExtension = _baseExtension;
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        if (!revealed) {
            return notRevealedURI;
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension)) : notRevealedURI;
    }

    function tokensOfOwner(address owner) external view returns(uint[] memory) {
        uint[] memory tokens = new uint[](balanceOf(owner));
        uint index = 0;
        for (uint i = 1; i <= _tokenIdCounter.current(); i++) {
            if (ownerOf(i) == owner) {
                tokens[index++] = i;
            }
        }

        return tokens;
    }


    // Withdraw methods.
    function withdraw() public onlyOwners {
        uint balance = address(this).balance;
        require(balance > 0, 'Insufficient funds.');
        for (uint i = 0; i < withdrawAddresses.length; i++) {
            _withdraw(withdrawAddresses[i], SafeMath.div(SafeMath.mul(balance, withdrawPercentages[i]), 10000));
        }
    }

    function _withdraw(address _addr, uint _amt) private {
        (bool success,) = _addr.call{value: _amt}('');
        require(success, 'Withdraw failed.');
    }

    function emergencyWithdraw() external onlyOwner {
        require(block.timestamp >= 1651276800, 'Emergency withdraw not yet available.');
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}('');
        require(success, 'Withdraw failed.');
    }


    // Modifiers.
    modifier onlyOwners() {
        require(owners[msg.sender], 'Caller is not one of the owners');
        _;
    }
}