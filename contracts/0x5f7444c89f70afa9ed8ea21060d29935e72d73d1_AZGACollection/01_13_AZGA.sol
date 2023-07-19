// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";

import "ReentrancyGuard.sol";
import "Ownable.sol";
import "Counters.sol";
import "MerkleProof.sol";
import {IERC2981, ERC2981} from "ERC2981.sol";
import  "OperatorFilterer.sol";

contract AZGACollection is ERC721A, ERC2981, OperatorFilterer, Ownable, ReentrancyGuard {

    bool public saleLive = false;
    bool public presaleLive = false;
    bool public operatorFilteringEnabled;

    bytes32 private whitelistRoot;

    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public MAX_MINT = 2; // This actually means 1 mints but we say 2 for minor gas saving
    uint256 private constant MAX_RESERVED = 185;
    uint256 public giftCount = 0;
    uint256 public PRESALE_PRICE = 0 ether;
    uint256 public PRICE = 0 ether;

    address private dev;
    address private treasury;

    string private _contractURI;
    string private _metadataBaseURI;

    mapping (address => uint256) private presaleMintCount;

    /**
     * @dev modifiers for requirements consistent accorss multiple functions
     */
    modifier checkTokenSupplyAvailable(uint256 mintNum) {
        require(totalSupply() + mintNum < (MAX_SUPPLY - (MAX_RESERVED - giftCount) + 1), "Error: this would exceed max supply");
        _;
    }

    modifier validPayment(uint256 mintNum, uint256 mintPrice) {
        require(mintPrice * mintNum == msg.value, "Error, incorrect amount");
        _;
    }

    modifier addressWhitelisted(bytes32[] calldata merkleProof, bytes32 listRoot) {
        require(MerkleProof.verifyCalldata(merkleProof, listRoot, keccak256(abi.encodePacked(msg.sender))), "You are not on the whitelist");
        _;
    }

    constructor(string memory _cURI, string memory _metaBURI, address _developer, address _treasury) public ERC721A ("AZGA", "Assassin") {
        _contractURI = _cURI;
        _metadataBaseURI = _metaBURI;
        dev = _developer;
        treasury = _treasury;

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(_treasury, 1000);
    }

    /**
     * @dev mint functions: saleMint is open to anyone
     * presaleMint requires whitelist
     * gift can only be called by owner
     */
    function saleMint(uint256 qty) validPayment(qty, PRICE) checkTokenSupplyAvailable(qty) nonReentrant external payable {
        require(saleLive, "Public Mint is currently closed");
        require(qty < MAX_MINT, "Maximum number of mints per transaction reached");
        _mint(msg.sender, qty);
    }
    
    // Presale
    function presaleMint(uint256 qty, bytes32[] calldata merkleProof) validPayment(qty, PRESALE_PRICE) checkTokenSupplyAvailable(qty) addressWhitelisted(merkleProof, whitelistRoot) nonReentrant external payable {
        require(presaleLive, "Presale Mint is currently closed");
        require(presaleMintCount[msg.sender] + qty < MAX_MINT, "Maximum number of tokens for this address reached");
        presaleMintCount[msg.sender] += qty;
        _mint(msg.sender, qty);
    }

    function gift(address[] calldata _recipients, uint256[] calldata _num) external onlyOwner {
        uint256 totalNum;

        for(uint256 i = 0; i < _num.length; i++) {
            totalNum += _num[i];
        }

        require(giftCount + totalNum <= MAX_RESERVED, "Error: this would exceed max gift supply");

        giftCount += totalNum;
        for(uint256 j = 0; j < _recipients.length; j++) {
            _mint(_recipients[j], _num[j]);
        }
    }
    
    /**
     * @dev supporting functions that are used by the team for various things
     */

    /**
     * @dev getOwnersTokens will return an array of all the tokens belonging to input address
     */
    function getOwnersTokens(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        require(balanceOf(_owner) > 0, "Wallet contains no Assassin tokens");
        uint256 tokenCount = balanceOf(_owner);
        uint256 foundTokens = 0;
        uint256[] memory tokenIdsArr = new uint256[](tokenCount);

        for (uint256 i = _startTokenId(); i <= totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                tokenIdsArr[foundTokens] = i;
                foundTokens++;
            }
        }
        return tokenIdsArr;
    }

    /**
     * @dev returnAddressesOfHolder will return an array of addresses belonging to the input tokenIDs
     */
    function returnAddressesOfHolder(uint256[] calldata tokenIds) external view onlyOwner returns (address[] memory) {
        
        address[] memory fetchedAdd = new address[](tokenIds.length);

        for(uint256 i = 0; i < tokenIds.length; i++) {
            fetchedAdd[i] = ownerOf(tokenIds[i]);
        }
        return fetchedAdd;
    }

    /**
     * @dev isHolder is a simple function that returns true if address holder any tokens
     */
    function isHolder(address _owner) external view returns (bool) {
        bool holderStatus = false;
        uint256 bal = balanceOf(_owner);
        if(bal > 0) {
            holderStatus = true;
        }
        return holderStatus;
    }

    /**
     * @dev return the basic status of contract in one func
     * 0: presale state 1: sale state 2: totalSupply 3: giftCount
     */
    function getStatus() external view returns (uint256[4] memory) {
        uint256 pre = presaleLive ? 1 : 0;
        uint256 sl = saleLive ? 1 : 0;
        uint256[4] memory stateData = [pre, sl, totalSupply(), giftCount];
        return stateData;
    }

    function withdrawFunds() public onlyOwner {
        uint256 total = address(this).balance;
        uint256 dev_amt = (total * 5) / 100;

        (bool success_dev, ) = payable(dev).call{value: dev_amt}("");
        (bool success, ) = payable(treasury).call{value: address(this).balance}("");
        require(success_dev, "Failed to send payment to dev.");
        require(success, "Failed to send payment.");
    }

    /**
     * @dev functions to update variables such as baseURI
     */

    function updateMetadataURI(string calldata _URI) external onlyOwner {
        _metadataBaseURI = _URI;
    }

    function updateContractURI(string calldata _URI) external onlyOwner {
        _contractURI = _URI;
    }


    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        whitelistRoot = _root;
    }
    
    function updatePrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function updatePrePrice(uint256 _price) external onlyOwner {
        PRESALE_PRICE = _price;
    }
    
    function updateMaxMint(uint256 _amt) external onlyOwner {
        MAX_MINT = _amt;
    }

    function updateTreasury(address _trsy) external onlyOwner {
        treasury = _trsy;
    }

    /**
     * @dev functions to manage phases of launch
     */
    function togglePresale() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleSale() external onlyOwner {
        saleLive = !saleLive;
    }


    /**
     * @dev read only functions
     */

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    // ERC721A change startTokenID to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


     // OpenSea Registry
     function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721A, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    /**
     * @dev Below is for testing
     */
     function mintUnlimitedTokens(uint256 _num) external checkTokenSupplyAvailable(_num) onlyOwner {
        _mint(msg.sender, _num);
     }
}