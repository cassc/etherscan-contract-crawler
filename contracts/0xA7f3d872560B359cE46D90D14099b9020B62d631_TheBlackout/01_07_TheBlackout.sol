// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TheBlackout is ERC721A, Ownable, Pausable {
    uint256 public maxSupply = 6666;

    uint256 public publicPrice = 0.06 ether;
    uint256 public whitelistPrice = 0.04 ether;

    mapping(address => uint256) public amountMintedWhitelist;
    uint256 public maxMintableWhitelist = 3;

    mapping(address => uint256) public amountMintedPublic;
    uint256 public maxMintablePublic = 10;

    string private baseURI;
    bytes32 merkleRoot;

    modifier isUnderMaxSupply(uint256 _amount) {
        require(
            totalSupply() + _amount <= maxSupply,
            "Max supply has been reached"
        );
        _;
    }

    modifier isWhitelisted(address _wallet, bytes32[] calldata _proof) {
        bytes32 leaf = keccak256(abi.encodePacked(_wallet));
        require(
            MerkleProof.verify(_proof, merkleRoot, leaf),
            "Wallet is not whitelisted"
        );
        _;
    }

    constructor() ERC721A("The Blackout", "TBO") {
        _mint(msg.sender, 200);
        _pause();
    }

    function mintPublic(uint256 _amount)
        external
        payable
        whenNotPaused
        isUnderMaxSupply(_amount)
    {
        require(
            msg.value >= publicPrice * _amount,
            "Amount sent too low. Send more ETH"
        );
        require(
            amountMintedPublic[msg.sender] + _amount <= maxMintablePublic,
            "You are not eligible to mint more in Public"
        );

        _mint(msg.sender, _amount);

        amountMintedPublic[msg.sender] =
            amountMintedPublic[msg.sender] +
            _amount;
    }

    function mintWhitelist(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
        whenNotPaused
        isUnderMaxSupply(_amount)
        isWhitelisted(msg.sender, _proof)
    {
        require(
            msg.value >= whitelistPrice * _amount,
            "Amount sent too low. Send more ETH"
        );
        require(
            amountMintedWhitelist[msg.sender] + _amount <= maxMintableWhitelist,
            "You are not eligible to mint more in Whitelist"
        );

        _mint(msg.sender, _amount);

        amountMintedWhitelist[msg.sender] =
            amountMintedWhitelist[msg.sender] +
            _amount;
    }

    function airdrop(address[] memory _addresses, uint256 _amount)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mint(_addresses[i], _amount);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setPaused(bool _paused) external onlyOwner {
        _paused ? _pause() : _unpause();
    }

    function setMaxMintableWhitelist(uint256 _maxMintableWhitelist)
        external
        onlyOwner
    {
        maxMintableWhitelist = _maxMintableWhitelist;
    }

    function setMaxMintablePublic(uint256 _maxMintablePublic)
        external
        onlyOwner
    {
        maxMintablePublic = _maxMintablePublic;
    }

    function setPrice(uint256 _publicPrice, uint256 _whitelistPrice)
        external
        onlyOwner
    {
        publicPrice = _publicPrice;
        whitelistPrice = _whitelistPrice;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}