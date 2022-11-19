// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


interface GVKContract {
    function mint(address to, uint256 id) external;
   
}
contract GVKPayment is Ownable,ReentrancyGuard{

    using SafeMath for uint256;

    GVKContract private GVK; 

    address payable private withdrawAddress;
    uint256 private totalSupply;
    uint256 private totalMinted;
    uint256 private salesStartTime;
    uint256 private preSaleDuration;
    uint256 private preSaleWalletLimit;
    uint256 private limitPerTx;
    uint256 private preSalePrice;
    uint256 private publicSalePrice;

    bool private publicSale;
    bool private preSale;


    mapping (address => bool) private whitelistedAddresses;
    mapping(address => uint256) public balancePerWallet;

    event ethFundsWithdraw(uint256 indexed _amount, address indexed _address);
    event withdrawAddressUpdated(address indexed _withdrawAddress);
    event nftContractAddressUpdated(address indexed _address);
    event addressWhiteListed(address[] _address);
    event addressWhiteListRemoved(address[] _address);
    event preSalePurchase(address indexed _beneficiary,uint256[] _tokenId);
    event publicSalePurchase(address indexed _beneficiary,uint256[] _tokenId);
    event saleStartTimeUpdated(uint256 indexed _salesStartTime);
    event preSaleDurationUpdated(uint256 indexed _preSaleDuration);
    event preSaleWalletLimitUpdated(uint256 indexed _preSaleWalletLimit);
    event preSalePriceUpdated(uint256 indexed _preSalePrice);
    event totalSupplyUpdated(uint256 indexed _totalSupply);
    event publicSalePriceUpdated(uint256 indexed _publicSalePrice);
   

    constructor( address payable _withdrawAddress, address _gvkContract){
        GVK = GVKContract(_gvkContract);
        withdrawAddress = _withdrawAddress;
        //when SaleTime start
        salesStartTime = 1668794400;
        preSaleDuration = 1 days;
        preSalePrice = 0.08 ether;
        publicSalePrice = 0.1 ether;
        totalSupply = 5000;
        preSaleWalletLimit = 5;
        limitPerTx = 5;
        publicSale = true;
        preSale = true;
        
    }

    // Presale for whiteListed users
    function purchasePreSale(
        uint256[] calldata _tokenId
    ) public payable nonReentrant{
        require((preSale == true ), "PreSale: Sale is not active");
        require((block.timestamp >= salesStartTime), "PreSale: Sale not started");
        require((block.timestamp <= salesStartTime.add(preSaleDuration)), "PreSale: Sale time ended");
        require((whitelistedAddresses[msg.sender] == true), "PreSale: You are not whitelisted for presale");
        require((totalMinted.add(_tokenId.length) <= totalSupply), "PreSale: Invalid mint count");
        require((_tokenId.length <= limitPerTx), "PreSale: Maximum item per transaction exceeded");
        require(_tokenId.length <= preSaleWalletLimit.sub(balancePerWallet[msg.sender]), "PreSale: Sale Limit exceeded ");
        require(msg.value == (preSalePrice.mul(_tokenId.length)), "PreSale: Insufficient funds passed to mint");

        balancePerWallet[msg.sender] = balancePerWallet[msg.sender].add(_tokenId.length);
        totalMinted = totalMinted.add(_tokenId.length);
        mintBatch(msg.sender, _tokenId);
        emit preSalePurchase(msg.sender, _tokenId);
        
    }
    // Public sale
    function purchasePublicSale(
        uint256[] calldata _tokenId
    ) public payable nonReentrant{
        require((publicSale == true ), "PublicSale: Sale is not active");
        require((block.timestamp > salesStartTime.add(preSaleDuration)), "PublicSale: Sale not started");
        require((totalMinted <= totalSupply),"Minted completed");
        require((totalMinted.add(_tokenId.length) <= totalSupply), "PublicSale: Invalid mint count");
        require((_tokenId.length <= limitPerTx), "PublicSale: Maximum item per transaction excceded");
        require(msg.value == (publicSalePrice.mul(_tokenId.length)), "PublicSale: Insufficient funds passed to mint");

        balancePerWallet[msg.sender] = balancePerWallet[msg.sender].add(_tokenId.length);
        totalMinted = totalMinted.add(_tokenId.length);
        mintBatch(msg.sender, _tokenId);
        emit publicSalePurchase(msg.sender, _tokenId);
        
    }

    function mintBatch(
        address _to,
        uint256[] memory ids
    ) private {

        for (uint256 index = 0; index < ids.length; index++) {
            GVK.mint(_to, ids[index]);
        }

    }

    function withdrawEthFunds(
        uint256 _amount
    ) public onlyOwner{

        require(_amount > 0,"Dapp: invalid amount.");

        withdrawAddress.transfer(_amount);
        emit ethFundsWithdraw(_amount, msg.sender);

    }

    function updateWithdrawAddress(
        address payable _withdrawAddress
    ) public onlyOwner{

        require(_withdrawAddress != address(0),"Dapp: Invalid address.");

        withdrawAddress = _withdrawAddress;
        emit withdrawAddressUpdated(_withdrawAddress);

    }

    function updateNFTContractAddress(
        address _address
    ) public onlyOwner{

        require(_address != address(0),"Dapp: Invalid address.");
        
        GVK = GVKContract(_address);
        emit nftContractAddressUpdated(_address);

    }

    function addWhitelistedAddress(
        address[] calldata _address
    ) public onlyOwner{

        for (uint256 index = 0; index < _address.length; index++) {
            require(
                !whitelistedAddresses[_address[index]],
                "address already whitelisted"
            );
            whitelistedAddresses[_address[index]] = true;
        }
        emit addressWhiteListed(_address);

    }

    function removeWhitelistedAddress(
        address[] calldata _address
    ) public onlyOwner{

        for (uint256 index = 0; index < _address.length; index++) {
            require(
                whitelistedAddresses[_address[index]],
                "address already delisted"
            );
            whitelistedAddresses[_address[index]] = false;
        }
        emit addressWhiteListRemoved(_address);

    }

    function updateSalesStartTime(
        uint256 _salesStartTime
    ) public onlyOwner{

        require(_salesStartTime>0,"GVKPayment: Invalid sale start time!");

        salesStartTime = _salesStartTime;
        emit saleStartTimeUpdated(_salesStartTime);

    }

    function updatePreSaleDuration(
        uint256 _preSaleDuration
    ) public onlyOwner {

        require(_preSaleDuration>0,"GVKPayment: Invalid Presale duration!");

        preSaleDuration = _preSaleDuration;
        emit preSaleDurationUpdated(_preSaleDuration);

    }

    function updatePreSaleWalletLimit(
        uint256 _preSaleWalletLimit
    ) public onlyOwner{

        require(_preSaleWalletLimit>0,"GVKPayment: Invalid Presale wallet limit!");

        preSaleWalletLimit = _preSaleWalletLimit;
        emit preSaleWalletLimitUpdated(_preSaleWalletLimit);
    }

    function updatePreSalePrice(
        uint256 _preSalePrice
    ) public onlyOwner{

        require(_preSalePrice>0,"GVKPayment: Invalid Presale price!");

        preSalePrice = _preSalePrice;
        emit preSalePriceUpdated(_preSalePrice);
    }

    function updateTotalSupply(
        uint256 _totalSupply
    ) public onlyOwner{

        require(_totalSupply>0,"GVKPayment: Invalid total supply!");

        totalSupply = _totalSupply;
        emit totalSupplyUpdated(_totalSupply);
    }

    function updatePublicSalePrice(
        uint256 _publicSalePrice
    ) public onlyOwner{

        require(_publicSalePrice>0,"GVKPayment: Invalid Public Sale price!");

        publicSalePrice = _publicSalePrice;
        emit publicSalePriceUpdated(_publicSalePrice);
    }

    function updatePublicSaleStatus(
        bool _publicSale
    ) public onlyOwner{

        publicSale = _publicSale;

    }

    function updatePreSaleStatus(
        bool _preSale
    ) public onlyOwner{

        preSale = _preSale;

    }
   
    //get functions
    function getWithdrawAddress() public view returns(address){

        return withdrawAddress;

    }

    function getTotalSupply() public view returns(uint256){

        return totalSupply;

    }

    function getTotalMinted() public view returns(uint256){

        return totalMinted;

    }

    function getSalesStartTime() public view returns(uint256){

        return salesStartTime;

    }

    function isWhitelisted(address _address) public view returns(bool){

        return whitelistedAddresses[_address];

    }

    function isPresale() public view returns(bool){

        return preSale;

    }

    function isPublicSale() public view returns(bool){

        return publicSale;

    }

    function getPresaleDuration() public view returns(uint256){

        return preSaleDuration;

    }

    function getPresaleWalletLimit() public view returns(uint256){

        return preSaleWalletLimit;

    }

    function getLimitPerTx() public view returns(uint256){

        return limitPerTx;

    }

    function getPreSalePrice() public view returns(uint256){

        return preSalePrice;

    }

    function getPublicSalePrice() public view returns(uint256){

        return publicSalePrice;

    }

}