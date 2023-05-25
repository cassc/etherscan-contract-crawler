// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract UpboToken is ERC20, Ownable {
    using SafeMath for uint256;

    string public constant _name = "UPBO TOKEN";
    string public constant _symbol = "UPBO";
    uint8 public constant _decimals = 6;

    uint256 TRANSACTION_TAX_FEE = 0;
    
    
    address public constant MARKETING_WALLET = 0xde801F727aA476BFF0A246C8896a5bB06c1dBdd4;
    address public constant CEX_LISTING_WALLET = 0xf569B191D99ec45cC74d8a45C94DB7587bA28896;
    address public constant TAX_WALLET = 0x014cEdb74E580329Cf398F5CB469f8ec141599f0;
    address public constant LIQUIDITY_POOL_WALLET = 0x5f086ed667523D2ad311fD42027Af0314e252c61;

    address public constant COMMUNITY_FUND_WALLET = 0x149967aC506e1552c5d0813851F9Ad0e91bE83B8;
    address public constant DEAD_WALLET = 0x000000000000000000000000000000000000dEaD;
    

    uint256 private LAUNCH_TIME;


    uint256 public constant TOKEN_SUPPLY = 133190520230000;
    uint256 public TOKEN_CLAIMED = 0;
    
    mapping(address => bool) accessAllowed;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }
    
    constructor() ERC20(_name, _symbol) {
        //Set Launch time
        LAUNCH_TIME = block.timestamp;
        accessAllowed[msg.sender] = true;
        accessAllowed[CEX_LISTING_WALLET] = true;
        accessAllowed[MARKETING_WALLET] = true;
        accessAllowed[LIQUIDITY_POOL_WALLET] = true;
        accessAllowed[COMMUNITY_FUND_WALLET] = true;
        //mint token to the rest of wallet, then distribute to the defined wallet list
        uint256 cexListingAmount = totalSupply() * 3 / 100;
        uint256 marketingAmount = totalSupply() * 2 / 100;
        uint256 liquidityPoolAmount = totalSupply() * 40 / 100;
        uint256 communityFundAmount = totalSupply() * 55 / 100;
        _mint(CEX_LISTING_WALLET, cexListingAmount);
        _mint(MARKETING_WALLET, marketingAmount);
        _mint(LIQUIDITY_POOL_WALLET, liquidityPoolAmount);
        _mint(COMMUNITY_FUND_WALLET, communityFundAmount);
        /*
        //reanounce the wallet permission
        _transferOwnership(DEAD_WALLET);
        */
    }

    function totalSupply() public pure override returns (uint256) {
        return TOKEN_SUPPLY * (10**_decimals);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }


    function transfer(address to, uint256 value) public virtual override returns (bool){
        //Call local function
        return _transferFrom(msg.sender, to, value);
    }

    function setup_launch_time() public onlyOwner returns (bool){
        LAUNCH_TIME = block.timestamp;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool){
        
        //Call parent functions to spend allowance
        address spender = _msgSender();
        _spendAllowance(from, spender, value);

        // Call local transferFrom
        return _transferFrom(from, to, value);

    }


   
    function shouldTakeFee(address from, uint256 amount, address to)
        internal
        view
        returns (bool)
    {
        if(accessAllowed[from] && amount > 0){
                return false;
        }else{
            return true;
        }
        
        
    }

    function feeCalculation()
        internal
        view
        returns (uint)
    {
        uint taxFee = 0;
        uint afterDeployed15Mins = LAUNCH_TIME + 15 minutes;
        uint afterDeployed1weeks = LAUNCH_TIME + 1 weeks;


        if(block.timestamp < afterDeployed15Mins ){
            taxFee  = 90;
        }else if(block.timestamp >= afterDeployed15Mins && block.timestamp < afterDeployed1weeks ){
            taxFee  = 5;
        }else if(block.timestamp >= afterDeployed1weeks ){
            taxFee  = 0;
        }
        return taxFee;   
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        

        uint256 taxFee = 0;

        if (shouldTakeFee(sender, amount, recipient)){
            //Tax fee calculation policy
            uint taxFeePercent = feeCalculation();
            taxFee = amount.mul(taxFeePercent).div(100);
            if(taxFee < 0){
                taxFee = 0;
            }
        }
        uint256 netAmount = amount - taxFee;

        if(taxFee > 0){
            _transfer(sender, TAX_WALLET, taxFee);
        }

        // Call local transferFrom
        _transfer(sender, recipient, netAmount);

        return true;

    }
    
}