// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ERC721A.sol";
import "Strings.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Pausable.sol";

contract CryptoCossacksClubERC721A is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    using Strings for uint256;

    mapping(address => uint16) public mintedMapping;
    mapping(address => uint16) public whiteListMintedMapping;
    uint256 public salePrice = 150000000000000000;
    uint256 public whiteListPrice = 100000000000000000;
    uint256 private whiteListCode = 28061971;
    uint8 public charityPaymentPercent = 50;
    uint16 public maxSupply = 5000;
    uint16 public maxPerWallet = 100;
    uint16 public maxPerWalletWhiteList = 100;
    uint16 private _giveAwayStartIndex = 0;
    uint16 private _giveAwayAmount = 50;
    string private baseURI =
        "https://cryptocossacks.mypinata.cloud/ipfs/QmbwBEfoYbdCPRh4txUu8oRWtD5djmnKLws3kEQNBrNqkP/";
    bool public publicMintStatus = false;
    bool public whiteListMintStatus = true;
    address[] public charityWithdrawAddresses = [
        address(0x165CD37b4C644C2921454429E7F9358d18A45e14),
        address(0xa1b1bbB8070Df2450810b8eB2425D543cfCeF79b),
        address(0xfc0b52E020223c98a546F814cdA6d7872D74b386)
    ];

    event PublicMint(
        address indexed mintAuthor,
        uint16 indexed amount,
        uint256 indexed value
    );
    event WhiteListMint(
        address indexed mintAuthor,
        uint16 indexed amount,
        uint256 indexed value
    );

    constructor() ERC721A("CryptoCossacks Club", "CCC") {}

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!paused(), "ERC721Pausable: token transfer while paused");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        salePrice = price;
    }

    function setWhiteListCode(uint256 code) external onlyOwner {
        whiteListCode = code;
    }

    function setWhitelistSalePrice(uint256 price) external onlyOwner {
        whiteListPrice = price;
    }

    function setCharityPaymentPercent(uint8 amount) external onlyOwner {
        charityPaymentPercent = amount;
    }

    function setMaxSupply(uint16 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setGiveAwayStartIndex(uint16 index) external onlyOwner {
        _giveAwayStartIndex = index;
    }

    function setGiveAwayAmount(uint16 amount) external onlyOwner {
        _giveAwayAmount = amount;
    }

    function setMaxPerWallet(uint16 amount) external onlyOwner {
        maxPerWallet = amount;
    }

    function setMaxPerWalletWhiteList(uint16 amount) external onlyOwner {
        maxPerWalletWhiteList = amount;
    }

    function setPublicMintStatus() external onlyOwner {
        publicMintStatus = !publicMintStatus;
    }

    function setWhiteListMintStatus() external onlyOwner {
        whiteListMintStatus = !whiteListMintStatus;
    }

    function pauseSales() external onlyOwner {
        _pause();
    }

    function unpauseSales() external onlyOwner {
        _unpause();
    }

    function setCharityWithdrawWallets(address[] memory newWithdrawAddresses)
        external
        onlyOwner
    {
        charityWithdrawAddresses = newWithdrawAddresses;
    }

    function withdraw(address withdrawAddress) external onlyOwner nonReentrant {
        require(
            charityWithdrawAddresses.length > 0,
            "First setup charityWithdrawAddresses please"
        );
        uint256 amount = address(this).balance;
        uint256 amountOfAddresses = charityWithdrawAddresses.length;
        uint256 toWithdrawCharity = ((amount * charityPaymentPercent) / 100) /
            amountOfAddresses;
        uint256 toWithdrawTeam = amount -
            ((amount * charityPaymentPercent) / 100);
        Address.sendValue(payable(withdrawAddress), toWithdrawTeam);
        for (uint8 i = 0; i < charityWithdrawAddresses.length; i++) {
            Address.sendValue(
                payable(charityWithdrawAddresses[i]),
                toWithdrawCharity
            );
        }
    }

    function withdrawGiveAway(address[] memory _addresses)
        external
        onlyOwner
        nonReentrant
    {
        require(
            _addresses.length == _giveAwayAmount,
            "You try to withdraw different amount of nfts that in giveAwayAmount"
        );
        for (uint8 i = 0; i < _addresses.length; i++) {
            safeTransferFrom(
                msg.sender,
                _addresses[i],
                _giveAwayStartIndex + i
            );
        }
    }

    function ownerMint(uint16 amount, address recipient)
        external
        onlyOwner
        whenNotPaused
    {
        require(
            _currentIndex + amount <= maxSupply,
            "Not enough tokens to mint!"
        );
        mintedMapping[recipient] += amount;
        _safeMint(recipient, amount);
    }

    function _corePublicMint(uint16 amount, address recipient) private {
        require(publicMintStatus, "Minting is not active!");
        require(
            _currentIndex + amount <= maxSupply,
            "Not enough tokens to mint!"
        );
        require(
            mintedMapping[recipient] + amount <= maxPerWallet,
            "You can't mint more tokens than maxPerWallet"
        );
        require(msg.value == salePrice * amount, "Incorrect amount!");
        mintedMapping[recipient] += amount;
        emit PublicMint(recipient, amount, msg.value);
        _safeMint(recipient, amount);
    }

    function publicMint(uint16 amount)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        _corePublicMint(amount, msg.sender);
    }

    function crossmintPublicMint(uint16 amount, address recipient)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        _corePublicMint(amount, recipient);
    }

    function _coreWhitelistMint(
        uint16 amount,
        address recipient,
        uint256 code
    ) private {
        require(whiteListMintStatus, "WhiteList minting is not active!");
        require(
            whiteListCode == code,
            "Sorry, but you are not in the whitelist"
        );
        require(
            whiteListMintedMapping[recipient] + amount <= maxPerWalletWhiteList,
            "You can't mint more tokens than maxPerWalletWhiteList"
        );
        require(
            _currentIndex + amount <= maxSupply,
            "Not enough tokens to mint!"
        );
        require(msg.value == whiteListPrice * amount, "Incorrect amount!");
        mintedMapping[recipient] += amount;
        whiteListMintedMapping[recipient] += amount;
        emit WhiteListMint(recipient, amount, msg.value);
        _safeMint(recipient, amount);
    }

    function crossmintWhitelistMint(
        uint16 amount,
        address recipient,
        uint256 code
    ) external payable nonReentrant whenNotPaused {
        _coreWhitelistMint(amount, recipient, code);
    }

    function whitelistMint(uint16 amount, uint256 code)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        _coreWhitelistMint(amount, msg.sender, code);
    }
}