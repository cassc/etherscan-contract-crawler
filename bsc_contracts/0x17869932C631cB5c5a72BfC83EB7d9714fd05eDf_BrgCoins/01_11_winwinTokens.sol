// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IPancakeswapV2Pair.sol";
import "./interfaces/IPancakeswapV2Factory.sol";
import "./interfaces/IPancakeswapV2Router02.sol";

pragma solidity >=0.8.0;

contract BrgCoins is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeCast for int256;

    string private constant _name = "BRGCoin";
    string private constant _symbol = "BRG";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant _tokenTotal = 100_000_000_000e9;
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));

    mapping(address => bool) blacklist;
    mapping(address => bool) isTaxless;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;

    //all fees
    uint256 public constant feeDecimal = 2;
    //uint256 public sellFee = 0;
    uint256 public redistributionFee= 200;
    

    uint256 public liquidityFee = 300;
    uint256 public performanceFee = 300;
    uint256 public burnFee = 100;
    uint256 public taxFeeTotal =0;
    bool public enableAllFee= false;

    uint256 public feeTotal;
    address public teamWallet;
    //@dev can be configured. 
    address public performancePoolWallet=address(0);
    address public developmentWallet = address(0);
    address public constant burnWallet = 0x000000000000000000000000000000000000dEaD;

    address public admin;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public isFeeActive = true; // should be true
    uint256 public maxTxAmountPercentage = 500;
    uint256 public maxTxAmount =
        _tokenTotal.mul(maxTxAmountPercentage).div(10000); // 5%
    uint256 public minTokensBeforeSwap = 100e9;

    bool public sellCooldownEnabled = true;

    uint256 public listedAt;

    mapping(address => uint256) public transferAmounts;
    mapping(address => uint256) public lastSellCycleStart;
    mapping(address => uint256) public sellCooldown;
    uint256 public sellCooldownTime = 10 minutes;
    uint256 public sellCooldownAmount = _tokenTotal.mul(5).div(10000); // 0.05%

    IPancakeswapV2Router02 public pancakeswapV2Router;
    address public pancakeSwapV2Pair;

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

    constructor(address _router) {
        IPancakeswapV2Router02 _pancakeSwapV2Router = IPancakeswapV2Router02(
            _router
        ); 
        pancakeSwapV2Pair = IPancakeswapV2Factory(
            _pancakeSwapV2Router.factory()
        ).createPair(address(this), _pancakeSwapV2Router.WETH());
        pancakeswapV2Router = _pancakeSwapV2Router;

        address _owner = _msgSender();
        teamWallet = _msgSender();

        isTaxless[_owner] = true;
        isTaxless[teamWallet] = true;

        _isExcluded[pancakeSwapV2Pair] = true;
        _excluded.push(pancakeSwapV2Pair);

        _reflectionBalance[_owner] = _reflectionTotal;
        _tokenBalance[_owner] = _tokenTotal;
        emit Transfer(address(0), _owner, _tokenTotal);

        transferOwnership(_owner);
    }

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
                "BEP20: transfer amount exceeds allowance"
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
                "BEP20: decreased allowance below zero"
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
            account != address(pancakeswapV2Router),
            "TOKEN: We can not exclude Pacakeswap router."
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

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "BEP20: approve from the zero address");
        require(_spender != address(0), "BEP20: approve to the zero address");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
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
                sender != pancakeSwapV2Pair ||
                    balanceOf(recipient).add(amount) <= _tokenTotal.div(10000),
                "AntiBot: Buy Banned!"
            );
            if (listedAt + 180 seconds >= block.timestamp)
                // don't allow sell for 180 seconds after launch
                require(
                    recipient != pancakeSwapV2Pair,
                    "AntiBot: Sell Banned!"
                );
        }

        if (
            sellCooldownEnabled &&
            recipient == pancakeSwapV2Pair &&
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
            sender != pancakeSwapV2Pair &&
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
         if(redistributionFee!= 0 && (to == pancakeSwapV2Pair|| enableAllFee)){
            uint256 _redistributionFee= amount.mul(redistributionFee).div(10**(feeDecimal + 2));
            transferAmount = transferAmount.sub(_redistributionFee);
            _reflectionTotal = _reflectionTotal.sub(_redistributionFee.mul(rate));
            taxFeeTotal = taxFeeTotal.add(_redistributionFee);
             //emit Transfer(account, distributionWallet, _taxFee);
        }
        // @dev liquidity fee 3% On sale
        if (liquidityFee != 0 && (to == pancakeSwapV2Pair|| enableAllFee)) {
            uint256 _liquidityFee = amount.mul(liquidityFee).div(
                10**(feeDecimal + 2)
            );
            transferAmount = transferAmount.sub(_liquidityFee);
            _reflectionBalance[address(this)] = _reflectionBalance[
                address(this)
            ].add(_liquidityFee.mul(rate));
            if (_isExcluded[address(this)]) {
                _tokenBalance[address(this)] = _tokenBalance[address(this)].add(
                    _liquidityFee
                );
            }
            feeTotal = feeTotal.add(_liquidityFee);
            emit Transfer(account, address(this), _liquidityFee);
        }

       //performance pool fee 3% On sale
        if (performanceFee != 0 && (to == pancakeSwapV2Pair || enableAllFee)) {
            uint256 _performanceFee = amount.mul(performanceFee).div(10**(feeDecimal + 2));
            transferAmount = transferAmount.sub(_performanceFee);
            _reflectionBalance[performancePoolWallet] = _reflectionBalance[performancePoolWallet].add(
                _performanceFee.mul(rate)
            );
            if (_isExcluded[performancePoolWallet]) {
                _tokenBalance[performancePoolWallet] = _tokenBalance[performancePoolWallet].add(
                    _performanceFee
                );
            }
            feeTotal = feeTotal.add(_performanceFee);
            emit Transfer(account, performancePoolWallet, _performanceFee);
        }

        // @dev burn fee 1 on Sale
        if (burnFee != 0 &&( to == pancakeSwapV2Pair|| enableAllFee )) {
           uint256 _burnFee = amount.mul(burnFee).div(10**(feeDecimal + 2));
            transferAmount = transferAmount.sub(_burnFee);
            _reflectionBalance[burnWallet] = _reflectionBalance[burnWallet].add(
                _burnFee.mul(rate)
            );
            emit Transfer(account, burnWallet, _burnFee);
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
        swapTokensForBnb(half); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function deliver(uint256 amount) external {
        require(!_isExcluded[_msgSender()], "Excluded cannot call this!");
        uint256 rate = _getReflectionRate();
        _reflectionBalance[_msgSender()] = _reflectionBalance[_msgSender()].sub(
            amount.mul(rate)
        );
        _reflectionTotal = _reflectionTotal.sub(amount.mul(rate));
        feeTotal = feeTotal.add(amount);
        taxFeeTotal = taxFeeTotal.add(amount);
        emit Transfer(_msgSender(), address(this), amount);
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

    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwnerAndAdmin {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function setFeeActive(bool value) external onlyOwnerAndAdmin {
        isFeeActive = value;
    }

    function setRedistributionFee(uint256 fee) external onlyOwnerAndAdmin {
        redistributionFee= fee;
    }

    function setLiquidityFee(uint256 fee) external onlyOwnerAndAdmin {
        liquidityFee = fee;
    }

    function enableFeeOnTransfers(bool _enable) external onlyOwnerAndAdmin {
        enableAllFee = _enable;
    }
    function getEnableFeeOnTransfers() external view returns(bool){
        return enableAllFee;
    }

    function setPerformanceFee(uint256 fee) external onlyOwnerAndAdmin {
        performanceFee = fee; 
    }

    function setBurnFee(uint256 fee) external onlyOwnerAndAdmin {
        burnFee = fee; 
    }

    function setTeamWallet(address wallet) external onlyOwnerAndAdmin {
        require(wallet != address(0),"Invalid Address, Address should not be zero");
        teamWallet = wallet;
    }
    function setDevelopmentTeamWallet(address wallet) external onlyOwnerAndAdmin {
        require(wallet != address(0),"Invalid Address, Address should not be zero");
        developmentWallet = wallet;
    }
    
    function setPerformancePoolWallet(address wallet) external onlyOwnerAndAdmin {
        require(wallet != address(0),"Invalid Address, Address should not be zero");
        performancePoolWallet = wallet;
    }

    function setMaxTxAmountPercentage(uint256 _maxAmountTxPercentage)
        external
        onlyOwner
    {
        maxTxAmountPercentage = _maxAmountTxPercentage;
        emit txAmountPercentage(maxTxAmountPercentage);
    }

    function setAdmin(address account) external onlyOwnerAndAdmin {
        require(account != address(0),"Invalid Address, Address should not be zero");
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
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public  onlyOwnerAndAdmin {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    //Recover eth accidentally sent to the contract
    function claim(address payable destination) public onlyOwnerAndAdmin {
        require(destination != address(0),"Invalid Address, Address should not be zero");
        destination.transfer(address(this).balance);
    }
    function manualBurn(uint256 amount) public onlyOwnerAndAdmin {
       transfer(burnWallet, amount); 
    }

}