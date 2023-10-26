// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Token is ERC20, Ownable {
    modifier lockSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd() {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant MAX_TAX_BPS = 10_00;

    IUniswapV2Router02 internal immutable _router;
    address internal immutable _pair;
    uint256 public immutable snipeBlocks;

    /// @notice addresses that each tax is sent to
    address payable[2] public taxWallets;
    /// @notice buyTaxes in BPS
    uint256[2] public buyTaxes;
    /// @notice sell in BPS
    uint256[2] public sellTaxes;
    /// @notice Maximum that can be bought in a single transaction
    uint256 public maxBuy;
    /// @notice Maps each recipient to their tax exlcusion status
    mapping(address => bool) public taxExcluded;
    /// @notice Maps each recipient to their blacklist status
    mapping(address => bool) public blacklist;

    /// @notice Contract Token balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000 ether;
    /// @notice Flag for auto-calling `_swap`
    bool public autoSwap = true;
    /// @notice Flag indicating whether buys/sells are permitted
    bool public tradingActive = false;
    /// @notice Block when trading is first enabled
    uint256 public tradingBlock;

    uint256 internal _totalSupply = 0;
    mapping(address => uint256) private _balances;
    /// @notice tokens that are allocated for each tax
    uint256[2] public totalTaxes;

    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;

    event TaxWalletChanged(
        address previousWallet,
        address nextWallet
    );
    event BuyTaxesChanged(uint256[2] previousTaxes, uint256[2] nextTaxes);
    event SellTaxesChanged(uint256[2] previousTaxes, uint256[2] nextTaxes);
    event MinTokenBalanceChanged(uint256 previousMin, uint256 nextMin);
    event MaxBuyChanged(uint256 previousMax, uint256 nextMax);
    event TaxesRescued(uint256 index, uint256 amount);
    event TradingActiveChanged(bool enabled);
    event TaxExclusionChanged(address user, bool taxExcluded);
    event BlacklistUpdated(address user, bool previousStatus, bool nextStatus);
    event AutoSwapChanged(bool enabled);

    constructor(
      string memory _name,
      string memory _symbol,
      uint256 _maxSupply,
      uint256 _maxBuy,
      address payable[2] memory _taxWallets,
      uint256[2] memory _buyTaxes,
      uint256[2] memory _sellTaxes,
      IUniswapV2Router02 _uniswapRouter,
      uint256 _teamAmount,
      uint256 _snipeBlocks
    ) ERC20(_name, _symbol)
        Ownable() payable
    {
        taxExcluded[owner()] = true;
        taxExcluded[address(this)] = true;
        maxBuy = _maxBuy;
        taxWallets = _taxWallets;
        buyTaxes = _buyTaxes;
        sellTaxes = _sellTaxes;
        snipeBlocks = _snipeBlocks;

        _router = _uniswapRouter;
        _pair = IUniswapV2Factory(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH()
        );

        // Calculate amounts (x, liquidity, team)
        uint256 _xAmount = _maxSupply / 100; // 1%
        uint256 _liquidityAmount = _maxSupply - _xAmount - _teamAmount;
        require(_liquidityAmount >= _maxSupply * 90 / 100, "Insufficient _liquidityAmount"); // Must be >= 90% of the max supply

        // Send _xAmount to the first tax wallet
        _goup(_taxWallets[0], _xAmount);

        // Send _teamAmount to the second tax wallet
        _goup(_taxWallets[1], _teamAmount);

        // Send _liquidityAmount to this contract and add liquidity
        _goup(address(this), _liquidityAmount);
    }

    function addLiquidity() public payable {
        uint256 _liquidityAmount = balanceOf(address(this));
        _approve(address(this), address(_router), _liquidityAmount);
        _router.addLiquidityETH{value: msg.value}(
            address(this),
            _liquidityAmount,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Change the address of the team tax wallet
    /// @param _taxWallet The new address of the team tax wallet
    function setTaxWallet(address payable _taxWallet)
        external
        onlyOwner
    {
        emit TaxWalletChanged(taxWallets[1], _taxWallet);
        taxWallets[1] = _taxWallet;
    }

    /// @notice Change the buy tax rates
    /// @param _tax The new buy tax rate
    function setBuyTax(uint256 _tax) external onlyOwner {
        require(
            _tax <= MAX_TAX_BPS,
            "_tax must be <= MAX_TAX_BPS"
        );
        uint256 xTax = _tax * 10 / 100;
        uint256 teamTax = _tax - xTax;
        uint256[2] memory _taxes = [xTax, teamTax];
        emit BuyTaxesChanged(buyTaxes, _taxes);
        buyTaxes = _taxes;
    }

    /// @notice Change the sell tax rates
    /// @param _tax The new sell tax rate
    function setSellTax(uint256 _tax) external onlyOwner {
        require(
            _tax <= MAX_TAX_BPS,
            "_tax must be <= MAX_TAX_BPS"
        );
        uint256 xTax = _tax * 10 / 100;
        uint256 teamTax = _tax - xTax;
        uint256[2] memory _taxes = [xTax, teamTax];
        emit SellTaxesChanged(sellTaxes, _taxes);
        sellTaxes = _taxes;
    }

    /// @notice Change the minimum contract Token balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner {
        emit MinTokenBalanceChanged(minTokenBalance, _minTokenBalance);
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Change the max buy amount
    /// @param _maxBuy The new max buy amount
    function setMaxBuy(uint256 _maxBuy) external onlyOwner {
        emit MaxBuyChanged(maxBuy, _maxBuy);
        maxBuy = _maxBuy;
    }

    /// @notice Rescue Token from the taxes
    /// @dev Should only be used in an emergency
    /// @param _index The tax allocation to rescue from
    /// @param _amount The amount of Token to rescue
    /// @param _recipient The recipient of the rescued Token
    function rescueTaxTokens(
        uint256 _index,
        uint256 _amount,
        address _recipient
    ) external onlyOwner {
        require(0 <= _index && _index < totalTaxes.length, "_index OOB");
        require(
            _amount <= totalTaxes[_index],
            "Amount cannot be greater than totalTax"
        );
        _rawTransfer(address(this), _recipient, _amount);
        emit TaxesRescued(_index, _amount);
        totalTaxes[_index] -= _amount;
    }

    /// @notice Admin function to update a recipient's blacklist status
    /// @param user the recipient
    /// @param status the new status
    function updateBlacklist(address user, bool status)
        external
        virtual
        onlyOwner
    {
        _updateBlacklist(user, status);
    }

    function _updateBlacklist(address user, bool status) internal {
        emit BlacklistUpdated(user, blacklist[user], status);
        blacklist[user] = status;
    }

    /// @notice Enables or disables trading on Uniswap
    function setTradingActive(bool _tradingActive) external onlyOwner {
        tradingActive = _tradingActive;
        tradingBlock = block.number;
        emit TradingActiveChanged(_tradingActive);
    }

    /// @notice Updates tax exclusion status
    /// @param _account Account to update the tax exclusion status of
    /// @param _taxExcluded If true, exclude taxes for this user
    function setTaxExcluded(address _account, bool _taxExcluded)
        external
        onlyOwner
    {
        taxExcluded[_account] = _taxExcluded;
        emit TaxExclusionChanged(_account, _taxExcluded);
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _autoSwap If true, enables swap during `_transfer`
    function setAutoSwap(bool _autoSwap) external onlyOwner {
        autoSwap = _autoSwap;
        emit AutoSwapChanged(_autoSwap);
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function _addBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] + amount;
    }

    function _subtractBalance(address account, uint256 amount) internal {
        _balances[account] = _balances[account] - amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(!blacklist[recipient], "Recipient is blacklisted");

        if (taxExcluded[sender] || taxExcluded[recipient]) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        if (
            totalTaxes[0] + totalTaxes[1] >= minTokenBalance &&
            !_inSwap &&
            sender != _pair &&
            autoSwap
        ) {
            _swap();
        }

        uint256 send = amount;
        uint256[2] memory taxAmounts;
        if (sender == _pair) {
            require(tradingActive, "Trading is not yet active");
            if (block.number <= tradingBlock + snipeBlocks) {
                _updateBlacklist(recipient, true);
            }
            (send, taxAmounts) = _getTaxAmounts(amount, true);
            require(amount <= maxBuy, "Buy amount exceeds maxBuy");
        } else if (recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            (send, taxAmounts) = _getTaxAmounts(amount, false);
        }
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, taxAmounts);
    }

    /// @notice Perform a Uniswap v2 swap from Token to ETH and handle tax distribution
    function _swap() internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        uint256 walletTaxes = totalTaxes[0] + totalTaxes[1];

        _approve(address(this), address(_router), walletTaxes);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            walletTaxes,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        uint256 contractEthBalance = address(this).balance;

        uint256 tax0Eth = (contractEthBalance * totalTaxes[0]) / walletTaxes;
        uint256 tax1Eth = (contractEthBalance * totalTaxes[1]) / walletTaxes;
        totalTaxes = [0, 0];

        if (tax0Eth > 0) {
            taxWallets[0].transfer(tax0Eth);
        }
        if (tax1Eth > 0) {
            taxWallets[1].transfer(tax1Eth);
        }
    }

    function swapAll() external {
        if (!_inSwap) {
            _swap();
        }
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers Token from an account to this contract for taxes
    /// @param _account The account to transfer Token from
    /// @param _taxAmounts The amount for each tax
    function _takeTaxes(address _account, uint256[2] memory _taxAmounts)
        internal
    {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _taxAmounts[0] + _taxAmounts[1];
        _rawTransfer(_account, address(this), totalAmount);
        totalTaxes[0] += _taxAmounts[0];
        totalTaxes[1] += _taxAmounts[1];
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return taxAmounts The raw tax amounts
    function _getTaxAmounts(uint256 amount, bool buying)
        internal
        view
        returns (uint256 send, uint256[2] memory taxAmounts)
    {
      if (buying) {
        taxAmounts = [
            (amount * buyTaxes[0]) / BPS_DENOMINATOR,
            (amount * buyTaxes[1]) / BPS_DENOMINATOR
        ];
      } else {
        taxAmounts = [
            (amount * sellTaxes[0]) / BPS_DENOMINATOR,
            (amount * sellTaxes[1]) / BPS_DENOMINATOR
        ];
      }
        send = amount - taxAmounts[0] - taxAmounts[1];
    }

    // modified from OpenZeppelin ERC20
    function _rawTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _subtractBalance(sender, amount);
        }
        _addBalance(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _goup(address account, uint256 amount) internal {
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    receive() external payable {}
}