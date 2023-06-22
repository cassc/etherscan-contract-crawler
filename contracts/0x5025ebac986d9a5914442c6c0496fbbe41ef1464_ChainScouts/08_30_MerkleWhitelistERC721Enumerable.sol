//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ExtensibleERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

enum MintingState {
    NOT_ALLOWED,
    WHITELIST_ONLY,
    PUBLIC
}

struct Payee {
    address payable addr;
    uint16 ratio;
}

abstract contract MerkleWhitelistERC721Enumerable is ExtensibleERC721Enumerable {
    mapping (address => uint) public whitelistMintsUsed;
    MintingState public mintingState = MintingState.NOT_ALLOWED;
    uint public maxMintPerTx;
    uint public maxSupply;
    uint public maxWhitelistMints;
    bytes32 internal root;
    address payable[] internal payeeAddresses;
    uint16[] internal payeeRatios;
    uint internal totalRatio;

    event MintingStateChanged(MintingState oldState, MintingState newState);

    constructor(Payee[] memory _payees, uint _maxMintPerTx, uint _maxSupply, uint _maxWhitelistMints, bytes32 _root) {
        maxMintPerTx = _maxMintPerTx;
        maxSupply = _maxSupply;
        maxWhitelistMints = _maxWhitelistMints;
        root = _root;
        payeeAddresses = new address payable[](_payees.length);
        payeeRatios = new uint16[](_payees.length);

        for (uint i = 0; i < _payees.length; ++i) {
            payeeAddresses[i] = _payees[i].addr;
            payeeRatios[i] = _payees[i].ratio;
            totalRatio += _payees[i].ratio;
        }
        if (totalRatio == 0) {
            revert("Total payee ratio must be > 0");
        }
    }

    function adminSetMaxPerTx(uint max) external onlyAdmin {
        maxMintPerTx = max;
    }

    /*
    function adminSetMaxSupply(uint max) external onlyAdmin {
        maxSupply = max;
    }
    */

    function adminSetMintingState(MintingState ms) external onlyAdmin {
        emit MintingStateChanged(mintingState, ms);
        mintingState = ms;
    }

    function adminSetMaxWhitelistMints(uint max) external onlyAdmin {
        maxWhitelistMints = max;
    }

    function adminSetMerkleRoot(bytes32 _root) external onlyAdmin {
        root = _root;
    }

    function isWhitelisted(bytes32[] calldata proof, address addr) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr));
        return MerkleProof.verify(proof, root, leaf);
    }

    function distributeFunds() internal virtual {
        address payable[] memory a = payeeAddresses;
        uint16[] memory r = payeeRatios;

        uint origValue = msg.value;
        uint remainingValue = msg.value;

        for (uint i = 0; i < a.length - 1; ++i) {
            uint amount = origValue * r[i] / totalRatio;
            Address.sendValue(a[i], amount);
            remainingValue -= amount;
        }
        Address.sendValue(a[a.length - 1], remainingValue);
    }

    function createMetadataForMintedToken(uint tokenId) internal virtual;

    function mintPriceWei() public view virtual returns (uint);

    function whitelistMint(bytes32[] calldata proof, uint count) public payable returns (uint) {
        require(mintingState == MintingState.WHITELIST_ONLY, "Whitelist minting is not allowed atm");
        require(isWhitelisted(proof, msg.sender), "Bad whitelist proof");
        require(maxWhitelistMints - whitelistMintsUsed[msg.sender] >= count, "Not enough whitelisted mints");
        whitelistMintsUsed[msg.sender] += count;

        return internalMint(count);
    }

    function publicMint(uint count) public payable returns (uint) {
        if (!isAdmin[msg.sender]) {
            require(mintingState == MintingState.PUBLIC, "Public minting is not allowed atm");
            require(count <= maxMintPerTx, "Cannot mint more than maxMintPerTx()");
        }
        return internalMint(count);
    }

    function internalMint(uint count) internal whenEnabled returns (uint) {
        if (!isAdmin[msg.sender]) {
            require(count >= 1, "Must mint at least one");
            require(!Address.isContract(msg.sender), "Contracts cannot mint");
            require(msg.value == count * mintPriceWei(), "Send mintPriceWei() wei for each mint");
        }

        uint supply = totalSupply();
        require(supply + count <= maxSupply, "Cannot mint over maxSupply()");

        uint startingIndex = _currentIndex;

        for (uint i = startingIndex; i < startingIndex + count; ++i) {
            createMetadataForMintedToken(i);
        }
        _mint(msg.sender, count, "", false);

        distributeFunds();

        return startingIndex;
    }
}