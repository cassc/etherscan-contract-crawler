// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract TheAtlasLyonsClub is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 2022;

    uint256 public maxPurchase = 10;
    uint256 public walletLimit = 2;
    uint256 public itemPrice = 0.055 ether;
    bool public isSaleActive;
    bool public isPreSaleActive;

    string private _baseTokenURI;

    address public wallet1 = 0xf83d94C22D8F41808b1BAa88707887374240d741;
    address public wallet2 = 0x457CDa89Ca4119319D4c26679961d072A1d5be2E;
    address public wallet3 = 0xE3Cca74b4C64550Ecf0124028fCF258230849727;
    address public wallet4 = 0x967521795247933C229603739e00C3Da486FE755;

    mapping(address => bool) public allowlist;

    modifier whenPublicSaleActive() {
        require(isSaleActive, "Public sale is not active");
        _;
    }

    modifier whenPreSaleActive() {
        require(isPreSaleActive, "Pre sale is not active");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier checkPrice(uint256 _howMany) {
        require(itemPrice * _howMany <= msg.value, "Ether value sent is not correct");
        _;
    }

    constructor() ERC721A("The Atlas Lyons Club", "ALC", 82, MAX_SUPPLY) {}

    function forAirdrop(address[] memory _to, uint256[] memory _count)
        external
        onlyOwner
    {
        uint256 _length = _to.length;
        for (uint256 i = 0; i < _length; i++) {
            giveaway(_to[i], _count[i]);
        }
    }

    function giveaway(address _to, uint256 _howMany) public onlyOwner {
        require(_to != address(0), "Zero address");
        _beforeMint(_howMany);
        _safeMint(_to, _howMany);
    }

    function _beforeMint(uint256 _howMany) private view {
        require(_howMany > 0, "Must mint at least one");
        uint256 supply = totalSupply();
        require(
            supply + _howMany <= MAX_SUPPLY,
            "Minting would exceed max supply"
        );
    }

    function whitelistMint(uint256 _howMany)
        external
        payable
        nonReentrant
        whenPreSaleActive
        callerIsUser
        checkPrice(_howMany)
    {
        _beforeMint(_howMany);
        require(allowlist[_msgSender()], "Sorry, not whitelisted");
        require(
            numberMinted(_msgSender()) + _howMany <= walletLimit,
            "Wallet limit exceeds"
        );

        _safeMint(_msgSender(), _howMany);
    }

    function saleMint(uint256 _howMany)
        external
        payable
        nonReentrant
        whenPublicSaleActive
        callerIsUser
        checkPrice(_howMany)
    {
        _beforeMint(_howMany);
        require(_howMany <= maxPurchase, "Sorry, too many per transaction");
        _safeMint(_msgSender(), _howMany);
    }

    function startPublicSale() external onlyOwner {
        require(!isSaleActive, "Public sale has already begun");
        isSaleActive = true;
    }

    function pausePublicSale() external onlyOwner whenPublicSaleActive {
        isSaleActive = false;
    }

    function startPreSale() external onlyOwner {
        require(!isPreSaleActive, "Pre sale has already begun");
        isPreSaleActive = true;
    }

    function pausePreSale() external onlyOwner whenPreSaleActive {
        isPreSaleActive = false;
    }

    function addToWhitelistArray(address[] memory _addr) external onlyOwner {
        for (uint256 i; i < _addr.length; i++) {
            addToWhitelist(_addr[i]);
        }
    }

    function addToWhitelist(address _addr) public onlyOwner {
        allowlist[_addr] = true;
    }

    function removeFromWhitelist(address _addr) external onlyOwner {
        allowlist[_addr] = false;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // list all the tokens ids of a wallet
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function updateWallets(
        address _wallet1,
        address _wallet2,
        address _wallet3,
        address _wallet4
    ) external onlyOwner {
        wallet1 = _wallet1;
        wallet2 = _wallet2;
        wallet3 = _wallet3;
        wallet4 = _wallet4;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        _withdraw();
    }

    function _withdraw() internal {
        uint256 bal = accountBalance();
        (bool success1, ) = wallet1.call{value: (bal * 5) / 100}("");
        (bool success2, ) = wallet2.call{value: (bal * 5) / 100}("");
        (bool success3, ) = wallet3.call{value: (bal * 9) / 100}("");
        (bool success4, ) = wallet4.call{value: accountBalance()}("");
        require(
            success1 && success2 && success3 && success4,
            "Transfer failed."
        );
    }

    receive() external payable {
        _withdraw();
    }

    function accountBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        itemPrice = _newPrice;
    }

    function modifyWalletLimit(uint256 _walletLimit) external onlyOwner {
        walletLimit = _walletLimit;
    }

    function modifyMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}