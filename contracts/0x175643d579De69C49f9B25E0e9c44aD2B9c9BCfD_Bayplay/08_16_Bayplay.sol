// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./rarible/royalties/contracts/LibPart.sol";
import "./rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./rarible/royalties/contracts/RoyaltiesV2.sol";

contract Bayplay is ERC721A, Ownable, RoyaltiesV2, DefaultOperatorFilterer {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant TOTAL_SUPPLY = 4000;

    uint256 public constant PRE_LIMIT = 3;
    uint256 public constant PRE_PRICE = 0.04 ether;

    uint256 public constant MINT_PER_TRANSACTION = 3;
    uint256 public constant PUBLIC_PRICE = 0.06 ether;

    uint256 private constant HUNDRED_PERCENT_IN_BASIS_POINTS = 10000;

    bool private reveal = false;
    string private beforeRevealURI = "ipfs://xxxxx/";
    string private baseTokenURI = "ipfs://xxxxx/";

    // Signer of the whitelist signature
    address private wlSigner;

    // Manage pre1-mint count
    mapping(address => uint256) private pre1Minted;

    // Sales stage status
    struct SalesStatus {
        bool pre1Active;
        bool pre2Active;
        bool publicActive;
    }

    SalesStatus public salesStatus = SalesStatus(false, false, false);    

    // Sales end timestamp
    struct SalesTime {
        uint32 pre1StartAt;
        uint32 pre1EndAt;
        uint32 pre2StartAt;
        uint32 pre2EndAt;
        uint32 publicStartAt;
    }

    SalesTime public salesTime = SalesTime(0, 0, 0, 0, 0);

    // Address of the royalty recipient 
    address payable private defaultRoyaltiesReceipientAddress;

    // Percentage basis points of the royalty
    uint96 private defaultPercentageBasisPoints = 1000;  // 10%

    constructor() ERC721A("BAYPLAY", "BP") {
        defaultRoyaltiesReceipientAddress = payable(address(this));
    }

    function setSigner(address signer) external onlyOwner {
        wlSigner = signer;
    }

    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    function setRevealURI(string calldata newRevealTokenURI) external onlyOwner {
        beforeRevealURI = newRevealTokenURI;
    }

    function startReveal() external onlyOwner {
        reveal = true;
    }

    function revertReveal() external onlyOwner {
        reveal = false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(reveal){
            return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
        }else{
            return beforeRevealURI;
        }
    }    

    function pre1Mint(uint256 quantity, bytes calldata signature) external payable {
        require(salesStatus.pre1Active, "Presale1 mint isn't active");
        require(salesTime.pre1StartAt <= block.timestamp, "Presale1 mint hasn't started");
        require(block.timestamp <= salesTime.pre1EndAt, "Presale1 mint ended");

        // Check total sold
        require(_totalMinted() + quantity <= TOTAL_SUPPLY, "Not enough remaining supply");

        // Check number of pre-mint spots
        require(
            pre1Minted[msg.sender] + quantity <= PRE_LIMIT,
            "Not enough unused pre-mint spots"
        );

        // Check WL eligibility
        require(verifySignature(signature, 1), "Signer address mismatch");

        // Validate the paid amount
        require(msg.value == PRE_PRICE * quantity, "Invalid eth amount");

        // Increment used pre-mint spots
        unchecked { pre1Minted[msg.sender] += quantity; }

        _mint(msg.sender, quantity);
    }

    function pre2Mint(uint256 quantity, bytes calldata signature) external payable {
        require(salesStatus.pre2Active, "Presale2 mint isn't active");
        require(salesTime.pre2StartAt <= block.timestamp, "Presale2 mint hasn't started");
        require(block.timestamp <= salesTime.pre2EndAt, "Presale2 mint ended");

        // Check total sold
        require(_totalMinted() + quantity <= TOTAL_SUPPLY, "Not enough remaining supply");

        // Check quantity
        require(quantity <= MINT_PER_TRANSACTION, "quantity too large");

        // Check WL eligibility
        require(verifySignature(signature, 2), "Signer address mismatch");

        // Validate the paid amount
        require(msg.value == PRE_PRICE * quantity, "Invalid eth amount");

        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(salesStatus.publicActive, "Public mint isn't active");
        require(salesTime.publicStartAt <= block.timestamp, "Public mint hasn't started");

        // Check total sold
        require(_totalMinted() + quantity <= TOTAL_SUPPLY, "Not enough remaining supply");

        // Check number of public-mint spots
        require(quantity <= MINT_PER_TRANSACTION, "quantity too large");

        // Validate the paid amount
        require(msg.value == PUBLIC_PRICE * quantity, "Invalid eth amount");        

        _mint(msg.sender, quantity);
    }

    function teamMint(uint256 quantity, address recipient) external onlyOwner {
        // Check total sold
        require(_totalMinted() + quantity <= TOTAL_SUPPLY, "Not enough remaining supply");

        _mint(recipient, quantity);
    }

    function setSalesStage(bool pre1, bool pre2, bool pub) external onlyOwner {
        salesStatus.pre1Active = pre1;
        salesStatus.pre2Active = pre2;
        salesStatus.publicActive = pub;
    }

    function setSalesTime(uint32 pre1StartAt, uint32 pre1EndAt, uint32 pre2StartAt, uint32 pre2EndAt, uint32 publicStartAt) external onlyOwner {
        salesTime.pre1StartAt = pre1StartAt;
        salesTime.pre1EndAt = pre1EndAt;
        salesTime.pre2StartAt = pre2StartAt;
        salesTime.pre2EndAt = pre2EndAt;
        salesTime.publicStartAt = publicStartAt;
    }

    function getSaleStatus() external view returns (bool, bool, bool) {
        return (
            salesStatus.pre1Active && salesTime.pre1StartAt <= block.timestamp && block.timestamp <= salesTime.pre1EndAt,
            salesStatus.pre2Active && salesTime.pre2StartAt <= block.timestamp && block.timestamp <= salesTime.pre2EndAt,
            salesStatus.publicActive && salesTime.publicStartAt <= block.timestamp
        );
    }

    // Enfoce Royalty
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }    

    // Set the royalty recipient.
    function setDefaultRoyaltiesReceipientAddress(address payable newDefaultRoyaltiesReceipientAddress) external onlyOwner {
        require(newDefaultRoyaltiesReceipientAddress != address(0), "invalid address");
        defaultRoyaltiesReceipientAddress = newDefaultRoyaltiesReceipientAddress;
    }

    // Set the percentage basis points of the loyalty.
    function setDefaultPercentageBasisPoints(uint96 newDefaultPercentageBasisPoints) external onlyOwner {
        defaultPercentageBasisPoints = newDefaultPercentageBasisPoints;
    }

    // Return royality information for Rarible.
    function getRaribleV2Royalties(uint256) external view override returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }

    // Return royality information in EIP-2981 standard.
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (defaultRoyaltiesReceipientAddress, (_salePrice * defaultPercentageBasisPoints) / HUNDRED_PERCENT_IN_BASIS_POINTS);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(ERC721A) 
        returns (bool) 
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }    

    // Withdraw funds
    function withdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "recipient shouldn't be 0");

        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    // For receiving fund
    receive() external payable {}

    // verify WL signature
    function verifySignature(bytes calldata signature, uint8 stage) private view returns (bool) {
        // Message format is 1 byte shifted address + stage (1 byte)
        uint256 message = (uint256(uint160(msg.sender)) << 8) + stage;
        
        return
            wlSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(message)
                    )
                ).recover(signature);
    }
}