// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Factory.sol";
import "./SafeMath.sol";

contract EmberERC20 is ERC20, Owned {
    using SafeMath for uint256;

    uint public max_holding;
    uint public max_transfer;
    uint public sell_tax_threshold;
    uint public buy_tax;
    uint public sell_tax;
    uint public in_swap = 1; // 1 is false, 2 is true
    uint public is_trading_enabled = 1; // 1 is false, 2 is true

    address public tax_receiver;

    mapping(address => bool) public lps;
    mapping(address => bool) public routers;
    mapping(address => bool) public anti_whale_exceptions;
    mapping(address => bool) public tax_exceptions;

    address public weth;
    address public uni_router;
    address public uni_factory;

    constructor(
        string memory name,
        string memory ticker,
        uint8 decimals,
        uint _totalSupply,
        uint _max_holding,
        uint _max_transfer,
        uint _buy_tax,
        uint _sell_tax,

        address _uni_router,
        address _weth
    ) ERC20(name, ticker, decimals) Owned(msg.sender) {
        require(_buy_tax <= 30, "buy tax too high");
        require(_sell_tax <= 30, "sell tax too high");

        if (_max_holding == 0) {
            _max_holding = type(uint256).max;
        }

        if (_max_transfer == 0) {
            _max_transfer = type(uint256).max;
        }

        require(
            _max_holding >= _totalSupply.div(100),
            "Max Holding Limit cannot be less than 1% of total supply"
        );
        require(
            _max_transfer >= _totalSupply.div(100),
            "Max Transfer Limit cannot be less than 1% of total supply"
        );

        max_holding = _max_holding;
        max_transfer = _max_transfer;

        sell_tax_threshold = _totalSupply / 100;
        buy_tax = _buy_tax;
        sell_tax = _sell_tax;

        anti_whale_exceptions[address(this)] = true;
        anti_whale_exceptions[msg.sender] = true;

        uni_router = _uni_router;
        uni_factory = IUniswapV2Router01(uni_router).factory();
        weth = _weth;

        routers[_uni_router] = true;
        allowance[address(this)][_uni_router] = type(uint256).max;
        anti_whale_exceptions[_uni_router] = true;
        allowance[msg.sender][address(this)] = type(uint256).max;

        tax_receiver = owner;

        _mint(msg.sender, _totalSupply);
    }

    modifier lockTheSwap() {
        in_swap = 2;
        _;
        in_swap = 1;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) {
            require(allowed >= amount, "no allowance");
            allowance[from][msg.sender] = allowed - amount;
        }

        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) private {
        require(
            is_trading_enabled == 2 || tx.origin == owner,
            "trading isnt live"
        );
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner && to != owner && tx.origin != owner) {
            bool isSelling;
            if (lps[from] && !routers[to] && !tax_exceptions[to]) {
                require(
                    max_transfer >= amount || anti_whale_exceptions[to],
                    "max tx limit"
                );

                taxAmount = amount.mul(buy_tax).div(100);
            }

            if (lps[to] && from != address(this) && !tax_exceptions[from]) {
                isSelling = true;
                require(
                    max_transfer >= amount || anti_whale_exceptions[from],
                    "max tx limit"
                );

                taxAmount = amount.mul(sell_tax).div(100);
            }

            uint256 contractTokenBalance = balanceOf[address(this)];
            if (
                in_swap == 1 &&
                isSelling &&
                contractTokenBalance > sell_tax_threshold
            ) {
                swapTokensForEth(contractTokenBalance);
            }
        }

        if (taxAmount > 0) {
            balanceOf[address(this)] = balanceOf[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        } else {
            require(
                max_transfer >= amount || anti_whale_exceptions[from],
                "max tx limit"
            );
        }

        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount.sub(taxAmount));

        require(
            balanceOf[to] <= max_holding ||
                anti_whale_exceptions[to] ||
                tx.origin == owner,
            "max holding limit"
        );

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapTokensForEth(uint amount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;

        try
            IUniswapV2Router01(uni_router)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amount,
                    0,
                    path,
                    tax_receiver,
                    99999999999999999999
                )
        {
            //
        } catch {
            // Ignore, to prevent calls from failing if owner sets invalid router
        }
    }

    function isAntiWhaleEnabled() external view returns (bool) {
        return max_holding != 0 || max_transfer != 0;
    }

    function setLimits(
        uint _max_holding,
        uint _max_transfer
    ) external onlyOwner {
        if (_max_holding == 0) {
            _max_holding = type(uint256).max;
        }

        if (_max_transfer == 0) {
            _max_transfer = type(uint256).max;
        }

        require(
            _max_holding >= totalSupply.div(100),
            "Max Holding Limit cannot be less than 1% of total supply"
        );
        require(
            _max_transfer >= totalSupply.div(100),
            "Max Transfer Limit cannot be less than 1% of total supply"
        );

        max_holding = _max_holding;
        max_transfer = _max_transfer;
    }

    function setAntiWhaleException(address user, bool val) external onlyOwner {
        anti_whale_exceptions[user] = val;
    }

    function enableTrading() external onlyOwner {
        is_trading_enabled = 2;
    }

    function setUniRouter(address newRouter, address newFactory) external onlyOwner {
        uni_factory = newFactory;
        uni_router = newRouter;
        routers[newRouter] = true;
        allowance[address(this)][newRouter] = type(uint256).max;
        anti_whale_exceptions[newRouter] = true;
    }

    function setAmm(address lp) public onlyOwner {
        lps[lp] = true;
        anti_whale_exceptions[lp] = true;
    }

    function addRouter(address router) external onlyOwner {
        routers[router] = true;
        allowance[address(this)][router] = type(uint256).max;
        anti_whale_exceptions[router] = true;
    }

    function setExcludeFromFee(address addy, bool val) external onlyOwner {
        tax_exceptions[addy] = val;
    }

    function setSwapThreshold(uint newThreshold) external onlyOwner {
        sell_tax_threshold = newThreshold;
    }

    function setTaxes(uint _buy_tax, uint _sell_tax) external onlyOwner {
        require(_buy_tax <= 30, "buy tax too high");
        require(_sell_tax <= 30, "sell tax too high");

        buy_tax = _buy_tax;
        sell_tax = _sell_tax;
    }

    function setTaxReceiver(address _tax_receiver) external onlyOwner {
        tax_receiver = _tax_receiver;
    }

    function addLp(uint amount) external payable onlyOwner {
        is_trading_enabled = 2;
        _transfer(owner, address(this), amount);
        uint balance = address(this).balance;
        address pair = uniV2Pair();
        IUniswapV2Router01(uni_router).addLiquidityETH{value: balance}(
            address(this),
            amount,
            amount,
            balance,
            owner,
            block.timestamp
        );
        setAmm(pair);
        is_trading_enabled = 1;
    }

    function uniV2Pair() public view returns (address pair) {
        pair = pairFor(weth, address(this));
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            uni_factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function version() public pure returns (uint) {
        return 2;
    }
}