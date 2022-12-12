// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
error invalidTaxValue();
error overMaxLimit();
error overAllowedBalance();
contract AntiSnipe is ERC20, ERC20Burnable,AccessControl,ERC20Permit{
    address constant private NullAddress = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant liquidity_pool = keccak256("liquidity_pool");
    bytes32 public constant tax_exempt = keccak256("tax_exempt");
    uint256 constant public percision = 1e18; 
    uint256 public saleTax = 5 * percision;
    uint256 public buyTax = 5 * percision;
    address public taxCollecter;
    uint256  public maxTxAmount;
    constructor(uint256 initialSupply,string memory name,string memory symbol,address to) ERC20(name, symbol)   ERC20Permit(name){
        _grantRole(DEFAULT_ADMIN_ROLE, to);
        _mint(to,initialSupply);
    }

    function totalSupply() public view  override returns (uint256) {
        uint256 _totalSupplyWithNull = super.totalSupply();
        uint256 _totalSupply = _totalSupplyWithNull - balanceOf(NullAddress);
        return _totalSupply;
    }

    function setBuyTax(uint256 tax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if(tax >( 100 *1e18)){
            revert invalidTaxValue();
        }
        buyTax = tax;
    }
    function setSaleTax(uint256 tax) external onlyRole(DEFAULT_ADMIN_ROLE){
        if(tax >( 100 *1e18)){
            revert invalidTaxValue();
        }
        saleTax = tax;
    }
    function transferFrom(address from,address to,uint256 amount) public virtual override validAmount(amount,from,to) returns (bool) {
        bool receiverIsLiquidityPool =  hasRole(liquidity_pool,to);
        bool senderIsLiquidityPool = hasRole(liquidity_pool, from);
        uint256 tax;
        if(!senderIsLiquidityPool && taxCollecter!= address(0) && receiverIsLiquidityPool && !hasRole(tax_exempt, from)){
            tax = (amount * saleTax)/(100 * 1e18);
            _transfer(msg.sender, taxCollecter, tax);
        }
        else if(senderIsLiquidityPool && taxCollecter!= address(0) && !receiverIsLiquidityPool && !hasRole(tax_exempt, to)){
            tax = (amount * buyTax)/(100 * 1e18);
            _transfer(msg.sender, taxCollecter, tax);         
        }
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, (amount -tax));
        return true;      
    }
    function setTaxCollector(address collector)external onlyRole(DEFAULT_ADMIN_ROLE){
        taxCollecter = collector;
    }

    function setMaxTxAmount (uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE){
        maxTxAmount = amount;
    }

    modifier validAmount(uint256 amount,address from,address to){
        bool receiverIsLiquidityPool =  hasRole(liquidity_pool,to);
        bool senderIsLiquidityPool = hasRole(liquidity_pool, from);
        if(amount > maxTxAmount && maxTxAmount!= 0 && (receiverIsLiquidityPool || senderIsLiquidityPool)){
            revert overMaxLimit();
        }
        _;
    }

}