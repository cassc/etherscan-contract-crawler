//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
    Copyrights Paladins-Tech
    All rights reserved
    For any commercial use contact us at paladins-tech.eth
 */

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DegenerateGrannyRetirementClub is ERC1155, PaymentSplitter, Ownable {
    string public name = "DegenerateGrannyRetirementClub";

    address[] private team_ = [
        0x76299b8be5bA5723cF4C60fc41C76Df30E094922,
        0x5428A759608643Bf6598400F6ab56490f4C015E6,
        0x553C9df7B78b5c5Ea2B00B64E1280aE3A264d9F4,
        0x3A70344c268cD039B107D9f65705F6092303c919,
        0x83932858105913FE67b3ECe4506bFf35748d0b42
    ];
    uint256[] private teamShares_ = [20, 20, 20, 20, 20];

    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public constant MAX_PUBLIC_PRESALE_SUPPLY = 600;
    uint256 public constant MAX_SUPPLY = 6000;
    uint256 public constant TEAM_RESERVE = 30;
    uint256 public constant MAX_GIFT = 300;

    uint256 public publicSalePrice = 0.2 ether;

    uint256 public constant PRIVATE_PRESALE_PRICE = 0.10 ether;
    uint256 public constant PUBLIC_PRESALE_PRICE = 0.15 ether;

    address private freeMintAddress = 0xb176a50074c5f91de893E25aCaDFBBCf35736EBc;
    address private privatePresaleAddress = 0x2b793A6C3a5CFb8bb1318152075a1D3597c2A81a;
    address private publicPresaleAddress = 0xF88c22D209887389C79F9a5C567b535aCdc0dfD4;

    uint256 currentSupply;
    uint256 currentPublicPresaleSupply;
    uint256 currentGift;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;

    bool private teamReserved;

    enum WorkflowStatus {
        Before,
        FreeMint,
        PrivatePresale,
        PublicPresale,
        Sale,
        SoldOut,
        Paused
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWallet;
    mapping(address => uint256) public freeMintPerWallet;
    mapping(address => uint256) public publicPresalePerWallet;
    mapping(address => uint256) public privatePresalePerWallet;

    constructor(string memory _baseUri)
        ERC1155(_baseUri)
        PaymentSplitter(team_, teamShares_)
    {
        workflow = WorkflowStatus.Before;
    }

    //GETTERS

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function getSalePrice() public view returns (uint256) {
        return publicSalePrice;
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

    //HELPER FUNCTIONS

    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {
        for (uint256 i = 0; i < number; i++) {
            _mint(to, baseId + i, 1, new bytes(0));
        }
    }

    //END HELPER FUNCTIONS

    //MINT FUNCTIONS

    /**
        Claims tokens for free paying only gas fees
     */
    function freeMint(
        uint256 number,
        uint256 max,
        bytes calldata signature
    ) external {
        uint256 supply = currentSupply;
        require(
            verifyAddressSigner(
                freeMintAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(workflow == WorkflowStatus.FreeMint, "DegenerateGrannyRetirementClub: Freemint has not started!");
        require(
            freeMintPerWallet[msg.sender] + number <= max,
            "DegenerateGrannyRetirementClub: You can't mint more than your allowed number of NFTs."
        );

        currentSupply += number;
        freeMintPerWallet[msg.sender] += number;

        mintBatch(msg.sender, supply, number);
    }

    function privatePresaleMint(
        uint256 number,
        uint256 max,
        bytes calldata signature
    ) external payable {
        uint256 supply = currentSupply;
        require(
            verifyAddressSigner(
                privatePresaleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(workflow == WorkflowStatus.PrivatePresale, "DegenerateGrannyRetirementClub: Private Presale has not started!");
        require(
            privatePresalePerWallet[msg.sender] + number <= max,
            "DegenerateGrannyRetirementClub: You can't mint more than your allowed number of NFTs."
        );
        require(
            msg.value >= number * PRIVATE_PRESALE_PRICE,
            "DegenerateGrannyRetirementClub: Insufficient funds"
        );

        currentSupply += number;
        privatePresalePerWallet[msg.sender] += number;

        mintBatch(msg.sender, supply, number);
    }

    function publicPresaleMint(
        uint256 number,
        uint256 max,
        bytes calldata signature
    ) external payable {
        uint256 supply = currentSupply;
        require(
            verifyAddressSigner(
                publicPresaleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(workflow == WorkflowStatus.PublicPresale, "DegenerateGrannyRetirementClub: Public Presale has not started!");
        require(
            currentPublicPresaleSupply + number <= MAX_PUBLIC_PRESALE_SUPPLY,
            "DegenerateGrannyRetirementClub: Public presale sold out !"
        );
        require(
            publicPresalePerWallet[msg.sender] + number <= max,
            "DegenerateGrannyRetirementClub: You can't mint more than your allowed number of NFTs."
        );
        require(
            msg.value >= number * PUBLIC_PRESALE_PRICE,
            "DegenerateGrannyRetirementClub: Insufficient funds"
        );

        currentSupply += number;
        publicPresalePerWallet[msg.sender] += number;
        currentPublicPresaleSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function publicSaleMint(uint256 amount) external payable {
        require(amount > 0, "You must mint at least one NFT.");
        uint256 supply = currentSupply;
        require(supply + amount <= MAX_SUPPLY, "DegenerateGrannyRetirementClub: Sold out!"); 
        require(
            workflow == WorkflowStatus.Sale,
            "DegenerateGrannyRetirementClub: public sale not started."
        );
        require(
            msg.value >= publicSalePrice * amount,
            "DegenerateGrannyRetirementClub: Insuficient funds"
        );

        tokensPerWallet[msg.sender] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    /**
        Mints reserve for the team. Only callable once. Amount fixed.
     */
    function teamReserve() external onlyOwner {
        require(teamReserved == false, "DegenerateGrannyRetirementClub: Team already reserved");
        uint256 supply = currentGift;
        require(
            supply + TEAM_RESERVE <= MAX_SUPPLY,
            "DegenerateGrannyRetirementClub: Mint too large"
        );

        teamReserved = true;
        currentSupply += TEAM_RESERVE;

        mintBatch(msg.sender, currentSupply - TEAM_RESERVE, TEAM_RESERVE);
    }

    function forceMint(uint256 number) external onlyOwner {
        uint256 supply = currentGift;
        require(
            supply + number <= MAX_GIFT,
            "DegenerateGrannyRetirementClub: You can't mint more than max supply"
        );

        currentSupply += number;
        currentGift += number;

        mintBatch(msg.sender, currentSupply - number, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentGift;
        require(
            addresses.length + supply <= MAX_GIFT,
            "DegenerateGrannyRetirementClub: You can't airdrop more than max gift"
        );
        uint256 baseId = currentSupply;
        currentSupply += addresses.length;
        currentGift += addresses.length;

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], baseId + i, 1, new bytes(0));
        }
    }

    // END MINT FUNCTIONS

    function setUpFreemint() external onlyOwner {
        workflow = WorkflowStatus.FreeMint;
    }

    function setUpPrivatePresale() external onlyOwner {
        workflow = WorkflowStatus.PrivatePresale;
    }

    function setUpPublicPresale() external onlyOwner {
        workflow = WorkflowStatus.PublicPresale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    /**
        Automatic reveal is too dangerous : manual reveal is better. It allows much more flexibility and is the reveal is still instantaneous.
        Note that images on OpenSea will take a little bit of time to update. This is OpenSea responsability, it has nothing to do with the contract.    
     */
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setFreeMintAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        freeMintAddress = _newAddress;
    }

    function setPrivatePresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        privatePresaleAddress = _newAddress;
    }

    function setPublicPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        publicPresaleAddress = _newAddress;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        publicSalePrice = _newPrice;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!revealed) {
            return notRevealedUri;
        } else {
            return baseURI;
        }
    }
}