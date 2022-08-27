//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721Base.sol";
import "./Proxyable.sol";

contract NFTSales is Ownable, ReentrancyGuard, Proxyable, ERC721Base {
    using Strings for uint256;

    bool public saleActive;
    uint256 public maxPerMint;
    uint256 public maxPerWallet;
    uint256 public maxSupply;
    uint256 public price;
    address public treasury;

    event WithdrawRevenue(address indexed sender, uint256 indexed amount);

    error ExceedsMaxPerMint(uint256 max, uint256 requested);
    error ExceedsMaxPerWallet(uint256 max, uint256 balance);
    error ExceedsMaxSupply(uint256 max, uint256 requested);
    error InsufficientPayment(uint256 sent, uint256 required);
    error SaleIsClosed();
    error ValueCannotBeZero();

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxPerMint,
        uint256 _maxPerWallet,
        string memory _uri,
        address _treasury
    ) ERC721Base(name, symbol) notZeroAddress(_treasury) {
        maxSupply = _maxSupply;
        price = _price;
        maxPerMint = _maxPerMint;
        maxPerWallet = _maxPerWallet;
        treasury = _treasury;
        _tokenBaseURI = _uri;
    }

    receive() external payable onlyOwner {}

    modifier saleIsActive() {
        if (!saleActive) revert SaleIsClosed();
        _;
    }

    function airdrop(address[] calldata receivers, uint256[] calldata amounts)
        external
        onlyOwner
    {
        _airdrop(receivers, amounts);
    }

    function batchMint(address receiver, uint256 amount) external onlyProxy {
        _batchMint(receiver, amount);
    }

    function mint(address receiver) external onlyProxy {
        _mint(receiver);
    }

    function buy() external payable saleIsActive nonReentrant {
        _paymentAmountValid(1);
        _checkMaxSupply(1);
        _checkMaxPerWallet(1);
        _mint(_msgSender());
    }

    function batchBuy(uint256 amount)
        external
        payable
        saleIsActive
        nonReentrant
    {
        _paymentAmountValid(amount);
        _checkMaxPerMint(amount);
        _checkMaxSupply(amount);
        _checkMaxPerWallet(amount);

        _batchMint(_msgSender(), amount);
    }

    function setMaxPerMint(uint256 value) external onlyOwner {
        _checkNonZero(value);
        maxPerMint = value;
    }

    function setMaxPerWallet(uint256 value) external onlyOwner {
        _checkNonZero(value);
        maxPerWallet = value;
    }

    function setPrice(uint256 value) external onlyOwner {
        price = value;
    }

    function setSaleActive(bool value) external onlyOwner {
        saleActive = value;
    }

    function setTreasury(address _treasury)
        external
        onlyOwner
        notZeroAddress(_treasury)
    {
        treasury = _treasury;
    }

    function updateConfig(
        bool _saleActive,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _maxPerMint,
        uint256 _maxPerWallet,
        string calldata tokenBaseURI
    ) external onlyOwner {
        saleActive = _saleActive;
        maxSupply = _maxSupply;
        price = _price;
        maxPerMint = _maxPerMint;
        maxPerWallet = _maxPerWallet;
        _tokenBaseURI = tokenBaseURI;
    }

    // withdraw native to treasury
    function withdrawRevenue() external {
        require(
            _msgSender() == owner() ||
                _msgSender() == treasury ||
                proxyToApproved[_msgSender()],
            "Not allowed"
        );
        uint256 amount = address(this).balance;
        if (amount == 0) return;
        (bool success, ) = treasury.call{value: amount}("");
        require(success, "Transfer failed");
        emit WithdrawRevenue(_msgSender(), amount);
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            proxyToApproved[operator] ||
            super.isApprovedForAll(_owner, operator);
    }

    function _checkNonZero(uint256 _value) private pure {
        if (_value == 0) revert ValueCannotBeZero();
    }

    function _checkMaxSupply(uint256 amount) private view {
        amount += totalSupply;
        if (amount > maxSupply)
            revert ExceedsMaxSupply({max: maxSupply, requested: amount});
    }

    function _checkMaxPerMint(uint256 amount) private view {
        if (amount > maxPerMint)
            revert ExceedsMaxPerMint({max: maxPerMint, requested: amount});
    }

    function _checkMaxPerWallet(uint256 amount) private view {
        amount += balanceOf(_msgSender());
        if (amount > maxPerWallet)
            revert ExceedsMaxPerWallet({max: maxPerWallet, balance: amount});
    }

    function _paymentAmountValid(uint256 amount) private view {
        uint256 requiredAmount = amount * price;
        if (requiredAmount != msg.value)
            revert InsufficientPayment({
                sent: msg.value,
                required: requiredAmount
            });
    }
}