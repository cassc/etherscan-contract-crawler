//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IDropspaceSale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract DropspaceSale is IDropspaceSale, ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 MAX = 2**256 - 1;

    uint256 public override mintLimit;
    uint256 public override mintPrice;
    uint256 public override supplyLimit;

    string public override baseURI;

    bool public override smartContractAllowance = false;
    bool public override saleActive;
    bool public override presaleActive;
    bool public override whitelistSaleActive;
    bool public override stageSaleActive;

    address payable public override withdrawalWallet;
    address payable public override devWallet;
    address public override ticketAddress;

    bool public override whitelistBuyOnce;

    uint256 devSaleShare;
    uint256 ownerSaleShare;

    mapping(uint256 => bool) public override usedTickets;
    bytes32 public override whitelistRoot;
    mapping(address => bool) public override whitelistClaimed;

    mapping(uint256 => bytes32) public override stageWhitelistRoot;
    mapping(uint256 => uint256) public override stagePrice;
    mapping(uint256 => uint256) public override stageLimit;

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
    ) ERC721A(_name, _ticker) {
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

    function changeSupplyLimit(uint256 _supplyLimit) external onlyOwner override {
        require(supplyLimit >= totalSupply(), "DropspaceSale::changeSupplyLimit: Supply Limit can't be reduced below total supply");
        require(supplyLimit <= 8000, "DropspaceSale::changeSupplyLimit: Supply Limit can't be greater than 8000.");
        supplyLimit = _supplyLimit;
        emit SupplyLimitChanged(_supplyLimit);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner override {
        mintPrice = _mintPrice;
        emit MintPriceChanged(_mintPrice);
    }

    function setWhitelistClaimStatus(address _user, bool _status) public onlyOwner override {
        _setWhitelistClaimStatus(_user, _status);
    }

    function _setWhitelistClaimStatus(address _user, bool _status) internal {
        whitelistClaimed[_user] = _status;
        emit WhitelistClaimStatusChanged(_user, _status);
    }

    // For the Stage 1-5 whitelists
    function setStageWhitelistRoot(uint256 _stage, bytes32 _whitelistRoot) external onlyOwner override {
        stageWhitelistRoot[_stage] = _whitelistRoot;
        emit StageWhitelistRootChanged(_stage, _whitelistRoot);   
    }

    // For the Stage 1-5 price
    function setStagePrice(uint256 _stage, uint256 _price) external onlyOwner override {
        stagePrice[_stage] = _price;
        emit StagePriceChanged(_stage, _price);
    }

    // For the Stage 1-5 limit
    function setStageLimit(uint256 _stage, uint256 _limit) external onlyOwner override {
        stageLimit[_stage] = _limit;
        emit StageLimitChanged(_stage, _limit);
    }

    // For usual whitelist
    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner override {
        whitelistRoot = _whitelistRoot;
        emit WhitelistRootChanged(_whitelistRoot);   
    }

    function toggleSaleActive() external onlyOwner override {
        saleActive = !saleActive;

        if (saleActive) {
            mintPrice = 0.2 ether;
            emit MintPriceChanged(mintPrice);
            mintLimit = 10;
            emit MintLimitChanged(mintLimit);
        }

        emit ToggleSaleState(saleActive);
    }

    function toggleStageSaleActive() external onlyOwner override {
        stageSaleActive = !stageSaleActive;
        emit ToggleStageSaleState(stageSaleActive);
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
        emit Buy(_msgSender(), _amount);
    }

    function _mint(uint256 _amount) internal {
        require(totalSupply().add(_amount) <= supplyLimit, "Not enough tokens left.");
        
        _safeMint(_msgSender(), _amount);
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
        require(IERC721(ticketAddress).ownerOf(_ticketId) == _msgSender(), "Dropspace::presaleBuy: invalid ticket.");
        require(!usedTickets[_ticketId], "Dropspace::presaleBuy: Ticket already used.");
        require(_amount <= mintLimit, "Dropspace::presaleBuy: Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_amount), "Dropspace::presaleBuy: Insufficient payment.");

        usedTickets[_ticketId] = true;
        _mint(_amount);
        emit PresaleBuy(_msgSender(), _ticketId, _amount);
    }

    function _verifyWhitelist(address _user, bytes32[] calldata _merkleProof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verify(_merkleProof, whitelistRoot, leaf);
    }

    function _verifyWhitelistStage(address _user, bytes32[] calldata _merkleProof, uint256 _stage) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_user));
        return MerkleProof.verify(_merkleProof, stageWhitelistRoot[_stage], leaf);
    }

    function stageBuy(uint256 _amount, bytes32[] calldata _merkleProof, uint256 _stage) external payable override {
        require(stageSaleActive, "DropSpaceSale::stageBuy: Stage Buy is not Active.");
        require(msg.value == stagePrice[_stage].mul(_amount), "Dropspace::stageBuy: Insufficient payment.");
        require(_verifyWhitelistStage(_msgSender(), _merkleProof, _stage), "Dropspace::stageBuy: User is not whitelisted");
        require(_amount <= stageLimit[_stage], "Dropspace::stageBuy: Too many tokens for one transaction.");

        if (whitelistBuyOnce) {
            require(!whitelistClaimed[_msgSender()], "Dropspace::stageBuy: Already claimed");
            _setWhitelistClaimStatus(_msgSender(), true);
        }

        _mint(_amount);

        emit StageBuy(_msgSender(), _amount, _stage);
    }

    function whitelistBuy(uint256 _amount, bytes32[] calldata _merkleProof) external payable override {
        require(whitelistSaleActive, "DropSpaceSale::whitelistBuy: Whitelist Buy is not Active.");
        require(_amount <= mintLimit, "Dropspace::whitelistBuy: Too many tokens for one transaction.");
        require(msg.value >= mintPrice.mul(_amount), "Dropspace::whitelistBuy: Insufficient payment.");
        require(_verifyWhitelist(_msgSender(), _merkleProof), "Dropspace::whitelistBuy: User is not whitelisted");

        if (whitelistBuyOnce) {
            require(!whitelistClaimed[_msgSender()], "Dropspace::whitelistBuy: Already claimed");
            _setWhitelistClaimStatus(_msgSender(), true);
        }

        _mint(_amount);

        emit WhitelistBuy(_msgSender(), _amount);
    }

    function clearTicket(uint256 _ticketId) external override onlyOwner{
        require(usedTickets[_ticketId], "Dropspace::clearTicket: Ticket is not used");
        usedTickets[_ticketId] = false;
        emit TicketCleared(_ticketId);
    }

    receive() external override payable {}
}