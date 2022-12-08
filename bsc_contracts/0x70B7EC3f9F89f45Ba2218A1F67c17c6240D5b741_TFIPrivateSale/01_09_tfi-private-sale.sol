// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TFIPrivateSale is Pausable, Ownable {
    using SafeMath for uint256;
    mapping (address => bool) whitelistedAddresses;
    mapping (address => bool) blacklistedAddresses;
    bool public whitelistEnabled;
    bool public privateSaleOpen;
    bool public fundAutoTransfer;
    uint256 public buyFee; // 0-100% -> 0-100.000 -> 3 decimals 
    uint256 public priceForOneTokenInWei;
    address payable public fundDestination;
    IERC20 public tfi;
    event TokenPurchase(uint coinSent, uint256 feeValue, uint256 remainingCoin, uint256 priceForOneTokenInWei, uint256 tokenToBuy, uint256 fundToTransfer, bool fundAutoTransfer, uint256 totalSupply);
    event RecoverTokenSent(address _from, address _destAddr, uint _amount);

    constructor() {
        whitelistedAddresses[msg.sender] = true;
        whitelistedAddresses[address(0)] = true;
        buyFee = 0; // -> 100000 = 100%
        whitelistEnabled = false;
        privateSaleOpen = false;
        fundAutoTransfer = true;
        fundDestination = payable(msg.sender);
        priceForOneTokenInWei = 1 * 10 ** 18;
    }
    fallback () external payable {
        revert();    
    }
    receive () external payable {
        revert();
  }


// ---------- Modifiers ---------- //

    modifier isWhitelisted(address _address) {
        require(
            //all tx allowed when whitelist is disabled, 
            //all tx allowed when initiated by contract owner
            //if whitelist enabled and _msgSender is not the owner, tx allowd only if the sender address is whitelisted
            !whitelistEnabled || _msgSender() == owner() || (whitelistEnabled && whitelistedAddresses[_address]),
            "Source and destination need to be whitelisted"    
        );
        _;
    }

    modifier isNotBlacklisted(address _address) {
        require(
            !blacklistedAddresses[_address],
            "Address blacklisted, cannot operate"   
        );
        _;
    }

// ---------- Modifiers ---------- //


// ---------- Helper functions  ---------- //

    function setTFI(address _tfi) public onlyOwner {
        tfi = IERC20(_tfi);
    }

    function TFIBalance() public view returns (uint256){
        return tfi.balanceOf(address(this));
    }

    function enableWhitelist() public onlyOwner {
        whitelistEnabled = true;
    }

    function disableWhitelist() public onlyOwner {
        whitelistEnabled = false;
    }
    
    function addUserToWhitelist(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function removeUserFromWhitelist(address _addressToUnWhitelist) public onlyOwner {
        delete whitelistedAddresses[_addressToUnWhitelist];
    }

    function isAddressWhitelisted(address _addressToCheck) public view returns (bool){
        return whitelistedAddresses[_addressToCheck];
    }

    function addUserToBlacklist(address _addressToBlacklist) public onlyOwner {
        require (_addressToBlacklist != owner(), "Owner cannot be blacklisted");
        blacklistedAddresses[_addressToBlacklist] = true;
    }

    function removeUserFromBlacklist(address _addressToUnBlacklist) public onlyOwner {
        delete blacklistedAddresses[_addressToUnBlacklist];
    }

    function isAddressBlacklisted(address _addressToCheck) public view returns (bool){
        return blacklistedAddresses[_addressToCheck];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPrivateSalePriceForOneTokenInWei(uint256 _priceForOneTokenInWei) public onlyOwner{
        require(_priceForOneTokenInWei > 0, "PriceForOneTokenInWei must be greater than zero");
        priceForOneTokenInWei = _priceForOneTokenInWei;
    }

    function setBuyFee(uint256 _buyFee) public onlyOwner{
        require(_buyFee <= 100000, "Buy Fee to high");
        buyFee = _buyFee;
    }

    function enableFundAutoTransfer() public onlyOwner {
        fundAutoTransfer = true;
    }

    function disableFundAutoTransfer() public onlyOwner {
        fundAutoTransfer = false;
    }

    function setFundDestination(address payable _newDestinantion) 
        public
        onlyOwner
        isNotBlacklisted(_newDestinantion)
    {
            require(_newDestinantion != address(0), "Zero address cannot be set as fund destination");
            fundDestination = _newDestinantion;
    }

    function openPrivateSale() public onlyOwner{
        privateSaleOpen = true;
    }

    function closePrivateSale() public onlyOwner{
        privateSaleOpen = false;
    }

    function withdrawCoins() public onlyOwner {
        fundDestination.transfer(address(this).balance);
    }

    function withdrawTFI(address to) public onlyOwner {
        tfi.transfer(to, tfi.balanceOf(address(this)));
    }

    function recoverERC20(IERC20 token, address to) public onlyOwner {
        uint256 erc20Balance = token.balanceOf(address(this));
        token.transfer(to, erc20Balance);
        emit RecoverTokenSent(msg.sender, to, erc20Balance);
    }  


// ---------- Helper functions  ---------- //

    function preValidatePurchase(address _beneficiary, uint256 _coinAmountInWei) public view
        whenNotPaused
        isWhitelisted(_beneficiary)
        isNotBlacklisted(_beneficiary)
    returns (bool) {
        require(privateSaleOpen, "Private Sale is currentely closed");
        require(_beneficiary != address(0), "Zero address cannot buy");
        require(_coinAmountInWei != 0, "Buy amount must be greater than zero");
        require(_coinAmountInWei <= tfi.balanceOf(address(this)), "Amount too high, not enough token to sell");

        return true;
    }


    function buyPreview(uint256 coinAmountInWei) public view returns (uint256){
        uint256 tokenToBuy = 0;
        //calculate total fee
        uint256 feeValue = coinAmountInWei.div(100000).mul(buyFee);

        //calulate remaining coin for token buy
        uint256 remainingCoin = coinAmountInWei.sub(feeValue);

        //calculate total token to buy in Eth
        tokenToBuy = remainingCoin.mul(1 ether).div(priceForOneTokenInWei);
        
        return tokenToBuy;
    }

    function buyTFI() public payable {

        //call validation function
        if (preValidatePurchase(msg.sender, msg.value)) {

            //calculate total fee
            uint256 feeValue = msg.value.div(100000).mul(buyFee);

            //calulate remaining coin for token buy
            uint256 remainingCoin = msg.value.sub(feeValue);

            //calculate total token to buy in Eth
            uint256 tokenToBuy = remainingCoin.mul(1 ether).div(priceForOneTokenInWei);

            // mint tokens to buyer address
            tfi.transfer(msg.sender, tokenToBuy);

            uint256 fundToTransfer = address(this).balance;
            //if enabled, trasfer coins to fundDestination
            if (fundAutoTransfer){
                //transfer coin to fundDestination
                fundDestination.transfer(fundToTransfer);
            }
            
            emit TokenPurchase(msg.value, feeValue, remainingCoin, priceForOneTokenInWei, tokenToBuy, fundToTransfer, fundAutoTransfer, tfi.totalSupply());

        }
    }
}