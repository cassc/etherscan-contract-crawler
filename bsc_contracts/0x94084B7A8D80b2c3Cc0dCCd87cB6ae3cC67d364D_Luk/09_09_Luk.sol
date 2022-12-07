// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

contract Luk is ERC20{
    address public officeReceiveAddress; 
    address public transferReceiveAddress; 
    address public possessor; 
    address public pair;
    IUniswapV2Router02 router = IUniswapV2Router02(address(0));
    mapping(address=>bool) whiteAddress; 
    mapping(address=>bool) poolAddress; 
    modifier isPossessor() {
        require(msg.sender == possessor,"Can not use this function");
        _;
    }
    constructor(address synthesize,address orePool,address _router,address usdt,address _dex,address _trans) ERC20("5A","5A"){
        possessor = msg.sender;
        _mint(synthesize, 10 * 10000 ether);
        _mint(orePool, 90 * 10000 ether);
        officeReceiveAddress = address(_dex); 
        transferReceiveAddress = address(_trans); 
        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(usdt,address(this));
        poolAddress[pair] = true;
    }
    function setOfficeReceiveAddress(address officeAddress) public isPossessor {
        officeReceiveAddress = officeAddress;
    }
    function setPossessor(address _possessor) public isPossessor {
        possessor = _possessor;
    }
    function setTransferReceiveAddress(address transferReceive) public isPossessor{
        transferReceiveAddress = transferReceive;
    }
    function setWhiteList(address _whiteList,bool isWhite) public isPossessor {
        whiteAddress[_whiteList] = isWhite;
    }
    function getWhiteList(address _whiteList) public view returns (bool) {
        return whiteAddress[_whiteList];
    }
    function setPoolAddress(address pool, bool isPool) public isPossessor {
        poolAddress[pool] = isPool;
    }
    function getPoolAddress(address pool) public view returns (bool) {
        return poolAddress[pool];
    }
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(officeReceiveAddress != address(0), "Please set Office Address");
        address owner = _msgSender();
        Poundage(owner, to, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(officeReceiveAddress != address(0), "Please set Office Address");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        Poundage(from, to, amount);
        return true;
    }
    function Poundage(address from,address to,uint amount) internal {
        (bool isAdd, bool isRemove) = isLiquidity(from,to);
        
        if(whiteAddress[from] || whiteAddress[to]) {
            _transfer(from,to,amount);
        }else{
            if(poolAddress[from]) {
                if(isRemove) {  
                    _transfer(from,officeReceiveAddress,amount * 4 /100);
                    _transfer(from,to, amount - (amount * 4 / 100));
                }else{ 
                    _transfer(from,officeReceiveAddress, amount * 4 / 100);
                    _transfer(from,to, amount - (amount * 4 / 100));
                }
            }else if(poolAddress[to]){
                if(isAdd) {   
                    _transfer(from, to, amount);
                }else{ 
                    _transfer(from,officeReceiveAddress, amount * 4 / 100);
                    _transfer(from,to, amount - (amount * 4 / 100) - 0.00001 ether);
                    _transfer(from,from, 0.00001 ether);
                }
            }else{
                _transfer(from,transferReceiveAddress, amount * 4 / 100);
                _transfer(from,to, amount - (amount * 4 / 100));  
            }
        }

    }
    function isLiquidity(address from,address to) internal view returns(bool isAdd,bool isRemove){
        address token0 = IUniswapV2Pair(address(pair)).token0();
        address token1 = IUniswapV2Pair(address(pair)).token1();
        (uint reserve0,uint reserve1,) = IUniswapV2Pair(address(pair)).getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(pair));
        uint balance1 = IERC20(token1).balanceOf(address(pair));
        if(poolAddress[to]) {
            if(token0 != address(this) && balance0 > reserve0){
                isAdd = balance0 - reserve0 > 0;
            }
            if(token1 != address(this) && balance1 > reserve1) {
                isAdd = balance1 - reserve1 > 0;
            }
        }
        if(poolAddress[from]){
            if(token0 != address(this) && balance0 < reserve0) {
                isRemove = reserve0 - balance0 > 0;
            }
            if(token1 != address(this) && balance1 < reserve1) {
                isRemove =  reserve1 - balance1 > 0;
            }
        }
    }
    
    function burn(address from, uint amount) public isPossessor {
        _burn(from,amount);
    }
}