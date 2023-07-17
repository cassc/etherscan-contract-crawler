// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseOpenSea {
    // string private _contractURI;
    address private _proxyRegistry;

    function proxyRegistry() public view returns (address) {
        return _proxyRegistry;
    }

    function isOwnersOpenSeaProxy(address owner, address operator)
        public
        view
        returns (bool)
    {
        address proxyRegistry_ = _proxyRegistry;

        if (proxyRegistry_ != address(0)) {
            if (block.chainid == 1 || block.chainid == 4) {
                return
                    address(ProxyRegistry(proxyRegistry_).proxies(owner)) ==
                    operator;
            } else if (block.chainid == 137 || block.chainid == 80001) {
                return proxyRegistry_ == operator;
            }
        }

        return false;
    }

    function _setOpenSeaRegistry(address proxyRegistryAddress) internal {
        _proxyRegistry = proxyRegistryAddress;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Doozuki is ERC721, Ownable, BaseOpenSea {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 private _merkleRoot;

    uint256 public constant maxSupply = 3333;
    uint256 public constant maxFreeMint = 300;
    uint256 public constant maxReserved = 0;
    uint256 private constant presalePrice = 0 ether;
    uint256 public constant publicMintPrice = 0.033 ether;
    uint256 private constant maxMintsPerAddressFree = 1;
    uint256 private constant maxMintsPerAddressSale = 8;
    uint256 private constant reservedAmount = 8;
    uint256 public reservedMintAmount;
    uint256 public freeMintAmount;
    uint256 public constant freemintStartDate = 1643570937;
    uint256 public constant freemintEndDate = 1643640000;
    uint256 public constant saleStartDate = 1643381100;
    string private baseUri =
        "https://gateway.pinata.cloud/ipfs/QmenEuiZf6YHt9uSvx8iidhkd5ZFGasabX29RXWsKV7hcq/";
    string private baseExtension = ".json";

    mapping(address => uint256) public mintedTokensByAddress;
    mapping(address => uint256) public freemintedbyaddress;

    constructor(address openSeaProxyRegistry, bytes32 root)
        ERC721("Doozuki", "DZK")
    {
        // rinkeby: 0xf57b2c51ded3a29e6891aba85459d600256cf317
        // mainnet: 0xa5409ec958c83c3f309868babaca7c86dcb077c1
        if (openSeaProxyRegistry != address(0)) {
            _setOpenSeaRegistry(openSeaProxyRegistry);
        }
        _merkleRoot = root;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    function isFreeMintOpen() public view returns (bool) {
        if (
            block.timestamp >= freemintStartDate &&
            block.timestamp <= freemintEndDate
        ) {
            return true;
        } else {
            return false;
        }
    }

    function isSaleOpen() public view returns (bool) {
        // if (block.timestamp >= saleStartDate) {
        if (block.timestamp >= freemintEndDate + 30 minutes) {
            return true;
        } else {
            return false;
        }
    }

    function freeMint(uint256 amount) external onlyEOA {
        require(isFreeMintOpen(), "Free Mint session close");
        require(freeMintAmount <= maxFreeMint, "Free Mint Stock Unavailable");
        require(
            (amount > 0) && (amount <= maxMintsPerAddressFree),
            "Incorrect amount"
        );
        require(totalSupply() + amount <= maxSupply, "Max Supply reached");
        require(
            mintedTokensByAddress[msg.sender] + amount <=
                maxMintsPerAddressFree,
            "Max per address"
        );
        mintedTokensByAddress[msg.sender] += 1;
        freeMintAmount += 1;
        _mintToken(msg.sender, amount);
    }

    function saleMint(uint256 amount) external payable onlyEOA {
        require(isSaleOpen(), "Sale not open");
        if (
            freemintedbyaddress[msg.sender] < maxMintsPerAddressFree &&
            freeMintAmount < maxFreeMint
        ) {
            require(
                totalSupply() + amount + 1 <= maxSupply,
                "Max Supply reached"
            );
            require(
                (amount > 0) && (amount <= maxMintsPerAddressSale + 1),
                "Incorrect amount"
            );
            require(
                msg.value >= publicMintPrice * amount,
                "Incorrect Price sent"
            );
            freeMintAmount += 1;
            freemintedbyaddress[msg.sender] += 1;
            mintedTokensByAddress[msg.sender] += amount + 1;
            _mintToken(msg.sender, amount + 1);
        } else {
            require(totalSupply() + amount <= maxSupply, "Max Supply reached");
            require(
                (amount > 0) && (amount <= maxMintsPerAddressSale),
                "Incorrect amount"
            );
            require(
                mintedTokensByAddress[msg.sender] + amount <=
                    maxMintsPerAddressSale,
                "Max per address"
            );
            require(
                msg.value >= publicMintPrice * amount,
                "Incorrect Price sent"
            );
            mintedTokensByAddress[msg.sender] += amount;

            _mintToken(msg.sender, amount);
        }
    }

    function mintReserved(bytes32[] calldata proof) external onlyEOA {
        require(verifyWhitelist(proof, _merkleRoot), "Not whitelisted");
        require(
            reservedMintAmount + reservedAmount <= maxReserved,
            "Reserved Mint Stock Unavailable"
        );
        require(
            mintedTokensByAddress[msg.sender] + reservedAmount <=
                maxMintsPerAddressSale,
            "Max per address"
        );

        require(
            totalSupply() + reservedAmount <= maxSupply,
            "Max Supply reached"
        );
        mintedTokensByAddress[msg.sender] += reservedAmount;
        _mintToken(msg.sender, reservedAmount);
    }

    function _mintToken(address to, uint256 amount) private {
        uint256 id;
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            id = _tokenIds.current();
            _mint(to, id);
        }
    }

    function supplyLeft() public view returns (uint256) {
        return maxSupply - totalSupply();
    }

    function reservedLeft() public view returns (uint256) {
        return maxReserved - reservedMintAmount;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory _tokenURI = "Token with that ID does not exist.";
        if (_exists(tokenId)) {
            _tokenURI = string(
                abi.encodePacked(baseUri, tokenId.toString(), baseExtension)
            );
        }
        return _tokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function withdrawBalance() external onlyOwner {
        require(address(this).balance > 0, "Zero Balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(owner, operator) ||
            isOwnersOpenSeaProxy(owner, operator);
    }

    function verifyWhitelist(bytes32[] memory _proof, bytes32 _roothash)
        private
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_proof, _roothash, _leaf);
    }
}