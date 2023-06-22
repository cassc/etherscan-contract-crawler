//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Imnium is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 4444;
    uint256 public price = 0.3 ether;
    uint256 public presalePrice = 0.27 ether;

    uint256 public maxPublicMint = 10;

    address private whitelistAddress =
        0x813eeb1bBEf2de2689e428e56C00254341c8Bc57;

    uint256 public presaleStart = 1644692340;
    uint256 public publicStart = 1644778740;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;

    mapping(address => uint256) public tokensMinted;

    address[] private team_ = [
        0x8dD47E819c53138aA18F8651D797e7969f34d1F1,
        0x389Aeb695B97e001d89BfB6b9f901e6C4B46bddA,
        0xA2f0A9Fda26c2ACE84a9EF1Bab072630AA35605b,
        0x567e7f90D97DD1De458C926e60242DfB42529fAd,
        0x61932D0CA0d88Cf27FA71593b2d3DE4CF45168D6,
        0xE9aa20FCFb5c5d8e0137e5F6C7507aBac2EbeCd0,
        0xbc9d63dadc3141cCa17d828383339D60ff44dD73
    ];
    uint256[] private teamShares_ = [800, 100, 300, 285, 100, 4210, 4205];

    constructor() ERC721A("Imnium", "IMN") PaymentSplitter(team_, teamShares_) {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmdyPC2eNzREwk7DSbJrZvWPdrVJXs4zTUfokskGm7TeTb");
        _safeMint(msg.sender, 1);
    }

    modifier whenNotPaused() {
        require(paused == false, "Contract is paused");
        _;
    }

    //GETTERS

    function getPresaleStart() public view returns (uint256) {
        return presaleStart;
    }

    function getPublicStart() public view returns (uint256) {
        return publicStart;
    }

    function getSalePrice() public view returns (uint256) {
        return price;
    }

    function getPresalePrice() public view returns (uint256) {
        return presalePrice;
    }

    //END GETTERS

    //SETTERS

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        whitelistAddress = _newAddress;
    }

    function setPresaleStart(uint256 _newStart) public onlyOwner {
        presaleStart = _newStart;
    }

    function setPublicStart(uint256 _newStart) public onlyOwner {
        publicStart = _newStart;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxPublicMint(uint256 _maxMint) public onlyOwner {
        maxPublicMint = _maxMint;
    }

    function switchPause() public onlyOwner {
        paused = !paused;
    }

    //END SETTERS

    //SIGNATURE VERIFICATION

    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            referenceAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(uint256 number, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(number, sender));
    }

    //END SIGNATURE VERIFICATION

    //MINT FUNCTIONS

    function presaleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                whitelistAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            presaleStart > 0 && block.timestamp >= presaleStart,
            "Imnium: Whitelist mint is not started yet!"
        );
        require(
            (publicStart > 0 && block.timestamp >= publicStart) ||
                tokensMinted[msg.sender] + amount <= max,
            "Imnium: You can't mint more NFTs!"
        );
        require(supply + amount <= maxSupply, "Imnium: SOLD OUT !");
        require(msg.value >= presalePrice * amount, "Imnium: INVALID PRICE");

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(
            tokensMinted[msg.sender] + amount <= maxPublicMint,
            "Imnium: You can't mint more NFTs!"
        );
        require(supply + amount <= maxSupply, "Imnium: Sold out!");
        require(
            publicStart > 0 && block.timestamp >= publicStart,
            "Imnium: public sale not started."
        );
        require(msg.value >= price * amount, "Imnium: Insuficient funds");

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + addresses.length <= maxSupply,
            "Imnium: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function forceMint(uint256 amount) public onlyOwner{
        require(totalSupply() + amount <= maxSupply, "Imnium: You can't mint more than max supply");

        _safeMint(msg.sender, amount);
    }

    // END MINT FUNCTIONS

    // FACTORY

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }
}