// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JayDeeNDegens is ERC721A, Ownable {
    uint256 public constant PRICE = 0.01 ether;
    uint256 public maxSupply;
    uint256 public degenEpoch;
    uint256 public publicEpoch;
    string public baseTokenURI;
    string public contractURI;
    bool public paused = false;

    address private withdrawAddress;
    bytes32 private merkleRoot;

    mapping(address => bool) public claimed;

    event JayDeeMint(address _minter, uint256 _tokenId);
    event Paused(bool _paused);

    constructor(
        uint256 _maxSupply,
        string memory _baseUri,
        address _withdrawAddress,
        bytes32 _merkleRoot
    ) ERC721A("JayDee & The Degens", "JAYDND") {
        maxSupply = _maxSupply;
        baseTokenURI = _baseUri;
        withdrawAddress = _withdrawAddress;
        merkleRoot = _merkleRoot;
        degenEpoch = 1656174000;
        publicEpoch = 1656433200;
        contractURI = "ipfs://QmcWvkQhDBNpHfXLJmh2FNNnZYpuxNE6GM89EoYjfrnUdN";
    }

    modifier doesNotExceedSupply(uint256 _amount) {
        require(totalSupply() + _amount <= maxSupply, "Exceeds max supply");
        _;
    }

    modifier onlyValidEpoch(uint256 _epoch) {
        require(block.timestamp >= _epoch, "Not yet");
        _;
    }

    modifier onlySender() {
        require(msg.sender == tx.origin, "sender not tx origin");
        _;
    }

    modifier notPaused() {
        require(!paused, "paused");
        _;
    }

    function reserveMint(uint256 _amount, address _toAddress)
        external
        doesNotExceedSupply(_amount)
        onlyOwner
    {
        require(_amount > 0, "_amount should be >= 1");
        _mint(_toAddress, _amount);
    }

    //free
    function wlMint(bytes32[] calldata _proof)
        external
        notPaused
        onlyValidEpoch(degenEpoch)
        doesNotExceedSupply(1)
    {
        require(!claimed[msg.sender], "Address already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, merkleRoot, leaf),
            "Not whitelisted"
        );
        uint256 tokenId = _nextTokenId();
        _mint(msg.sender, 1);
        claimed[msg.sender] = true;
        emit JayDeeMint(msg.sender, tokenId);
    }

    function mint()
        external
        payable
        notPaused
        onlyValidEpoch(publicEpoch)
        onlySender
        doesNotExceedSupply(1)
    {
        require(PRICE == msg.value, "ETH amount is incorrect");
        uint256 tokenId = _nextTokenId();
        _mint(msg.sender, 1);
        emit JayDeeMint(msg.sender, tokenId);
    }

    function flipPause() external onlyOwner {
        paused = !paused;
        emit Paused(paused);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseTokenURI = _baseUri;
    }

    function setWithDrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setDegenEpoch(uint256 _degenEpoch) external onlyOwner {
        degenEpoch = _degenEpoch;
    }

    function setPublicEpoch(uint256 _publicEpoch) external onlyOwner {
        publicEpoch = _publicEpoch;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        (bool success, ) = withdrawAddress.call{value: balance}("");
        require(success, "Error withdrawing eth");
    }
}