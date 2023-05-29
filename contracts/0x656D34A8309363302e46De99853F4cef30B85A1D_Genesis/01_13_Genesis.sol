// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract Genesis is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Total number of tokenIds minted
    uint256 public tokenIDs = 6;

    // Variables for metadata links
    string _baseTokenURI;

    // Variables for the token
    // Constant number for how many NFTs an address is allowed to mint.
    uint256 private constant maxNumberUserCanMint = 3;
    // Max Supply of the NFT
    uint256 public constant maxSupply = 8888;
    uint256 public ownerMints = 0;
    uint256 public constant ownerMintsMax = 201;

    address public crossmintAddress;

    // Constant values
    uint256 public constant costPerToken = 0.08 ether;

    // public key for signing
    address internal constant publicKey = 0xFCDD24e44A8c669c2798394fc7091b84D360d916;

    // This is ESG's Gnosis Safe Wallet
    address public constant legendaryWallet = 0x4AAe0981Ec489eE1710C6cB1F6b203ab6e020754; 

    constructor() ERC721('R Planet', 'RPlanet') {
        _safeMint(legendaryWallet, 1);
        _safeMint(legendaryWallet, 2);
        _safeMint(legendaryWallet, 3);
        _safeMint(legendaryWallet, 4);
        _safeMint(legendaryWallet, 5);
        _safeMint(legendaryWallet, 6);
        _baseTokenURI = 'https://rplanet-placeholder.s3.amazonaws.com/metadata/';
        setCrossmintAddress(0xdAb1a1854214684acE522439684a145E62505233);

        _transferOwnership(0x962c53CC0d27Bc962b68E25bA51E2e412Bf5ff91);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }

    // Function to make sure we still have NFTs in stock prior to minting
    modifier isMintValid(uint256 count) {
        require(tokenIDs <= maxSupply, 'No tokenIDs left!');
        require(balanceOf(msg.sender) <= maxNumberUserCanMint && count <= maxNumberUserCanMint, 'A user can only mint 3 NFTs!');
        require(msg.value >= costPerToken * count, 'Value of funds not correct!');
        _;
    }

    function mint(
        uint256 count,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable isMintValid(count) {
        // Verify that the signature was signed using our server private key
        require(verifySignedAddress(_v, _r, _s), 'Unable to verify server signature!');

        for (uint i = 0; i < count; i++) {
            tokenIDs++;
            _safeMint(msg.sender, tokenIDs);
        }

        require(balanceOf(msg.sender) <= maxNumberUserCanMint, 'A user can only mint 3 NFTs!');
    }

    function crossmint(address mintTo, uint256 _count) public payable {
        require(costPerToken * _count >= msg.value, "Incorrect ETH value sent");
        require(tokenIDs + _count <= maxSupply, "No more left");
        require(balanceOf(mintTo) <= maxNumberUserCanMint && _count <= maxNumberUserCanMint, 'A user can only mint 3 NFTs!');

        // 0xdAb1a1854214684acE522439684a145E62505233
        require(msg.sender == crossmintAddress,
            "This function is for Crossmint only."
        );

        for (uint i = 0; i < _count; i++) {
            tokenIDs++;
            _safeMint(mintTo, tokenIDs);
        }

        require(balanceOf(mintTo) <= maxNumberUserCanMint, 'A user can only mint 3 NFTs!');
    }

    // The Project Management team will be participating in the private
    // sale and will be minting NFTs for team allocation, partner appreciation,
    // corp treasury, and partnership allocations.
    function ownerOnlyMint(uint256 _count) public payable onlyOwner {
        ownerMints += _count;

        require(ownerMints <= ownerMintsMax, "no more mints");

        for (uint i = 0; i < _count; i++) {
            tokenIDs++;
            _safeMint(legendaryWallet, tokenIDs);
        }

        require(tokenIDs <= maxSupply, 'No tokenIDs left!');
    }


    // include a setting function so that you can change this later
    function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    // Function to verify that the signature was signed using our server private key
    function verifySignedAddress(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (bool) {
        if (uint256(_s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return false;
        }
        if (_v != 27 && _v != 28) {
            return false;
        }

        bytes memory prefix = '\x19Ethereum Signed Message:\n32';
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked(msg.sender))));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer == publicKey;
    }

    function withdraw() public onlyOwner payable {
        (bool os, ) = legendaryWallet.call{value: address(this).balance}('');
        require(os, 'Withdraw unsuccessful');
    }
}