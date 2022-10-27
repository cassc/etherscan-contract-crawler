// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract CASA is AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable, IERC721ReceiverUpgradeable,ReentrancyGuardUpgradeable{

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    Counters.Counter public saleIdCounter;

    address payable public owner; //Contract owner/deployer

    IERC20Upgradeable public tokenContract; // CryptoDrift Token Contract Address
    IERC721Upgradeable public nftContract; // CryptoDrift Nft Contract Address
    IERC20Upgradeable public busdContract; //BUSD Contract Address Testnet = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee, Mainnet = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56

    bool public _isPaused; //Pause/unpause contract
    uint256 public transactionCut; // Share goes to company in every contract transaction
    address public transactionCutWalletAddress; // company wallet address

    bool isOpenSale; //Selling status
    bool isOpenBuyBNB; //Buying via BNB status
    bool isOpenBuyBUSD; //Buying via BUSD status
    bool isOpenBuyTOKEN; //Buying via Token Status

    struct Sale {
      uint256 id;
      uint256 nftId;
      address seller;
      uint256 sellingPrice;
      uint256 status;
      uint256 carType;
      uint256 tokenType;
    }

    mapping(uint256 => Sale) public SALES; //Store all sales

    event SaleCreated(uint256 nftId, uint256 sellingPrice, uint256 saleId);
    event SaleCancelled(uint256 nftId, uint256 saleId);
    event Sold(uint256 nftId, uint256 sellingPrice, uint256 saleId);

    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);

        owner = payable(msg.sender);
        _isPaused = false;
        transactionCut = 500;

        isOpenSale = true;
        isOpenBuyBNB = true;
        isOpenBuyBUSD = true;
        isOpenBuyTOKEN = false;

    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _transferSale(address receiver, uint256 amount) internal{
      uint256 _devCut = amount.mul(transactionCut).div(10000);
      uint256 sellerProceeds = amount - _devCut;
      tokenContract.transfer(receiver, sellerProceeds);
      tokenContract.transfer(transactionCutWalletAddress, _devCut);
    }

    function _createSale(uint256 _nftId,uint256 _sellingPrice, uint256 _carType,uint256 tokenType) external {
      require(isOpenSale, "Sale is closed!");
      require(nftContract.ownerOf(_nftId) == msg.sender, "Nft Not Owned");

      nftContract.safeTransferFrom(msg.sender, address(this),_nftId, "");

      saleIdCounter.increment();

      uint256 saleId = saleIdCounter.current();
      Sale memory sale = Sale(saleId,_nftId,msg.sender,_sellingPrice,1,_carType,tokenType);
      SALES[_nftId] = sale;
       
      emit SaleCreated(_nftId, _sellingPrice, saleId); 
    }

    function _cancelSale(uint256 _nftId) external nonReentrant {
      Sale memory sale = SALES[_nftId];
      require(sale.status == 1 && sale.seller != address(0),"Sale not created or already cancelled!");
      require(sale.seller == msg.sender,"You are not the owner"); 
      
      delete SALES[_nftId];

      nftContract.safeTransferFrom(address(this), sale.seller,_nftId, "");

      emit SaleCancelled(_nftId, sale.id);
    }
    
    function _cancelSaleAdmin(uint256 _nftId) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE){
      Sale memory sale = SALES[_nftId];
      require(sale.status == 1 && sale.seller != address(0),"Sale not created or already cancelled!");
       
      delete SALES[_nftId];
      
      nftContract.safeTransferFrom(address(this), sale.seller,_nftId, "");

      emit SaleCancelled(_nftId, sale.id);
    }

    function _buyToken(uint256 _nftId) external {
      require(isOpenBuyTOKEN, "Purchase via Token is Closed!");
      Sale memory sale = SALES[_nftId];
      require(sale.status == 1,"Sale not created or already cancelled!");
      require(sale.seller != msg.sender, "Cannot buy your own sale");
      require(sale.tokenType == 3, "Token purchase only!");
      require(tokenContract.balanceOf(msg.sender) >= sale.sellingPrice, "Not Enough Token Balance");

      delete SALES[_nftId];

      tokenContract.transferFrom(msg.sender,address(this), sale.sellingPrice);
      nftContract.safeTransferFrom(address(this), msg.sender,_nftId, "");

      uint256 _cut = sale.sellingPrice.mul(transactionCut).div(10000);
      uint256 sellerProceeds = sale.sellingPrice - _cut;

      tokenContract.transfer(sale.seller,sellerProceeds);
      tokenContract.transfer(transactionCutWalletAddress,_cut);

      emit Sold(_nftId, sale.sellingPrice, sale.id); 
    }

    function _buyBUSD(uint256 _nftId) external {
      require(isOpenBuyBUSD, "Purchase via BUSD is Closed!");
      Sale memory sale = SALES[_nftId];
      require(sale.status == 1,"Sale not created or already cancelled!");
      require(sale.seller != msg.sender, "Cannot buy your own sale");
      require(sale.tokenType == 1, "BUSD purchase only!");
      require(busdContract.balanceOf(msg.sender) >= sale.sellingPrice, "Not Enough BUSD Balance");

      delete SALES[_nftId];

      busdContract.transferFrom(msg.sender,address(this), sale.sellingPrice);
      nftContract.safeTransferFrom(address(this), msg.sender,_nftId, "");

      uint256 _cut = sale.sellingPrice.mul(transactionCut).div(10000);
      uint256 sellerProceeds = sale.sellingPrice - _cut;

      busdContract.transfer(sale.seller,sellerProceeds);
      busdContract.transfer(transactionCutWalletAddress,_cut);

      emit Sold(_nftId, sale.sellingPrice, sale.id); 
    }

    function _buyBNB(uint256 _nftId) external payable{
      require(isOpenBuyBNB, "Purchase via BNB is Closed!");
      Sale memory sale = SALES[_nftId];
      require(sale.status == 1,"Sale not created or already cancelled!");
      require(sale.seller != msg.sender, "Cannot buy your own sale");
      require(sale.tokenType == 2, "BNB purchase only!");
      require(msg.value >= sale.sellingPrice, "Not Enough BNB Balance");

      delete SALES[_nftId];

      nftContract.safeTransferFrom(address(this), msg.sender,_nftId, "");

      uint256 _cut = sale.sellingPrice.mul(transactionCut).div(10000);
      uint256 sellerProceeds = sale.sellingPrice - _cut;

      payable(sale.seller).transfer(sellerProceeds);
      payable(transactionCutWalletAddress).transfer(_cut);

      emit Sold(_nftId, sale.sellingPrice, sale.id); 
    }

    //Admin settings
    function setTokenContractAddress(address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE){
       tokenContract = IERC20Upgradeable(contractAddress);
    }

    function setBUSDContractAddress(address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE){
       busdContract = IERC20Upgradeable(contractAddress);
    }

    function setNFTContractAddress(address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE){
      nftContract = IERC721Upgradeable(contractAddress);
    }

    function setTransactionCut(uint256 cut) external onlyRole(DEFAULT_ADMIN_ROLE){
      transactionCut = cut;
    }

    function setTransactionCutWallet(address wallet) external onlyRole(DEFAULT_ADMIN_ROLE){
      transactionCutWalletAddress = wallet;
    }

    function setMarketStatus()external onlyRole(DEFAULT_ADMIN_ROLE){
      _isPaused = !_isPaused;
    }

    function setSaleStatus() external onlyRole(DEFAULT_ADMIN_ROLE){
      isOpenSale = !isOpenSale;
    }

    function setBuyBNBStatus() external onlyRole(DEFAULT_ADMIN_ROLE){
      isOpenBuyBNB = !isOpenBuyBNB;
    }

    function setBuyBUSDStatus() external onlyRole(DEFAULT_ADMIN_ROLE){
      isOpenBuyBUSD = !isOpenBuyBUSD;
    }

    function setBuyTOKENStatus() external onlyRole(DEFAULT_ADMIN_ROLE){
      isOpenBuyTOKEN = !isOpenBuyTOKEN;
    }

    function withdrawToken() external onlyRole(DEFAULT_ADMIN_ROLE){
       tokenContract.transfer(msg.sender,tokenContract.balanceOf(address(this)));
    }

    function withdrawBUSD() external onlyRole(DEFAULT_ADMIN_ROLE){
       busdContract.transfer(msg.sender,busdContract.balanceOf(address(this)));
    }

    function withdraw(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        owner.transfer(amount);
    }
    function withdrawBNB() external onlyRole(DEFAULT_ADMIN_ROLE){
        owner.transfer(address(this).balance);
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable) returns (bool){
        return  interfaceId == type(IERC721ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    //Upgrades here

}