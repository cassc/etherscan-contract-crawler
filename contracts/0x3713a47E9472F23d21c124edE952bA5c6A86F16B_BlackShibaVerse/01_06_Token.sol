// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * Website : BlackShibaverse.io
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface UniswaV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface UniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract BlackShibaVerse is ERC20, Ownable {
    // 10, 000, 000, 000
    uint256 private constant _totalSupply = 1e10 * 1e18;
    uint256 public constant maxWallet = 2;
    uint256 public constant taxPercent = 5;
    address public constant devWallet =
        0x81C13d0b718711CBb8816f3f6f610f340b6D86FB;
    address public immutable pair;
    bool public isLaunched = false;
    UniswapV2Router public immutable uniswapV2Router;
    mapping(address => bool) private whitelisted;
    bool swapping = false;

    constructor() ERC20("Black Shibaverse", "BLACK") {
        uniswapV2Router = UniswapV2Router(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        pair = UniswaV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        whitelisted[msg.sender] = true;
        whitelisted[address(this)] = true;
        whitelisted[devWallet] = true;
        whitelisted[address(uniswapV2Router)] = true;
        _mint(devWallet, _totalSupply);
    }

    function checkWhitelist(address _wallet) external view returns (bool) {
        return whitelisted[_wallet];
    }

    function setWhitelistStatus(address _wallet, bool _status)
        external
        onlyOwner
    {
        whitelisted[_wallet] = _status;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!whitelisted[from] && !whitelisted[to] && to != pair) {
            require(
                balanceOf(to) + amount <= (_totalSupply * maxWallet) / 100,
                "Max Wallet Amount is 2%"
            );
        }
        uint256 tax = 0;
        if (
            !whitelisted[from] &&
            !whitelisted[to] &&
            (from == pair || to == pair)
        ) {
            tax = (amount * taxPercent) / 100;
            super._transfer(from, address(this), tax);
            amount = amount - tax;
        }
        if (tax > 0 && isLaunched && to == pair && !swapping) {
            swapping = true;
            SendTaxesToDevWallet();
            swapping = false;
        }

        isLaunched = true;
        super._transfer(from, to, amount);
    }

    function SendTaxesToDevWallet() internal {
        uint256 amount = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), amount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of Tokens
            path,
            devWallet,
            block.timestamp
        );
    }
}