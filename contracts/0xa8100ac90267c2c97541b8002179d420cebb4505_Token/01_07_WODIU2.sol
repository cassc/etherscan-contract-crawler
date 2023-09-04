pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Token is ERC20  {

    mapping (uint => uint) private _txCount;

    address public pair;
    address public treasury;

    constructor(
        
        ) ERC20(unicode"我丢", unicode"我丢") {
        address _factory=0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
        address _pairToken=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        address _treasury=0x2699eD9d4e41c22FF15D8FCf14F7F8E183aac52c;

        pair = IUniswapV2Factory(_factory).createPair(address(this), _pairToken);
        _mint(0xD8218b18485F4CF14CE977e62140ee6006E7Dde9, 100e8 * 10 ** decimals());
        treasury = _treasury;
    }

    function _transfer(address from, address to, uint256 amount) internal override blockLimit {
        
        if(from == pair){
            // buy
            _t(from, to, amount);
        }else if(to  == pair){
            // sell
            _t(from, to, amount);
        }else{
            // others
            super._transfer(from, to, amount);
        }
    }

    function _t(address from, address to, uint256 amount) internal {
        uint treasuryAmount =amount * 3 / 100;
        amount -= treasuryAmount;

        super._transfer(from, treasury, treasuryAmount);
        super._transfer(from, to, amount);
    }

    modifier blockLimit() {
        require(_txCount[block.number] < 5, "over block limit");
        _;
        _txCount[block.number] ++;
    }

}