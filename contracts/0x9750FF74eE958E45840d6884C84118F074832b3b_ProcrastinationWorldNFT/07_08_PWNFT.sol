// SPDX-License-Identifier: MIT

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";

pragma solidity >=0.8.9 <0.9.0;

contract ProcrastinationWorldNFT is ERC721A, Ownable {
    using Strings for uint256;

    string public uriPrefix = "";
    string public hiddenMetadataUri;

    bool public procrastinating = true;
    bool public revealed = false;

    uint256 public maxSupply = 2584;
    uint256 public mintCost = 0.013 ether;
    uint256 public maxPerWallet = 21;
    uint256 public maxMintPerTransaction = 21;
    uint256 public stage = 0;
    bytes32 public merkleRoot;

    mapping(address => uint256) public perWallet;

    constructor() ERC721A("Procrastination World NFT", "PROCRAST") {
        setHiddenMetadataUri("ipfs://QmaGez2StByX4tX6qFctZQB2eJygyPbusrohGwmpZMjEA4/hidden.json");
        setMerkleRoot(0x2d188c6bb0835fcaec0dc3b626adf0fda616169b3371fdabffa249a7d045f9c6);
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner
    {
        merkleRoot = _root;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
    }

    function setProcrastinating(bool _state) public onlyOwner {
        procrastinating = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function mint(uint256 _mintAmount,  bytes32[] memory proof) public payable {
        require(stage > 0 && stage <= 2, "Stage not set!");
        require(!procrastinating, "The contract is still procrastinating!");
        uint256 totalMinted = totalSupply();
        require(totalMinted + _mintAmount <= maxSupply, "Max supply exceeded!");
        require(_mintAmount > 0, "Invalid mint amount!");
        require(_mintAmount <= maxMintPerTransaction, "Max Procrastinators per transaction");

        if (stage < 2) {
            require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Whitelist");
        }

        uint256 totalPerWallet = perWallet[msg.sender] + _mintAmount;
        require(totalPerWallet <= maxPerWallet, "Max Procrastinators per wallet");

        require(msg.value >= mintCost * _mintAmount, "Insufficient funds!");

        _safeMint(msg.sender, _mintAmount);
        perWallet[msg.sender] += _mintAmount;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner
    {
        require(_mintAmount > 0, "Invalid mint amount!");
        uint256 totalMinted = totalSupply();
        require(totalMinted + _mintAmount <= maxSupply, "Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Something wrong");
    }

    function startStage1() public onlyOwner {
        require(stage == 0, "Stage is not 0!");
        procrastinating = false;
        uint256 totalMinted = totalSupply();
        maxSupply = totalMinted + 610;
        mintCost = 0.013 ether;
        stage = 1;
    }

    function startStage2() public onlyOwner {
        require(stage == 1, "Stage is not 1!");
        procrastinating = false;
        uint256 totalMinted = totalSupply();
        maxSupply = totalMinted + 1741;
        mintCost = 0.021 ether;
        stage = 2;
    }
}