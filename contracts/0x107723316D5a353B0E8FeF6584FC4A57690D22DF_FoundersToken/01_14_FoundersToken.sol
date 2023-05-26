// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract FoundersToken is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for string;

    string public baseURI;
    
    uint16 MAX_NUTS;
    uint8 dogeMints;
    uint8 nutMints;
    uint16 public totalSupply;

    bytes32 tripleNuts = 0x57cf187930c63df3da848b764bc684984803f6918994ac6331ed91ff79d9b2b9;
    bytes32 doubleDoge = 0xd5f1adbbdb3da0e7acb311c235c2051ea1bc7ffa030336690e1baa62df340147;
    bytes32 singleDoge = 0x5d7edc6c4a0eeb2bb3b4d6f3b825c9b6b09e3b06da8b77b23beb0c8345eee401;

    // After whitelist, single mints
    bytes32 singlesNuts = 0x63131604734e0f9dbcb268b5f330b040020701d72d91bbc82eef7c71b1445e34;



    address proxyRegistryAddress;
    
    mapping(address => uint8) public alreadyMintedNutsWhitelist;
    mapping(address => uint8) public alreadyMintedDogeSingleWhitelist;
    mapping(address => uint8) public alreadyMinteDogeDoubleWhitelist;
    mapping(address => uint8) public alreadyMintedSingleNutsWhitelist;

    uint256 mintPrice = 1 ether;

    bool public whitelistMinting;
    bool public publicMinting;
    bool public lotteryMinting;

    constructor(address _proxyRegistryAddress) ERC721("FoundersToken", "FT") {
        proxyRegistryAddress = _proxyRegistryAddress;
        whitelistMinting = false;
        publicMinting = false;
        lotteryMinting = false;
        baseURI = "https://storage.googleapis.com/founders-token/Founders/Json/";
        MAX_NUTS = 420;
        dogeMints = 0;
        totalSupply = 0;
        nutMints = 0;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        address wallet = 0x67bceE2C58bcB26fEEeb7bb084605b508Bb55425;
        payable(wallet).transfer(balance);
    }

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function nutWhitelistMinting(uint8 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + amount <= 400, "Purchase would exceed max supply");
        require(nutMints + amount <= 200, "Nut whitelist minting has been capped.");

        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(alreadyMintedNutsWhitelist[msg.sender] + amount <= 3, "3 mints maximum.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, tripleNuts, leaf), "Address not whitelisted");
    

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
            nutMints += 1;
        }
        alreadyMintedNutsWhitelist[msg.sender] += amount;
    }

    function nutLotteryMinting(bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(lotteryMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + 1 <= 400, "Purchase would exceed max supply");
        require(mintPrice <= msg.value, "Ether value sent is not correct");

        require(alreadyMintedSingleNutsWhitelist[msg.sender] == 0, "Maximum 1 mint");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, singlesNuts, leaf), "Address not whitelisted");

        _safeMint(msg.sender, totalSupply + 1);
        totalSupply += 1;

        alreadyMintedSingleNutsWhitelist[msg.sender] += 1;
    }

    function dogeDoubleWhitelist(uint8 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + amount <= 400, "Purchase would exceed max supply");
        require(dogeMints + amount <= 200, "Doge whitelist minting has been capped.");

        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(alreadyMinteDogeDoubleWhitelist[msg.sender] + amount <= 2, "2 mints maximum.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, doubleDoge, leaf), "Address not whitelisted");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
            dogeMints += 1;
        }
        alreadyMinteDogeDoubleWhitelist[msg.sender] += amount;
    }

    function dogeSingleWhitelist(uint8 amount, bytes32[] calldata _merkleProof) external payable nonReentrant {
        require(whitelistMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + amount <= 400, "Purchase would exceed max supply");
        require(dogeMints + amount <= 200, "Doge whitelist minting has been capped.");

        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");
        require(alreadyMintedDogeSingleWhitelist[msg.sender] + amount <= 1, "3 mints maximum.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, singleDoge, leaf), "Address not whitelisted");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
            dogeMints += 1;
        }
        alreadyMintedDogeSingleWhitelist[msg.sender] += amount;
    }


    function publicMint(uint8 amount) external payable nonReentrant {
        require(publicMinting, "Whitelist minting isn't allowed yet");
        require(totalSupply + amount <= 400, "Purchase would exceed max supply");
        require(mintPrice.mul(amount) <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply + 1);
            totalSupply += 1;
        }
    }


    function mint(address _address, uint256 amount) public onlyOwner {
        require(totalSupply + 1 < MAX_NUTS, "All nuts have already been minted!");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_address, totalSupply + 1);
            totalSupply += 1;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return string(abi.encodePacked(_baseURI(), uint2str(tokenId), ".json"));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setWhitelistMinting(bool enabled) external onlyOwner {
        whitelistMinting = enabled;
    }

    function setPublicMinting(bool enabled) external onlyOwner {
        publicMinting = enabled;
    }

    function setLotteryMinting(bool enabled) external onlyOwner {
        lotteryMinting = enabled;
    }


    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

     /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev override transfer to prevent transfer of calimed tokens
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}