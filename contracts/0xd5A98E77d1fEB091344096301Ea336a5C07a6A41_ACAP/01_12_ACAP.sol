// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract ACAP is ERC20, Ownable {
    using SafeMath for uint256;

    modifier lockSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier liquidityAdd {
        _inLiquidityAdd = true;
        _;
        _inLiquidityAdd = false;
    }

    uint256 public constant MAX_SUPPLY = 1_000_000_000 ether;

    uint256 internal _maxTransfer = 5;
    uint256 public marketingRate = 2;
    uint256 public treasuryRate = 9;
    uint256 public reflectRate = 4;
    /// @notice Contract ACAP balance threshold before `_swap` is invoked
    uint256 public minTokenBalance = 1000 ether;
    bool public swapFees = true;

    // total wei reflected ever
    uint256 public ethReflectionBasis;
    uint256 public totalReflected;
    uint256 public totalMarketing;
    uint256 public totalTreasury;

    address payable public buybackWallet;
    address payable public treasuryWallet;

    uint256 internal _totalSupply = 0;
    IUniswapV2Router02 internal _router = IUniswapV2Router02(address(0));
    address internal _pair;
    bool internal _inSwap = false;
    bool internal _inLiquidityAdd = false;
    bool public tradingActive = false;

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _reflectionExcluded;
    mapping(address => bool) private _taxExcluded;
    mapping(address => uint256) public lastReflectionBasis;
    address[] internal _reflectionExcludedList;

    constructor(
        address _uniswapFactory,
        address _uniswapRouter,
        address payable _buybackWallet,
        address payable _treasuryWallet
    ) ERC20("Alpha Capital", "ACAP") Ownable() {
        addTaxExcluded(owner());
        addTaxExcluded(address(0));
        addTaxExcluded(_buybackWallet);
        addTaxExcluded(_treasuryWallet);
        addTaxExcluded(address(this));

        buybackWallet = _buybackWallet;
        treasuryWallet = _treasuryWallet;

        _router = IUniswapV2Router02(_uniswapRouter);
        IUniswapV2Factory uniswapContract = IUniswapV2Factory(_uniswapFactory);
        _pair = uniswapContract.createPair(address(this), _router.WETH());
    }

    /// @notice Change the address of the buyback wallet
    /// @param _buybackWallet The new address of the buyback wallet
    function setBuybackWallet(address payable _buybackWallet) external onlyOwner() {
        buybackWallet = _buybackWallet;
    }

    /// @notice Change the address of the treasury wallet
    /// @param _treasuryWallet The new address of the treasury wallet
    function setTreasuryWallet(address payable _treasuryWallet) external onlyOwner() {
        treasuryWallet = _treasuryWallet;
    }

    /// @notice Change the marketing tax rate
    /// @param _marketingRate The new marketing tax rate
    function setMarketingRate(uint256 _marketingRate) external onlyOwner() {
        require(_marketingRate <= 100, "_marketingRate cannot exceed 100%");
        marketingRate = _marketingRate;
    }

    /// @notice Change the treasury tax rate
    /// @param _treasuryRate The new treasury tax rate
    function setTreasuryRate(uint256 _treasuryRate) external onlyOwner() {
        require(_treasuryRate <= 100, "_treasuryRate cannot exceed 100%");
        treasuryRate = _treasuryRate;
    }

    /// @notice Change the reflection tax rate
    /// @param _reflectRate The new reflection tax rate
    function setReflectRate(uint256 _reflectRate) external onlyOwner() {
        require(_reflectRate <= 100, "_reflectRate cannot exceed 100%");
        reflectRate = _reflectRate;
    }

    /// @notice Change the minimum contract ACAP balance before `_swap` gets invoked
    /// @param _minTokenBalance The new minimum balance
    function setMinTokenBalance(uint256 _minTokenBalance) external onlyOwner() {
        minTokenBalance = _minTokenBalance;
    }

    /// @notice Rescue ACAP from the marketing amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of ACAP to rescue
    /// @param _recipient The recipient of the rescued ACAP
    function rescueMarketingTokens(uint256 _amount, address _recipient) external onlyOwner() {
        require(_amount <= totalMarketing, "Amount cannot be greater than totalMarketing");
        _rawTransfer(address(this), _recipient, _amount);
        totalMarketing -= _amount;
    }

    /// @notice Rescue ACAP from the treasury amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of ACAP to rescue
    /// @param _recipient The recipient of the rescued ACAP
    function rescueTreasuryTokens(uint256 _amount, address _recipient) external onlyOwner() {
        require(_amount <= totalTreasury, "Amount cannot be greater than totalTreasury");
        _rawTransfer(address(this), _recipient, _amount);
        totalTreasury -= _amount;
    }

    /// @notice Rescue ACAP from the reflection amount
    /// @dev Should only be used in an emergency
    /// @param _amount The amount of ACAP to rescue
    /// @param _recipient The recipient of the rescued ACAP
    function rescueReflectionTokens(uint256 _amount, address _recipient) external onlyOwner() {
        require(_amount <= totalReflected, "Amount cannot be greater than totalReflected");
        _rawTransfer(address(this), _recipient, _amount);
        totalReflected -= _amount;
    }

    function addLiquidity(uint256 tokens) external payable onlyOwner() liquidityAdd {
        _mint(address(this), tokens);
        _approve(address(this), address(_router), tokens);

        _router.addLiquidityETH{value: msg.value}(
            address(this),
            tokens,
            0,
            0,
            owner(),
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );
    }

    /// @notice Enables trading on Uniswap
    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    /// @notice Disables trading on Uniswap
    function disableTrading() external onlyOwner {
        tradingActive = false;
    }

    function addReflection() external payable {
        ethReflectionBasis += msg.value;
    }

    function isReflectionExcluded(address account) public view returns (bool) {
        return _reflectionExcluded[account];
    }

    function removeReflectionExcluded(address account) external onlyOwner() {
        require(isReflectionExcluded(account), "Account must be excluded");

        _reflectionExcluded[account] = false;
    }

    function addReflectionExcluded(address account) external onlyOwner() {
        _addReflectionExcluded(account);
    }

    function _addReflectionExcluded(address account) internal {
        require(!isReflectionExcluded(account), "Account must not be excluded");
        _reflectionExcluded[account] = true;
    }

    function isTaxExcluded(address account) public view returns (bool) {
        return _taxExcluded[account];
    }

    function addTaxExcluded(address account) public onlyOwner() {
        require(!isTaxExcluded(account), "Account must not be excluded");

        _taxExcluded[account] = true;
    }

    function removeTaxExcluded(address account) external onlyOwner() {
        require(isTaxExcluded(account), "Account must not be excluded");

        _taxExcluded[account] = false;
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
        if (isTaxExcluded(sender) || isTaxExcluded(recipient)) {
            _rawTransfer(sender, recipient, amount);
            return;
        }

        uint256 maxTxAmount = totalSupply() * _maxTransfer / 1000;
        require(amount <= maxTxAmount || _inLiquidityAdd || _inSwap || recipient == address(_router), "Exceeds max transaction amount");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= minTokenBalance;

        if(contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        if (
            overMinTokenBalance &&
            !_inSwap &&
            sender != _pair &&
            swapFees
        ) {
            _swap(contractTokenBalance);
        }

        _claimReflection(payable(sender));
        _claimReflection(payable(recipient));

        uint256 send = amount;
        uint256 reflect;
        uint256 marketing;
        uint256 treasury;
        if (sender == _pair || recipient == _pair) {
            require(tradingActive, "Trading is not yet active");
            (
                send,
                reflect,
                marketing,
                treasury
            ) = _getTaxAmounts(amount);
        } 
        _rawTransfer(sender, recipient, send);
        _takeTaxes(sender, marketing, treasury, reflect);
    }

    function unclaimedReflection(address addr) public view returns (uint256) {
        if (addr == _pair || addr == address(_router)) return 0;

        uint256 basisDifference = ethReflectionBasis - lastReflectionBasis[addr];
        return basisDifference * balanceOf(addr) / _totalSupply;
    }

    /// @notice Claims reflection pool ETH
    /// @param addr The address to claim the reflection for
    function _claimReflection(address payable addr) internal {
        uint256 unclaimed = unclaimedReflection(addr);
        lastReflectionBasis[addr] = ethReflectionBasis;
        if (unclaimed > 0) {
            addr.transfer(unclaimed);
        }
    }

    function claimReflection() external {
        _claimReflection(payable(msg.sender));
    }

    /// @notice Perform a Uniswap v2 swap from ACAP to ETH and handle tax distribution
    /// @param amount The amount of ACAP to swap in wei
    /// @dev `amount` is always <= this contract's ETH balance. Calculate and distribute marketing and reflection taxes
    function _swap(uint256 amount) internal lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _approve(address(this), address(_router), amount);

        uint256 contractEthBalance = address(this).balance;

        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;

        uint256 totalTaxes = totalMarketing.add(totalTreasury).add(totalReflected);
        uint256 marketingAmount = amount.mul(totalMarketing).div(totalTaxes);
        uint256 treasuryAmount = amount.mul(totalTreasury).div(totalTaxes);
        uint256 reflectedAmount = amount.sub(marketingAmount).sub(treasuryAmount);

        uint256 marketingEth = tradeValue.mul(totalMarketing).div(totalTaxes);
        uint256 treasuryEth = tradeValue.mul(totalTreasury).div(totalTaxes);
        uint256 reflectedEth = tradeValue.sub(marketingEth).sub(treasuryEth);

        if (marketingEth > 0) {
            buybackWallet.transfer(marketingEth);
        }
        if (treasuryEth > 0) {
            treasuryWallet.transfer(treasuryEth);
        }
        totalMarketing = totalMarketing.sub(marketingAmount);
        totalTreasury = totalTreasury.sub(treasuryAmount);
        totalReflected = totalReflected.sub(reflectedAmount);
        ethReflectionBasis = ethReflectionBasis.add(reflectedEth);
    }

    function swapAll() external {
        uint256 maxTxAmount = totalSupply() * _maxTransfer / 1000;
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= maxTxAmount)
        {
            contractTokenBalance = maxTxAmount;
        }

        if (
            !_inSwap
        ) {
            _swap(contractTokenBalance);
        }
    }

    function withdrawAll() external onlyOwner() {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Transfers ACAP from an account to this contract for taxes
    /// @param _account The account to transfer ACAP from
    /// @param _marketingAmount The amount of marketing tax to transfer
    /// @param _treasuryAmount The amount of treasury tax to transfer
    /// @param _reflectAmount The amount of reflection tax to transfer
    function _takeTaxes(
        address _account,
        uint256 _marketingAmount,
        uint256 _treasuryAmount,
        uint256 _reflectAmount
   ) internal {
        require(_account != address(0), "taxation from the zero address");

        uint256 totalAmount = _marketingAmount.add(_treasuryAmount).add(_reflectAmount);
        _rawTransfer(_account, address(this), totalAmount);
        totalMarketing += _marketingAmount;
        totalTreasury += _treasuryAmount;
        totalReflected += _reflectAmount;
    }

    /// @notice Get a breakdown of send and tax amounts
    /// @param amount The amount to tax in wei
    /// @return send The raw amount to send
    /// @return reflect The raw reflection tax amount
    /// @return marketing The raw marketing tax amount
    /// @return treasury The raw treasury tax amount
    function _getTaxAmounts(uint256 amount)
        internal
        view
        returns (
            uint256 send,
            uint256 reflect,
            uint256 marketing,
            uint256 treasury
        )
    {
        reflect = amount.mul(reflectRate).div(100);
        marketing = amount.mul(marketingRate).div(100);
        treasury = amount.mul(treasuryRate).div(100);
        send = amount.sub(reflect).sub(marketing).sub(treasury);
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

    function setMaxTransfer(uint256 maxTransfer) external onlyOwner() {
        _maxTransfer = maxTransfer;
    }

    /// @notice Enable or disable whether swap occurs during `_transfer`
    /// @param _swapFees If true, enables swap during `_transfer`
    function setSwapFees(bool _swapFees) external onlyOwner() {
        swapFees = _swapFees;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal override {
        require(_totalSupply.add(amount) <= MAX_SUPPLY, "Max supply exceeded");
        _totalSupply += amount;
        _addBalance(account, amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 amount) external onlyOwner() {
        _mint(account, amount);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts) external onlyOwner() {
        require(accounts.length == amounts.length, "array lengths must match");

        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], amounts[i]);
        }
    }

    receive() external payable {}
}