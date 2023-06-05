// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NftinitFounders is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 public MAX_SUPPLY = 120;

    uint256 public SALE_PRICE = 0.85 ether;

    uint256 public MAX_PER_WL = 2;
    uint256 public MAX_PER_TX = 2;

    //  0: INACTIVE, 1: PRE_SALE, 2: PUBLIC_SALE
    uint256 public SALE_STATE = 0;

    bytes32 private merkleRoot;

    mapping(address => uint256) whitelistMints;

    Counters.Counter private idTracker;

    string public baseURI;

    constructor() ERC721("NFTinit Founders", "INIT") {
        idTracker.increment();
    }

    function totalSupply() public view returns (uint256) {
        return idTracker.current() - 1;
    }

    function mintInternal(address addr) internal {
        _mint(addr, idTracker.current());
        idTracker.increment();
    }

    function ownerMint(uint256 amount) external onlyOwner {
        require(
            idTracker.current() + amount - 1 <= MAX_SUPPLY,
            "INIT: Purchasable NFTs are all minted."
        );

        for (uint256 i = 0; i < amount; i++) {
            mintInternal(msg.sender);
        }
    }

    function mintPreSale(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(SALE_STATE == 1, "INIT: Pre-sale has not started yet.");
        require(
            idTracker.current() + amount - 1 <= MAX_SUPPLY,
            "INIT: Purchasable NFTs are all minted."
        );
        require(msg.value >= amount * SALE_PRICE, "INIT: Insufficient funds.");
        require(
            whitelistMints[msg.sender] + amount <= MAX_PER_WL,
            "INIT: Address has reached the wallet cap in pre-sale."
        );

        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "INIT: Merkle verification has failed, address is not in the pre-sale whitelist."
        );

        for (uint256 i = 0; i < amount; i++) {
            mintInternal(msg.sender);
        }
        whitelistMints[msg.sender] += amount;
    }

    function mintPublicSale(uint256 amount) external payable {
        require(SALE_STATE == 2, "INIT: Public sale has not started yet.");
        require(
            idTracker.current() + amount - 1 <= MAX_SUPPLY,
            "INIT: Purchasable NFTs are all minted."
        );
        require(
            amount <= MAX_PER_TX,
            "INIT: Amount exceeds transaction mint cap."
        );
        require(msg.value >= amount * SALE_PRICE, "INIT: Insufficient funds.");

        for (uint256 i = 0; i < amount; i++) {
            mintInternal(msg.sender);
        }
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function setSaleState(uint256 _saleState) external onlyOwner {
        require(
            _saleState >= 0 && _saleState < 3,
            "INIT: Invalid new sale state."
        );
        SALE_STATE = _saleState;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "INIT: No balance to withdraw.");

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "INIT: Transfer failed.");
    }
}