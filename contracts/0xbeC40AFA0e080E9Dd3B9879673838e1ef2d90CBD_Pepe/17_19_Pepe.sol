// ERC721 contract for the Pepe project
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "erc721a/contracts/ERC721A.sol";

contract Pepe is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public supplyLimit = 6969;
    uint256 public mintPrice = 4200000000000000;
    uint256 public whitelistMintPrice = 3690000000000000;

    uint8 public maxMintPerTxn = 10;
    uint8 public maxMintWhitelist = 5;

    address payable public withdrawalWallet;
    string private baseURI;

    bool public saleActive = false;
    bool public whitelistSaleActive = false;

    mapping(address => uint8) public whitelist;

    constructor(
        address payable _withdrawalWallet,
        string memory _name,
        string memory _ticker,
        string memory _baseURI
    ) ERC721A(_name, _ticker) {
        withdrawalWallet = _withdrawalWallet;
        baseURI = _baseURI;
    }

    // Given in WEI
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setWhitelistMintPrice(
        uint256 _whitelistMintPrice
    ) external onlyOwner {
        whitelistMintPrice = _whitelistMintPrice;
    }

    function setWhitelistStatus(
        address _user,
        uint8 _maxMint
    ) public onlyOwner {
        whitelist[_user] = _maxMint;
    }

    function setWhithdrawalWallet(
        address payable _withdrawalWallet
    ) external onlyOwner {
        withdrawalWallet = _withdrawalWallet;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        return whitelist[_user] > 0;
    }

    function setSupplyLimit(uint256 _supplyLimit) external onlyOwner {
        supplyLimit = _supplyLimit;
    }

    function addWhitelist(address[] memory _userList) external onlyOwner {
        for (uint256 i = 0; i < _userList.length; i++) {
            whitelist[_userList[i]] = maxMintWhitelist;
        }
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }

    function toggleWhitelistSaleActive() external onlyOwner {
        whitelistSaleActive = !whitelistSaleActive;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        withdrawalWallet.transfer(contractBalance);
    }

    function buy(uint256 _amount) external payable {
        require(saleActive, "Sale is not active.");
        require(_amount <= maxMintPerTxn, "Max mint per Tx is 10.");
        require(msg.value >= mintPrice.mul(_amount), "Insufficient payment.");
        require(
            totalSupply().add(_amount) <= supplyLimit,
            "Not enough tokens left."
        );

        _safeMint(_msgSender(), _amount);
    }

    function whitelistBuy(uint8 _amount) external payable {
        require(whitelistSaleActive, "Whitelist sale is not active.");
        require(
            msg.value >= whitelistMintPrice.mul(_amount),
            "Insufficient payment."
        );
        require(
            whitelist[_msgSender()] >= _amount,
            "You are not whitelisted or have insufficient whitelist mint-spots left."
        );
        require(
            totalSupply().add(_amount) <= supplyLimit,
            "Not enough tokens left."
        );

        _safeMint(_msgSender(), _amount);
        whitelist[_msgSender()] -= _amount;
    }

    function gift(
        address[] calldata _recipients,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(
            _recipients.length == _amounts.length,
            "Recipient and amount array length mismatch."
        );

        // Check that we enough tokens left in aggregate
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalAmount += _amounts[i];
        }

        require(
            totalSupply().add(totalAmount) <= supplyLimit,
            "Not enough tokens left."
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _safeMint(_recipients[i], _amounts[i]);
        }
    }
}