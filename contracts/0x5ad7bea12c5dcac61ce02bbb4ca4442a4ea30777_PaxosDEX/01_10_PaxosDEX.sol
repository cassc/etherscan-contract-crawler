//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {ERC20} from "./ERC20.sol";
import {Ownable} from "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract PaxosDEX is ERC20, Ownable {

    /// @notice address who is available to mint tokens
    address public minter;

    /// uniswap router
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /// uniswap pair
    address public uniswapV2Pair;

    constructor()
        ERC20("PaxosDEX", "PXD")
    {
        initLiqPair();
    }

    // initialize liq pair and approve the token to save time
    function initLiqPair() internal {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );
        _approve(owner(),address(uniswapV2Router), ~uint256(0));

    }


    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    function circulatingSupply()
        public
        view
        virtual
        returns (uint256)
    {
        return totalSupply();
    }


    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    modifier onlyMinter() {
        require(
            msg.sender == minter || msg.sender == owner(),
            "Only minter can call this"
        );
        _;
    }
}