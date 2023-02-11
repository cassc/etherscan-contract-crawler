// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

pragma solidity 0.8.9;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
 contract INAI is ERC20, Ownable {
    // TOKENOMICS START ==========================================================>

    string private _name = "Innovation AI";
    string private _symbol = "INAI";

    uint8 private _decimals = 9;
    uint256 private _supply = 10000000;
    uint256 public taxForLiquidity = 0;
    uint256 public taxForMarketing = 2;
    uint256 public maxTxAmount = 100000 * 10**_decimals;
    uint256 public maxWalletAmount = 100000 * 10**_decimals;
    address public marketingWallet;
    // TOKENOMICS END ============================================================>

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint256 private _marketingReserves = 0;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private _numTokensSellToAddToLiquidity = 5000 * 10**_decimals;
    uint256 private _numTokensSellToAddToETH = 2000 * 10**_decimals;
    bool inSwapAndLiquify;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address router_, address marketingWallet_) ERC20(_name, _symbol) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router_);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _mint(msg.sender, (_supply * 10**_decimals), uniswapV2Pair);

        uniswapV2Router = _uniswapV2Router;
        marketingWallet = marketingWallet_;

        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[marketingWallet] = true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");

        if ((from == uniswapV2Pair || to == uniswapV2Pair) && !inSwapAndLiquify) {
            if (from != uniswapV2Pair) {
                uint256 contractLiquidityBalance = balanceOf(address(this)) - _marketingReserves;
                if (contractLiquidityBalance >= _numTokensSellToAddToLiquidity) {
                    _swapAndLiquify(_numTokensSellToAddToLiquidity);
                }
                if ((_marketingReserves) >= _numTokensSellToAddToETH) {
                    _swapTokensForEth(_numTokensSellToAddToETH);
                    _marketingReserves -= _numTokensSellToAddToETH;
                    bool sent = payable(marketingWallet).send(address(this).balance);
                    require(sent, "Failed to send ETH");
                }
            }

            uint256 transferAmount;
            if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
                transferAmount = amount;
            } 
            else {
                require(amount <= maxTxAmount, "ERC20: transfer amount exceeds the max transaction amount");
                if(from == uniswapV2Pair){
                    require((amount + balanceOf(to)) <= maxWalletAmount, "ERC20: balance amount exceeded max wallet amount limit");
                }

                uint256 marketingShare = ((amount * taxForMarketing) / 100);
                uint256 liquidityShare = ((amount * taxForLiquidity) / 100);
                transferAmount = amount - (marketingShare + liquidityShare);
                _marketingReserves += marketingShare;

                super._transfer(from, address(this), (marketingShare + liquidityShare));
            }
            super._transfer(from, to, transferAmount);
        } 
        else {
            super._transfer(from, to, amount);
        }
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = (contractTokenBalance / 2);
        uint256 otherHalf = (contractTokenBalance - half);

        uint256 initialBalance = address(this).balance;

        _swapTokensForEth(half);

        uint256 newBalance = (address(this).balance - initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            (block.timestamp + 300)
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount)
        private
        lockTheSwap
    {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function changeMarketingWallet(address newWallet)
        public
        returns (bool)
    {
        require(msg.sender == marketingWallet);
        _wallet = newWallet;
        marketingWallet = newWallet;
        return true;
    }

    function changeTaxForLiquidityAndMarketing(uint256 _taxForLiquidity, uint256 _taxForMarketing)
        public
        onlyOwner
        returns (bool)
    {
        require((_taxForLiquidity+_taxForMarketing) <= 10, "ERC20: total tax must not be greater than 10");
        taxForLiquidity = _taxForLiquidity;
        taxForMarketing = _taxForMarketing;
        _marketingReserves = 0;
        return true;
    }

    function changeMaxTxAmount(uint256 _maxTxAmount)
        public
        onlyOwner
        returns (bool)
    {
        maxTxAmount = _maxTxAmount;

        return true;
    }

    function changeMaxWalletAmount(uint256 _maxWalletAmount)
        public
        onlyOwner
        returns (bool)
    {
        maxWalletAmount = _maxWalletAmount;

        return true;
    }

    receive() external payable {}
}