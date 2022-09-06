// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import 'erc721a/contracts/ERC721A.sol';

//OpenSea ERC721Tradable
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract DoDoFrensNFT is Ownable, ERC721A {
    constructor() ERC721A('DoDoFrens', 'DODO') {}

    uint256 public constant __maxSupply = 8000;
    uint256 public constant __maxMintPerWallet = 1;
    uint256 public constant __mintPrice = 0;

    bool private __publicSaleActive;
    bool private __whitelistSaleActive;
    string private __tokenBaseURI;
    address private __openSeaRegistry;

    mapping(address => bool) private __wakumbas;
    mapping(address => uint256) private __minted;

    using ECDSA for bytes32;

    function isValidSignature(address addr, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(addr));
        return owner() == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function recover(address addr, bytes memory signature) public view onlyOwner returns (address) {
        bytes memory message = abi.encodePacked(addr);
        return keccak256(message).toEthSignedMessageHash().recover(signature);
    }

    function mint(bytes calldata signature) public payable {
        require(totalSupply() + 1 <= __maxSupply, 'Cannot exceed total supply');
        if (_msgSender() != owner()) {
            require(isValidSignature(_msgSender(), signature), 'Invalid signature');
            require(__publicSaleActive, 'Sale has not started');
            require(__minted[_msgSender()] + 1 <= __maxMintPerWallet, 'Cannot exceed max mint per wallet');
            require(__mintPrice <= msg.value, 'Not enough eth for mint');
        }
        __minted[_msgSender()] += 1;
        _safeMint(_msgSender(), 1);
    }

    function mintWL(bytes calldata signature) public payable {
        require(isValidSignature(_msgSender(), signature), 'Invalid signature');
        require(__whitelistSaleActive, 'Sale has not started');
        require(__minted[_msgSender()] + 1 <= __maxMintPerWallet, 'Cannot exceed max mint per wallet');
        require(totalSupply() + 1 <= __maxSupply, 'Cannot exceed total supply');
        __minted[_msgSender()] += 1;
        _safeMint(_msgSender(), 1);
    }

    function ritualOfSummon(address addr, uint256 quantity) public onlyWakumba {
        __minted[addr] += quantity;
        _safeMint(addr, quantity);
    }

    function sacraficeForHonor(uint256 tokenId) public onlyWakumba {
        require(_exists(tokenId), 'Token does not exist');
        _burn(tokenId);
    }

    function setTokenBaseURI(string memory baseUri) public onlyOwner {
        __tokenBaseURI = baseUri;
    }

    function setOpenSeaRegistry(address addr) public onlyOwner {
        __openSeaRegistry = addr;
    }

    function isPublicSaleActive() public view returns (bool) {
        return __publicSaleActive;
    }

    function isWhitelistSaleActive() public view returns (bool) {
        return __whitelistSaleActive;
    }

    function startPublicSale() public onlyOwner {
        __publicSaleActive = true;
    }

    function startWhitelistSale() public onlyOwner {
        __whitelistSaleActive = true;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        ProxyRegistry openSeaRegistry = ProxyRegistry(__openSeaRegistry);

        if (address(openSeaRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (__wakumbas[operator]) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function _baseURI() internal view override returns (string memory) {
        return __tokenBaseURI;
    }

    function addWakumba(address addr) public onlyOwner {
        __wakumbas[addr] = true;
    }

    function removeWakumba(address addr) public onlyOwner {
        __wakumbas[addr] = false;
    }

    modifier onlyWakumba() {
        require(__wakumbas[_msgSender()], 'No Wakumba to perform this ritual.');
        _;
    }
}