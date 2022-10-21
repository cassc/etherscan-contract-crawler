//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/access/AccessControl.sol";
import "./interface/IMinterEtherukoGenesis.sol";
import "./EtherukoGenesis.sol";

contract MinterEtherukoGenesis is
    Ownable,
    IMinterEtherukoGenesis,
    AccessControl
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    EtherukoGenesis public etherukoGenesis;
    address payable public feeTo;

    uint256 public wlPrice = 0.04 ether;
    uint256 public pbPrice = 0.08 ether;

    uint256 public maxTxLimit = 6;

    bool public onSale = false;

    uint256 public maxSale = 3333;
    uint256 public teamSaleLeft = 150;

    mapping(address => bool) public og;
    mapping(address => bool) public whitelist;

    mapping(address => bool) public ogSaled;
    mapping(address => uint8) public whiteListSaleCount;

    uint8 public whiteListSaleMaxCount = 2;

    constructor(EtherukoGenesis _etherukoGenesis, address payable _feeTo) {
        require(
            address(_etherukoGenesis) != address(0),
            "require: _etherukoGenesis is not zero address"
        );
        require(_feeTo != address(0));
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        setGenesis(_etherukoGenesis);
        setFeeTo(_feeTo);
    }

    modifier onlyOg(address account) {
        require(og[account], "require: account must be og");
        _;
    }

    modifier onlyWl(address account) {
        require(whitelist[account], "require: account must be whitelist");
        _;
    }

    modifier onlyOnSale() {
        require(onSale, "require: onSale must be true");
        _;
    }

    function setGenesis(EtherukoGenesis _etherukoGenesis) public onlyOwner {
        require(
            address(_etherukoGenesis) != address(0),
            "require: _etherukoGenesis is not zero address"
        );
        etherukoGenesis = _etherukoGenesis;
    }

    function setFeeTo(address payable _feeTo) public onlyOwner {
        require(_feeTo != address(0), "require: _feeTo is not zero address");
        feeTo = _feeTo;
        emit SetFeeTo(_feeTo);
    }

    function setMaxTxLimit(uint256 _maxTxLimit) public onlyOwner {
        maxTxLimit = _maxTxLimit;
        emit SetMaxTxLimit(_maxTxLimit);
    }

    function setMaxSale(uint256 _maxSale) public onlyOwner {
        maxSale = _maxSale;
        emit SetMaxSale(_maxSale);
    }

    function setTeamSaleLeft(uint256 _teamSaleLeft) public onlyOwner {
        teamSaleLeft = _teamSaleLeft;
        emit SetTeamSaleLeft(_teamSaleLeft);
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }

    function grantAdmin(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, account);
        emit GrantAdmin(account);
    }

    function revokeAdmin(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(ADMIN_ROLE, account);
        emit RevokeAdmin(account);
    }

    function isWhitelist(address account) public view returns (bool) {
        return whitelist[account];
    }

    function grantWhiteList(address[] calldata _wallet)
        public
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _wallet.length; i++) {
            whitelist[_wallet[i]] = true;
        }
        emit GrantWhitelist(_wallet);
    }

    function revokeWhiteList(address[] calldata _wallet)
        public
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _wallet.length; i++) {
            whitelist[_wallet[i]] = false;
        }
        emit RevokeWhitelist(_wallet);
    }

    function grantOG(address[] calldata _wallet) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < _wallet.length; i++) {
            og[_wallet[i]] = true;
        }
        emit GrantOG(_wallet);
    }

    function grantWlAndOg(address[] calldata _wallet)
        public
        onlyRole(ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _wallet.length; i++) {
            og[_wallet[i]] = true;
            whitelist[_wallet[i]] = true;
        }
        emit GrantWlAndOg(_wallet);
    }

    function revokeOG(address[] calldata _wallet) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < _wallet.length; i++) {
            og[_wallet[i]] = false;
        }
        emit RevokeOG(_wallet);
    }

    function isOg(address account) public view returns (bool) {
        return og[account];
    }

    function setWlPrice(uint256 _wlPrice) public onlyRole(ADMIN_ROLE) {
        wlPrice = _wlPrice;
        emit SetWlPrice(_wlPrice);
    }

    function setPbPrice(uint256 _pbPrice) public onlyRole(ADMIN_ROLE) {
        pbPrice = _pbPrice;
        emit SetPbPrice(_pbPrice);
    }

    function setWhiteListSaleMaxCount(uint8 _whiteListSaleMaxCount)
        public
        onlyRole(ADMIN_ROLE)
    {
        whiteListSaleMaxCount = _whiteListSaleMaxCount;
        emit SetWhiteListSaleMaxCount(_whiteListSaleMaxCount);
    }

    function startSale() public onlyRole(ADMIN_ROLE) {
        onSale = true;
        emit StartSale(onSale);
    }

    function stopSale() public onlyRole(ADMIN_ROLE) {
        onSale = false;
        emit StopSale(onSale);
    }

    
    function ogFreeMint() public onlyOg(msg.sender) onlyOnSale {
        require(
            ogSaled[msg.sender] == false,
            "msg.sender already purchased by og"
        );
        ogSaled[msg.sender] = true;
        uint256 totalSupply = etherukoGenesis.totalSupply();
        require(
            totalSupply + 1 <= maxSale,
            "require: totalSupply + 1 <= maxSale"
        );
        etherukoGenesis.safeMint(msg.sender, 1);
        emit OgFreeMint(msg.sender, totalSupply + 1);
    }

    function wlPriceMint(uint256 amount)
        public
        payable
        onlyWl(msg.sender)
        onlyOnSale
    {
        require(
            whiteListSaleCount[msg.sender] < whiteListSaleMaxCount,
            "require: whiteListSaleCount[msg.sender] < whiteListSaleMaxCount"
        );
        whiteListSaleCount[msg.sender] += 1;
        require(amount <= 2, "require: amount must be less than 2");
        uint256 totalSupply = etherukoGenesis.totalSupply();
        uint256 amountAddedBonus = amount == 2 ? 3 : 1;
        require(
            totalSupply + amountAddedBonus <= maxSale - teamSaleLeft,
            "require: totalSupply + amountAddedBonus <= maxSale - teamSaleLeft"
        );
        uint256 totalPrice = amount * wlPrice;
        require(msg.value >= totalPrice, "require: msg.value >= totalPrice");
        etherukoGenesis.safeMint(msg.sender, amountAddedBonus);
        feeTo.transfer(msg.value);
        emit WlPriceMint(
            msg.sender,
            amountAddedBonus,
            totalSupply + amountAddedBonus,
            msg.value
        );
    }

    function pbPriceMint(uint256 amount) public payable onlyOnSale {
        require(amount <= maxTxLimit, "require: amount <= maxTxLimit");
        uint256 totalSupply = etherukoGenesis.totalSupply();
        uint256 amountAddedBonus = amount + (amount / 3);
        require(
            totalSupply + amountAddedBonus <= maxSale - teamSaleLeft,
            "require: totalSupply + amountAddedBonus <= maxSale - teamSaleLeft"
        );
        uint256 totalPrice = amount * pbPrice;
        require(msg.value >= totalPrice, "require: msg.value >= totalPrice");
        etherukoGenesis.safeMint(msg.sender, amountAddedBonus);
        feeTo.transfer(msg.value);
        emit PbPriceMint(msg.sender, amountAddedBonus, totalSupply + amountAddedBonus, msg.value);
    }

    function teamMint(address[] calldata to, uint256[] calldata amount)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(to.length == amount.length, "require: to.length == amount.length");
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < to.length; i++) {
            etherukoGenesis.safeMint(to[i], amount[i]);
            totalAmount += amount[i];
        }
        require(
            teamSaleLeft >= totalAmount,
            "require: teamSaleLeft >= totalAmount"
        );
        teamSaleLeft -= totalAmount;
        emit TeamMint(to, amount);
    }
}