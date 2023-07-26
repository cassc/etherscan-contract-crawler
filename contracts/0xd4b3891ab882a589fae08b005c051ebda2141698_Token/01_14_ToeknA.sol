// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/uniswap/IUniswapV2Factory.sol";
import "./lib/uniswap/IUniswapV2Pair.sol";
import "./lib/uniswap/IUniswapV2Router02.sol";

contract Token is ERC20Burnable, Ownable{
    using SafeERC20 for IERC20;

    IUniswapV2Router02 immutable public swapV2Router;
    mapping(address => bool) public swapV2Pairs;
    address public immutable mainPair;
    address public marketAddress;


    constructor(address swapV2RouterAddress_, address _marketAddress) ERC20("ElonMusk2.0", "ElonMusk2.0"){
        _mint(0xf5067e929B322709bC5861a425Bf31c38a11E38d, 420_690_000_000_000 * (10 ** decimals()));
        marketAddress = _marketAddress;

        swapV2Router = IUniswapV2Router02(swapV2RouterAddress_);
        IUniswapV2Router02 _uniswapV2Router02 = IUniswapV2Router02(swapV2RouterAddress_);
        address _swapV2PairAddress = IUniswapV2Factory(_uniswapV2Router02.factory())
            .createPair(address(this), _uniswapV2Router02.WETH());
        require(IUniswapV2Pair(_swapV2PairAddress).token1() == address(this), "Not token1");
        mainPair = _swapV2PairAddress;
        swapV2Pairs[_swapV2PairAddress] = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        
        uint256 _fee;
        if(swapV2Pairs[sender] || swapV2Pairs[recipient]){
            (bool isAdd, bool _isRm) = _isLiquidity(sender, recipient, amount);
            if (!isAdd && !_isRm){
                if (swapV2Pairs[sender]){  
                    _fee = amount * 1 / 100;
                }else { 
                    _fee = amount * 1 / 100;
                }
            }
        }
        if (_fee > 0){
            super._transfer(sender, marketAddress, _fee);
            amount -= _fee;
        }
        super._transfer(sender, recipient, amount);
    }

    function updateSwapPairConfig(address pair_, bool status_) public onlyOwner {
        require(swapV2Pairs[pair_] != status_, "A");
        swapV2Pairs[pair_] = status_;
    }

    function updateMarketAddress(address _marketAddress) public onlyOwner {
        require(_marketAddress != address(0), "A");
        marketAddress = _marketAddress;
    }


    function _isLiquidity(address from, address to, uint256 amount) internal view returns (bool isAdd, bool isRm){
        if(swapV2Pairs[to]){
            IUniswapV2Pair _pair = IUniswapV2Pair(to);
            address _token0 = _pair.token0();
            if (address(this) != _token0){ 
                (uint256 r0, uint256 r1,) = _pair.getReserves();
                if (r0 == 0){
                    isAdd = true;
                }else {
                    uint256 token0Bal = IERC20(_token0).balanceOf(address(_pair));
                    isAdd = token0Bal > r0 + r0 * amount / r1 / 2;
                }
            }
        }
        
        if(swapV2Pairs[from]){
            IUniswapV2Pair _pair = IUniswapV2Pair(from);
            address _token0 = _pair.token0();
            if (address(this) != _token0){ 
                (uint256 r0, ,) = _pair.getReserves();
                uint256 token0Bal = IERC20(_token0).balanceOf(address(_pair));
                isRm = r0 > token0Bal; 
            }
        }
    }
}