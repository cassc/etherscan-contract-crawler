// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "@openzeppelin/utils/Context.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";

contract Samurai is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // token details
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = "Samurai";
    string private constant _symbol = "SamurAi";

    address public constant DEAD_ADDRESS = address(0xdead);
    uint256 public constant BUY_PROTOCOL_FEE = 3;
    uint256 public constant SELL_PROTOCOL_FEE = 3;
    uint256 public constant SWAP_TOKENS_AT = 1000000 * 10**_decimals;

    // For the samurai mode
    uint256 public constant ATH_SELL_PROTOCOL_FEE = 10;
    uint256 public constant DIP_BUY_INCENTIVE = 5;
    uint256 public constant PERCENTAGE_FROM_LAST_ATH = 10; // 10% from more last ATH
    uint256 public constant PERCENTAGE_FROM_LAST_DIP = 10; // 10% from less last DIP

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public lastAthPrice;
    uint256 public lastDipPrice;
    uint256 public feesAsIncentive;

    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public samuraiModeEnabled = false;
    bool private _swappingSwitch = true;

    address payable private _protocolWallet;

    mapping(address => bool) private _isExcludedFromFees;

    event SwapFees(uint256 tokensSwapped, uint256 ethReceived);

    /**
     * @dev Constructor
     */
    constructor() {
        _protocolWallet = payable(0x64eb584CEfCF087Fe6f500c9A5acF158BB5ea6D9);

        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD_ADDRESS] = true;
        _isExcludedFromFees[_msgSender()] = true;

        uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        _balances[_msgSender()] = _tTotal;
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Check if the address is excluded from fees
     */
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    /**
     * @dev Transfer tokens
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (!tradingActive) {
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "Trading is not active"
            );
        }

        uint256 protocolFeesBalance = balanceOf(address(this)).sub(
            feesAsIncentive
        );
        bool canSwap = protocolFeesBalance >= SWAP_TOKENS_AT;
        bool takeFee = true;
        uint256 fees = 0;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (
            canSwap &&
            swapEnabled &&
            uniswapV2Pair == to &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            if (!_swappingSwitch) {
                _swapFees();

                _swappingSwitch = true;
            } else {
                _swappingSwitch = false;
            }
        }

        // NOTE: only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            if (uniswapV2Pair == to) {
                if (samuraiModeEnabled && _isNewAth()) {
                    // NOTE: If the price in the new ATH the first seller will pay the ATH fees
                    uint256 calculatedAthFees = _calculateAthFees(amount);

                    if (calculatedAthFees > 0) {
                        _recordAth(calculatedAthFees);
                        fees += calculatedAthFees;
                    }
                }

                fees += amount.mul(SELL_PROTOCOL_FEE).div(100);
            }

            if (uniswapV2Pair == from) {
                // NOTE: If the price in the new dip the first buyer will get the incentive (5%)
                if (samuraiModeEnabled && _isNewDip()) {
                    uint256 calculatedDipIncetive = _calculateDipIncentive(
                        amount
                    );

                    if (calculatedDipIncetive > 0) {
                        _recordDip(calculatedDipIncetive);

                        // transfer the incentive to the buyer
                        _balances[address(this)] -= calculatedDipIncetive;
                        _balances[to] += calculatedDipIncetive;

                        emit Transfer(address(this), to, calculatedDipIncetive);
                    }
                }

                fees = amount.mul(BUY_PROTOCOL_FEE).div(100);
            }

            if (fees > 0) {
                _balances[address(this)] += fees;

                emit Transfer(from, address(this), fees);
            }
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(fees));

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Froce swap protocol fees
     * NOTE: Used for transferring the fees to the protocol wallet
     */
    function forceSwapProtocolFees() external {
        require(
            _msgSender() == _protocolWallet,
            "Only protocol wallet can call this method"
        );

        _swapFees();
    }

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    // -- NOTE: Private methods used by this contract only
    // -- NOTE: The owner dosen't have access to these methods
    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    /**
     * @dev Calculate the ATH fees
     */
    function _calculateAthFees(uint256 amount) private pure returns (uint256) {
        uint256 fees = amount.mul(ATH_SELL_PROTOCOL_FEE).div(100);

        return fees;
    }

    /**
     * @dev Calculate the dip incentive
     */
    function _calculateDipIncentive(uint256 amount)
        private
        view
        returns (uint256)
    {
        uint256 incentive = amount.mul(DIP_BUY_INCENTIVE).div(100);

        if (feesAsIncentive < incentive) {
            incentive = feesAsIncentive;
        }

        return incentive;
    }

    /**
     * @dev Check if the price is in the new ATH
     */
    function _isNewAth() private view returns (bool) {
        uint256 price = _getRealtimePrice();

        if (price > lastAthPrice) {
            uint256 percentageOfAth = lastAthPrice
                .mul(PERCENTAGE_FROM_LAST_ATH)
                .div(100);
            uint256 newAth = lastAthPrice.add(percentageOfAth);

            if (newAth <= price) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Check if the price is in the new dip
     */
    function _isNewDip() private view returns (bool) {
        uint256 price = _getRealtimePrice();

        if (price < lastDipPrice) {
            uint256 percentageOfDip = lastDipPrice
                .mul(PERCENTAGE_FROM_LAST_DIP)
                .div(100);
            uint256 newDip = lastDipPrice.sub(percentageOfDip);

            if (newDip >= price) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Get a price based-on uniswap pool reserves
     */
    function _getRealtimePrice() private view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 price = reserve1.mul(1e18).div(reserve0);

        return price;
    }

    /**
     * @dev Record the new DIP price and fees
     */
    function _recordDip(uint256 incentive) private {
        feesAsIncentive -= incentive;
        lastDipPrice = _getRealtimePrice();
    }

    /**
     * @dev Record the new ATH price and fees
     */
    function _recordAth(uint256 fees) private {
        feesAsIncentive += fees;
        lastAthPrice = _getRealtimePrice();
    }

    /**
     * @dev Send the ETH to the protocol wallet
     */
    function _sendETHToProtocolWallet(uint256 amount) private {
        _protocolWallet.transfer(amount);
    }

    /**
     * @dev Send the ETH fees to the protocol wallet
     */
    function _swapFees() private {
        uint256 protocolFeesBalance = balanceOf(address(this)).sub(
            feesAsIncentive
        );

        if (protocolFeesBalance == 0) {
            return;
        }
        _swapTokensForETH(protocolFeesBalance);

        uint256 contractETHBalance = address(this).balance;
        _sendETHToProtocolWallet(contractETHBalance);

        emit SwapFees(protocolFeesBalance, contractETHBalance);
    }

    /**
     * @dev Swap tokens for ETH
     */
    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
    // -- NOTE: Methods impossible useing after renouncing ownership
    // -- MORE INFO: https://docs.openzeppelin.com/contracts/2.x/api/ownership#Ownable-renounceOwnership
    // -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    /**
     * @dev Open trading to the public
     * NOTE: Impossible the owner turn off the trading
     * NOTE: Call for 1 time only
     */
    function startTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
    }

    /**
     * @dev Exclude an account from fees
     */
    function excludeFromFees(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFees[account] = excluded;
    }

    /**
     * @dev Start the samurai mode
     */
    function startSamuraiMode() external onlyOwner {
        samuraiModeEnabled = true;

        lastAthPrice = _getRealtimePrice();
        lastDipPrice = _getRealtimePrice();
    }
}