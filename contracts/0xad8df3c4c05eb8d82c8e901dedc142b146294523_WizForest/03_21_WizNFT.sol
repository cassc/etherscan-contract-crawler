// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import 'erc721a/contracts/ERC721A.sol';

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract WizNFT is Ownable, ERC721A {
    using ECDSA for bytes32;

    uint256 public constant maxTokenSupply = 10000;
    uint256 public constant tokenPrice = 0;
    uint public constant maxPerWallet = 1;

    bool public isPublicSale;
    string private baseMetadataUri;
    address private openSeaRegistryAddress;
    mapping(address => bool) private altarOfSacrifice;
    mapping(address => uint) private mintedPerAddress;

    constructor() ERC721A('WizNFT', 'WZNFT') {}

    function mint(bytes calldata proof) public payable {
        require(totalSupply() + 1 <= maxTokenSupply, "Cannot exceed total supply");
        if (_msgSender() != owner()) {
            require(isValidProof(_msgSender(), proof), "User has no valid proof");
            require(isPublicSale, "Sale has not started");
            require(mintedPerAddress[_msgSender()] + 1 <= maxPerWallet, "Cannot exceed max mint per wallet");
            require(tokenPrice <= msg.value, "Not enough eth for mint");
        }
        mintedPerAddress[_msgSender()] += 1;
        _safeMint(_msgSender(), 1);
    }

    function mintWhitelist(bytes calldata proof) public payable {
        require(isValidProof(_msgSender(), proof), "User has no valid proof");
        require(mintedPerAddress[_msgSender()] + 1 <= maxPerWallet, "Cannot exceed max mint per wallet");
        require(totalSupply() + 1 <= maxTokenSupply, "Cannot exceed total supply");
        mintedPerAddress[_msgSender()] += 1;
        _safeMint(_msgSender(), 1);
    }

    function mintFromAltar(address a, uint quantity) public onlyAltars {
        mintedPerAddress[a] += quantity;
        _safeMint(a, quantity);
    }

    function burnFromAltar(uint256 tokenId) public onlyAltars {
        require(_exists(tokenId), 'Token does not exist');
        _burn(tokenId);
    }

    function setBaseMetadataUri(string memory a) public onlyOwner {
        baseMetadataUri = a;
    }

    function setOpenSeaRegistryAddress(address a) public onlyOwner {
        openSeaRegistryAddress = a;
    }

    function startPublicSale() public onlyOwner {
        isPublicSale = true;
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        ProxyRegistry openSeaRegistry = ProxyRegistry(openSeaRegistryAddress);

        if (address(openSeaRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (altarOfSacrifice[operator]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseMetadataUri;
    }

    function addAltar(address a) public onlyOwner {
        altarOfSacrifice[a] = true;
    }

    function removeAltar(address a) public onlyOwner {
        altarOfSacrifice[a] = false;
    }

    modifier onlyAltars() {
        require(altarOfSacrifice[_msgSender()], 'Not an altar of sacrifice');
        _;
    }

    function isValidProof(address a, bytes memory proof) internal returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(a));
        return owner() == data.toEthSignedMessageHash().recover(proof);
    }
}