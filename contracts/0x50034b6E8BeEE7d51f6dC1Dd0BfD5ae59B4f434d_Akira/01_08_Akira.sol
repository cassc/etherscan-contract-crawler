// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import { Ownable } from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721AQueryable } from "erc721a/contracts/extensions/ERC721AQueryable.sol";

error NotEligible();
error NotStarted();
error MintLimit();
error InvalidProof();
error InvalidPrice();
error MaxSupply();
error InvalidLength();
error WithdrawFailed();

contract Akira is Ownable, ERC721AQueryable {
    string public baseURI;
    uint256 public immutable maxSupply;

    enum Status {
        close,
        whitelistMint,
        publicMint
    }
    Status public status;

    struct MintConfig {
        uint256 whitelistPrice;
        uint256 publicPrice;
        uint256 maxWhitelistMint;
        uint256 maxPublicMint;
        bytes32 merkleRoot;
    }
    MintConfig public mintConfig;

    mapping(address => uint256) amountWhitelistMinted;
    mapping(address => uint256) amountPublicMinted;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory uri,
        uint256 _maxSupply,
        MintConfig memory _mintConfig
    ) ERC721A(_name, _symbol) {
        baseURI = uri;
        maxSupply = _maxSupply;
        mintConfig = _mintConfig;
    }

    modifier mintChecker(
        Status _status,
        uint256 _price,
        uint256 _amount
    ) {
        if (msg.sender != tx.origin) _revert(NotEligible.selector);
        if (status < _status) _revert(NotStarted.selector);
        if (_totalMinted() + _amount > maxSupply) _revert(MaxSupply.selector);
        if (msg.value < _amount * _price) _revert(InvalidPrice.selector);
        _;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function setPrice(uint256 _whitelistPrice, uint256 _publicPrice) external onlyOwner {
        mintConfig.whitelistPrice = _whitelistPrice;
        mintConfig.publicPrice = _publicPrice;
    }

    function setMaxMintPerWallet(uint256 _maxWhitelistMint, uint256 _maxPublicMint) external onlyOwner {
        mintConfig.maxWhitelistMint = _maxWhitelistMint;
        mintConfig.maxPublicMint = _maxPublicMint;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        mintConfig.merkleRoot = _merkleRoot;
    }

    function whitelisted(address _address, bytes32[] calldata _merkleProof) external view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, mintConfig.merkleRoot, node);
    }

    function whitelistMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        mintChecker(Status.whitelistMint, mintConfig.whitelistPrice, _amount)
    {
        if (amountWhitelistMinted[msg.sender] + _amount > mintConfig.maxWhitelistMint) _revert(MintLimit.selector);
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, mintConfig.merkleRoot, node)) _revert(InvalidProof.selector);
        amountWhitelistMinted[msg.sender] += _amount;
        _mint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount)
        external
        payable
        mintChecker(Status.publicMint, mintConfig.publicPrice, _amount)
    {
        if (amountPublicMinted[msg.sender] + _amount > mintConfig.maxPublicMint) _revert(MintLimit.selector);
        amountPublicMinted[msg.sender] += _amount;
        _mint(msg.sender, _amount);
    }

    function reserves(uint256 _amount) external onlyOwner {
        if (_totalMinted() + _amount > maxSupply) _revert(MaxSupply.selector);
        _mint(msg.sender, _amount);
    }

    function airdrop(address[] calldata _to, uint256[] calldata _amount) external onlyOwner {
        if (_to.length != _amount.length) _revert(InvalidLength.selector);

        for (uint256 i = 0; i < _amount.length; i++) {
            if (_totalMinted() + _amount[i] > maxSupply) _revert(MaxSupply.selector);
            _mint(_to[i], _amount[i]);
        }
    }

    function withdraw(address payable _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _receiver.call{ value: balance }("");
        if (!success) _revert(WithdrawFailed.selector);
    }

    /******************** OVERRIDES ********************/
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}