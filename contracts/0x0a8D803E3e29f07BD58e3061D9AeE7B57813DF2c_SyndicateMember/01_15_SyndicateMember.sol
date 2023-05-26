// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

enum Stages {
    WHITELIST,
    PRIVATE_SALE,
    PUBLIC_SALE
}

contract SyndicateMember is ERC1155, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter public id;

    string public name = "Syndicate 893";
    uint256 private totalSupply = 893;
    uint256 public mintPrice = 0.15 ether;
    uint8 public maxMintAmt = 2;
    bytes32 public merkleRoot;

    mapping(address => uint8) private mintedCount;

    Stages public stage = Stages.WHITELIST;

    constructor(string memory _uri) ERC1155(_uri) {}

    modifier atStage(Stages _stage) {
        require(stage == _stage, "Incorrect stage");
        _;
    }

    modifier onlyWhitelist(bytes32[] calldata _merkleProof) {
        require(_inWhitelist(_merkleProof, msg.sender), "Not on whitelist");
        _;
    }

    modifier ensureEnoughFunds(uint256 _amount) {
        require(msg.value >= mintPrice * _amount, "Not enough funds");
        _;
    }

    modifier lessThanMaxAmount(uint256 _amount) {
        require(_amount <= maxMintAmt, "Amount too large");
        _;
    }

    modifier ensureEnoughTokensAvailable(uint256 _amount) {
        require(id.current() < totalSupply - _amount, "Not enough tokens left");
        _;
    }

    function _inWhitelist(bytes32[] calldata _merkleProof, address _sender)
        internal
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(_sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, _leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function inWhitelist(bytes32[] calldata _merkleProof, address _user)
        external
        view
        returns (bool)
    {
        return _inWhitelist(_merkleProof, _user);
    }

    function setPrivateSale() external atStage(Stages.WHITELIST) onlyOwner {
        stage = Stages.PRIVATE_SALE;
    }

    function setPublicSale() external atStage(Stages.PRIVATE_SALE) onlyOwner {
        stage = Stages.PUBLIC_SALE;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function _doSubscriptionMint(uint8 _amount) internal {
        uint256[] memory _ids = new uint256[](_amount);
        uint256[] memory _amounts = new uint256[](_amount);

        for (uint256 _i = 0; _i < _amount; _i++) {
            _ids[_i] = id.current();
            _amounts[_i] = 1;
            id.increment();
        }

        _mintBatch(msg.sender, _ids, _amounts, "");
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(sent, "Failed to send Ether");
    }

    function mintPrivate(bytes32[] calldata _merkleProof, uint8 _amount)
        external
        payable
        atStage(Stages.PRIVATE_SALE)
        onlyWhitelist(_merkleProof)
        ensureEnoughFunds(_amount)
        lessThanMaxAmount(_amount)
        ensureEnoughTokensAvailable(_amount)
    {
        require(
            mintedCount[msg.sender] < maxMintAmt,
            "Max minted amount reached"
        );

        mintedCount[msg.sender] += 1;

        _doSubscriptionMint(_amount);
    }

    function mintPublic(uint8 _amount)
        external
        payable
        atStage(Stages.PUBLIC_SALE)
        ensureEnoughFunds(_amount)
        lessThanMaxAmount(_amount)
        ensureEnoughTokensAvailable(_amount)
    {
        _doSubscriptionMint(_amount);
    }

    // Metadata is always the same regardless of id
    function uri(uint256 _id) public view override returns (string memory) {
        require(_id < id.current(), "Invalid id");
        return
            string(
                abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json")
            );
    }
}