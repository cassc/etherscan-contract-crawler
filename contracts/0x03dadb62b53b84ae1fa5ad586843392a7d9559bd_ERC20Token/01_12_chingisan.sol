// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ERC20Token is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public BuyTax;
    uint256 public SellTax;
    
    IUniswapV2Router02 private uniswapV2Router;
    address[] private uniswapV2Pair;
    address private _feeReciever;
  
    mapping(address=>bool) private _excludedFromFee;

    /*
    
    FEE- 100 = 1%
    
    Router Address = Any Uniswap V2 Router / Clone 
    
    */

    constructor(
        uint256 TOTAL_SUPPLY,
        string memory NAME_,
        string memory SYMBOL_,
        uint256 _buyTax,
        uint256 _sellTax,
        address uniswap_V2_Router_Address,
        address _feeAddress
    ) 
    ERC20(NAME_, SYMBOL_) 
    {
        require(_buyTax <= 3000 && _sellTax <=3000, "Invalid Address Input , and Fee must be less than 30% or 3000");
        _mint(msg.sender, TOTAL_SUPPLY * 10 ** decimals());
        _excludedFromFee[msg.sender] = true;
        BuyTax = _buyTax;
        SellTax = _sellTax;
        _feeReciever = _feeAddress;
        IUniswapV2Router02 _uniswapV2Router =IUniswapV2Router02 (uniswap_V2_Router_Address);
        uniswapV2Router = _uniswapV2Router;
        address initPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair.push(initPair);    
    }

    function isExcludedFromFee(address _Address) public view returns(bool){
        return _excludedFromFee[_Address];
    }

    function excludeAddressFromFee(address _Address) public onlyOwner returns(bool){
        require(_Address != address(0),"Address Cannot be Zero Address");
        require(_excludedFromFee[_Address] == false ,"Address Already Excluded");
        _excludedFromFee[_Address] = true;
        return true;
    }

    function includeAddressInFee(address _Address) public onlyOwner returns(bool){
        require(_Address != address(0),"Address Cannot be Zero Address");
        require(_excludedFromFee[_Address] == true ,"Address Already Excluded");
        _excludedFromFee[_Address] = false;
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns(bool) {
        transfer_(msg.sender, to , amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        transfer_(from, to, amount);
        return true;
    }

    function transfer_(address from,address to, uint256 amount) internal {
        if (from != owner() && to != owner() || _excludedFromFee[from] == false) { // fee functions apply to all except owner and fee excluded addresses
            bool isJustTransfer = false;
            for (uint256 i = 0; i < uniswapV2Pair.length; i++) {
                if (from != uniswapV2Pair[i] && to != uniswapV2Pair[i]) {
                    isJustTransfer = true;
                    break;
                }
            }
            if (isJustTransfer == true) {
                _transfer(from, to ,amount);
            }else if
            (from == uniswapV2Pair[0] && to != address(uniswapV2Router)) { //buy tax deduction
            uint256 feeAmount = amount.mul(BuyTax).div(10000);
            uint256 transferAmount = amount.sub(feeAmount);
            _transfer(from , to , transferAmount);
            _transfer(from, _feeReciever, feeAmount);
            }else if        
            (to == uniswapV2Pair[0] && from != address(uniswapV2Router)) { //sell tax deduction
            uint256 feeAmount = amount.mul(SellTax).div(10000);
            uint256 transferAmount = amount.sub(feeAmount);
            _transfer(from , to , transferAmount);
            _transfer(from, _feeReciever, feeAmount);
            } else { 
            uint256 feeAmount = amount.mul(1).div(100000);
            uint256 transferAmount = amount.sub(feeAmount);
            _transfer(from , to , transferAmount);
            _transfer(from, address(0), feeAmount);
            }
        }
        else
        {
          _transfer(from,to , amount);
        }
    }

    function _transfer(address from,address to, uint256 amount) internal virtual override {
        super._transfer(from, to , amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
    receive() external payable {}

    function changeBuyTax(uint256 amountPercentTax) public onlyOwner returns(bool){
        require(amountPercentTax > 0 && amountPercentTax <= 3000, "Value Must Not be 0 and Should be less than 3000 (30%)");
        BuyTax = amountPercentTax;
        return true;
    }

    function changeSellTax(uint256 amountPercentTax) public onlyOwner returns(bool){
        require(amountPercentTax > 0 && amountPercentTax <= 3000, "Value Must Not be 0 and Should be less than 3000 (30%)");
        SellTax = amountPercentTax;
        return true;
    }

    function changeFeeAdd( address newReciever) public onlyOwner returns(bool){
        require(newReciever != address(0),"Invalid Address");
        _feeReciever = newReciever;
        return true;
    }

// Adding A pair enables the Buy/Tax functions to be executed for the pair

    function addPair(address newPair) external onlyOwner returns(bool){
    require(newPair != address(0), "Invalid address");

    for (uint256 i = 0; i < uniswapV2Pair.length; i++) {
        require(uniswapV2Pair[i] != newPair, "Address already exists in the pair array");
    }

    uniswapV2Pair.push(newPair);
    return true;
    }

    function removePair(address pair) external onlyOwner returns(bool) {
        require(pair != address(0), "Invalid address");

        for (uint256 i = 0; i < uniswapV2Pair.length; i++) {
            if (uniswapV2Pair[i] == pair) {
                uniswapV2Pair[i] = uniswapV2Pair[uniswapV2Pair.length - 1];
                uniswapV2Pair.pop();
                return true;
            }
        }

        revert("Address not found in the pair array");
    }

    function getAllPairs() external view returns (address[] memory) {
        return uniswapV2Pair;
    }
    
    function showFeeReciever() public view returns(address){
        return _feeReciever;
    }

    //Utility function to withdraw Tokens sent to contract by mistake

    function flushStuckEther( address to) public onlyOwner returns(bool) {
        require(to != address(0),"Must Be Non-Zero Address");
        address payable ownerWallet = payable(to);
        ownerWallet.transfer(address(this).balance);
        return true;
    }

    function flushStuckERC20( address erc20address ,address to) public onlyOwner returns(bool) {
        require(to != address(0),"Must Be Non-Zero Address");
        IERC20(erc20address).transfer(to, IERC20(erc20address).balanceOf(address(this)));
        return true;
    }

    // Miscallenous 

    /*
    Following Functions are Helpers for Pair Management

    returns => Created Liquidity Pairs 
    returns=> bool
    */

    function initializeNewPair(address liquidityToken) public onlyOwner returns(address){
        address createdPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this),liquidityToken);

        uniswapV2Pair.push(createdPair);
        return createdPair;     
    }

    function migrateV2Router(address newRouter) public onlyOwner returns(bool){
        delete uniswapV2Pair;

        uniswapV2Router = IUniswapV2Router02(newRouter);

        address createdPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this),address(0));

        uniswapV2Pair.push(createdPair);
        return true;
    }
}