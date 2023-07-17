//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MillionaireRow is ERC721A, Ownable, PaymentSplitter {
    bool public presaleActive = false;
    bool public whitelistSaleActive = false;
    bool public saleActive = false;

    string internal baseTokenURI;

    uint256 public price = 0.15 ether;
    uint256 public maxSupply = 4444;
    uint256 public maxTx = 10;
    uint256 public maxPerWallet = 10;

    bytes32 internal merkleRoot;

    uint256 private teamLength;

    constructor(
        address[] memory _team,
        uint256[] memory _teamShares,
        bytes32 _merkleRoot,
        string memory _baseTokenURI
    ) ERC721A("MillionaireRow", "MROW") PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseTokenURI = _baseTokenURI;
        teamLength = _team.length;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleWhitelistActive() external onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function setMaxTx(uint256 newMax) external onlyOwner {
        maxTx = newMax;
    }

    function setMaxPerWallet(uint256 newMax) external onlyOwner {
        maxPerWallet = newMax;
    }

    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokens = new uint256[](balanceOf(_owner));
        uint256 ctr = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                tokens[ctr] = i;
                ctr++;
            }
        }
        return tokens;
    }

    function giveaway(address[] calldata adds, uint256 qty) external onlyOwner {
        uint256 minted = totalSupply();
        require(
            (adds.length * qty) + minted <= maxSupply,
            "Value exceeds total supply"
        );
        for (uint256 i = 0; i < adds.length; i++) {
            _safeMint(adds[i], qty);
        }
    }

    function mintPresale(uint256 qty) external payable canMint(qty, 0) {
        _safeMint(msg.sender, qty);
    }

    function mintWhitelist(uint256 qty, bytes32[] calldata _merkleProof)
        external
        payable
        canMint(qty, 1)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Address not on the whitelist"
        );
        _safeMint(msg.sender, qty);
    }

    function mint(uint256 qty) external payable canMint(qty, 2) {
        _safeMint(msg.sender, qty);
    }

    function releaseAll() external onlyOwner {
        for (uint256 i = 0; i < teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    // Modifiers
    modifier canMint(uint256 qty, uint256 mintType) {
        if (mintType == 0) {
            require(presaleActive, "Presale isn't active");
            require(
                qty + totalSupply() <= 100,
                "Value exceeds total presale supply"
            );
        } else if (mintType == 1) {
            require(whitelistSaleActive, "Whitelist sale isn't active");
        } else {
            require(saleActive, "Sale isn't active");
        }
        require(
            _numberMinted(msg.sender) + qty <= maxPerWallet,
            "Exceeds max mints for wallet"
        );
        require(qty <= maxTx && qty > 0, "Qty of mints not allowed");
        require(qty + totalSupply() <= maxSupply, "Value exceeds total supply");
        require(msg.value == price * qty, "Invalid value");
        _;
    }
}