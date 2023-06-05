// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

/*
BOT-X-CLUB
Website: https://botx-club.com
2022
*/

// @author Arraya

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
//    ______  _____ _____    __   __      _____  _     _   _______    //
//    | ___ \|  _  |_   _|   \ \ / /     /  __ \| |   | | | | ___ \   //
//    | |_/ /| | | | | |______\ V /______| /  \/| |   | | | | |_/ /   //
//    | ___ \| | | | | |______/   \______| |    | |   | | | | ___ \   //
//    | |_/ /\ \_/ / | |     / /^\ \     | \__/\| |___| |_| | |_/ /   //
//    \____/  \___/  \_/     \/   \/      \____/\_____/\___/\____/    //
//                                                                    //
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./base/extensions/ERC721AQueryable.sol";
import "./interface/IBotXNFT.sol";
import "./interface/IBotXToken.sol";

contract BotXNFT is Pausable, Ownable, ERC721AQueryable, IBotXNFT {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeMath for uint256;

    IBotXToken public botXToken;

    // Image Placeholder URI
    string public placeHolderURI;

    // Public Reveal Status
    bool public PublicRevealStatus = false;

    bool public SaleStatus = false;

    address public raffleToken;

    // General details
    uint256 public constant maxSupply = 10000;

    bytes32 public merkleRoot;

    // Owner Wallet Address to withdraw
    address public constant ownerWallet =
        0xFea483E08BD1996b5bA1f29a3521BCf5CB4a5631;

    // Team Wallet Address to withdraw
    address public constant teamWallet =
        0x02405E4bfdc8DC4d61F5bA785988eb786606F6fB;

    // Public sale details
    uint256 public price = 0.12 ether; // Public sale price
    uint256 public publicSaleTransLimit = 10; // Public sale limit per transaction
    bool public publicSaleStarted; // Flag to enable public sale
    mapping(address => uint256) public mintListPurchases;
    //Address => tokenIDs
    mapping(address => uint256) public mintRecords;

    mapping(address => uint256) public raffleRecords;
    address[] public raffleTicketsHolders;

    uint256 public preSaleTransLimit = 5;
    // Presale sale details
    uint256 public preSalePrice = 0.085 ether;
    uint256 public raffleTicketPrice = 20 ether;
    uint256 public preSaleMintLimit = 10; // Presale limit per wallet
    uint256 public preSaleAmountMinted;
    mapping(address => uint256) public preSaleListPurchases;

    // Reserve details for founders / gifts
    uint256 private reservedSupply = 1000;

    mapping(address => bool) internal admins;

    // Metadata details
    string _baseTokenURI;
    string _contractURI;

    modifier onlyAdmin() {
        require(admins[_msgSender()], "Caller is not the admin");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory _placeHolderURI,
        string memory baseURI,
        IBotXToken _botXToken
    ) ERC721A(name, symbol) {
        placeHolderURI = _placeHolderURI;
        _baseTokenURI = baseURI;
        admins[_msgSender()] = true;
        botXToken = _botXToken;
        _pause();
    }

    // Public sale functions

    function mint(uint256 _nbTokens) external payable whenNotPaused {
        require(SaleStatus, "Public sale not yet started");

        // Public sale minting
        require(
            _nbTokens <= publicSaleTransLimit,
            "You cannot mint that many NFTs at once"
        );
        require(
            totalSupply() + _nbTokens <= maxSupply - reservedSupply,
            "Not enough Tokens left."
        );
        require(_nbTokens * price <= msg.value, "Insufficient ETH");
        mintListPurchases[msg.sender] += _nbTokens;
        _safeMint(msg.sender, _nbTokens);
    }

    function merkleMint(
        uint256 numberOfTokens,
        uint256 maxQuantity,
        bytes32[] memory _merkleProof
    ) public payable whenNotPaused {
        require(!SaleStatus, "Pre-sale not running");

        require(
            preSaleListPurchases[msg.sender] + numberOfTokens <=
                preSaleMintLimit,
            "Exceeded presale allowed buy limit"
        );

        require(preSalePrice * numberOfTokens <= msg.value, "Insufficient ETH");

        require(
            totalSupply() + numberOfTokens <= maxSupply,
            "MerkleMint: Mint would exceed max supply"
        );
        require(
            totalSupply() + numberOfTokens <= maxSupply - reservedSupply,
            "Not enough Tokens left."
        );
        bytes32 node = keccak256(abi.encode(msg.sender, maxQuantity));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "MerkleMint: Address not eligible for mint"
        );

        require(
            balanceOf(msg.sender) + numberOfTokens <= maxQuantity,
            "MerkleMint: Mint would exceed max allowed"
        );

        preSaleAmountMinted += numberOfTokens;
        preSaleListPurchases[msg.sender] += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function setPublicSaleTransLimit(uint256 limit) external onlyAdmin {
        publicSaleTransLimit = limit;
    }

    function setPreSaleTransLimit(uint256 limit) external onlyAdmin {
        preSaleTransLimit = limit;
    }

    // Make it possible to change the price: just in case
    function setPublicPrice(uint256 _newPrice) external onlyAdmin {
        price = _newPrice;
    }

    function getPublicPrice() public view returns (uint256) {
        return price;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IBotXNFT, IERC721A)
        returns (address)
    {
        return super.ownerOf(tokenId);
    }

    function setPreSalePrice(uint256 _newPreSalePrice) external onlyOwner {
        preSalePrice = _newPreSalePrice;
    }

    function getPreSalePrice() public view returns (uint256) {
        return preSalePrice;
    }

    function setPreSaleMintLimit(uint256 _newPresaleMintLimit)
        external
        onlyOwner
    {
        preSaleMintLimit = _newPresaleMintLimit;
    }

    function getReservedLeft() public view returns (uint256) {
        return reservedSupply;
    }

    // Make it possible to change the reserve only if sale not started: just in case
    function setReservedSupply(uint256 _newReservedSupply) external onlyOwner {
        reservedSupply = _newReservedSupply;
    }

    // Storefront metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _URI) external onlyOwner {
        _contractURI = _URI;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    // Reserve functions
    // Owner to send reserve NFT to address
    function sendReserve(address _receiver, uint256 _nbTokens)
        public
        onlyAdmin
    {
        require(
            totalSupply() + _nbTokens <= maxSupply - reservedSupply,
            "Not enough supply left"
        );
        require(
            _nbTokens <= reservedSupply,
            "That would exceed the max reserved"
        );
        _safeMint(_receiver, _nbTokens);
        reservedSupply = reservedSupply - _nbTokens;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 ownerAmount = _balance.mul(95).div(100); // 95 % ETH amount
        require(payable(ownerWallet).send(ownerAmount)); // send the owner withdraw amount to constant owner wallet
        require(payable(teamWallet).send(address(this).balance)); // send the team withdraw amount to constant team wallet
    }

    function burn(uint256 tokenId) external onlyAdmin {
        super._burn(tokenId);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (bool)
    {
        if (admins[owner] || admins[operator]) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A, IBotXNFT, IERC721A) {
        super.transferFrom(from, to, tokenId);
    }

    function buyTickets(uint256 amount) public {
        require(
            address(botXToken) != address(0),
            "BotXNFT: CLUB Token address failed!"
        );
        uint256 totalPrice = amount.mul(raffleTicketPrice);
        if (!admins[_msgSender()]) {
            require(
                IERC20(address(botXToken)).balanceOf(_msgSender()) >=
                    totalPrice,
                "BotXNFT: caller's token amount is not enough!"
            );
            botXToken.burn(_msgSender(), totalPrice);
        }
        if (raffleRecords[_msgSender()] == 0) {
            raffleTicketsHolders.push(_msgSender());
        }
        raffleRecords[_msgSender()] += amount;
    }

    function getRaffleTicketsHolderList()
        public
        view
        returns (address[] memory, uint256)
    {
        return (raffleTicketsHolders, raffleTicketsHolders.length);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        require(tokenId <= totalSupply(), "Token does not exist");
        if (PublicRevealStatus) {
            return string(abi.encodePacked(_baseURI(), tokenId.toString()));
        } else {
            return placeHolderURI;
        }
    }

    function setPlaceholderURI(string memory uri) public onlyAdmin {
        placeHolderURI = uri;
    }

    function togglePublicReveal() external onlyAdmin {
        PublicRevealStatus = !PublicRevealStatus;
    }

    function getMintRecord(address _minter) public view returns (uint256) {
        return mintRecords[_minter];
    }

    // Function to grant admin role
    function addAdminRole(address _address) external onlyOwner {
        admins[_address] = true;
    }

    // Function to revoke admin role
    function revokeAdminRole(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function hasAdminRole(address _address) external view returns (bool) {
        return admins[_address];
    }

    function setPaused(bool _paused) public onlyAdmin {
        if (!_paused) {
            _unpause();
        } else {
            _pause();
        }
    }

    function setMerkleRoot(bytes32 _hash) external onlyAdmin {
        merkleRoot = _hash;
    }

    function flipSaleStatus() public onlyAdmin {
        SaleStatus = !SaleStatus;
    }

    function setRaffleToken(address _raffleToken) external onlyAdmin {
        raffleToken = _raffleToken;
    }

    function setRaffleTicketPrice(uint256 _price) external onlyAdmin {
        raffleTicketPrice = _price;
    }

    function setBotXTokenContract(IBotXToken _tokenAddress) public onlyAdmin {
        botXToken = _tokenAddress;
    }
}