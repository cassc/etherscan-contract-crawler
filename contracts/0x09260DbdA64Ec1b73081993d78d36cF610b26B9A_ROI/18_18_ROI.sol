// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error invalidDividentValue();
error overMaxLimit();
error invalidTxLimit();
error overAllowedBalance();
error zeroAddress();
/** 
* @title An ERC20 contract with divident
* @author sandwizard
* @dev Inherits the OpenZepplin ERC20 implentation
**/ 
contract ROI is ERC20, ERC20Burnable,AccessControl,ERC20Permit,Ownable{
    /// @notice dead address used to burn tokens
    address constant private NullAddress = 0x000000000000000000000000000000000000dEaD;
    /// @notice liquidity_pool role identifier. used to apply divident on liquidity pools
    /// @dev for use with role based access control.from open zeeplin access control
    /// @return  liquidity_pool  role identifier
    bytes32 public constant liquidity_pool = keccak256("liquidity_pool");
    /// @notice value used in calculations (calculations scaled up by percision )
    /// @dev for calculations for solidity floating point limitations
    /// @return  percision the value used in calculations scaled up by
    uint256 constant public percision = 1e18; 
    /// @notice sale divident applied on sell to liquidity pools 
    /// @dev must grant liquidity pool role to be applied. is scaled by 1e18
    /// @return  saleDividentPercentage which is 1e18 * saleDivident
    uint256 public saleDividentPercentage = 0 * percision;
    /// @notice dvident address where divident is collected and processed
    /// @return  dividentAddress
    address public divident;

    /// @notice Deploys the smart contract and creates mints inital sypply to "to" address
    constructor(uint256 initialSupply_,string memory name_,string memory symbol_,address to_) ERC20(name_, symbol_)   ERC20Permit(name_){
        if(to_ == address(0)){
            revert zeroAddress();
        }
        _transferOwnership(to_);
        _grantRole(DEFAULT_ADMIN_ROLE, to_);
        _mint(to_,initialSupply_);
    }
    /** 
    * @return totalsupply factoring in burned tokens sent to dead address
    **/ 
    function totalSupply() public view  override returns (uint256) {
        uint256 _totalSupplyWithNull = super.totalSupply();
        uint256 _totalSupply = _totalSupplyWithNull - balanceOf(NullAddress);
        return _totalSupply;
    }
    /// @notice must pass 1e18* saleDivident 
    /// @dev only admin can access 
    function setSaleDividentPercentage(uint256 _saleDivident) external onlyOwner{
        if(_saleDivident >( 25 *1e18)){
            revert invalidDividentValue();
        }
        saleDividentPercentage = _saleDivident;
    }
    
    /// @dev normal erc20 transferFrom function incase of wallet transfer
    /// @dev else sell divident  is applied
    function transferFrom(address from,address to,uint256 amount) public virtual override  returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        _transferDividence(from,to,amount);
        return true;
    }
    /// @notice set the dividentAddress where divident is colleted . zero address will stop all divident collection
    /// @dev only admin can change
    function setDivident(address divident_)external onlyOwner{
        divident = divident_;
    }

    /// @dev normal erc20 transfer function incase of wallet transfer
    /// @dev else divident and limit(only sale) is applied when a lp pool is involved
    /// @dev in case on both sender and receiver is lp pool no divident or limit applied
    function transfer(address to, uint256 amount) public virtual override returns (bool)  {
        address owner_ = _msgSender();
        _transfer(owner_, to, amount);
        _transferDividence(owner_,to,amount);
        return true;
    }
    /// @dev transfers dividence if applicable
    function _transferDividence(address from,address to,uint256 amount) internal{
        bool receiverIsLiquidityPool =  hasRole(liquidity_pool,to);
        bool senderIsLiquidityPool = hasRole(liquidity_pool, from);
        uint256 dividence;
        // sale of token
        if( !senderIsLiquidityPool &&  receiverIsLiquidityPool){
            if(address(divident)!= address(0) && saleDividentPercentage!=0) {
                dividence = (amount * saleDividentPercentage)/(100 * 1e18);
                _transfer(from, address(divident), dividence);
            }   
        }
    }
}