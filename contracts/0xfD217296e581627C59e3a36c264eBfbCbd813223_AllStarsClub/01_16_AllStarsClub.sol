//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AllStarsClub is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 7777;
    uint256 public price = 0.27 ether;

    uint256 public maxPublicMint = 2;

    address private vipAddress = 0xac75B9FD9579Ac5dA1451A042B77f2d708f7DA1F;
    address private whitelistAddress = 0xe49f799210A207Aa68cd0638f0C9510bdfcC11bc;

    uint256 public vipStart = 1643918340;
    uint256 public whitelistStart = 1643921940;
    uint256 public publicStart = 1643923740;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;


    mapping(address => uint256) public tokensMinted;

    address[] private team_ = [
        0x7F0B1716F540Aa30F56E4d44F04fA59ef4F3c15d,
        0x567e7f90D97DD1De458C926e60242DfB42529fAd
    ];
    uint256[] private teamShares_ = [97,3];

    constructor()
        ERC721A("AllStarsClub", "ASC")
        PaymentSplitter(team_, teamShares_)
    {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmciPwyNQTkKnDJKDJv1YzSxgRQis7jMMT4CzafLWy7ijP");
    }

    modifier whenNotPaused{
        require(paused == false, "Contract is paused");
        _;
    }

    //GETTERS

    function getVipStart() public view returns (uint256) {
        return vipStart;
    }

    function getWhitelistStart() public view returns (uint256) {
        return whitelistStart;
    }

    function getPublicStart() public view returns (uint256) {
        return publicStart;
    }

    function getPrice() public view returns (uint256) {
        return price;
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

    function setVipAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        vipAddress = _newAddress;
    }

    function setVipStart(uint256 _newStart) public onlyOwner {
        vipStart = _newStart;
    }

    function setWhitelistStart(uint256 _newStart) public onlyOwner {
        whitelistStart = _newStart;
    }

    function setPublicStart(uint256 _newStart) public onlyOwner {
        publicStart = _newStart;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
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

    function vipMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable whenNotPaused{
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                vipAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            vipStart > 0 && block.timestamp >= vipStart,
            "AllStarsClub: Vip mint is not started yet!"
        );
        require(
            tokensMinted[msg.sender] + amount <= max,
            "AllStarsClub: You can't mint more NFTS!"
        );
        require(supply + amount <= maxSupply, "AllStarsClub: SOLD OUT !");
        require(msg.value >= price * amount, "AllStarsClub: INVALID PRICE");

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function presaleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable whenNotPaused{
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
        uint256 start = whitelistStart;
        require(
            start > 0 && block.timestamp >= start,
            "AllStarsClub: Whitelist mint is not started yet!"
        );
        require(
            tokensMinted[msg.sender] + amount <= max,
            "AllStarsClub: You can't mint more NFTs!"
        );
        require(supply + amount <= maxSupply, "AllStarsClub: SOLD OUT !");
        require(msg.value >= price * amount, "AllStarsClub: INVALID PRICE");

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable whenNotPaused{
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(
            tokensMinted[msg.sender] + amount <= maxPublicMint,
            "AllStarsClub: You can't mint more NFTs!"
        );
        require(supply + amount <= maxSupply, "AllStarsClub: Sold out!");
        require(
            publicStart > 0 && block.timestamp >= publicStart,
            "AllStarsClub: public sale not started."
        );
        require(msg.value >= price * amount, "AllStarsClub: Insuficient funds");

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + addresses.length <= maxSupply,
            "AllStarsClub: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
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