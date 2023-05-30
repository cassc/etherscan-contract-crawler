//SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.7;  
  
import "erc721a/contracts/ERC721A.sol";  
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./../DefaultOperatorFilterer.sol";

contract WanderlustGirls is ERC721A, DefaultOperatorFilterer, ERC2981, Ownable, ReentrancyGuard {  
    using Counters for Counters.Counter;
    
    address public pieContractAddress = 0xfb5aceff3117ac013a387D383fD1643D573bd5b4;
    address public oeContractAddress = 0xd86b1768Fe0fe28d533b85B002aAf24BBdCa3587;

    address public royaltySplit;

    string public baseURI;

    bool public baseURILocked = false;

    uint96 private royaltyBps = 1000;

    uint256 private basePrice = 0.0333 ether;

    uint256 public pieDiscountPct = 20;

    uint256 public maxSupply = 333;

    mapping (uint256 => uint256) public mintedAt;

    mapping (uint256 => uint256) public quantityToDiscountPct;
    mapping (uint256 => bool) public quantityHasDiscount;

    mapping(address => bool) private gifters;

    bool public mintPaused = true;
    bool public whitelistOnly = true;

    modifier onlyGifter() {
        require(gifters[_msgSender()] || owner() == _msgSender(), "Not a gifter");
        _;
    }

    constructor() ERC721A("WanderlustGirls", "WANDERLUST") {
        addQuantityDiscount(5, 5);
        addQuantityDiscount(10, 10);
        addQuantityDiscount(15, 15);
    }

    function addQuantityDiscount(uint256 _quantity, uint256 _discountPct) public onlyOwner {
        quantityToDiscountPct[_quantity] = _discountPct;
        quantityHasDiscount[_quantity] = true;
    }

    function updatePieContractAddress(address _address) public onlyOwner {
        pieContractAddress = _address;
    }

    function updateOEContractAddress(address _address) public onlyOwner {
        oeContractAddress = _address;
    }

    function updateMintPaused(bool _mintPaused) public onlyOwner {
        mintPaused = _mintPaused;
    }

    function updateWhitelistOnly(bool _whitelistOnly) public onlyOwner {
        whitelistOnly = _whitelistOnly;
    }

    function updatePieDiscountPct(uint256 _discountPct) public onlyOwner {
        pieDiscountPct = _discountPct;
    }

    function updateBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    function checkPieHolder(address user) public view returns (bool) {
        IERC721 pieContract = IERC721(pieContractAddress);
        bool hasPie = pieContract.balanceOf(user) > 0;
        return hasPie;
    }

    function checkOEHolder(address user) public view returns (bool) {
        IERC1155 oeContract = IERC1155(oeContractAddress);
        bool hasOE = oeContract.balanceOf(user, 0) > 0;
        return hasOE;
    }

    function checkWhitelisted(address user) public view returns (bool) {
        return checkPieHolder(user) || checkOEHolder(user); 
    }

    function checkPrice(uint256 quantity, address user) public view returns (uint256) {
        bool hasPie = checkPieHolder(user);

        uint256 total = basePrice * quantity;

        uint256 discountPct = 0;

        if(hasPie) {
            discountPct += pieDiscountPct;
        }

        if(quantityHasDiscount[quantity]) {
            discountPct += quantityToDiscountPct[quantity];
        }

        uint256 discountAmt = (total * discountPct) / 100;

        total -= discountAmt;

        return total;
    }

    function mint(uint256 quantity) public payable nonReentrant {
        require(!mintPaused, "minting paused");
        require(totalSupply() + quantity <= maxSupply, "max supply reached");

        if(whitelistOnly) {
            require(checkWhitelisted(msg.sender), "not whitelisted");
        }

        uint256 totalPrice = checkPrice(quantity, msg.sender);

        require(msg.value == totalPrice, "not enough eth sent");

        uint256 minTokenID = totalSupply();
        uint256 maxTokenID = minTokenID + quantity - 1;

        _safeMint(msg.sender, quantity);

        for(uint256 i = minTokenID; i <= maxTokenID; i++) {
            mintedAt[i] = block.timestamp;
        }
    }

    function gift(address[] memory recipients) public onlyGifter {
        require(recipients.length > 0, "no recipients");
        require(totalSupply() + recipients.length <= maxSupply, "max supply reached");

        for (uint256 i = 0; i < recipients.length; i++) {
            _safeMint(recipients[i], 1);
        }
    }

    function updateRoyalty(uint96 _royaltyBps) public onlyOwner {
        require(royaltySplit!=address(0), "split address not set, please set split address before updating royalty");
        royaltyBps = _royaltyBps;
        _setDefaultRoyalty(royaltySplit, royaltyBps);
    }

    function updateBaseURI(string calldata givenBaseURI) public onlyOwner {
        require(!baseURILocked, "base uri locked");
       
        baseURI = givenBaseURI;
    }

    function lockBaseURI() public onlyOwner {
        baseURILocked = true;
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
    }
 
    function setSplitAddress(address _address) public onlyOwner {
        royaltySplit = _address;
        _setDefaultRoyalty(royaltySplit, royaltyBps);
    }

    function withdraw() public onlyOwner {
        require(royaltySplit != address(0), "split address not set");

        (bool success, ) = royaltySplit.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Opensea Operator filter registry
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

    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}