// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import {SafeMath} from "../lib/SafeMath.sol";
import {SafeCast} from "../lib/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IFeeReceiver} from "../interfaces/IFeeReceiver.sol";

contract FeeCollector is 
OwnableUpgradeable, 
PausableUpgradeable {
    using SafeMath for uint;
    using SafeCast for uint;

    uint totalBNBRecieved;
    uint totalBUSDRecieved;
    uint totalBIBRecieved;

    mapping(address=>bool) public allowToCall;

    uint public constant VERSION = 0x01;
    uint public vaultRatio = 150;
    uint public stakedRatio = 400;
    uint public kolRatio = 50;
    uint public poolRatio = 550;
    uint public minBUSDToSwap = 400 ether;
    uint public minBNBToSwap = 2 ether;

    uint public constant FEE_RATIO_DIV = 1000;
    
    IFeeReceiver public stakedReceiver;
    IFeeReceiver public kolReceiver;
    IFeeReceiver public poolReceiver;
    IUniswapV2Router02 public uniswapV2Router;

    address public vault;

    IERC20 public bibToken;
    IERC20 public busdToken;
    uint public minBIBToSwap = 1**6 ether;

    enum TokenType{
        TOKEN_TYPE_BNB,
        TOKEN_TYPE_BIB,
        TOKEN_TYPE_BUSD
    } 

    event VaultChanged(address sender, address oldValue, address newValue);
    event BIBContractChanged(address sender, address oldValue, address newValue);
    event BUSDContractChanged(address sender, address oldValue, address newValue);
    event RouterContractChanged(address sender, address oldValue, address newValue);
    event HandleCollect(address sender, TokenType tokenType, uint amount);
    event Distribute(address sender, address receiver, uint amount);

    receive() external payable{}

    function initialize(
        address _vault,
        address _bibToken,
        address _busdToken,
        address _stakedReceiver,
        address _kolReceiver,
        address _poolReceiver
        ) public reinitializer(1)  {
            
        vault = _vault;
        bibToken = IERC20(_bibToken);
        busdToken = IERC20(_busdToken);

        stakedReceiver = IFeeReceiver(_stakedReceiver);
        kolReceiver = IFeeReceiver(_kolReceiver);
        poolReceiver = IFeeReceiver(_poolReceiver);

        vaultRatio = 150;
        stakedRatio = 400;
        kolRatio = 50;
        poolRatio = 550;
        minBUSDToSwap = 400 ether;
        minBNBToSwap = 2 ether;
        minBIBToSwap = 1**6 ether;

        __Pausable_init();
        __Ownable_init();
    }

    function setDistributeRatio(
        uint _vaultRatio,
        uint _stakedRatio,
        uint _kolRatio,
        uint _poolRatio
        ) public onlyOwner{
         vaultRatio = _vaultRatio;
         kolRatio = _kolRatio;
         poolRatio = _poolRatio;
         stakedRatio = _stakedRatio;

        require(vaultRatio <= FEE_RATIO_DIV, "INVALID_VAULT_RATIO");
        require(kolRatio.add(poolRatio).add(stakedRatio) <= FEE_RATIO_DIV, "INVALID_DIVEND_RATIO");
    }

    function setSwapThreshHold(uint _minBUSDToSwap, uint _minBNBToSwap, uint _minBIBToSwap) public onlyOwner{
        minBUSDToSwap = _minBUSDToSwap;
        minBNBToSwap = _minBNBToSwap;
        minBIBToSwap = _minBIBToSwap;
    }

    function setFeeReceiver(
        address _stakedReceiver,
        address _kolReceiver,
        address _poolReceiver) public onlyOwner{
        stakedReceiver = IFeeReceiver(_stakedReceiver);
        kolReceiver = IFeeReceiver(_kolReceiver);
        poolReceiver = IFeeReceiver(_poolReceiver);
    }

    function setBIBContract(address _bibToken) public onlyOwner{
        require(address(0) != _bibToken, "INVALID_ADDRESS");
        emit BIBContractChanged(msg.sender, address(bibToken), _bibToken);
        bibToken = IERC20(_bibToken);
    }

    function setBUSDContract(address _busdToken) public onlyOwner{
        require(address(0) != _busdToken, "INVALID_ADDRESS");
        emit BUSDContractChanged(msg.sender, address(busdToken), _busdToken);
        busdToken = IERC20(_busdToken);
    }

    function setVault(address _vault) public onlyOwner{
        require(address(0) != _vault, "INVALID_ADDRESS");
        emit VaultChanged(msg.sender, address(vault), _vault);
        vault = _vault;
    }

   function setSwapRouter(address _uniswapV2Router) public onlyOwner{
        require(address(0) != _uniswapV2Router, "INVALID_ADDRESS");
        emit RouterContractChanged(msg.sender, address(uniswapV2Router), _uniswapV2Router);
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    function setAllowToCall(address caller, bool value) public onlyOwner{
        allowToCall[caller] = value;
    }

    function isAllowCall(address caller) public view returns(bool){
        return allowToCall[caller];
    }

    modifier onlyCaller(){
        require(allowToCall[msg.sender], "ONLY_CALLER");
        _;
    }

    function caculateFees(uint amount, uint feeRatio) public pure  returns(uint, uint){
        uint firstPart =  amount.mul(feeRatio).div(FEE_RATIO_DIV);
        return (firstPart, amount.sub(firstPart));
    }

    function distributeFees() public onlyOwner{
        handleCollectBIB(bibToken.balanceOf(address(this)));
        handleCollectBUSD(busdToken.balanceOf(address(this)));
        handleCollectBNB(address(this).balance);
    }

    function distribute(uint amount) internal {
        (uint vaultPart,uint remain) = caculateFees(amount, vaultRatio);
        // to vault
        if(address(0) != vault){
            bibToken.transfer(vault, vaultPart);
        }
        // stake part
        (uint stakedPart, ) = caculateFees(remain, stakedRatio);
        if(address(0) != address(stakedReceiver)){
            bibToken.transfer(address(stakedReceiver), stakedPart);
            stakedReceiver.handleReceive(stakedPart);
            emit Distribute(msg.sender, address(stakedReceiver), amount);
        }
        // kol part
        (uint kolPart, ) = caculateFees(remain, kolRatio);
        if(address(0) != address(kolReceiver)){
            bibToken.transfer(address(kolReceiver), kolPart);
            emit Distribute(msg.sender, address(kolReceiver), amount);
        }
        // kol part
        (uint poolPart, ) = caculateFees(remain, poolRatio);
        if(address(0) != address(poolReceiver)){
            bibToken.transfer(address(poolReceiver), poolPart);
            poolReceiver.handleReceive(poolPart);
            emit Distribute(msg.sender, address(poolReceiver), amount);
        }
    }
   
    function handleCollectBIB(uint amount) public onlyCaller{
        emit HandleCollect(msg.sender, TokenType.TOKEN_TYPE_BIB, amount);

        amount = bibToken.balanceOf(address(this));
        if(amount >= minBIBToSwap){
            distribute(amount);
        }
    }

    function handleCollectBUSD(uint amount) public onlyCaller{
        emit HandleCollect(msg.sender, TokenType.TOKEN_TYPE_BUSD, amount);

        amount = busdToken.balanceOf(address(this));
        if(amount >= minBUSDToSwap){
            // swap BIB
            address[] memory path = new address[](2);
            path[0] = address(busdToken);
            path[1] = address(bibToken);

            busdToken.approve(address(uniswapV2Router), amount);

            uint balanceBefore = bibToken.balanceOf(address(this));

            // make the swap
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            );
            uint swapped = bibToken.balanceOf(address(this)).sub(balanceBefore);

            distribute(swapped);
        }

    }

    function handleCollectBNB(uint amount) public payable onlyCaller{
        emit HandleCollect(msg.sender, TokenType.TOKEN_TYPE_BNB, amount);

        amount = address(this).balance;
        if(amount >= minBNBToSwap){
            // swap BIB
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(bibToken);

            uint balanceBefore = bibToken.balanceOf(address(this));

            // make the swap
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                0, 
                path,
                address(this),
                block.timestamp
            );

            uint swapped = bibToken.balanceOf(address(this)).sub(balanceBefore);
            distribute(swapped);
        }
    }
}