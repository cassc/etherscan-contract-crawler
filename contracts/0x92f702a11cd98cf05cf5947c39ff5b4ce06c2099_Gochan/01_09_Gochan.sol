// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "v2-core/interfaces/IUniswapV2Factory.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";

contract Gochan is ERC20, Ownable {
    uint256 public immutable initialSupply;
    uint256 public immutable percentageBase;

    uint256 public disabledBlocks;
    uint256 public blockStart;
    uint256 public timeStart;

    address public routerAddress;
    uint256 public tax;
    address public recipient;
    uint256 public taxCollected;

    uint256 public maxWallet;
    uint256 public maxTx;
    uint256 public txCooldown;
    uint256 public fxEnd;

    mapping(address => uint256) public lastTxTimestamp;

    uint256 public taxThreshold;
    uint256 public lastTaxBlock;

    mapping(address => bool) public exempt;
    mapping(address => bool) public dex;

    constructor(
        address _router,
        address _taxReceiver,
        address[] memory wallets,
        uint256[] memory tokenAmounts,
        uint256 initialLiquidity
    ) payable ERC20("GOCHAN COIN", "GOCHAN") Ownable() {
        initialSupply = 420_000_000_000 ether;
        percentageBase = 100_000;

        disabledBlocks = 4;
        routerAddress = _router;
        tax = 2_000; // 2%
        recipient = _taxReceiver;

        maxWallet = 2_000; // 2%
        maxTx = 200; // 0.2%
        txCooldown = 15 seconds;
        fxEnd = 4 hours;
        taxThreshold = 5 minutes;

        exempt[address(this)] = true;

        require(wallets.length == tokenAmounts.length, "Invalid input");
        for (uint256 i = 0; i < wallets.length; i++) {
            _mint(wallets[i], tokenAmounts[i]);
            require(tokenAmounts[i] <= initialSupply * maxWallet / percentageBase, "Invalid token amount");
        }
        _mint(address(this), initialLiquidity);
        require(totalSupply() == initialSupply, "Initial supply does not match");
    }

    function addInitialLiquidity(
        uint256 liquidityAmount,
        uint256 ethAmount
    ) external payable onlyOwner {
        require(blockStart == 0, "Liquidity already added");
        require(timeStart == 0, "Liquidity already added");

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        _approve(address(this), routerAddress, ~uint256(0));

        address pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        dex[pair] = true;

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            liquidityAmount,
            0,
            0,
            msg.sender,
            block.timestamp + 15 minutes
        );

        blockStart = block.number;
        timeStart = block.timestamp;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 toRecip = amount;

        if (
            blockStart == 0 ||
            timeStart == 0
        ) {
            require(
                from == address(this) ||
                to == address(this),
                "Liquidity not added"
            );
        }

        bool isBeforeFx = block.number <= blockStart + disabledBlocks;
        if (dex[from] || dex[to]) {
            uint256 taxRate;
            bool isDuringFx = block.timestamp <= timeStart + fxEnd;

            if (exempt[from] || exempt[to]) {
                taxRate = 0;
            } else if (
                isBeforeFx &&
                dex[from] &&
                !exempt[to]
            ) {
                taxRate = 95_000; // 95% 
            } else {
                taxRate = tax;
            }

            uint256 toTax = (amount * taxRate) / percentageBase;
            toRecip = amount - toTax;
            if (toTax > 0) {
                super._transfer(from, address(this), toTax);
                taxCollected += toTax;
            }

            if (!isBeforeFx && isDuringFx) {
                require(
                    amount <= maxTx * initialSupply / percentageBase,
                    "Transfer amount exceeds maxTx."
                );

                if (!dex[from]) {
                    require(
                        block.timestamp - lastTxTimestamp[from] >= txCooldown,
                        "Transfer cooldown not expired."
                    );
                    lastTxTimestamp[from] = block.timestamp;
                }
            }
        }

        if (!isBeforeFx && !dex[to]) {
            require(
                balanceOf(to) + toRecip <= maxWallet * initialSupply / percentageBase,
                "Recipient wallet balance exceeds maxWallet."
            ); 
        }

        if (
            !dex[from] && 
            taxCollected > 0 &&
            block.timestamp - lastTaxBlock > taxThreshold
        ) {
            lastTaxBlock = block.timestamp;
            uint256 toSwap = taxCollected;
            taxCollected = 0;
            _swapTokensToEth(toSwap, recipient);
        }
        
        super._transfer(from, to, toRecip);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        if (allowance(owner, spender) == ~uint256(0)) {
            return;
        }
        return super._spendAllowance(owner, spender, amount);
    }

    function _swapTokensToEth(
        uint256 tokenAmount,
        address recip
    ) private {
        if (tokenAmount > balanceOf(address(this))) {
            tokenAmount = balanceOf(address(this));
        }
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            recip,
            block.timestamp + 15 minutes
        );
    }

    receive() external payable {}
}