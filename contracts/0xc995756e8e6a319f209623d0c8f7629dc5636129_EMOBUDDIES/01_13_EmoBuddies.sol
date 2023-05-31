// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "SafeMath.sol";
import "Address.sol";

import "ERC721A.sol";

contract EMOBUDDIES is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    // CONTRACT VARIABLES

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_PURCHASABLE = 5;
    uint256 public tokenPrice = 0.03 ether; // 0.03 ETH
    uint256 public allowListMaxMint = 5;
    string public baseURIExtended = "https://www.emobuddies.io/api/";
    string public extension = ""; // configurable extension
    bool public saleIsActive = false;
    bool public allowlistActive = false;

    // team wallet addresses
    address a0 = 0x6b0AF3Dc5fd8073cc556Fc3B7CdE477f53e86Ce7; // chase
    address a1 = 0xF4c6C3909A5CA4F0DcB70aeBe4B2D9BeAd9A8f48; // plug
    address a2 = 0x69Fda80bEd38BEF4a5aa21e582ce36b498A61783; // lauren
    address a3 = 0x4A52DE265141479F44644A551Be51F7460316A88; // rusty
    address a4 = 0xeF8E16708D2Bd570Ed1965088fCF221De6e964eF; // catalyst digital
    address a5 = 0xBa194a2E4094326755B8B1C97784c0C8636f0AB4; // maddi
    address a6 = 0x476806EDc6B83203d92DF4C69e0BB0c173516D0B; // wen

    mapping(address => bool) private _allowList;
    mapping(address => uint256) private _allowListClaimed;
    mapping(address => uint256) private _publicClaimed;

    // CONSTRUCTOR

    constructor() ERC721A("EMO BUDDIES", "EMOBUDDIES") {
        _safeMint(owner(), 1); // one to initialize the contract
    }

    // MODIFIERS

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // SETTER FUNCTIONS

    function openSale() external onlyOwner {
        saleIsActive = true;
    }

    function closeSale() external onlyOwner {
        saleIsActive = false;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURIExtended = _uri;
    }

    function setTokenPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
    }

    function setExtension(string memory _extension) external onlyOwner {
        extension = _extension;
    }

    // minting for free to wallet
    // use to reserve for team, pay mods, etc
    function reserveTokens(address to, uint256 numberOfTokens)
        external
        onlyOwner
    {
        require(
            numberOfTokens > 0 && numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "Not enough reserve left for team"
        );

        _safeMint(to, numberOfTokens);
    }

    function publicListClaimedBy(address owner)
        external
        view
        returns (uint256)
    {
        require(owner != address(0), "Zero address not on Allow List");

        return _publicClaimed[owner];
    }

    // ALLOWLIST FUNCTIONS

    function openAllowList() external onlyOwner {
        allowlistActive = true;
    }

    function closeAllowList() external onlyOwner {
        allowlistActive = false;
    }

    function setAllowListMaxMint(uint256 _maxMint) external onlyOwner {
        allowListMaxMint = _maxMint;
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _allowList[addresses[i]] = true;

            _allowListClaimed[addresses[i]] > 0
                ? _allowListClaimed[addresses[i]]
                : 0;
        }
    }

    function allowListClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address not on Allow List");

        return _allowListClaimed[owner];
    }

    function onAllowList(address addr) external view returns (bool) {
        return _allowList[addr];
    }

    function removeFromAllowList(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(
                addresses[i] != address(0),
                "Can't remove the null address"
            );

            // We don't want to reset possible _allowListClaimed numbers.
            _allowList[addresses[i]] = false;
        }
    }

    // ALLOWLIST MINT

    function purchaseAllowList(uint256 numberOfTokens)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(allowlistActive, "Allowlist is not active");
        require(numberOfTokens > 0, "Minimum mint is 1 token");
        require(_allowList[msg.sender], "You are not on the Allowlist");
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed MAX_SUPPLY"
        );
        require(
            _allowListClaimed[msg.sender] + numberOfTokens <= allowListMaxMint,
            "Purchase exceeds max allowed"
        );
        require(
            tokenPrice * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );
        _safeMint(msg.sender, numberOfTokens);
        _allowListClaimed[msg.sender] += numberOfTokens;
    }

    // PUBLIC MINT

    function mint(uint256 numberOfTokens)
        external
        payable
        callerIsUser
        nonReentrant
    {
        require(saleIsActive, "Sale is not active");
        require(numberOfTokens > 0, "Minimum mint is 1 token");
        require(
            _publicClaimed[msg.sender] + numberOfTokens <= MAX_PURCHASABLE,
            "Purchase exceeds max allowed"
        );
        require(
            totalSupply() + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed MAX_SUPPLY"
        );
        require(
            tokenPrice * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );

        _safeMint(msg.sender, numberOfTokens);
        _publicClaimed[msg.sender] += numberOfTokens;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), extension)
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIExtended;
    }

    // WITHDRAW

    // WITHDRAW FUNCTIONS

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");

        _widthdraw(a1, balance.mul(20).div(100)); // plug 20%
        _widthdraw(a2, balance.mul(15).div(100)); // lauren 15%
        _widthdraw(a3, balance.mul(10).div(100)); // rusty 10%
        _widthdraw(a4, balance.mul(5).div(100)); // cd 5%
        _widthdraw(a5, balance.mul(2).div(100)); // maddi 2%
        _widthdraw(a6, balance.mul(4).div(100)); // wen 4%
        _widthdraw(a0, address(this).balance); // rest to chase - 44%
    }

    // Private Function -- Only Accesible By Contract
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}