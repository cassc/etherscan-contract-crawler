// SPDX-License-Identifier: MIT
/*

    GRUG
    Website: https://grugcoin.com
    Ooga: Booga


                                                             ,                  
                                         #**@#*.%&.,   #@%(,  % ,@#.*           
                                        @           ,&               %%(        
                                      @                               @         
     *&///////(@(                    #          &&&*        ,,        /         
   #///////////////&(               @                                & @        
   @///////////@(((@//(@         &.          [email protected] @*       /  @    ,%*%  .,       
   &//////////@(@/////////%    %                  *,& .  @&.,&          @       
   &////////////////////////(&#                              @   #       .      
   ,(///////////////////////@           .#  @@&     (        [email protected]  &  *&@@/&      
    ,%/////////////////////&               %&%%&/               @*     .  @     
      %////////////////////(                    %@&,             @       *.     
       ((@////////////////%/                    *&             *@        @      
      @@    %&////////////%/                                  @@        .#      
               *&/////////@                          .(%(*.             @       
                   .&&///@                     (#             @,     ,@         
                         &                                        @,            
                        @                                 * *#&[email protected]//&            
                      #&                         ./(*#,# ..&@@#//(///%,         
                     @*                              @&//(@@////////////((      
                   @****(@(                            @  ,@(//////////////(@%  
                @@*****&&%***@                 @        @      (@/////////////  
           *(@@&@@/****(//*****&              @.         /%         [email protected](///////  
     /@*          (***#(/*(&&(***@,                            .%@%     @(////  
*/

pragma solidity >=0.8.16;

import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/access/Ownable.sol";

import "uniswap/periphery/interfaces/IUniswapV2Router02.sol";
import "uniswap/core/interfaces/IUniswapV2Factory.sol";

contract GrugToken is ERC20, Ownable {

    IUniswapV2Router02 private constant _uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint16 private constant BIPS_DEMONINATOR = 10_000;

    uint8 private constant BOT_MAXTX = 0x01;
    uint8 private constant BOT_MAXWALLET = 0x02;

    mapping(address => bool) private _addressExempt;
    mapping(address => bool) private _addressBlacklist;
    uint256 private _maxTxAmount = 0;
    uint256 private _maxWalletAmount = 0;
    address private _uniswapPair;
    
    uint8 private _botProtection = 0;

    function maxTxAmount() external view returns(uint256) { return _maxTxAmount; }
    function maxWalletAmount() external view returns(uint256) { return _maxWalletAmount; }
    function uniswapPair() external view returns(address) { return _uniswapPair; }

    constructor(uint256 totalSupply, address mintTo) ERC20("GRUG", "GRUG") payable
    {
        _maxTxAmount = totalSupply * 50 / BIPS_DEMONINATOR;
        _maxWalletAmount = totalSupply * 330 / BIPS_DEMONINATOR;

        address uniswapV2Pair =
            IUniswapV2Factory(_uniswapRouter.factory())
            .createPair(address(this), _uniswapRouter.WETH());
        _uniswapPair = uniswapV2Pair;

        _mint(mintTo, totalSupply);

        _botProtection = BOT_MAXTX | BOT_MAXWALLET;
    }

    function setBotProtect(uint8 flags) onlyOwner() external {
        _botProtection = flags;
    }

    function setMaxTxAmount(uint256 amount) onlyOwner() external {
        _maxTxAmount = amount;
    }

    function setAddrExempt(address addr, bool exempt) onlyOwner() public {
        _addressExempt[addr] = exempt;
    }

    function setBot(address[] calldata addr) onlyOwner() external {
        for(uint i = 0; i < addr.length; i++) {
            require (addr[i] != _uniswapPair, "Cannot blacklist Uniswap Pair");
            _addressBlacklist[addr[i]] = true;
        }
    }

    function unsetBot(address[] calldata addr) onlyOwner() external {
        for(uint i = 0; i < addr.length; i++) {
            require (addr[i] != _uniswapPair, "Cannot blacklist Uniswap Pair");
            _addressBlacklist[addr[i]] = false;
        }
    }

    function _transferOwnership(address newOwner) override internal
    {
        if(newOwner == address(0)) {
            require(_botProtection == 0, "Bot Protection must be disabled before contract can be renounced");
            require(_maxTxAmount == 0, "Max Tx Amount must be zero (disabled) before contract can be renounced");
            require(_maxWalletAmount == 0, "Max Wallet Amount must be zero (disabled) before contract can be renounced");
        }
        super._transferOwnership(newOwner);
    }

    /* We override the internal transfer function to add bot protection. */
    function _transfer(address from, address to, uint256 amount) internal override
    {
        uint8 flags = _botProtection;
        if(flags != 0) {
            if((flags & BOT_MAXTX) == BOT_MAXTX)
                _checkMaxTxAmount(from, to, amount);

            if((flags & BOT_MAXWALLET) == BOT_MAXWALLET)
                _checkMaxWallet(from, to, amount);
        }

        require(!(_addressBlacklist[from] || _addressBlacklist[to]), "Address is blacklisted");

        return super._transfer(from, to, amount);
    }

    /* Prevents bots from buying up large amounts of initial supply */
    function _checkMaxTxAmount(address from, address to, uint256 amount) private view
    {
        uint256 max = _maxTxAmount;
        if(max == 0)
            return;

        address owner = owner();
        if(from == owner || to == owner || from == address(this))
            return;

        if(_addressExempt[_msgSender()] == true)
            return;
        
        require(amount <= max, "Cannot transfer this amount in a single transaction");
    }

    function _checkMaxWallet(address from, address to, uint256 amount) private view
    {
        uint256 max = _maxWalletAmount;
        if(max == 0)
            return;

        address owner = owner();
        if(from == owner || to == owner || from == address(this))
            return;

        if(_addressExempt[_msgSender()] == true)
            return;
        
        uint256 balance = amount + balanceOf(to);
        require(balance <= max, "Cannot hold this amount in a single wallet");
    }
}