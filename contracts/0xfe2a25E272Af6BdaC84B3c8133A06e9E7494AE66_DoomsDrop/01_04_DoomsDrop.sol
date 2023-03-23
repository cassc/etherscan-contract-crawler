// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IDooms {
    function transferFrom(address from_, address to_, uint256 id_) external;
}

contract DoomsDrop is Ownable {
    error InvalidProof();
    error AllowedMintsExceeded();
    error InvalidAmount();
    error NotYet();
    error Nop();

    bytes32 private _root;
    mapping(address => uint256) private _minted;
    IDooms private immutable _dooms;

    uint256 public price = 0.25 ether;
    uint256 public maxPerWallet = 2;
    uint256 public nextTokenId = 300;
    bool public publicOpen;

    constructor(address dooms_) {
        _dooms = IDooms(dooms_);
    }

    modifier check(uint256 quantity_) {
        if (msg.sender != tx.origin) {
            revert Nop();
        }

        if (msg.value != quantity_ * price) {
            revert InvalidAmount();
        }

        if (_minted[msg.sender] + quantity_ > maxPerWallet) {
            revert AllowedMintsExceeded();
        }

        _;
    }

    // Public
    function mint(bytes32[] memory proof_, uint256 quantity_) external payable check(quantity_) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(proof_, _root, leaf)) {
            revert InvalidProof();
        }

        _mintBatch(msg.sender, quantity_);
    }

    function publicMint(uint256 quantity_) external payable check(quantity_) {
        if (!publicOpen) {
            revert NotYet();
        }

        _mintBatch(msg.sender, quantity_);
    }

    // Owner only
    function setMerkleRoot(bytes32 root_) external onlyOwner {
        _root = root_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    function setNextTokenId(uint256 nextTokenId_) external onlyOwner {
        nextTokenId = nextTokenId_;
    }

     function setPublicOpen(bool open_) external onlyOwner {
        publicOpen = open_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );

        require(success);
    }

    // Utils
    function _mintBatch(address to_, uint256 quantity_) private {
        unchecked {
            _minted[to_] += quantity_;

            for (uint256 i; i < quantity_; i++) {
                _dooms.transferFrom(address(this), to_, nextTokenId++);
            }
        }
    }
}