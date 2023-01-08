// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IRegister.sol";
import "./IManager.sol";
import "lib/EnsPrimaryContractNamer/src/PrimaryEns.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";

contract WhitelistRegistrationRules is IRegister, PrimaryEns, IERC721Receiver {
    IManager public immutable domainManager;
    mapping(uint256 => bytes32) public merkleRoots;
    mapping(uint256 => uint256) public mintPrices;
    mapping(uint256 => uint256) public maxMintPerAddress;

    mapping(uint256 => mapping(address => uint256)) public mintCount;

    address private tokenOwner;

    bytes4 constant ERC721_SELECTOR = this.onERC721Received.selector;

    event UpdateMerkleRoot(uint256 indexed _tokenId, bytes32 _merkleRoot);
    event UpdateMintPrice(uint256 indexed _tokenId, uint256 _priceInWei);
    event UpdateMaxMint(uint256 indexed _tokenId, uint256 _maxMint);

    constructor(address _esf) {
        domainManager = IManager(_esf);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) public returns (bytes4) {
        domainManager.transferFrom(address(this), tokenOwner, _tokenId);
        return ERC721_SELECTOR;
    }

    function canRegister(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        uint256 _priceInWei,
        bytes32[] calldata _proofs
    ) public view returns (bool) {
        require(_addr == address(this), "incorrect minting address");
        return true;
    }

    function registerSubdomain(
        uint256 _id,
        string calldata _label,
        bytes32[] calldata _proofs,
        address _mintTo
    ) external payable {
        //only do price and whitelist checks for none owner addresses
        if (msg.sender != domainManager.TokenOwnerMap(_id)) {
            uint256 maxMint = maxMintPerAddress[_id];

            bytes32 leaf;

            if (maxMint == 0) {
                leaf = keccak256(abi.encodePacked(msg.sender, _label));
            } else {
                leaf = keccak256(abi.encodePacked(msg.sender));
                require(
                    mintCount[_id][msg.sender] < maxMint,
                    "mint count exceeded"
                );
                unchecked {
                    ++mintCount[_id][msg.sender];
                }
            }

            if (merkleRoots[_id] != bytes32(uint256(0x1337))) {
                require(
                    MerkleProof.verify(_proofs, merkleRoots[_id], leaf),
                    "not authorised"
                );
            }

            require(
                domainManager.DefaultMintPrice(_id) != 0,
                "not for primary sale"
            );
            require(msg.value == mintPrices[_id], "incorrect price");
        }

        tokenOwner = _mintTo;
        domainManager.registerSubdomain{value: msg.value}(_id, _label, _proofs);
        delete tokenOwner;
    }

    function ownerBulkMint(
        uint256 _tokenId,
        address[] calldata _addr,
        string[] calldata _labels
    ) public payable isTokenOwner(_tokenId) {
        require(_addr.length == _labels.length, "arrays need to be same length");

        bytes32[] memory emptyProofs = new bytes32[](0);

        for(uint256 i; i < _addr.length;){

            tokenOwner = _addr[i];

            domainManager.registerSubdomain{value: msg.value}(_tokenId, _labels[i], emptyProofs);

            unchecked{
                ++i;
            }
        }

        delete tokenOwner;
    }

    function updateMerkleRoot(
        uint256 _tokenId,
        bytes32 _merkleRoot
    ) public isTokenOwner(_tokenId) {
        merkleRoots[_tokenId] = _merkleRoot;

        emit UpdateMerkleRoot(_tokenId, _merkleRoot);
    }

    function updateMintPrices(
        uint256 _tokenId,
        uint256 _price
    ) public isTokenOwner(_tokenId) {
        mintPrices[_tokenId] = _price;

        emit UpdateMintPrice(_tokenId, _price);
    }

    function updateMintPriceMaxMintAndMerkleRoot(
        uint256 _tokenId,
        uint256 _price,
        bytes32 _merkleRoot,
        uint256 _maxMint
    ) public isTokenOwner(_tokenId) {
        mintPrices[_tokenId] = _price;
        merkleRoots[_tokenId] = _merkleRoot;
        maxMintPerAddress[_tokenId] = _maxMint;

        emit UpdateMerkleRoot(_tokenId, _merkleRoot);
        emit UpdateMintPrice(_tokenId, _price);
        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMintPriceAndMaxMint(
        uint256 _tokenId,
        uint256 _price,
        uint256 _maxMint
    ) public isTokenOwner(_tokenId) {
        mintPrices[_tokenId] = _price;
        maxMintPerAddress[_tokenId] = _maxMint;

        emit UpdateMintPrice(_tokenId, _price);
        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMaxMint(
        uint256 _tokenId,
        uint256 _maxMint
    ) public isTokenOwner(_tokenId) {
        maxMintPerAddress[_tokenId] = _maxMint;

        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function updateMaxMintAndMerkle(
        uint256 _tokenId,
        uint256 _maxMint,
        bytes32 _merkleRoot
    ) public isTokenOwner(_tokenId) {
        maxMintPerAddress[_tokenId] = _maxMint;
        merkleRoots[_tokenId] = _merkleRoot;

        emit UpdateMerkleRoot(_tokenId, _merkleRoot);
        emit UpdateMaxMint(_tokenId, _maxMint);
    }

    function mintPrice(
        uint256 _tokenId,
        string calldata _label,
        address _addr,
        bytes32[] calldata _proofs
    ) external view returns (uint256) {
        return
            (msg.sender == domainManager.TokenOwnerMap(_tokenId))
                ? 0
                : mintPrices[_tokenId];
    }

    modifier isTokenOwner(uint256 _tokenId) {
        require(
            domainManager.TokenOwnerMap(_tokenId) == msg.sender,
            "not authorised"
        );
        _;
    }
}