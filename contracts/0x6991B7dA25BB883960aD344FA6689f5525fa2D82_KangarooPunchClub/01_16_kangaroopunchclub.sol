//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract KangarooPunchClub is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 9999;
    uint256 public price = 0.099 ether;
    uint256 public presalePrice = 0.088 ether;

    address private whitelistAddress = 0xFEa34B493Eb11af26f2DfCcc0eDB9322154c2Df9;

    uint256 public presaleStart = 1647448140;
    uint256 public publicStart = 1647449940;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public paused = false;

    mapping(address => uint256) public tokensMinted;

    address[] private team_ = [
        0x051E27DdD2FD877f31Ee5D68aaC95599Eb68f4DB,
        0x567e7f90D97DD1De458C926e60242DfB42529fAd,
        0xb7972F8ED9c302f50b697DDd6C10D8B2687CF585
    ];
    uint256[] private teamShares_ = [97,2,1];

    constructor() ERC721A("KangarooPunchClub", "KPC") PaymentSplitter(team_, teamShares_) {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmVWZFhtxezDhAty7sn5b45ws1hJmadgspbJQBjmEWfFCw");
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
            "Kangaroo Punch Club: Whitelist mint is not started yet!"
        );
        require(
            publicStart > 0 && block.timestamp < publicStart,
            "Kangaroo Punch Club: Whitelist mint is finished!"
        );
        require(
                tokensMinted[msg.sender] + amount <= max,
            "Kangaroo Punch Club: You can't mint more NFTs!"
        );
        require(
            supply + amount <= maxSupply,
            "Kangaroo Punch Club: SOLD OUT !"
        );
        require(
            msg.value >= presalePrice * amount,
            "Kangaroo Punch Club: Insuficient funds"
        );

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable whenNotPaused {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(supply + amount <= maxSupply, "Kangaroo Punch Club: Sold out!");
        require(
            publicStart > 0 && block.timestamp >= publicStart,
            "Kangaroo Punch Club: public sale not started."
        );
        require(
            msg.value >= price * amount,
            "Kangaroo Punch Club: Insuficient funds"
        );

        tokensMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + addresses.length <= maxSupply,
            "Kangaroo Punch Club: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function forceMint(uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= maxSupply,
            "Kangaroo Punch Club: You can't mint more than max supply"
        );

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