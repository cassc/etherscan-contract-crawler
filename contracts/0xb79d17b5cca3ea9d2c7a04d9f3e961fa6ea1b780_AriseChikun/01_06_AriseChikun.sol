// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Ownable.sol";

contract AriseChikun is ERC721A, Ownable {
    uint256 public presaleStart = 1690934400;
    uint256 public presaleEnd = 1690941600;

    uint256 public maxSupply = 9000;
    uint256 public presalePrice = 0.011 ether;
    uint256 public publicPrice = 0.022 ether;

    bytes32 public root;

    string public baseTokenURI;
    string public uriSuffix = ".json";

    bool public revealed;
    bool public paused;

    modifier onlyWhenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "NonEOA");
        _;
    }

    constructor(
        string memory _baseTokenURI,
        bytes32 _root
    ) ERC721A("Arise Chikun", "CHIKUNS") Ownable(msg.sender) {
        baseTokenURI = _baseTokenURI;
        root = _root;
    }

    function isValid(
        bytes32[] memory proof,
        bytes32 leaf
    ) internal view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function presaleMint(
        uint256 quantity,
        bytes32[] memory proof
    ) external payable onlyWhenNotPaused callerIsUser {
        require(
            block.timestamp > presaleStart && block.timestamp < presaleEnd,
            "NonPresalePeriod"
        );

        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender))),
            "NonWhitelisted"
        );

        require(_totalMinted() + quantity <= maxSupply, "SupplyExceeded");

        require(msg.value >= presalePrice * quantity, "InvalidEtherAmount");

        _mint(msg.sender, quantity);
    }

    function publicMint(
        uint256 quantity
    ) external payable onlyWhenNotPaused callerIsUser {
        require(block.timestamp > presaleEnd, "NonPublicPeriod");

        require(_totalMinted() + quantity <= maxSupply, "SupplyExceeded");

        require(msg.value >= publicPrice * quantity, "InvalidEtherAmount");

        _mint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "InvalidTokenId");

        string memory baseURI = _baseURI();
        if (!revealed) return baseURI;

        return string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix));
    }

    function mintMany(
        address[] calldata _to,
        uint256[] calldata _amount
    ) external onlyOwner {
        for (uint256 i; i < _to.length; ) {
            require(_totalMinted() + _amount[i] <= maxSupply, "SupplyExceeded");
            _mint(_to[i], _amount[i]);
            unchecked {
                i++;
            }
        }
    }

    function airdropNfts(address[] calldata _to) external onlyOwner {
        for (uint256 i; i < _to.length; ) {
            require(_totalMinted() <= maxSupply, "SupplyExceeded");
            _mint(_to[i], 1);
            unchecked {
                i++;
            }
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "WithdrawFailed");
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setPaused(bool _pasused) public onlyOwner {
        paused = _pasused;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        presalePrice = _price;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        publicPrice = _price;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_totalMinted() > _maxSupply, "InvalidMaxSupply");
        maxSupply = _maxSupply;
    }

    function setSaleTimings(
        uint256 _presaleStart,
        uint256 _presaleEnd
    ) external onlyOwner {
        presaleStart = _presaleStart;
        presaleEnd = _presaleEnd;
    }

    receive() external payable {}

    fallback() external payable {}
}