// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract ZippaPreSale is Initializable, OwnableUpgradeable , ReentrancyGuardUpgradeable{
    using SafeMathUpgradeable for uint256;
    struct Owner{
        bool status;
        address owner;
        uint amount;
    }

    struct Whitelisted{
        bool status;
        address whitelistedAddress;
    }

    bool public saleActive;
    address public saleToken;
    address public feeCollector;
    address public deployer;
    uint public price;
    uint256 public tokensSold;
    uint public minimumAmount;
    mapping(address => Owner) public owners;
    mapping(address => Whitelisted) public whitelisters;

    // Emitted when tokens are sold
    event Sale(address indexed account, uint indexed price, uint tokensGot);

    

    function initialize(address _feeCollector, address _saleToken) external virtual initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();
        deployer = _msgSender();
        feeCollector = _feeCollector;
        saleToken = _saleToken;
        saleActive = true;
        minimumAmount  = 2*10e18;
    }
    
    // If the intended price is 0.01 per token, call this function with the result of 0.01 * 10**18 (_price = intended price * 10**18; calc this in a calculator).
    function tokenPrice(uint _price) external onlyOwner {
        price = _price;
    }


    function changeFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function changeTokenAddress(address _tokenAddress) external onlyOwner {
        saleToken = _tokenAddress;
    }
    
   
    // Buy tokens function
    // Note: This function allows only purchases of "full" tokens, purchases of 0.1 tokens or 1.1 tokens for example are not possible
    function buyTokens(uint256 _tokenAmount) public payable nonReentrant {
        require(_tokenAmount >= minimumAmount, "PRESALE: Minimum Amount to purchase required");
        require(!whitelisters[_msgSender()].status, "PRESALE: This address is whitelisted");
        uint256 cost = (_tokenAmount.mul(price)).div(1e18);
        require(saleActive == true, "PRESALE: Sale has ended.");
        require(cost <= msg.value , "PRESALE: Insufficient amount provided for token purchase");
        uint256 tokensToGet = _tokenAmount;
        payable(feeCollector).transfer(msg.value);
        require(IERC20Upgradeable(saleToken).transfer(_msgSender(), tokensToGet), "PRESALE: CONTRACT DOES NOT HAVE ENOUGH TOKENS.");
        tokensSold = tokensSold.add(tokensToGet);
        emit Sale(_msgSender(), price, tokensToGet);
    }

    function disableSaleAndWithdraw() external onlyOwner{
        saleActive = false;
        IERC20Upgradeable(saleToken).transfer(feeCollector, IERC20Upgradeable(saleToken).balanceOf(address(this)));
    }

    function whiteListAddress(address _adr ) external onlyOwner{
        require(whitelisters[_adr].status , "PRESALE : ADDRESS ALREADY WHITELISTED");
        whitelisters[_adr] = Whitelisted(true,_adr);
    }

    function removeWhiteListedAddress(address _adr ) external onlyOwner{
        require(!whitelisters[_adr].status , "PRESALE : ADDRESS ISN'T  WHITELISTED");
        whitelisters[_adr] = Whitelisted(true,_adr);
    }


    function disableSaleWithoutTransfer() external onlyOwner{
        saleActive = false;
    }

    function setMinimumAmount(uint amount) external onlyOwner{
        minimumAmount = amount;
    }

    function enableSale() external onlyOwner{
        saleActive = true;
        require(IERC20Upgradeable(saleToken).balanceOf(address(this)) >= 1, "PRESALE: CONTRACT DOES NOT HAVE TOKENS TO SELL.");
    }
    
    function enableSaleWithoutTransfer() external onlyOwner{
        saleActive = true;
    }

    function withdrawBNB() external payable onlyOwner {
        payable(feeCollector).transfer(payable(address(this)).balance);
    }
    
    function withdrawIERC20Upgradeable(address _token) external onlyOwner {
        uint _tokenBalance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(_tokenBalance >= 1 && _token != saleToken, "PRESALE: CONTRACT DOES NOT OWN THAT TOKEN OR TOKEN IS PRESALE.");
        IERC20Upgradeable(_token).transfer(feeCollector, _tokenBalance);
    }

    receive() external payable {
       if(msg.value  > 0 && price > 0){
           uint amount = msg.value.div(price);
           if(amount > 0){
               buyTokens(amount);
           }
       }
    }

    fallback() external payable {
      if(msg.value  > 0 && price > 0){
           uint amount = msg.value.div(price);
           if(amount > 0){
               buyTokens(amount);
           }
       }
    }
}