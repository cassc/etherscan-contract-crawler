/**
 *Submitted for verification at Etherscan.io on 2023-08-08
*/

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ILpPair {
    function mint(address to) external returns (uint liquidity);
    function sync() external;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract LPUnfucker {
    function unfuckLp(address _router, address _tokenA, uint256 _amountTokenA, address _tokenB, uint256 _amountTokenB) external {
        ILpPair pair = ILpPair(IDexFactory(IDexRouter(_router).factory()).getPair(_tokenA, _tokenB));
        // ensure approval done
        IERC20(_tokenA).transferFrom(msg.sender, address(pair), _amountTokenA);
        IERC20(_tokenB).transferFrom(msg.sender, address(pair), _amountTokenB);
        pair.mint(msg.sender);
    }

    function unfuckLpEth(address _router, address _tokenA, uint256 _amountTokenA) external payable {
        IWETH weth = IWETH(IDexRouter(_router).WETH());
        weth.deposit{value: msg.value}();
        ILpPair pair = ILpPair(IDexFactory(IDexRouter(_router).factory()).getPair(_tokenA, address(weth)));
        // ensure approval done
        IERC20(_tokenA).transferFrom(msg.sender, address(pair), _amountTokenA);
        IERC20(address(weth)).transfer(address(pair), msg.value);
        pair.mint(msg.sender);
    }
}