//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract MaisonFaceless is ERC1155, PaymentSplitter, Ownable {
    string public name = "MaisonFaceless";

    address[] private team_ = [
        0xFc3f14c79fcd5e9A2B4F785bCd4cACf4369E60eF,
        0x3C915fE183472Dd290aAbDC1E41a27660E4dd7E0,
        0x6e3d9ebe7470be37459C5AB8D429992975544EF7
    ];
    uint256[] private teamShares_ = [96, 3, 1];

    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 2345;
    uint256 public maxSelfMint = 2;

    uint256 private publicSalePrice = 0.7 ether;

    address private presaleAddress = 0xdc995d34be5bff25EC91CA20B7C2dFc0CDec42AC;
    address private raffleAddress = 0x34d5D0c98D600d3302afB50F6953a94DBF24883F;

    uint256 currentSupply;

    uint256 raffleStart;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;


    enum WorkflowStatus {
        Before,
        Sale,
        PublicSale,
        Paused
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWallet;

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

    function presaleMint(uint256 amount, uint256 max, bytes calldata signature) external payable {
        require(amount > 0, "You must mint at least one NFT.");
        require(
            verifyAddressSigner(
                presaleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        uint256 supply = currentSupply;
        require(supply + amount <= maxSupply, "MaisonFaceless: Sold out!");
        require(
            workflow == WorkflowStatus.Sale,
            "MaisonFaceless: presale not started."
        );
        require(
            msg.value >= publicSalePrice * amount,
            "MaisonFaceless: Insuficient funds"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= maxSelfMint,
            "MaisonFaceless: You can't mint more NFTs!"
        );

        tokensPerWallet[msg.sender] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function raffleMint(uint256 amount, uint256 max, bytes calldata signature) external payable {
        require(amount > 0, "You must mint at least one NFT.");
        require(
            verifyAddressSigner(
                raffleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        uint256 supply = currentSupply;
        require(supply + amount <= maxSupply, "MaisonFaceless: Sold out!");
        require(
            workflow == WorkflowStatus.Sale && block.timestamp >= raffleStart,
            "MaisonFaceless: raffle not started."
        );
        require(
            msg.value >= publicSalePrice * amount,
            "MaisonFaceless: Insuficient funds"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= maxSelfMint,
            "MaisonFaceless: You can't mint more NFTs!"
        );

        tokensPerWallet[msg.sender] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require(amount > 0, "You must mint at least one NFT.");
        uint256 supply = currentSupply;
        require(supply + amount <= maxSupply, "MaisonFaceless: Sold out!");
        require(
            workflow == WorkflowStatus.PublicSale,
            "MaisonFaceless: public sale not started."
        );
        require(
            msg.value >= publicSalePrice * amount,
            "MaisonFaceless: Insuficient funds"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= maxSelfMint,
            "MaisonFaceless: You can't mint more NFTs!"
        );

        tokensPerWallet[msg.sender] += amount;
        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    
    // END MINT FUNCTIONS

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
        raffleStart = block.timestamp + 10 minutes;
    }

    function setUpPublicSale() external onlyOwner {
        workflow = WorkflowStatus.PublicSale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner{
        maxSupply = _newMaxSupply;
    }

    function setMaxSelfMint(uint256 _newMaxSelfMint) public onlyOwner{
        maxSelfMint = _newMaxSelfMint;
    }

    /**
        Automatic reveal is too dangerous : manual reveal is better. It allows much more flexibility and is the reveal is still instantaneous.
        Note that images on OpenSea will take a little bit of time to update. This is OpenSea responsibility, it has nothing to do with the contract.    
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

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setRaffleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        raffleAddress = _newAddress;
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