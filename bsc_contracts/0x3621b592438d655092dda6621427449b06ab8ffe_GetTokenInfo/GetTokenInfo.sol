/**
 *Submitted for verification at BscScan.com on 2023-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IBEP20 {
function totalSupply() external view returns (uint256);
function decimals() external view returns (uint8);
function symbol() external view returns (string memory);
function name() external view returns (string memory);
function owner() external view returns (address);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPancakePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract GetTokenInfo {

    // Ethereum mainnet    
    //address public factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    //address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // BSC mainnet    
    address public factory = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address public WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    function getTokenInfo(address token) public view returns(string memory _name, string memory _symbol, address _owner, uint _totalSupply, uint _decimals){
        _name = IBEP20(token).name();
        _symbol = IBEP20(token).symbol();
        
        try IBEP20(token).owner() returns (address _towner){
            _owner = _towner;
        }catch{
            _owner = address(0);
        }
        
        _totalSupply = IBEP20(token).totalSupply();
        _decimals = IBEP20(token).decimals();
    }

    function getDexInfo(address token) public view returns(address _pair, uint112 _reserveA, uint112 _reserveB, bool _loc){
        _pair = IPancakeFactory(factory).getPair(WETH, token);
        if (_pair != address(0)){
            (_reserveA, _reserveB, _loc) = getReserves(_pair, WETH, token);
        }else{
            (_reserveA, _reserveB, _loc) = (0, 0, false);
        }

    }

    function getAllInfo(address token) external view returns(string memory _name, string memory _symbol, address _owner, uint _totalSupply, uint _decimals, address _pair, uint112 _reserveA, uint112 _reserveB, bool _loc){
        (_name, _symbol, _owner, _totalSupply, _decimals) = getTokenInfo(token);
        (_pair, _reserveA, _reserveB, _loc) = getDexInfo(token);
    }

    // получаем резервы из пары и порядок следования токенов в паре
    function getReserves(address pairAddress, address tokenA, address tokenB) private view returns(uint112 reserveA, uint112 reserveB, bool loc) {  
        (address token0,) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        (uint112 reserve0, uint112 reserve1,) = IPancakePair(pairAddress).getReserves();
        (reserveA, reserveB, loc) = tokenA  == token0 ? (reserve0, reserve1, true) : (reserve1, reserve0, false);
    }    
}