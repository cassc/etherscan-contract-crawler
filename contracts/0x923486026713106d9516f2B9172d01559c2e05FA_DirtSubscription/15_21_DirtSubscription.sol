pragma solidity ^0.8.4;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DirtSubscription is 
    ERC721ABurnable, 
    ERC721AQueryable, 
    OperatorFilterer, 
    AccessControlEnumerable,
    ERC2981
{
    AggregatorV3Interface internal priceFeed;

    bool public operatorFilteringEnabled;
    uint256 public priceInUSD = 60; // price in dollars
    bool public open = false;
    string private _baseTokenURI;
    uint256 private _soulBoundExpiry = 1704067200; // unix timestamp in seconds: Jan 01 2024 00:00:00 UTC
    
    // mapping: tokenId -> unix timestamp for soulbound expiration
    mapping(uint256 => uint256) public _tokenSoulBoundExpiry;

    bytes32 public constant FINANCIER_ROLE = keccak256("FINANCIER_ROLE");

    
    constructor(address _priceFeed) ERC721A("DirtSubscription", "DS") {
        priceFeed = AggregatorV3Interface(_priceFeed); // To pass in the mock
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FINANCIER_ROLE, msg.sender);
        
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

     function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721A, AccessControlEnumerable, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Returns the latest price in ETH / USD
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            // int256 answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            // uint80 answeredInRound,
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getMintCost() public view returns (uint256) {
        int latestPriceEthByUSD =  getLatestPrice(); // 8 decimals returned
        uint256 priceInteger = uint256(latestPriceEthByUSD) / 1e8;
        uint256 mintCostByWei = (priceInUSD * 1e18) / priceInteger;
        return mintCostByWei;
    }

    function mintSubscription() external payable {
        require(open, "NOT OPEN");
        require(msg.value >= getMintCost(), "Not enough ETH");
        uint256 nextTokenId = _nextTokenId();
        _tokenSoulBoundExpiry[nextTokenId] = _soulBoundExpiry;
        _mint(msg.sender, 1);
    }

    function mintGiftSubscription(address recipient) external payable {
        require(open, "NOT OPEN");
        require(msg.value >= getMintCost(), "Not enough ETH");
        uint256 nextTokenId = _nextTokenId();
        _tokenSoulBoundExpiry[nextTokenId] = _soulBoundExpiry;
        _mint(recipient, 1);
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
            "NFT does not exist"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }
     // Needed for opensea royalty control
    function owner() public view virtual returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /// @dev See {ERC721A-_startTokenId}.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setOpen(bool open_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        open = open_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function setSoulBoundExpiry(uint256 soulBoundExpiry) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _soulBoundExpiry = soulBoundExpiry;
    }

    function setPriceInUSD(uint256 _priceInUSD) external onlyRole(DEFAULT_ADMIN_ROLE) {
        priceInUSD = _priceInUSD;
    }

    function _mayTransfer(uint256 tokenId)
        private
        view
        returns (bool) 
        {
        return block.timestamp > _tokenSoulBoundExpiry[tokenId];
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (
            from != address(0) && // ignore mint
            to != address(0) && // ignore burn
            !_mayTransfer(startTokenId) 
        ) {
            revert("Cannot transfer until soulbound expires");
        }
    }
    
    function withdrawEther() external onlyRole(FINANCIER_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

   /*//////////////////////////////////////////////////////////////
                        Opensea royalty enforcer FUNCTIONS
    //////////////////////////////////////////////////////////////*/
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

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    
}