// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**************************************************
 * Anero.sol
 *
 * Created for Anero by: Patrick Kishi
 * Audited by: Adnan, Jill
 * Special thanks goes to: Adnan, Jill
 ***************************************************
 */


contract Anero is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint16 public amountForDevs;
    uint16 public currentDevMintAmount;

    // Start time for each mint types
    uint256 public preSaleStartTime;
    uint256 public raffleSaleStartTime;
    uint256 public reservedSaleStartTime;

    // Price for presale and raffle sale, reserved sale
    uint256 public preSalePrice = 0.09 ether;
    uint256 public raffleSalePrice = 0.14 ether;
    uint256 public reservedSalePrice = 0.14 ether;

    // Signer for verification
    address private preSaleSigner1;
    address private preSaleSigner2;
    address private raffleSaleSigner;
    address private reservedSaleSigner;

    // metadata URI
    string private _baseTokenURI;
    string private _placeHolderURI;

    bool public reveal;
    bool public saleEnabled = false;

    uint8 public limit1 = 1;
    uint8 public limit2 = 2;

    enum SalePhase {
        None,
        PreSale,
        RaffleSale,
        ReservedSale
    }

    // wallet address => sale phase => minted amount
    mapping(address => mapping(SalePhase => uint8)) mintedAmountPerWallet;

    /**
        @param _baseURIString metadata base url
        @param _placeholder metadata before reveal
        @param maxBatchSize_ Max size for ERC721A batch mint.
        @param collectionSize_ NFT collection size
        @param amountForDevs_ Amount for Presale mint
    */
    constructor(
        string memory _baseURIString,
        string memory _placeholder,
        uint16 maxBatchSize_,
        uint16 collectionSize_,
        uint16 amountForDevs_
    ) ERC721A("Aneroverse", "ANERO", maxBatchSize_, collectionSize_) {
        require(amountForDevs_ <= collectionSize, "Exceeds Max Supply.");

        _baseTokenURI = _baseURIString;
        _placeHolderURI = _placeholder;

        amountForDevs = amountForDevs_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier whenRaffleSaleIsOn() {
        require(
                getCurrentSaleMode() == SalePhase.RaffleSale, 
            "Raffle sale is not active."
        );
        _;
    }

    modifier whenPreSaleOn() {
        require(
                getCurrentSaleMode() == SalePhase.PreSale,
            "Presale is not active."
        );
        _;
    }

    modifier whenReservedSaleOn() {
        require(getCurrentSaleMode() == SalePhase.ReservedSale,
            "Reserved sale is not active."
        );
        _;
    }

    // Admin actions

    function setReveal(bool _reveal) external onlyOwner {
        reveal = _reveal;
    }

    // Enable/Disable Sale
    function toggleSale(bool _enable) external onlyOwner {
        require(
            saleEnabled != _enable,
            "Already setted."
        );
        saleEnabled = _enable;
    }

    function startPreSaleAt(uint256 startTime) external onlyOwner {
        preSaleStartTime = startTime;
    }

    function startRaffleSaleAt(uint256 startTime) external onlyOwner {
        raffleSaleStartTime = startTime;
    }

    function startReservedSaleAt(uint256 startTime) external onlyOwner {
        reservedSaleStartTime = startTime;
    }

    function setPreSalePrice (uint256 _preSalePrice) external onlyOwner {
        preSalePrice = _preSalePrice;
    }

    function setRaffleSalePrice (uint256 _raffleSalePrice) external onlyOwner {
        raffleSalePrice = _raffleSalePrice;
    }

    function setReservedSalePrice (uint256 _reservedSalePrice) external onlyOwner {
        reservedSalePrice = _reservedSalePrice;
    }

    function setAmountForDevs (uint16 _amountForDevs) external onlyOwner {
        require(_amountForDevs <= collectionSize, "Exceeds Max Supply.");
        amountForDevs = _amountForDevs;
    }

    function setLimits(uint8 _limit1, uint8 _limit2) external onlyOwner {
        limit1 = _limit1;
        limit2 = _limit2;
    }
    //

    function verifySigner(bytes calldata signature, address signer) 
        public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        address recoveredAddress = ECDSA.recover(message, signature);
        return (recoveredAddress != address(0) && recoveredAddress == signer);
    }

    function preSaleMint(
      uint8 quantity,
      bytes calldata signature
    )
        external
        payable
        callerIsUser
        whenPreSaleOn
        nonReentrant
    {
        require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");
        uint8 limitAmount = limit1;
        if (verifySigner(signature, preSaleSigner2)) {
            limitAmount = limit2;
        } else if (verifySigner(signature, preSaleSigner1)) {
            limitAmount = limit1;
        } else {
            revert("You are not presale member.");
        }

        require(
            mintedAmountPerWallet[msg.sender][SalePhase.PreSale] + quantity <= limitAmount,
            "Exceeds limit"
        );

        mintedAmountPerWallet[msg.sender][SalePhase.PreSale] += quantity;
        _safeMint(msg.sender, quantity);

        refundIfOver(preSalePrice * quantity);
    }

    function raffleSaleMint(
        uint8 quantity,
        bytes calldata signature
    )
        external
        payable
        callerIsUser
        whenRaffleSaleIsOn
        nonReentrant
    {
        require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");

        require(verifySigner(signature, raffleSaleSigner), "You are not raffle sale member.");
        require(
            mintedAmountPerWallet[msg.sender][SalePhase.RaffleSale] + quantity <= limit1,
            "Exceeds limit."
        );
        mintedAmountPerWallet[msg.sender][SalePhase.RaffleSale] += quantity;

        _safeMint(msg.sender, quantity);
        refundIfOver(raffleSalePrice * quantity);
    }

     function reservedSaleMint(
        uint8 quantity,
        bytes calldata signature
    )
        external
        payable
        callerIsUser
        whenReservedSaleOn
        nonReentrant
    {
        require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");

        require(verifySigner(signature, reservedSaleSigner), "You are not reserved sale member.");
        require(
            mintedAmountPerWallet[msg.sender][SalePhase.ReservedSale] + quantity <= limit1,
            "Exceeds limit."
        );
        mintedAmountPerWallet[msg.sender][SalePhase.ReservedSale] += quantity;

        _safeMint(msg.sender, quantity);
        refundIfOver(reservedSalePrice * quantity);
    }

    // For marketing etc.
    function devMint(uint16 quantity) external onlyOwner {
        require(totalSupply() + quantity <= collectionSize, "Exceeds Max Supply");
        
        require(
            currentDevMintAmount + quantity <= amountForDevs, 
            "Reached dev mint supply."
        );
        if (quantity > maxBatchSize) {
            require(
                quantity % maxBatchSize == 0,
                "can only mint a multiple of the maxBatchSize"
            );
        }
        uint256 batchMintAmount = quantity > maxBatchSize ? maxBatchSize : quantity;

        uint256 numChunks = quantity / batchMintAmount;

        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, batchMintAmount);
        }

        currentDevMintAmount += quantity;
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!reveal) {
            return _placeHolderURI;
        }

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPlaceHolderURI(string memory _uri) external onlyOwner {
        _placeHolderURI = _uri;
    }

    function setSigners(
        address _presaleSigner1, 
        address _presaleSigner2,
        address _raffleSaleSigner,
        address _reservedSaleSigner
    ) external onlyOwner {
        preSaleSigner1 = _presaleSigner1;
        preSaleSigner2 = _presaleSigner2;
        raffleSaleSigner = _raffleSaleSigner;
        reservedSaleSigner = _reservedSaleSigner;
    }

    // withdraw ether
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // utility functions
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function getCurrentSaleMode() public view returns(SalePhase) {
        if (!saleEnabled) {
            return SalePhase.None;
        }

        if (block.timestamp >= reservedSaleStartTime) {
            return SalePhase.ReservedSale;
        }
        if (block.timestamp >= raffleSaleStartTime) {
            return SalePhase.RaffleSale;
        }
        if (block.timestamp >= preSaleStartTime) {
            return SalePhase.PreSale;
        }
        return SalePhase.None;
    }

}