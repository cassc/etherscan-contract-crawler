// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERCContract {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract DriftCredits is AccessControlUpgradeable,PausableUpgradeable,UUPSUpgradeable {

    using Counters for Counters.Counter;

    address payable public owner; //Contract owner/deployer
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    IERC20Upgradeable public busdContract; //BUSD Contract Address Testnet = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee, Mainnet = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    IERC20Upgradeable public tokenContract; // CryptoDrift Token Contract Address

    Counters.Counter public purchaseIdCounter; 

    bool creditPurchaseBNBOpen; //Purchase via BNB status
    bool creditPurchaseBUSDOpen; //Purchase via BUSD status
    bool creditPurchaseTokenOpen; //Purchase via TOKEN status

    uint256 minimumBnbPurchase; 
    uint256 minimumBUSDPurchase;
    uint256 minimumTokenPurchase;

    struct purchase{
      uint256 id;
      address buyer;
      uint256 amount;
      uint256 date;
      uint256 bnbUsdtValue;
    }

    mapping(address => purchase[]) public PURCHASES_BNB; //Store all BNB purchases 
    mapping(address => purchase[]) public PURCHASES_BUSD; //Store all BUSD purchases 
    mapping(address => purchase[]) public PURCHASES_TOKEN; //Store all TOKEN purchases 

    event Purchased(uint256 id, address buyer, uint256 amount, uint256 date);

    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        owner = payable(msg.sender);
        creditPurchaseBNBOpen = true;
        creditPurchaseBUSDOpen = true;
        creditPurchaseTokenOpen = false;
        
        minimumBnbPurchase = 0.010 ether;
        minimumBUSDPurchase = 0.014 ether;
        minimumTokenPurchase = 0.014 ether;
    }

    function purchaseViaBNB(uint256 bnbValue) external payable {

      require(creditPurchaseBNBOpen, "Purchasing is closed");
      require(msg.value >= minimumBnbPurchase,"Not Enough Bnb");

      uint256 id = purchaseIdCounter.current();
      uint256 date = block.timestamp;
      purchase memory transaction = purchase(id,msg.sender, msg.value,date,bnbValue);
      PURCHASES_BNB[msg.sender].push(transaction);
      purchaseIdCounter.increment();

      emit Purchased(id, msg.sender, msg.value, date);
    }

    function purchaseViaBUSD(uint256 bnbValue, uint256 amount) external  {

      require(creditPurchaseBUSDOpen, "Purchasing is closed");
      require(amount >= minimumBUSDPurchase,"Not Enough Busd");
      require(busdContract.balanceOf(msg.sender) >= amount, "Not Enough BUSD Balance");

      uint256 id = purchaseIdCounter.current();
      uint256 date = block.timestamp;
      purchase memory transaction = purchase(id,msg.sender, amount,date,bnbValue);
      PURCHASES_BUSD[msg.sender].push(transaction);
      purchaseIdCounter.increment();

      busdContract.transferFrom(msg.sender,address(this), amount);

      emit Purchased(id, msg.sender,amount, date);
    }

    function purchaseViaToken(uint256 bnbValue, uint256 amount) external  {

      require(creditPurchaseTokenOpen, "Purchasing is closed");
      require(amount >= minimumTokenPurchase,"Not Enough Token");
      require(tokenContract.balanceOf(msg.sender) >= amount, "Not Enough Token Balance");

      uint256 id = purchaseIdCounter.current();
      uint256 date = block.timestamp;
      purchase memory transaction = purchase(id,msg.sender, amount,date,bnbValue);
      PURCHASES_TOKEN[msg.sender].push(transaction);
      purchaseIdCounter.increment();

      tokenContract.transferFrom(msg.sender, address(this), amount);

      emit Purchased(id, msg.sender,amount, date);
    }

    //Fetch Records

    function getBNBPurchases(address walletAddress) external view returns(purchase[] memory purchases){
      return PURCHASES_BNB[walletAddress];
    }

    function getBUSDPurchases(address walletAddress) external view returns(purchase[] memory purchases){
      return PURCHASES_BUSD[walletAddress];
    }

    function getTOKENPurchases(address walletAddress) external view returns(purchase[] memory purchases){
      return PURCHASES_TOKEN[walletAddress];
    }

    function getPurchases(address walletAddress) external view returns(purchase[] memory purchases_BNB,purchase[] memory purchases_BUSD,purchase[] memory purchases_Token){
      return (PURCHASES_BNB[walletAddress],PURCHASES_BUSD[walletAddress],PURCHASES_TOKEN[walletAddress]);
    }

    function getBNBPurchaseById(address walletAddress,uint256 id) external view returns(purchase memory _purchase){
      purchase memory toReturn;
      purchase[] memory purchases = PURCHASES_BNB[walletAddress];
      for(uint256 i=0;i< purchases.length;i++){
        purchase memory pu = purchases[i];
        if(pu.id == id){
          toReturn = pu;
          break;
        }
      }
      return toReturn;
    }
    function getBUSDPurchaseById(address walletAddress,uint256 id) external view returns(purchase memory _purchase){
      purchase memory toReturn;
      purchase[] memory purchases = PURCHASES_BUSD[walletAddress];
      for(uint256 i=0;i< purchases.length;i++){
        purchase memory pu = purchases[i];
        if(pu.id == id){
          toReturn = pu;
          break;
        }
      }
      return toReturn;
    }

    function getTokenPurchaseById(address walletAddress,uint256 id) external view returns(purchase memory _purchase){
      purchase memory toReturn;
      purchase[] memory purchases = PURCHASES_TOKEN[walletAddress];
      for(uint256 i=0;i< purchases.length;i++){
        purchase memory pu = purchases[i];
        if(pu.id == id){
          toReturn = pu;
          break;
        }
      }
      return toReturn;
    }

    //Adming Settings

    function setBUSDContractAddress(address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE){
       busdContract = IERC20Upgradeable(contractAddress);
    }

    function setTokenContractAddress(address contractAddress) external onlyRole(DEFAULT_ADMIN_ROLE){
       tokenContract = IERC20Upgradeable(contractAddress);
    }

    function setPurchasingBNBStatus() external onlyRole(DEFAULT_ADMIN_ROLE){
        creditPurchaseBNBOpen = !creditPurchaseBNBOpen;
    }
    function setPurchasingBUSDStatus() external onlyRole(DEFAULT_ADMIN_ROLE){
        creditPurchaseBUSDOpen = !creditPurchaseBUSDOpen;
    }
    function setPurchasingTokenStatus() external onlyRole(DEFAULT_ADMIN_ROLE){
        creditPurchaseTokenOpen = !creditPurchaseTokenOpen;
    }
    function setMinimumBNBPurchase(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        minimumBnbPurchase = amount;
    }
    function setMinimumBUSDPurchase(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        minimumBUSDPurchase = amount;
    }
    function setMinimumTokenPurchase(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        minimumTokenPurchase = amount;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function withdrawBUSD(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        busdContract.transfer(msg.sender,amount);
    }

    function withdrawBUSDAll() external onlyRole(DEFAULT_ADMIN_ROLE) {
        busdContract.transfer(msg.sender,busdContract.balanceOf(address(this)));
    }
    
    function withdrawToken(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenContract.transfer(msg.sender,amount);
    }

    function withdrawTokenAll() external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenContract.transfer(msg.sender,tokenContract.balanceOf(address(this)));
    }

    function withdrawBNB(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        payable(msg.sender).transfer(amount);
    }
    function withdrawBNBAll() external onlyRole(DEFAULT_ADMIN_ROLE){
        payable(msg.sender).transfer(address(this).balance);
    }
    
    //Upgrade starts here

}