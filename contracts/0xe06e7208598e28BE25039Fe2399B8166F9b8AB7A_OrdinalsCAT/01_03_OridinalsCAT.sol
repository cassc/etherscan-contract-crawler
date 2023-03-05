/*

    ██████╗ ██████╗ ██████╗ ██╗███╗   ██╗ █████╗ ██╗     ███████╗    ███████╗██╗  ██╗██╗██████╗  ██████╗ █████╗ ████████╗
    ██╔═══██╗██╔══██╗██╔══██╗██║████╗  ██║██╔══██╗██║     ██╔════╝    ██╔════╝██║  ██║██║██╔══██╗██╔════╝██╔══██╗╚══██╔══╝
    ██║   ██║██████╔╝██║  ██║██║██╔██╗ ██║███████║██║     ███████╗    ███████╗███████║██║██████╔╝██║     ███████║   ██║   
    ██║   ██║██╔══██╗██║  ██║██║██║╚██╗██║██╔══██║██║     ╚════██║    ╚════██║██╔══██║██║██╔══██╗██║     ██╔══██║   ██║   
    ╚██████╔╝██║  ██║██████╔╝██║██║ ╚████║██║  ██║███████╗███████║    ███████║██║  ██║██║██████╔╝╚██████╗██║  ██║   ██║   
    ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝╚═╝  ╚═╝   ╚═╝   
                                                                                                                        

        *** Ordinals cutest cat of Shibarium ***

        💻 website  :   http://ordinalscat.com   
        🌏 twitter  :   https://twitter.com/oShibaCat
        🌏 telegram :   https://t.me/oshibacat                                                             

*/

// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.19;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function allPairsLength() external view returns (uint256);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IOrdinalsCAT {
    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

contract OrdinalsCAT is IOrdinalsCAT, Ownable {
    string public name = "Ordinals ShibaCat";
    string public symbol = "oShibaCat";

    uint8 public constant decimals = 6;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        totalSupply = 1_000_000_000_000_000 * 10**decimals;
        unchecked {
            balanceOf[msg.sender] += totalSupply;
        }
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f) // UniswapFactory
            .createPair(
                address(this),
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 // WETH
            );
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool) {
        balanceOf[_from] -= _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        uint256 allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint256).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }
}