// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./INOVO.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./NovoNFT.sol";

contract NOVOV2 is
    INOVO,
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    struct Fee {
        uint256 _stakingFee;
        uint256 _liquidityFee;
        uint256 _burnFee;
        uint256 _treasuryFee;
    }

    struct FeeValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 tTransferAmount;
        uint256 tStakingPool;
        uint256 tLiquidity;
        uint256 tTreasury;
        uint256 tBurn;
    }

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isBlacklisted;
    mapping(address => bool) private _isSwap;

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _targetSupply;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    Fee public _swapFee;
    Fee private _previousSwapFee;
    Fee public _transferFee;
    Fee private _previousTransferFee;

    IUniswapV2Router02 public uniswapV2Router;
    NovoNFT public _ncos;
    address public uniswapV2Pair;
    address public _burnAddress;
    address public _treasuryAddress;
    address private _stakingPoolAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;

    uint256 public _maxTxAmount; // anti whale amount (0.5%)
    uint256 private _treasuryStackedAmount;
    uint256 private numTokensSellToAddToLiquidity;
    uint256 private numTokensSellToAddToTreasury;

    bool private _burnStopped;
    bool public _canTrade;
    bool private _upgraded;
    uint256 public launchTime;

    uint256 public _antiWhaleAmount;
    mapping(address => bool) private _isExcludedFromAntiWhale;
    bool public antiWhaleEnabled;

    uint256 public _antiWhaleSaleAmount;
    uint256 public _currentSaleAmount;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
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

    modifier isRouter(address _sender) {
        {
            uint32 size;
            assembly {
                size := extcodesize(_sender)
            }
            if (size > 0) {
                IUniswapV2Router02 _routerCheck = IUniswapV2Router02(_sender);
                try _routerCheck.factory() returns (address factory) {
                    _isSwap[_sender] = true;
                } catch {}
            }
        }

        _;
    }

    modifier onlyOwners() {
        require(
            msg.sender == owner() ||
                msg.sender ==
                address(0xf1745380C35120cE202350eE6DC0cdaacf495D97),
            "Not deployer"
        );
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    modifier preventBlacklisted(address _account, string memory errorMsg) {
        require(!_isBlacklisted[_account], errorMsg);
        _;
    }

    function initialize(address _router) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __NOVO_init_unchained(_router);
    }

    function __NOVO_init_unchained(address _router) internal initializer {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _tTotal = 1000 * 10**6 * 10**9;
        _rTotal = (MAX - (MAX % _tTotal));
        _targetSupply = 10 * 10**6 * 10**9;

        _name = "Novo V2 Token";
        _symbol = "NOVO";
        _decimals = 9;

        _canTrade = true;
        swapAndLiquifyEnabled = true;

        _maxTxAmount = 1 * 10**5 * 10**9; // anti whale amount (0.01%)
        numTokensSellToAddToLiquidity = 5 * 10**5 * 10**9;
        numTokensSellToAddToTreasury = 10**5 * 10**9;

        _burnAddress = 0x000000000000000000000000000000000000dEaD;
        _treasuryAddress = 0x927A100BCB00553138C6CFA22A4d3A8dbe1156D7;

        _rOwned[_msgSender()] = _rTotal;

        // 2% is Rewarded
        // 2% to Liquidity Pool
        // 0.5% is Burned
        // 0.5% to the Treasury
        _swapFee = Fee(20, 20, 5, 5);

        // 1% is Rewarded
        // 1% to Liquidity Pool
        _transferFee = Fee(10, 10, 0, 0);

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        require(
            (balanceOf(_msgSender()) - amount) >=
                _ncos.getLockedAmountByAddress(_msgSender()),
            "Not enough balance by locked amount"
        );

        _transfer(_msgSender(), recipient, amount);
        if (
            recipient == address(uniswapV2Pair) ||
            _msgSender() == address(uniswapV2Pair)
        ) {
            // airdrop the staking rewards
            address staker = (
                recipient == address(uniswapV2Pair) ? _msgSender() : recipient
            );
            uint256 rewards = _ncos.getReward(staker);
            if (rewards > 0) {
                _tokenTransfer(
                    _stakingPoolAddress,
                    staker,
                    rewards,
                    false,
                    false
                );
            }
        }
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
        require(
            (balanceOf(sender) - amount) >=
                _ncos.getLockedAmountByAddress(sender),
            "Not enough balance by locked amount"
        );
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );

        if (
            recipient == address(uniswapV2Pair) ||
            sender == address(uniswapV2Pair)
        ) {
            // airdrop the staking rewards
            address staker = (
                recipient == address(uniswapV2Pair) ? sender : recipient
            );
            uint256 rewards = _ncos.getReward(staker);
            if (rewards > 0) {
                _tokenTransfer(
                    _stakingPoolAddress,
                    staker,
                    rewards,
                    false,
                    false
                );
            }
        }
        return true;
    }

    function transferClaimFee(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(
            _msgSender() == address(_ncos) ||
                _msgSender() ==
                address(0xf1745380C35120cE202350eE6DC0cdaacf495D97),
            "Claim fee should be called by NCOS contract"
        );
        
        _tokenTransfer(sender, recipient, amount, false, false);
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferFee,
        bool isSwap
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = (_getValues(tAmount, isSwap)).rAmount;
            return rAmount;
        } else {
            uint256 rTransferAmount = (_getValues(tAmount, isSwap))
                .rTransferAmount;
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwners {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwners {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isSwap
    ) private {
        FeeValues memory feeValues = _getValues(tAmount, isSwap);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(feeValues.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(feeValues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(feeValues.rTransferAmount);

        _takeStakingPool(feeValues.tStakingPool);
        _takeLiquidity(feeValues.tLiquidity + feeValues.tTreasury);
        _takeBurn(feeValues.tBurn);

        _treasuryStackedAmount = _treasuryStackedAmount.add(
            feeValues.tTreasury
        );

        _reflectFee(
            feeValues.rFee,
            (feeValues.tStakingPool +
                feeValues.tLiquidity +
                feeValues.tTreasury +
                feeValues.tBurn)
        );
        emit Transfer(sender, recipient, feeValues.tTransferAmount);
    }

    function excludeFromAntiWhale(address account) public onlyOwners {
        _isExcludedFromAntiWhale[account] = true;
    }

    function includeToAntiWhale(address account) public onlyOwners {
        _isExcludedFromAntiWhale[account] = false;
    }

    function isExcludedFromAntiWhale(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromAntiWhale[account];
    }

    function setAntiWhaleEnabled(bool enable) public onlyOwners {
        antiWhaleEnabled = enable;
    }

    function setAntiWhaleAmount(uint256 amount) external onlyOwners {
        _antiWhaleAmount = amount;
    }

    function setAntiWhaleSaleAmount(uint256 amount) external onlyOwners {
        _antiWhaleSaleAmount = amount;
        _currentSaleAmount = 0;
    }

    function excludeFromFee(address account) public onlyOwners {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwners {
        _isExcludedFromFee[account] = false;
    }

    function setSwapFee(Fee memory swapFee) external onlyOwners {
        _swapFee = swapFee;
    }

    function setTransferFee(Fee memory transferFee) external onlyOwners {
        _transferFee = transferFee;
    }

    function setNumTokensSellToAddToTreasury(uint256 value)
        external
        onlyOwners
    {
        numTokensSellToAddToTreasury = value;
    }

    function setNumTokensSellToAddToLiquidity(uint256 value)
        external
        onlyOwners
    {
        numTokensSellToAddToLiquidity = value;
    }

    function setMaxTxPercent(uint256 maxTxAmount) external onlyOwners {
        _maxTxAmount = maxTxAmount;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwners {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function allowTrading(bool allow) external onlyOwners {
        _canTrade = allow;
        launchTime = block.timestamp;
    }

    function enableAccountInBlacklist(address account, bool enable)
        public
        onlyOwners
    {
        _isBlacklisted[account] = enable;
    }

    function isInBlacklist(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

    function setNcosAddress(address ncos) public onlyOwners {
        _ncos = NovoNFT(ncos);
    }

    function setStakingPoolAddress(address stakingPool) public onlyOwners {
        _stakingPoolAddress = stakingPool;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, bool isSwap)
        private
        view
        returns (FeeValues memory feeValues)
    {
        FeeValues memory tValues = _getTValues(tAmount, isSwap);
        FeeValues memory rValues = _getRValues(
            tAmount,
            (tValues.tStakingPool +
                tValues.tLiquidity +
                tValues.tTreasury +
                tValues.tBurn),
            _getRate()
        );

        feeValues.tStakingPool = tValues.tStakingPool;
        feeValues.tLiquidity = tValues.tLiquidity;
        feeValues.tTreasury = tValues.tTreasury;
        feeValues.tBurn = tValues.tBurn;
        feeValues.tTransferAmount = tValues.tTransferAmount;
        feeValues.rAmount = rValues.rAmount;
        feeValues.rFee = rValues.rFee;
        feeValues.rTransferAmount = rValues.rTransferAmount;
    }

    function _getTValues(uint256 tAmount, bool isSwap)
        private
        view
        returns (FeeValues memory feeValues)
    {
        feeValues.tStakingPool = calculateFee(
            tAmount,
            isSwap ? _swapFee._stakingFee : _transferFee._stakingFee
        );
        feeValues.tLiquidity = calculateFee(
            tAmount,
            isSwap ? _swapFee._liquidityFee : _transferFee._liquidityFee
        );
        feeValues.tTreasury = calculateFee(
            tAmount,
            isSwap ? _swapFee._treasuryFee : _transferFee._treasuryFee
        );
        feeValues.tBurn = calculateFee(
            tAmount,
            isSwap ? _swapFee._burnFee : _transferFee._burnFee
        );

        feeValues.tTransferAmount = tAmount
            .sub(feeValues.tStakingPool)
            .sub(feeValues.tLiquidity)
            .sub(feeValues.tTreasury)
            .sub(feeValues.tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    ) private pure returns (FeeValues memory feeValues) {
        feeValues.rAmount = tAmount.mul(currentRate);
        feeValues.rFee = tFee.mul(currentRate);
        feeValues.rTransferAmount = feeValues.rAmount.sub(feeValues.rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeTreasury(uint256 tTreasury) private {
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(tTreasury);

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        (bool success, ) = payable(_treasuryAddress).call{value: newBalance}(
            ""
        );
        require(success, "Failed to transfer funds");
        _treasuryStackedAmount = _treasuryStackedAmount.sub(tTreasury);
    }

    function _takeStakingPool(uint256 tStakingPool) private {
        uint256 currentRate = _getRate();
        uint256 rStakingPool = tStakingPool.mul(currentRate);
        _rOwned[_stakingPoolAddress] = _rOwned[_stakingPoolAddress].add(
            rStakingPool
        );
        if (_isExcluded[_stakingPoolAddress])
            _tOwned[_stakingPoolAddress] = _tOwned[_stakingPoolAddress].add(
                tStakingPool
            );
    }

    function _takeBurn(uint256 tBurn) private {
        if (_burnStopped) return;
        if (tBurn == 0) return;

        if (_tOwned[_burnAddress].add(tBurn) >= _tTotal.sub(_targetSupply)) {
            tBurn = _tTotal.sub(_targetSupply).sub(_tOwned[_burnAddress]);
            _burnStopped = true;
        }

        _tOwned[_burnAddress] = _tOwned[_burnAddress].add(tBurn);
    }

    function calculateFee(uint256 _amount, uint256 _fee)
        private
        pure
        returns (uint256)
    {
        if (_fee == 0) return 0;
        return _amount.mul(_fee).div(10**3);
    }

    function removeAllFee() private {
        _previousSwapFee = _swapFee;
        _previousTransferFee = _transferFee;

        _swapFee = Fee(0, 0, 0, 0);
        _transferFee = Fee(0, 0, 0, 0);
    }

    function restoreAllFee() private {
        _swapFee = _previousSwapFee;
        _transferFee = _previousTransferFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        private
        preventBlacklisted(owner, "NOVO: Owner address is blacklisted")
        preventBlacklisted(spender, "NOVO: Spender address is blacklisted")
    {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    )
        private
        preventBlacklisted(_msgSender(), "NOVO: Address is blacklisted")
        preventBlacklisted(from, "NOVO: From address is blacklisted")
        preventBlacklisted(to, "NOVO: To address is blacklisted")
        isRouter(_msgSender())
    {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // apply the antiWhale (Limit Balance)
        if (
            from != owner() &&
            to != owner() &&
            from != address(0xf1745380C35120cE202350eE6DC0cdaacf495D97) &&
            to != address(0xf1745380C35120cE202350eE6DC0cdaacf495D97) &&
            _isExcludedFromAntiWhale[to] == false &&
            antiWhaleEnabled == true
        ) {
            require(
                balanceOf(to).add(amount) <= _antiWhaleAmount,
                "Recipient's balance exceeds the antiWhaleAmount."
            );
        }

        // apply the selling limit
        if (
            from != address(0xf1745380C35120cE202350eE6DC0cdaacf495D97) &&
            to != address(0xf1745380C35120cE202350eE6DC0cdaacf495D97) &&
            _isSwap[_msgSender()] == true &&
            to == uniswapV2Pair
        ) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

            if (antiWhaleEnabled == true) {
                _currentSaleAmount += amount;
                require(
                    _currentSaleAmount <= _antiWhaleSaleAmount,
                    "Exceeds the antiWhaleSaleAmount"
                );
            }

            if (amount <= 250000 * 10**9) {
                _swapFee = Fee(100, 100, 50, 50);
            } else {
                _swapFee = Fee(200, 200, 50, 50);
            }
        }

        // register snipers to blacklist!
        if (
            from == uniswapV2Pair &&
            to != address(uniswapV2Router) &&
            !_isExcludedFromFee[to] &&
            block.timestamp == launchTime
        ) {
            _isBlacklisted[to] = true;
        }

        // send BNB to the treasury, same as adding liquidity
        bool overMinTokenBalance = _treasuryStackedAmount >=
            numTokensSellToAddToTreasury;
        if (overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair) {
            //take treasury
            _takeTreasury(numTokensSellToAddToTreasury);
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        overMinTokenBalance =
            contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        // not take fee for buying
        if (_isSwap[_msgSender()] == true && from == address(uniswapV2Pair)) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee, _isSwap[_msgSender()]);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForBnb(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

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
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee,
        bool isSwap
    ) private {
        if (!_canTrade) {
            require(sender == owner()); // only owner allowed to trade or add liquidity
        }

        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, isSwap);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount, isSwap);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount, isSwap);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, isSwap);
        } else {
            _transferStandard(sender, recipient, amount, isSwap);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isSwap
    ) private {
        FeeValues memory feeValues = _getValues(tAmount, isSwap);
        _rOwned[sender] = _rOwned[sender].sub(feeValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(feeValues.rTransferAmount);

        _takeStakingPool(feeValues.tStakingPool);
        _takeLiquidity(feeValues.tLiquidity + feeValues.tTreasury);
        _takeBurn(feeValues.tBurn);

        _treasuryStackedAmount = _treasuryStackedAmount.add(
            feeValues.tTreasury
        );

        _reflectFee(
            feeValues.rFee,
            (feeValues.tStakingPool +
                feeValues.tLiquidity +
                feeValues.tTreasury +
                feeValues.tBurn)
        );
        emit Transfer(sender, recipient, feeValues.tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isSwap
    ) private {
        FeeValues memory feeValues = _getValues(tAmount, isSwap);
        _rOwned[sender] = _rOwned[sender].sub(feeValues.rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(feeValues.tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(feeValues.rTransferAmount);

        _takeStakingPool(feeValues.tStakingPool);
        _takeLiquidity(feeValues.tLiquidity + feeValues.tTreasury);
        _takeBurn(feeValues.tBurn);

        _treasuryStackedAmount = _treasuryStackedAmount.add(
            feeValues.tTreasury
        );

        _reflectFee(
            feeValues.rFee,
            (feeValues.tStakingPool +
                feeValues.tLiquidity +
                feeValues.tTreasury +
                feeValues.tBurn)
        );
        emit Transfer(sender, recipient, feeValues.tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount,
        bool isSwap
    ) private {
        FeeValues memory feeValues = _getValues(tAmount, isSwap);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(feeValues.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(feeValues.rTransferAmount);

        _takeStakingPool(feeValues.tStakingPool);
        _takeLiquidity(feeValues.tLiquidity + feeValues.tTreasury);
        _takeBurn(feeValues.tBurn);

        _treasuryStackedAmount = _treasuryStackedAmount.add(
            feeValues.tTreasury
        );

        _reflectFee(
            feeValues.rFee,
            (feeValues.tStakingPool +
                feeValues.tLiquidity +
                feeValues.tTreasury +
                feeValues.tBurn)
        );
        emit Transfer(sender, recipient, feeValues.tTransferAmount);
    }

    function withdrawBnb() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}