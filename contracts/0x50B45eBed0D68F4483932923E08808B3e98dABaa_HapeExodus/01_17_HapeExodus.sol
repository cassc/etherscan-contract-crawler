// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721.sol";

/* IF YOU READ THIS IT MEANS YOU GMI <3 */

contract HapeExodus is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public mintPrice = 0.04 ether;

    uint256 public maxPerTransaction = 20;
    uint256 public maxPerWallet = 100;
    uint256 public maxTotalSupply = 8192;

    uint256 public freeMintSupply = 3000;
    uint256 public freeMintCount = 0;

    bool public isSaleOpen = false;
    bool public isFreeForWhitelistedOnly = false;

    string public baseURI;

    address private vaultAddress = address(0);
    bytes32 private merkleRoot;

    mapping(address => uint256) public mintsPerWallet;

    constructor(string memory name, string memory symbol, address _vaultAddress) ERC721(name, symbol) {
        vaultAddress = _vaultAddress;
    }

    function mint(uint256 _amount, bytes32[] memory _whitelistProof) external payable nonReentrant {
        require(isSaleOpen, "Sale not open");
        require(_amount > 0, "Must mint at least one");
        require(_amount <= maxPerTransaction, "Exceeds max per transaction");
        require(totalSupply().add(_amount)<= maxTotalSupply, "Exceeds max total supply");

        uint256 walletCount = mintsPerWallet[_msgSender()];
        require(_amount.add(walletCount) <= maxPerWallet, "Exceeds max per wallet");

        uint256 availableFreeMintCount = freeMintCountForAddress(_msgSender(), _whitelistProof);
        require(mintPrice.mul(_amount.sub(availableFreeMintCount)) <= msg.value, "Ether value sent is not correct");
        if (availableFreeMintCount > 0) {
            freeMintCount++;
        }

        for (uint256 i = 0; i < _amount; i++) {
            mintsPerWallet[_msgSender()] = mintsPerWallet[_msgSender()].add(1);
            _safeMint(_msgSender());
        }
    }

    function freeMint(bytes32[] memory _whitelistProof) external nonReentrant {
        require(isSaleOpen, "Sale not open");
        require(totalSupply().add(1) <= maxTotalSupply, "Exceeds max total supply");

        uint256 availableFreeMintCount = freeMintCountForAddress(_msgSender(), _whitelistProof);
        require(availableFreeMintCount > 0, "No free mints available");

        mintsPerWallet[_msgSender()] = mintsPerWallet[_msgSender()].add(1);
        freeMintCount++;

        _safeMint(_msgSender());
    }

    function freeMintCountForAddress(address _address, bytes32[] memory _whitelistProof) public view returns (uint256) {
        if (mintsPerWallet[_address] > 0) {
            return 0;
        }

        if (freeMintSupply <= freeMintCount) {
            return 0;
        }

        if (!isFreeForWhitelistedOnly) {
            return 1;
        }

        bytes32 addressBytes = keccak256(abi.encodePacked(_address));
        if (MerkleProof.verify(_whitelistProof, merkleRoot, addressBytes)) {
            return 1;
        }

        return 0;
    }

    function privateMint(uint256 _amount, address _receiver) external onlyOwner {
        require(_amount > 0, "Must mint at least one");
        require(totalSupply().add(_amount) <= maxTotalSupply, "Exceeds max total supply");

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_receiver);
        }
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Token not owned or approved");
        _burn(tokenId);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxTotalSupply(uint256 _maxValue) external onlyOwner {
        maxTotalSupply = _maxValue;
    }

    function setFreeMintSupply(uint256 _maxValue) external onlyOwner {
        freeMintSupply = _maxValue;
    }

    function setMaxPerTransaction(uint256 _maxValue) external onlyOwner {
        maxPerTransaction = _maxValue;
    }

    function setMaxPerWallet(uint256 _maxValue) external onlyOwner {
        maxPerWallet = _maxValue;
    }

    function setIsSaleOpen(bool _open) external onlyOwner {
        isSaleOpen = _open;
    }

    function setIsFreeForWhitelistedOnly(bool _state) external onlyOwner {
        isFreeForWhitelistedOnly = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() external onlyOwner {
        require(vaultAddress != address(0), "Vault address not set");

        uint256 contractBalance = address(this).balance;
        payable(vaultAddress).transfer(contractBalance);
    }

    function setVaultAddress(address _newVaultAddress) external onlyOwner {
        vaultAddress = _newVaultAddress;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}