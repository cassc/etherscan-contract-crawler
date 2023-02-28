// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract LINGO is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) public rewardBalance;
    mapping(address => bool) private _isExcluded;

    address[] private _holders;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "LINGO";
    string private _symbol = "LINGO";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;
    bool private _onPresaleEnabled = true;

    bool private isTradingEnabled = false;

    address private _BurnWallet;
    uint256 private _Burn_FEE = 5; // 5%

    address private _TreasuryWallet =
        0x4f8BC322F2C28857a025cc1a6294350b38fD8081;
    address private ownerWallet = 0x791bB15845bE833f409633119da7F3a940d14208;
    uint256 private _treasuryFee = 5; // 5%
    uint256 private _rewardFee = 10; // 10%

    IUniswapV2Router02 public uniswapV2Router;
    IERC20 private BUSD;
    address public uniswapV2Pair;

    bool inSwapReward;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _maxAmountOnPresale = uint256(1000000).mul(10**9);

    modifier lockTheSwap() {
        inSwapReward = true;
        _;
        inSwapReward = false;
    }

    constructor(address dexAddress, address BurnWallet) {
        _rOwned[ownerWallet] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(dexAddress);
        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), address(BUSD));

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _BurnWallet = BurnWallet;
        emit Transfer(address(0), ownerWallet, _tTotal);
    }

    function updateDex(address _newDexAddress) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _newDexAddress
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), address(BUSD));

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
    }

    function disableOnPresalePermanently() external onlyOwner {
        _onPresaleEnabled = false;
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

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function getBurnWallet() public view returns (address) {
        return _BurnWallet;
    }

    function getTreasuryWallet() public view returns (address) {
        return _TreasuryWallet;
    }

    function setBurnWallet(address BurnWallet) external onlyOwner {
        require(!_isExcluded[BurnWallet], "Can't be excluded address");
        _BurnWallet = BurnWallet;
    }

    function setTreasuryWallet(address TreasuryWallet) external onlyOwner {
        require(!_isExcluded[TreasuryWallet], "Can't be excluded address");
        _TreasuryWallet = TreasuryWallet;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
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

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
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

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setTreasuryFeePercent(uint256 treasuryFee) external onlyOwner {
        _treasuryFee = treasuryFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        _Burn_FEE = burnFee;
    }

    function setRewardFeePercent(uint256 rewardFee) external onlyOwner {
        _rewardFee = rewardFee;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            _getRate()
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
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

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function removeAllFee() private {
        if (_taxFee == 0) return;

        _previousTaxFee = _taxFee;

        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (_onPresaleEnabled && to != uniswapV2Pair && to != owner()) {
            require(
                balanceOf(to).add(amount) < _maxAmountOnPresale,
                "Exceed Max Amount"
            );
        }

        if (uniswapV2Pair == from && isTradingEnabled) {
            // BUY
            uint256 burnAmount = amount.mul(_Burn_FEE).div(10**2);
            _tokenTransfer(from, _BurnWallet, burnAmount, false);
            amount = amount.sub(burnAmount);
        }

        if (uniswapV2Pair == to && isTradingEnabled && !inSwapReward) {
            // SELL
            uint256 treasuryAmount = amount.mul(_treasuryFee).div(10**2);
            uint256 rewardAmount = amount.mul(_rewardFee).div(10**2);
            rewardBalance[_TreasuryWallet] = rewardBalance[_TreasuryWallet].add(
                treasuryAmount
            );
            _tokenTransfer(
                from,
                address(this),
                rewardAmount + treasuryAmount,
                false
            );
            shareReward(rewardAmount);
            amount = amount.sub(treasuryAmount).sub(rewardAmount);
        }

        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function shareReward(uint256 contractTokenBalance) private {
        for (uint256 i = 0; i < _holders.length; i++) {
            rewardBalance[_holders[i]] = rewardBalance[_holders[i]].add(
                contractTokenBalance.mul(balanceOf(_holders[i])).div(
                    totalSupply()
                )
            );
        }
    }

    function claimReward() public lockTheSwap {
        require(rewardBalance[_msgSender()] != 0, "Not Enough");

        // swap tokens for ETH
        swapTokensForBUSD(rewardBalance[_msgSender()], _msgSender()); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        rewardBalance[_msgSender()] = 0;
    }

    function swapTokensForBUSD(uint256 tokenAmount, address to) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(BUSD);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BUSD
            path,
            to,
            block.timestamp
        );
    }

    function setTrading(bool option) public onlyOwner {
        isTradingEnabled = option;
    }

    function airdrop(address[] memory addresses, uint256[] memory amounts)
        public
        payable
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "Arrays length must be the same."
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 receiverAmount = amounts[i] * 10**9;
            _tokenTransfer(_msgSender(), addresses[i], receiverAmount, false);
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (
            balanceOf(recipient) == 0 &&
            amount > 0 &&
            !Address.isContract(recipient)
        ) {
            _holders.push(recipient);
        }

        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();

        if (balanceOf(sender) == 0) {
            for (uint256 i = 0; i < _holders.length; i++) {
                if (_holders[i] == sender) {
                    _holders[i] = _holders[_holders.length - 1];
                    _holders.pop();
                    break;
                }
            }
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee
        ) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}