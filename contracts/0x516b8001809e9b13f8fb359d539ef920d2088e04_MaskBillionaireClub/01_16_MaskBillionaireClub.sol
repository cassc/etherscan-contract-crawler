//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MaskBillionaireClub is ERC721, PaymentSplitter, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 private constant MAX_PRESALE = 3000;
    uint256 public constant MAX_SELF_MINT = 10;
    uint256 public constant TEAM_RESERVE = 30;

    uint256 public maxSupply = 8080;
    uint256 public currentSupply = 0;
    uint256 public salePrice = 0.4 ether;
    uint256 public presalePrice = 0.3 ether;

    uint256 private presaleCount;

    //Placeholders
    address private presaleAddress = address(0xa1bD8ca52bE830988171A808C31846c9DcF5cFD1);
    address private giftAddress = address(0x6B989aD91C72479a19c11Fa366dfd21f415176A1);
    address private raffleAddress = address(0x1efb132101e400064D770a4d31077a9abf060F56);

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public teamReserved = false;
    bool founderMinted = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Raffle,
        Sale,
        Paused,
        Reveal
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWallet;
    mapping(address => bool) public premintClaimed;

    address[] private team_ = [
        0xA32fA46906316611EaeDcCeDB926c4009c78054A,
        0x040FC936073ff3233DF246b41e82310C97CbA7d4,
        0x68d5FD7694f62f0E012ae8e08B42F451502DA0C2,
        0x6E25d1162679B8D8Ec85603f235C016029548eEc,
        0x79fe014A5FeFb1c49f32dFE1bB3dA463877973E8,
        0x12FacD947BeF9F3049735E4978d09C1035f74cc1,
        0x9c9800B8204109Cef92CB7Bf4E497282586a7a89,
        0xd1E534925CE149a6Ab6343b6Db1d4F8D603be576
    ];
    uint256[] private teamShares_ = [1430, 200, 300, 1945, 1945, 1945, 2085, 150];

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri)
        ERC721("MaskBillionaireClub", "MBC")
        PaymentSplitter(team_, teamShares_)
    {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    //GETTERS

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function getSalePrice() public view returns (uint256) {
        return salePrice;
    }

    function getPresalePrice() public view returns (uint256) {
        return presalePrice;
    }

    //END GETTERS

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

    //HELPERS

    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {
        for (uint256 i = 0; i < number; i++) {
            _safeMint(to, baseId + i);
        }
    }

    //END HELPERS

    //MINT FUNCTIONS

    /**
        Claims tokens for free paying only gas fees
     */
    function freeMint(uint256 max, bytes calldata signature) external {
        uint256 supply = currentSupply;
        require(
            verifyAddressSigner(
                giftAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            premintClaimed[msg.sender] == false,
            "MaskBillionaireClub: You already claimed your premint NFTs."
        );
        require(
            supply + max <= maxSupply,
            "MaskBillionaireClub: Mint too large"
        );

        premintClaimed[msg.sender] = true;
        currentSupply += max;

        mintBatch(msg.sender, supply, max);
    }

    /**
        Mints reserve for the team. Only callable once. Amount fixed.
     */
    function teamReserve() external onlyOwner {
        require(
            teamReserved == false,
            "MaskBillionaireClub: Team already reserved"
        );
        uint256 supply = currentSupply;
        require(
            supply + TEAM_RESERVE <= maxSupply,
            "MaskBillionaireClub: Mint too large"
        );

        teamReserved = true;
        currentSupply += TEAM_RESERVE;

        mintBatch(msg.sender, supply, TEAM_RESERVE);
    }

    function presaleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable {
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                presaleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            workflow == WorkflowStatus.Presale,
            "MaskBillionaireClub: Presale is not started yet!"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= max,
            "MaskBillionaireClub: You can only mint 2 NFTs at presale."
        );
        require(
            presaleCount + amount <= MAX_PRESALE,
            "MaskBillionaireClub: PRESALE SOLD OUT"
        );
        require(
            msg.value >= presalePrice * amount,
            "MaskBillionaireClub: INVALID PRICE"
        );

        tokensPerWallet[msg.sender] += amount;
        presaleCount += amount;
        currentSupply += amount;

        mintBatch(msg.sender, currentSupply - amount, amount);
    }

    function raffleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable {
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                raffleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            workflow == WorkflowStatus.Raffle,
            "MaskBillionaireClub: Raffle is not started yet!"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= MAX_SELF_MINT,
            "MaskBillionaireClub: You already minted 10 NFTs!"
        );
        require(
            currentSupply + amount <= maxSupply,
            "MaskBillionaireClub: Sold out!"
        );
        require(
            msg.value >= salePrice * amount,
            "MaskBillionaireClub: INVALID PRICE"
        );

        tokensPerWallet[msg.sender] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, currentSupply - amount, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require(amount > 0, "You must mint at least one NFT.");
        uint256 supply = currentSupply;
        require(supply + amount <= maxSupply, "MaskBillionaireClub: Sold out!");
        require(
            workflow == WorkflowStatus.Sale,
            "MaskBillionaireClub: public sale not started."
        );
        require(
            msg.value >= salePrice * amount,
            "MaskBillionaireClub: Insuficient funds"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= MAX_SELF_MINT,
            "MaskBillionaireClub: You already minted 10 NFTs!"
        );

        tokensPerWallet[msg.sender] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function forceMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;
        require(
            supply + number <= maxSupply,
            "MaskBillionaireClub: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(
            supply + addresses.length <= maxSupply,
            "MaskBillionaireClub: You can't mint more than max supply"
        );

        currentSupply += addresses.length;

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], supply + i);
        }
    }

    function mintFounder() public onlyOwner {
        require(
            founderMinted == false,
            "MaskBillionaireClub: Team already reserved"
        );
        uint256 supply = currentSupply;
        require(supply + 3 <= maxSupply, "MaskBillionaireClub: Mint too large");

        founderMinted = true;
        currentSupply += 3;

        mintBatch(msg.sender, supply, 3);
    }

    // END MINT FUNCTIONS

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;

        if (founderMinted == false) {
            mintFounder();
        }
    }

    function setUpRaffle() external onlyOwner {
        workflow = WorkflowStatus.Raffle;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setRaffleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        raffleAddress = _newAddress;
    }

    function setGiftAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        giftAddress = _newAddress;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        salePrice = _newPrice;
    }

    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }

    // FACTORY

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
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