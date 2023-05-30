//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IDropspaceSale.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DropspaceSale is IDropspaceSale, ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public override totalSupply = 0;
    uint256 public override mintLimit;
    uint256 public override mintPrice;
    uint256 public override supplyLimit;

    string public override baseURI;

    bool public override smartContractAllowance = false;
    bool public override saleActive;
    bool public override presaleActive;
    bool public override whitelistSaleActive;

    address payable public override withdrawalWallet;
    address payable public override devWallet;
    address public override ticketAddress;

    bool public override whitelistBuyOnce;

    uint256 devSaleShare;
    uint256 ownerSaleShare;

    mapping(uint256 => bool) public override usedTickets;
    mapping(address => bool) public override whitelist;

    constructor(
        uint256 _supplyLimit, 
        uint256 _mintLimit,
        uint256 _mintPrice,
        uint256 _devSaleShare,
        address payable _withdrawalWallet,
        address payable _devWallet,
        address _ticketAddress,
        string memory _name,
        string memory _ticker,
        string memory _baseURI
    ) ERC721(_name, _ticker) {
        supplyLimit = _supplyLimit;
        mintLimit = _mintLimit;
        mintPrice = _mintPrice;
        withdrawalWallet = _withdrawalWallet;
        devWallet = _devWallet;
        ticketAddress = _ticketAddress;
        baseURI = _baseURI;
        devSaleShare = _devSaleShare;
        ownerSaleShare = uint256(10000).sub(devSaleShare);
    }

    modifier onlyWithdrawalWallet() {
        require(address(withdrawalWallet) == _msgSender(), 
            "DropspaceSale: caller is not the withdrawal wallet");
        _;
    }

    function setWhitelistBuyOnce(bool _whitelistBuyOnce) external onlyOwner override {
        whitelistBuyOnce = _whitelistBuyOnce;
        emit WhitelistBuyOnceChanged(whitelistBuyOnce);
    }

    function emergencyWithdraw() external onlyOwner override {
        payable(owner()).transfer(address(this).balance);
    }

    function changeSupplyLimit(uint256 _supplyLimit) external onlyOwner override {
        supplyLimit = _supplyLimit;
        emit SupplyLimitChanged(_supplyLimit);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner override {
        mintPrice = _mintPrice;
        emit MintPriceChanged(_mintPrice);
    }

    function setWhitelistStatus(address _user, bool _status) public onlyOwner override {
        whitelist[_user] = _status;
        emit WhitelistStatusChanged(_user, _status);
    }

    function addWhitelist(address[] memory _userList) external onlyOwner override {
        for(uint256 i = 0; i < _userList.length; i++) {
            whitelist[_userList[i]] = true;
            emit WhiteListAdded(_userList[i], true);
        }
    }

    function setDevSaleShare(uint256 _devSaleShare) external override onlyOwner {
        devSaleShare = _devSaleShare;
        ownerSaleShare = uint256(10000).sub(devSaleShare);
        emit DevShareSaleChanged(devSaleShare);
    }

    function toggleSaleActive() external onlyOwner override {
        saleActive = !saleActive;
        emit ToggleSaleState(saleActive);
    }

    function toggleWhitelistSaleActive() external onlyOwner override {
        whitelistSaleActive = !whitelistSaleActive;
        emit ToggleWhitelistSaleState(whitelistSaleActive);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner override {
        baseURI = _baseURI;
        emit BaseURIChanged(baseURI);
    }

    function setSmartContractAllowance(bool _smartContractAllowance) external onlyOwner override {
        smartContractAllowance = _smartContractAllowance;
        emit SmartContractAllowanceChanged(smartContractAllowance);
    }

    function setWithdrawalWallet(address payable _withdrawalWallet) external onlyOwner override {
        withdrawalWallet = _withdrawalWallet;
        emit WithdrawalWalletChanged(withdrawalWallet);
    }

    function setDevWallet(address payable _devWallet) external onlyOwner override {
        devWallet = _devWallet;
        emit DevWalletChanged(devWallet);
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner override {
        mintLimit = _mintLimit;
        emit MintLimitChanged(mintLimit);
    }

    function withdraw() external onlyOwner override  {
        uint256 contractBalance = address(this).balance;
        devWallet.transfer(contractBalance.mul(devSaleShare).div(10000));
        withdrawalWallet.transfer(contractBalance.mul(ownerSaleShare).div(10000));
    }

    function reserve(uint256 _amount) external onlyOwner override {
        _mint(_amount);
        emit Reserve(_amount);
    }

    function buy(uint256 _amount) external override payable {
        require(saleActive, "Dropspace::buy: Sale is not active.");
        require(_amount <= mintLimit, "Dropspace::buy: Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_amount), "Dropspace::buy: Insufficient payment.");

        if (!smartContractAllowance) {
            require(tx.origin == _msgSender(), "Dropspace::buy: Smart contracts are not allowed to buy.");
        }

        _mint(_amount);
    }

    function _mint(uint256 _amount) internal {
        require(totalSupply.add(_amount) <= supplyLimit, "Not enough tokens left.");

        uint256 newId = totalSupply;
        for(uint i = 0; i < _amount; i++) {
            newId = newId.add(1);
            totalSupply = totalSupply.add(1);

            _safeMint(_msgSender(), newId);
            emit Mint(_msgSender(), newId, tokenURI(newId));
        }
    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? 
            string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }

    function togglePresaleActive() external onlyOwner override {
        presaleActive = !presaleActive;
        emit TogglePresaleState(presaleActive);
    }

    function setTicketAddress(address _ticketAddress) external onlyOwner override {
        require(_ticketAddress != address(0), "DropSpaceSale::setTicketAddress: Invalid address.");
        ticketAddress = _ticketAddress;
        emit TicketAddressChanged(_ticketAddress);
    }

    function presaleBuy(uint256 _ticketId, uint _amount) external payable override {
        require(presaleActive, "Dropspace::presaleBuy: Presale is not Active.");
        require(ERC721(ticketAddress).ownerOf(_ticketId) == _msgSender(), "Dropspace::presaleBuy: invalid ticket.");
        require(!usedTickets[_ticketId], "Dropspace::presaleBuy: Ticket already used.");
        require(_amount <= mintLimit, "Dropspace::presaleBuy: Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_amount), "Dropspace::presaleBuy: Insufficient payment.");

        usedTickets[_ticketId] = true;
        _mint(_amount);
        emit PresaleBuy(_msgSender(), _ticketId, _amount);
    }

    function whitelistBuy(uint256 _amount) external payable override {
        require(whitelistSaleActive, "DropSpaceSale::whitelistBuy: Whitelist Buy is not Active.");
        require(_amount <= mintLimit, "Dropspace::presaleBuy: Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_amount), "Dropspace::presaleBuy: Insufficient payment.");
        require(whitelist[_msgSender()], "Dropspace::whitelistBuy: You are not whitelisted."); 

        emit WhitelistBuy(_msgSender(), _amount);
        _mint(_amount);

        if (whitelistBuyOnce) {
            whitelist[_msgSender()] = false;
        }
    }

    function clearTicket(uint256 _ticketId) external override onlyOwner{
        require(usedTickets[_ticketId], "Dropspace::clearTicket: Ticket is not used");
        usedTickets[_ticketId] = false;
        emit TicketCleared(_ticketId);
    }

    receive() external override payable {}
}