// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//      .  .                     .
//     _|_ |              o      |
//      |  |--. .-. .-..  .  .--.|
//      |  |  |(.-'(   |  |  |   |
//      `-''  `-`--'`-`|-' `-'   `-
//                  ._.'
//
//      By Nikki Noona
//
//      https://thegirl.io

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract TheGirl is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI = "";
    string public hiddenMetadataUri =
        "ipfs://bafybeifk7ohnn2dg47edznw2gs5q7eii6w3vvsmlnnp3cm3nwqt4aboz3m";
    uint256 public publicPrice = 0.07 ether;
    uint256 public allowListPrice = 0.05 ether;
    uint256 public maxSupply = 7777;
    uint256 public teamSupply = 77;
    uint8 public mintsPerWallet = 7;
    bool public paused = true;
    bool public revealed = false;
    bytes32 public allowListMerkleRoot;
    bytes32 public complimentaryMintListMerkleRoot;
    address public beneficiary;
    mapping(address => bool) private _complimentaryMintClaimed;

    constructor(address _beneficiary) ERC721A("The Girl", "TG") {
        beneficiary = _beneficiary;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier mintChecks(uint256 _mintAmount) {
        require(!paused, "The contract is paused");
        require(
            _mintAmount + _numberMinted(msg.sender) <= mintsPerWallet,
            "Maximum mints per wallet exceeded"
        );
        require(_totalMinted() + _mintAmount <= maxSupply, "Supply exhausted");
        _;
    }

    modifier checkFunds(uint256 _mintAmount, bool isPublic) {
        require(
            msg.value >=
                (isPublic ? publicPrice : allowListPrice) * _mintAmount,
            "Insufficient ETH"
        );
        _;
    }

    function mint(uint8 _mintAmount)
        public
        payable
        mintChecks(_mintAmount)
        checkFunds(_mintAmount, true)
    {
        _safeMint(msg.sender, _mintAmount);
    }

    function mintAllowList(uint8 _mintAmount, bytes32[] calldata proof)
        public
        payable
        mintChecks(_mintAmount)
        checkFunds(_mintAmount, false)
    {
        require(
            _verify(_leaf(msg.sender), proof, allowListMerkleRoot),
            "Invalid proof"
        );

        _safeMint(msg.sender, _mintAmount);
    }

    function mintComplimentary(bytes32[] calldata proof) public payable {
        require(!paused, "The contract is paused");
        require(
            _complimentaryMintClaimed[msg.sender] != true,
            "Complimentary mint already claimed"
        );
        require(
            _verify(_leaf(msg.sender), proof, complimentaryMintListMerkleRoot),
            "Invalid proof"
        );
        require(_totalMinted() + 1 <= maxSupply, "Supply exhausted");
        _complimentaryMintClaimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function mintWithFriend(uint8 _mintAmount, uint256 tokenId)
        public
        payable
        mintChecks(_mintAmount)
        checkFunds(_mintAmount, false)
    {
        address friend = ownerOf(tokenId);

        _safeMint(msg.sender, _mintAmount);
        //Pay out token owner commission
        (bool os, ) = payable(friend).call{
            value: (publicPrice * _mintAmount * 10) / 100
        }("");
        require(os);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        onlyOwner
    {
        require(_totalMinted() + _mintAmount <= maxSupply, "Supply exhausted");
        require(_mintAmount <= teamSupply, "Team supply exhausted");
        teamSupply = teamSupply - _mintAmount;
        _safeMint(_receiver, _mintAmount);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function remainingMints(address userAddress) public view returns (uint256) {
        return mintsPerWallet - _numberMinted(userAddress);
    }

    function remainingTokens() public view returns (uint256) {
        return _totalMinted() - maxSupply;
    }

    function setMerkleRoots(
        bytes32 _allowListMerkleRoot,
        bytes32 _complimentaryMintListMerkleRoot
    ) external onlyOwner {
        allowListMerkleRoot = _allowListMerkleRoot;
        complimentaryMintListMerkleRoot = _complimentaryMintListMerkleRoot;
    }

    function mintComplimentaryClaimed() public view returns (bool) {
        return _complimentaryMintClaimed[msg.sender] == true;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setAllowListPrice(uint256 _allowListPrice) public onlyOwner {
        allowListPrice = _allowListPrice;
    }

    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _verify(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 _merkleRoot
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }
}