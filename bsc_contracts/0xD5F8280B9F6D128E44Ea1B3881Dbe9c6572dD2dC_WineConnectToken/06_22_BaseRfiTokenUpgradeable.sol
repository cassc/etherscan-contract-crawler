// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./OwnableUpgradeable.sol";
import "./TokenomicsUpgradeable.sol";

abstract contract BaseRfiTokenUpgradeable is Initializable, ERC20Upgradeable, OwnableUpgradeable, TokenomicsUpgradeable {

    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) internal _reflectedBalances;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    
    mapping (address => bool) internal _isExcludedFromFee;
    mapping (address => bool) internal _isExcludedFromRewards;
    address[] private _excluded;

    function __BaseRfiToken_init(string memory name_, string memory symbol_, address marketingAdr_, address eventAddr_) internal onlyInitializing {
        __BaseRfiToken_init_unchained(name_, symbol_, marketingAdr_, eventAddr_);
    }

    function __BaseRfiToken_init_unchained(string memory name_, string memory symbol_, address marketingAdr_, address eventAddr_) internal onlyInitializing {
        __ERC20_init(name_, symbol_);
        __Tokenomics_init(marketingAdr_, eventAddr_);
        __Ownable_init();

        _reflectedBalances[owner()] = _reflectedSupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingAdr_] = true;
        _isExcludedFromFee[eventAddr_] = true;
        
        _exclude(owner());
        _exclude(address(this));

        _mint(owner(), TOTAL_SUPPLY);
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromRewards[account]) return _balances[account];
            return tokenFromReflection(_reflectedBalances[account]);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= TOTAL_SUPPLY, "Amount must be less than supply");

        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount,0);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount, _getSumOfFees(_msgSender()));
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _reflectedSupply, "Amount must be less than total reflections");
        uint256 currentRate = _getCurrentRate();
        return rAmount.div(currentRate);
    }
    
    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcludedFromRewards[account];
    }

    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcludedFromRewards[account], "Account is not included");
        _exclude(account);
    }
    
    function _exclude(address account) internal {
        if(_reflectedBalances[account] > 0) {
            _balances[account] = tokenFromReflection(_reflectedBalances[account]);
        }
        _isExcludedFromRewards[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromRewards[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _balances[account] = 0;
                _isExcludedFromRewards[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function setExcludedFromFee(address account, bool value) external onlyOwner { 
        _isExcludedFromFee[account] = value; 
    }

    function isExcludedFromFee(address account) public view returns(bool) { 
        return _isExcludedFromFee[account]; 
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "BaseRfiToken: transfer from the zero address");
        require(recipient != address(0), "BaseRfiToken: transfer to the zero address");
        require(sender != address(BURN_ADDRESS), "BaseRfiToken: transfer from the burn address");
        require(amount > 0, "Transfer amount must be greater than zero");
       
        bool takeFee = true;

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            takeFee = false; 

        _beforeTokenTransfer(sender, recipient, takeFee);
        _transferTokens(sender, recipient, amount, takeFee);
    }

    function _transferTokens(address sender, address recipient, uint256 amount, bool takeFee) private {
        uint256 sumOfFees = 0;

        if (takeFee)
            sumOfFees = _getSumOfFees(sender); 

        (uint256 rAmount, uint256 rTransferAmount, uint256 tAmount, uint256 tTransferAmount, uint256 currentRate ) = _getValues(amount, sumOfFees);

        _reflectedBalances[sender] = _reflectedBalances[sender].sub(rAmount);
        _reflectedBalances[recipient] = _reflectedBalances[recipient].add(rTransferAmount);
  
        if (_isExcludedFromRewards[sender])
            _balances[sender] = _balances[sender].sub(tAmount);

        if (_isExcludedFromRewards[recipient])
            _balances[recipient] = _balances[recipient].add(tTransferAmount);
            
        _takeFees( _isV2Pair(sender), amount, currentRate, sumOfFees );

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFees(bool isBuy, uint256 amount, uint256 currentRate, uint256 sumOfFees ) private {
        if (sumOfFees > 0)
            _takeTransactionFees(isBuy, amount, currentRate);
    }

    function _getValues(uint256 tAmount, uint256 feesSum) internal view returns (uint256, uint256, uint256, uint256, uint256) {        
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);
        uint256 currentRate = _getCurrentRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rTotalFees = tTotalFees.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rTotalFees);
        
        return (rAmount, rTransferAmount, tAmount, tTransferAmount, currentRate);
    }

    function _getCurrentRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _reflectedSupply;
        uint256 tSupply = TOTAL_SUPPLY;  
 
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_reflectedBalances[_excluded[i]] > rSupply || _balances[_excluded[i]] > tSupply) return (_reflectedSupply, TOTAL_SUPPLY);
            rSupply = rSupply.sub(_reflectedBalances[_excluded[i]]);
            tSupply = tSupply.sub(_balances[_excluded[i]]);
        }

        if (tSupply == 0 || rSupply < _reflectedSupply.div(TOTAL_SUPPLY)) 
            return (_reflectedSupply, TOTAL_SUPPLY);

        return (rSupply, tSupply);
    }

    function _getSumOfFees(address sender) internal view virtual returns (uint256) {
        if (_isV2Pair(sender))
            return sumOfFeesBuy;

        return sumOfFeesSell;
    }

    function _redistribute(uint256 amount, uint256 currentRate, uint256 fee) internal {
        uint256 tFee = amount.mul(fee).div(FEES_DIVISOR);
        uint256 rFee = tFee.mul(currentRate);

        _reflectedSupply = _reflectedSupply.sub(rFee);
    }

    function updateBuyFeeValue(uint256 index, uint256 value) public override onlyOwner {
        super.updateBuyFeeValue(index, value);
    }

    function updateSellFeeValue(uint256 index, uint256 value) public override onlyOwner {
        super.updateSellFeeValue(index, value);
    }

    function updateEventWallet(address wallet) public override onlyOwner {
        super.updateEventWallet(wallet);
    }

    function updateMarketingWallet(address wallet) public override onlyOwner {
        super.updateMarketingWallet(wallet);
    }

    function _beforeTokenTransfer(address sender, address recipient, bool takeFee) internal virtual;

    function _takeTransactionFees(bool isBuy, uint256 amount, uint256 currentRate) internal virtual;

    function _isV2Pair(address account) internal view virtual returns(bool);
}