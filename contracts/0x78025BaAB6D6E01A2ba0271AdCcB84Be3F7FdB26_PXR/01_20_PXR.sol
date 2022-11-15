// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";

pragma solidity >=0.8.0;

contract PXR is
    ContextUpgradeable,
    IERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeCast for int256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private MAX;
    uint256 internal _tokenTotal;
    uint256 internal  _maxtokenSupply;

    uint256 internal _reflectionTotal;

    mapping(address => bool) blacklist;
    mapping(address => bool) isTaxless;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;

    //all fees
    uint256 public feeDecimal;
    uint256 public sellFee;
    uint256 public buyFee;
    uint256 public redistributionFee;
    uint256 public redistributionFeeTotal;
    uint256 public liquidityFee;
    uint256 public burnFee;
    uint256 public totalFeePercentage;

    uint256 public feeTotal;
    
    //@dev can be configured.
    address public feeWallet;
    address public developmentWallet;
    address public burnWallet;
    address public teamWallet;
    address public admin;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    bool public isFeeActive; // should be true
    uint256 public maxTxAmountPercentage;
    uint256 public maxTxAmount; // 5%
    uint256 public minTokensBeforeSwap;

    bool public sellCooldownEnabled;

    uint256 public listedAt;

    mapping(address => uint256) public transferAmounts;
    mapping(address => uint256) public lastSellCycleStart;
    mapping(address => uint256) public sellCooldown;
    uint256 public sellCooldownTime;
    uint256 public sellCooldownAmount; // 0.05%

    IUniswapV2Router02 public UniswapV2Router;
    address public UniswapV2Pair;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event txAmountPercentage(uint256 maxTxAmountPercentage);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwnerAndAdmin() {
        require(
            owner() == _msgSender() || _msgSender() == admin,
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    function initialize(
        address _router,
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        IUniswapV2Router02 _UniswapV2Router = IUniswapV2Router02(_router);

        UniswapV2Router = _UniswapV2Router;

        address _owner = _msgSender();
        admin = _msgSender();
        teamWallet = _msgSender();

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        MAX = ~uint256(0);
        _tokenTotal = 900_000_000e18;
        _maxtokenSupply = 2_000_000_000e18;
        _reflectionTotal = (MAX - (MAX % _tokenTotal));

        isTaxless[_owner] = true;
        isTaxless[teamWallet] = true;

        feeDecimal = 2;
        redistributionFee = 0;
        sellFee = 0;
        buyFee = 0;
        liquidityFee = 0;
        burnFee = 0;
        totalFeePercentage=0;
        feeTotal =0;
        redistributionFeeTotal =0;
        feeWallet = address(0);
        developmentWallet = address(0);
        burnWallet = 0x000000000000000000000000000000000000dEaD;
        swapAndLiquifyEnabled = true;
        isFeeActive = true;
        maxTxAmountPercentage = 500;
        maxTxAmount = _tokenTotal.mul(maxTxAmountPercentage).div(10000);
        minTokensBeforeSwap = 100e18;
        sellCooldownEnabled = true;
        sellCooldownTime = 10 minutes;
        sellCooldownAmount = _tokenTotal.mul(5).div(10000);

        _isExcluded[UniswapV2Pair] = true;
        _excluded.push(UniswapV2Pair);

        _reflectionBalance[_owner] = _reflectionTotal;
        _tokenBalance[_owner] = _tokenTotal;
        setUniswapV2Pair();
        emit Transfer(address(0), _owner, _tokenTotal);

        transferOwnership(_owner);
    }

    function mintMaxSupply(uint256 amount) public onlyOwnerAndAdmin {
        require(_tokenTotal+amount*(10**decimals()) <= _maxtokenSupply,"Total tokens should be less than max token supply");
        _mint(_msgSender(), amount*(10**decimals()));
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _tokenTotal += amount;
        _tokenBalance[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwnerAndAdmin
    {}

    function setUniswapV2Pair() private {
        UniswapV2Pair = IUniswapV2Factory(UniswapV2Router.factory()).createPair(
                address(this),
                UniswapV2Router.WETH()
            );
        _isExcluded[UniswapV2Pair] = true;
        _excluded.push(UniswapV2Pair);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][_spender];
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
    ) public virtual override returns (bool) {
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        require(tokenAmount <= _tokenTotal, "Amount must be less than supply");
        return tokenAmount.mul(_getReflectionRate());
    }

    function tokenFromReflection(uint256 reflectionAmount)
        public
        view
        returns (uint256)
    {
        require(
            reflectionAmount <= _reflectionTotal,
            "Amount must be less than total reflections"
        );
        return reflectionAmount.div(_getReflectionRate());
    }

    function excludeAccount(address account) external onlyOwnerAndAdmin {
        require(
            account != address(UniswapV2Router),
            "TOKEN: We can not exclude swap router."
        );

        require(!_isExcluded[account], "TOKEN: Account is already excluded");
        if (_reflectionBalance[account] > 0) {
            _tokenBalance[account] = tokenFromReflection(
                _reflectionBalance[account]
            );
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwnerAndAdmin {
        require(_isExcluded[account], "TOKEN: Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tokenBalance[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeAccounts(address[] memory accounts)
        external
        onlyOwnerAndAdmin
    {
        require(accounts.length < 10, "accounts length must be less then 10");

        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                accounts[i] != address(UniswapV2Router),
                "TOKEN: We can not exclude swap router."
            );
            require(
                !_isExcluded[accounts[i]],
                "TOKEN: Account is already excluded"
            );
            if (_reflectionBalance[accounts[i]] > 0) {
                _tokenBalance[accounts[i]] = tokenFromReflection(
                    _reflectionBalance[accounts[i]]
                );
            }
            _isExcluded[accounts[i]] = true;
            _excluded.push(accounts[i]);
        }
    }

    function includeAccounts(address[] memory accounts)
        external
        onlyOwnerAndAdmin
    {
        require(accounts.length < 10, "accounts length must be less then 10");

        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                _isExcluded[accounts[i]],
                "TOKEN: Account is already included"
            );
            for (uint256 j = 0; j < _excluded.length; j++) {
                if (_excluded[j] == accounts[i]) {
                    _excluded[j] = _excluded[_excluded.length - 1];
                    _tokenBalance[accounts[i]] = 0;
                    _isExcluded[accounts[i]] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        require(
            isTaxless[sender] || isTaxless[recipient] || amount <= maxTxAmount,
            "Max Transfer Limit Exceeds!"
        );

        require(!blacklist[sender], "Banned!");

        require(
            listedAt != 0 || isTaxless[sender] || isTaxless[recipient],
            "Not Listed yet!"
        );

        if (
            !isTaxless[sender] &&
            !isTaxless[recipient] &&
            listedAt + 3 minutes >= block.timestamp
        ) {
            // don't allow to buy more than 0.01% of total supply for 3 minutes after launch
            require(
                sender != UniswapV2Pair ||
                    balanceOf(recipient).add(amount) <= _tokenTotal.div(10000),
                "AntiBot: Buy Banned!"
            );
            if (listedAt + 180 seconds >= block.timestamp)
                // don't allow sell for 180 seconds after launch
                require(recipient != UniswapV2Pair, "AntiBot: Sell Banned!");
        }

        if (
            sellCooldownEnabled &&
            recipient == UniswapV2Pair &&
            !isTaxless[sender]
        ) {
            require(
                sellCooldown[sender] < block.timestamp,
                "Err: Sell Cooldown"
            );
            if (
                lastSellCycleStart[sender] + sellCooldownTime < block.timestamp
            ) {
                lastSellCycleStart[sender] = block.timestamp;
                transferAmounts[sender] = 0;
            }
            transferAmounts[sender] = transferAmounts[sender].add(amount);
            if (transferAmounts[sender] >= sellCooldownAmount) {
                sellCooldown[sender] = block.timestamp + sellCooldownTime;
            }
        }

        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        //swapAndLiquify
        uint256 contractTokenBalance = balanceOf(address(this));
        if (
            swapAndLiquifyEnabled &&
            !inSwapAndLiquify &&
            sender != UniswapV2Pair &&
            contractTokenBalance >= minTokensBeforeSwap
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        if (
            isFeeActive &&
            !isTaxless[sender] &&
            !isTaxless[recipient] &&
            !inSwapAndLiquify
        ) {
            transferAmount = collectFee(sender, recipient, amount, rate);
        }

        //transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(
            amount.mul(rate)
        );
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(
            transferAmount.mul(rate)
        );

        //if any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(
                transferAmount
            );
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    // On Sell 2% Redistribute To All Holders
    // On Sell 3% fee auto add to the liquidity pool.
    // On Sell 1% fee auto moved to Burn wallet
    // On Sell 3% fee auto moved to Performance wallet
    function collectFee(
        address account,
        address to,
        uint256 amount,
        uint256 rate
    ) private returns (uint256) {
        uint256 transferAmount = amount;
        //This 2% fee is applicable when the  contract is going to reward to the token holders.
        if (to == UniswapV2Pair) {
            if (redistributionFee != 0) {
                uint256 _redistributionFee = amount.mul(redistributionFee).div(
                    10**(feeDecimal + 2)
                );
                transferAmount = transferAmount.sub(_redistributionFee);
                _reflectionTotal = _reflectionTotal.sub(
                    _redistributionFee.mul(rate)
                );
                redistributionFeeTotal = redistributionFeeTotal.add(_redistributionFee);
                //emit Transfer(account, distributionWallet, _taxFee);
            }
            // @dev liquidity fee 3% On sale
            if (liquidityFee != 0) {
                uint256 _liquidityFee = amount.mul(liquidityFee).div(
                    10**(feeDecimal + 2)
                );
                transferAmount = transferAmount.sub(_liquidityFee);
                _reflectionBalance[address(this)] = _reflectionBalance[
                    address(this)
                ].add(_liquidityFee.mul(rate));
                if (_isExcluded[address(this)]) {
                    _tokenBalance[address(this)] = _tokenBalance[address(this)]
                        .add(_liquidityFee);
                }
                feeTotal = feeTotal.add(_liquidityFee);
                emit Transfer(account, address(this), _liquidityFee);
            }
            if (sellFee != 0) {
                uint256 _sellFee = amount.mul(sellFee).div(
                    10**(feeDecimal + 2)
                );
                transferAmount = transferAmount.sub(_sellFee);
                _reflectionBalance[feeWallet] = _reflectionBalance[feeWallet]
                    .add(_sellFee.mul(rate));
                if (_isExcluded[feeWallet]) {
                    _tokenBalance[feeWallet] = _tokenBalance[feeWallet].add(
                        _sellFee
                    );
                }
                feeTotal = feeTotal.add(_sellFee);
                emit Transfer(account, feeWallet, _sellFee);
            }

            // @dev burn fee 1 on Sale
            if (burnFee != 0) {
                uint256 _burnFee = amount.mul(burnFee).div(
                    10**(feeDecimal + 2)
                );
                transferAmount = transferAmount.sub(_burnFee);
                _reflectionBalance[burnWallet] = _reflectionBalance[burnWallet]
                    .add(_burnFee.mul(rate));
                emit Transfer(account, burnWallet, _burnFee);
            }
        }
        // @buy  fee 3%
        if (buyFee != 0 && account == UniswapV2Pair) {
            uint256 _buyFee = amount.mul(buyFee).div(10**(feeDecimal + 2));
            transferAmount = transferAmount.sub(_buyFee);
            _reflectionBalance[feeWallet] = _reflectionBalance[feeWallet].add(
                _buyFee.mul(rate)
            );
            feeTotal = feeTotal.add(_buyFee);
            emit Transfer(account, feeWallet, _buyFee);
        }

        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        if (contractTokenBalance > maxTxAmount)
            contractTokenBalance = maxTxAmount;

        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForETH(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        _approve(address(this), address(UniswapV2Router), tokenAmount);

        // make the swap
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(UniswapV2Router), tokenAmount);

        // add the liquidity
        UniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function setTaxless(address account, bool value)
        external
        onlyOwnerAndAdmin
    {
        isTaxless[account] = value;
    }

    function setBlacklist(address account, bool value)
        external
        onlyOwnerAndAdmin
    {
        blacklist[account] = value;
    }

    function setBlacklistAccounts(address[] memory accounts, bool value)
        external
        onlyOwnerAndAdmin
    {
        require(accounts.length < 10, "accounts length must be less then 10");
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklist[accounts[i]] = value;
        }
    }

    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwnerAndAdmin {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function setFeeActive(bool value) external onlyOwnerAndAdmin {
        isFeeActive = value;
    }

    function setAllFee(
        uint256 _buyFee,
        uint256 _sellFee,
        uint256 _liquidityFee,
        uint256 _burnFee,
        uint256 _redistributionFee
    ) external onlyOwnerAndAdmin {
        buyFee = _buyFee;
        sellFee = _sellFee;
        liquidityFee = _liquidityFee;
        burnFee = _burnFee;
        redistributionFee = _redistributionFee;
        totalFeePercentage = buyFee+sellFee+liquidityFee+burnFee+redistributionFee;
    }

    function setFeeWallet(address wallet) external onlyOwnerAndAdmin {
        require(
            wallet != address(0),
            "Invalid Address, Address should not be zero"
        );
        feeWallet = wallet;
    }

    function setTeamWallet(address wallet) external onlyOwnerAndAdmin {
        require(
            wallet != address(0),
            "Invalid Address, Address should not be zero"
        );
        teamWallet = wallet;
    }

    function setDevelopmentTeamWallet(address wallet)
        external
        onlyOwnerAndAdmin
    {
        require(
            wallet != address(0),
            "Invalid Address, Address should not be zero"
        );
        developmentWallet = wallet;
    }

    function setMaxTxAmountPercentage(uint256 _maxAmountTxPercentage)
        external
        onlyOwner
    {
        maxTxAmountPercentage = _maxAmountTxPercentage;
        emit txAmountPercentage(maxTxAmountPercentage);
    }

    function setAdmin(address account) external onlyOwnerAndAdmin {
        require(
            account != address(0),
            "Invalid Address, Address should not be zero"
        );
        admin = account;
    }

    function setMinTokensBeforeSwap(uint256 amount) external onlyOwnerAndAdmin {
        minTokensBeforeSwap = amount;
    }

    function setSellCooldownEnabled(bool value) external onlyOwnerAndAdmin {
        sellCooldownEnabled = value;
    }

    function setSellCooldown(uint256 interval, uint256 amount)
        external
        onlyOwnerAndAdmin
    {
        sellCooldownTime = interval;
        sellCooldownAmount = amount;
    }

    function launch() external onlyOwnerAndAdmin {
        require(listedAt == 0, "Already Listed!");
        listedAt = block.timestamp;
    }

    receive() external payable {}

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwnerAndAdmin
    {
        IERC20Upgradeable(tokenAddress).transfer(owner(), tokenAmount);
    }

    //Recover eth accidentally sent to the contract
    function claim(address payable destination) public onlyOwnerAndAdmin {
        require(
            destination != address(0),
            "Invalid Address, Address should not be zero"
        );
        destination.transfer(address(this).balance);
    }

    function manualBurn(uint256 amount) public {
        transfer(burnWallet, amount);
    }

    function removeERC20() public onlyOwnerAndAdmin {
        IERC20Upgradeable(address(this)).transfer(
            _msgSender(),
            IERC20Upgradeable(address(this)).balanceOf(address(this))
        );
    }
}