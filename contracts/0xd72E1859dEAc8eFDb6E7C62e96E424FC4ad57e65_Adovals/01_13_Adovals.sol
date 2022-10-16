// SPDX-License-Identifier: MIT

//     ___       __                 __
//    /   | ____/ /___ _   ______ _/ /____
//   / /| |/ __  / __ \ | / / __ `/ / ___/
//  / ___ / /_/ / /_/ / |/ / /_/ / (__  )
// /_/  |_\__,_/\____/|___/\__,_/_/____/

pragma solidity 0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Adovals is ERC721A, Ownable {
    using Strings for uint256;

    string public promoBaseURI;
    string internal baseURI;
    string internal reservedURI;
    string public baseExtension = ".json";
    string public notRevealedURI;
    bool public enabled = false;
    bool public inPresale = true;
    bool public revealed = false;
    uint256 public totalPresaleSupply = 0;
    uint256 public presaleMaxSupply = 200;
    uint256 public maxSupply = 1500;
    uint256 public promoTokens = 25;
    uint256 public reservedTokens = 10;
    uint256 public presaleMaxMintAmount = 2;
    uint256 public saleMaxMintAmount = 10;
    uint256 public presaleCost = 0.03 ether;
    uint256 public cost = 0.04 ether;
    bytes32 public merkleRoot;

    constructor(
        string memory name,
        string memory symbol,
        string memory initPromoBaseURI,
        string memory initBaseURI,
        string memory initReservedURI,
        string memory initNotRevealedURI,
        bytes32 root
    ) ERC721A(name, symbol) {
        setPromoBaseURI(initPromoBaseURI);
        setBaseURI(initBaseURI);
        setReservedURI(initReservedURI);
        setNotRevealedURI(initNotRevealedURI);
        merkleRoot = root;
    }

    modifier mintReq(uint256 mintAmount) {
        require(
            mintAmount > 0,
            "A mint amount bigger than 0 needs to be provided"
        );
        require(
            totalSupply() + mintAmount <= maxSupply,
            "There are not enough tokens left"
        );
        _;
    }

    function mint(uint256 mintAmount, bytes32[] calldata proof)
        external
        payable
        mintReq(mintAmount)
    {
        if (msg.sender != owner()) {
            require(enabled, "The contract is not enabled");
            require(
                !inPresale ||
                    isValid(proof, keccak256(abi.encodePacked(msg.sender))),
                "The used address is not in the presale allowlist"
            );
            require(
                (inPresale && mintAmount <= presaleMaxMintAmount) ||
                    (!inPresale && mintAmount <= saleMaxMintAmount),
                "The mint amount is bigger than the maximum"
            );
            require(
                (inPresale &&
                    _numberMinted(msg.sender) + mintAmount <=
                    presaleMaxMintAmount) ||
                    (!inPresale &&
                        _numberMinted(msg.sender) + mintAmount <=
                        saleMaxMintAmount),
                "The total mint amount for the account is bigger than the maximum"
            );
            require(
                !inPresale ||
                    totalPresaleSupply + mintAmount <= presaleMaxSupply,
                "There are not enough presale tokens left"
            );

            require(
                totalSupply() + mintAmount <= maxSupply - reservedTokens,
                "There are not enough tokens left"
            );

            require(
                msg.value >= presaleCost * mintAmount,
                "Not enough ether is sent for the purchase"
            );

            if (inPresale) {
                totalPresaleSupply = totalPresaleSupply + mintAmount;
            }
        }

        _safeMint(msg.sender, mintAmount);
    }

    function mintForAddress(uint256 mintAmount, address receiver)
        public
        mintReq(mintAmount)
        onlyOwner
    {
        _safeMint(receiver, mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (!revealed && tokenId >= promoTokens) {
            return notRevealedURI;
        }

        string memory currentBaseURI = tokenId < promoTokens
            ? promoBaseURI
            : baseURI;

        currentBaseURI = tokenId < maxSupply - reservedTokens
            ? currentBaseURI
            : reservedURI;

        return
            bytes(currentBaseURI).length != 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function isValid(bytes32[] memory proof, bytes32 leaf)
        public
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function setPromoBaseURI(string memory newPromoBaseURI) public onlyOwner {
        promoBaseURI = newPromoBaseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setReservedURI(string memory newReservedURI) public onlyOwner {
        reservedURI = newReservedURI;
    }

    function setNotRevealedURI(string memory newNotRevealedURI)
        public
        onlyOwner
    {
        notRevealedURI = newNotRevealedURI;
    }

    function enable(bool setEnabled) public onlyOwner {
        enabled = setEnabled;
    }

    function presale(bool setPresale) public onlyOwner {
        inPresale = setPresale;
    }

    function reveal(bool setRevealed) public onlyOwner {
        revealed = setRevealed;
    }

    function setPresaleMaxSupply(uint256 newPresaleMaxSupply) public onlyOwner {
        presaleMaxSupply = newPresaleMaxSupply;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setPromoTokens(uint256 newPromoTokens) public onlyOwner {
        promoTokens = newPromoTokens;
    }

    function setReservedTokens(uint256 numReserved) public onlyOwner {
        reservedTokens = numReserved;
    }

    function setPresaleMaxMintAmount(uint256 newPresaleMaxMintAmount)
        public
        onlyOwner
    {
        presaleMaxMintAmount = newPresaleMaxMintAmount;
    }

    function setSaleMaxMintAmount(uint256 newSaleMaxMintAmount)
        public
        onlyOwner
    {
        saleMaxMintAmount = newSaleMaxMintAmount;
    }

    function setPresaleCost(uint256 newPresaleCost) public onlyOwner {
        presaleCost = newPresaleCost;
    }

    function setCost(uint256 newCost) public onlyOwner {
        cost = newCost;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Failure withdrawing Ether");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}