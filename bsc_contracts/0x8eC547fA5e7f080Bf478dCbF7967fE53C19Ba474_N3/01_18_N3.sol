// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPancakePair.sol";
import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakeRouter.sol";

import "./interfaces/IN3.sol";
import "./interfaces/INEOMASSNFT.sol";
import "./interfaces/IFomo.sol";
import "./interfaces/IReferral.sol";

contract N3 is IN3, Context, IERC20, IERC20Metadata, Ownable {
    ///////////////////////////////////////////////////////////
    ////// @openzeppelin/contracts/token/ERC20/ERC20.sol //////
    ///////////////////////////////////////////////////////////

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    // constructor(string memory name_, string memory symbol_) {
    //     _name = name_;
    //     _symbol = symbol_;
    // }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override(IN3, IERC20) returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    // function _transfer(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) internal virtual {
    //     require(sender != address(0), "ERC20: transfer from the zero address");
    //     require(recipient != address(0), "ERC20: transfer to the zero address");

    //     _beforeTokenTransfer(sender, recipient, amount);

    //     uint256 senderBalance = _balances[sender];
    //     require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    //     unchecked {
    //         _balances[sender] = senderBalance - amount;
    //     }
    //     _balances[recipient] += amount;

    //     emit Transfer(sender, recipient, amount);

    //     _afterTokenTransfer(sender, recipient, amount);
    // }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    ///////////////////////////////////////////////////////////
    ////////////////////////// N3 ///////////////////////////
    ///////////////////////////////////////////////////////////

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool private _paused;
    mapping(address => bool) public operators;

    IERC20 public quoteToken;
    IPancakeRouter public router;
    IPancakePair public pair;

    bool private _whitelistLpLock = true; // only the wallets in whitelist can add/remove LP
    bool private _whitelistBuyLock = true; // only the wallets in whitelist can buy from LP
    mapping(address => bool) private _swapWhitelist;

    // price protection config
    uint256 public taxPriceProtection = 500; // ‱ additional sell tax to fomo for price protection
    uint256 public priceProtectionRate = 2000; // ‱ rate, price protection turn on if daily price drop rate > this value
    uint256 public todayTimeIndex; // Today's timestamp / (24*60*60)
    uint256 public todayOpenPrice; // Today's open price, 1e18 units N3 = how many units quote token

    address public addressTreasury; // address tax to treasury
    address public addressGloryNFT; // address tax to gloryNFT
    address public addressCompensationNFT; // address tax to compensationNFT
    address public addressNFT; // address tax to NFT
    address public addressFomo; // address tax to fomo
    address public addressReferral; // address tax to referral
    address public addressNewToken; // address tax to new token

    uint256 public taxTreasury = 100; // ‱ tax to treasury
    uint256 public taxGloryNFT = 100; // ‱ tax to gloryNFT
    uint256 public taxCompensationNFT = 100; // ‱ tax to NFT
    uint256 public taxNFT = 200; // ‱ tax to NFT
    uint256 public taxFomo = 300; // ‱ tax to fomo
    uint256 public override taxReferral = 100; // ‱ tax to referral
    uint256 public taxNewToken = 100; // ‱ tax to new token

    struct taxValue {
        uint256 _amountTreasury;
        uint256 _amountGloryNFT;
        uint256 _amountCompensationNFT;
        uint256 _amountNFT;
        uint256 _amountFomo;
        uint256 _amountReferral;
        uint256 _amountNewToken;
    }

    mapping (address => bool) public automatedMarketMakerPairs;  //
    mapping(address => bool) public isTaxExcluded;
    mapping(uint256 => bool) public isTaxTransferTypeExcluded;

    bool private _inProgressLp;

    constructor() {
        _paused = false;
        
        _name = "N3";
        _symbol = "N3";

        operators[msg.sender] = true;
        _mint(msg.sender, 10000 * 10000 * 10**18);

        isTaxTransferTypeExcluded[3] = true;
        isTaxTransferTypeExcluded[4] = true;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    modifier lockLp() {
        _inProgressLp = true;
        _;
        _inProgressLp = false;
    }

    function initData() public onlyOwner {
        //setRouter
        //setOperators
        //selfApprove
        //setPriceProtection
        //setTaxAddress
        //setTaxRate
        //setTaxExcludeds
        //setTaxTransferTypeExcludeds

        //setWhitelistLock
    }

    function setPaused(bool paused_) public onlyOwner {
        _paused = paused_;
    }

    function setOperator(address _operator, bool _enabled) public onlyOwner {
        operators[_operator] = _enabled;
    }

    function setOperators(address[] memory _operators, bool _enabled) public onlyOwner {
        for (uint256 i = 0; i < _operators.length; i++) {
            operators[_operators[i]] = _enabled;
        }
    }

    function setNameAndSymbol(string memory name_, string memory symbol_) public onlyOwner {
        _name = name_;
        _symbol = symbol_;
    }

    function setRouter(IERC20 _quoteToken, IPancakeRouter _router) public onlyOwner {
        quoteToken = _quoteToken;
        router = _router;
        address _pair = IPancakeFactory(_router.factory()).createPair(address(_quoteToken), address(this));
        pair = IPancakePair(_pair);

        automatedMarketMakerPairs[_pair] = true;
    }

    function setWhitelistLock(bool _lpLock, bool _buyLock) public onlyOwner {
        _whitelistLpLock = _lpLock;
        _whitelistBuyLock = _buyLock;
    }

    function setSwapAndLpWhitelist(address[] memory _users, bool _enabled) public onlyOwner {
        uint256 _len = _users.length;
        for (uint256 i = 0; i < _len; i++) {
            _swapWhitelist[_users[i]] = _enabled;
        }
    }

    function setPriceProtection(uint256 _taxPriceProtection, uint256 _priceProtectionRate) public onlyOwner {
        taxPriceProtection = _taxPriceProtection;
        priceProtectionRate = _priceProtectionRate;
    }

    function setTaxAddress(
        address _treasury,
        address _glorynft,
        address _compensationft,
        address _nft,
        address _fomo,
        address _referral,
        address _newToken
    ) public onlyOwner {
        addressTreasury = _treasury;
        addressGloryNFT = _glorynft;
        addressCompensationNFT = _compensationft;
        addressNFT = _nft;
        addressFomo = _fomo;
        addressReferral = _referral;
        addressNewToken = _newToken;
    }

    function setTaxRate(
        uint256 _treasury,
        uint256 _glorynft,
        uint256 _compensationnft,
        uint256 _nft,
        uint256 _fomo,
        uint256 _referral,
        uint256 _newToken
    ) public onlyOwner {
        taxTreasury = _treasury;
        taxGloryNFT = _glorynft;
        taxCompensationNFT = _compensationnft;
        taxNFT = _nft;
        taxFomo = _fomo;
        taxReferral = _referral;
        taxNewToken = _newToken;
    }

    function setTaxExcluded(address _user, bool _enabled) public onlyOwner {
        isTaxExcluded[_user] = _enabled;
    }

    function setTaxExcludeds(address[] memory _users, bool _enabled) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            isTaxExcluded[_users[i]] = _enabled;
        }
    }

    function setTaxTransferTypeExcluded(uint256 _transferType, bool _enabled) public onlyOwner {
        isTaxTransferTypeExcluded[_transferType] = _enabled;
    }

    function setTaxTransferTypeExcludeds(uint256[] memory _transferTypes, bool _enabled) public onlyOwner {
        for (uint256 i = 0; i < _transferTypes.length; i++) {
            isTaxTransferTypeExcluded[_transferTypes[i]] = _enabled;
        }
    }
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

    function selfApprove(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) public onlyOwner {
        _token.approve(_spender, _amount);
    }

    function _isLp(address _addr) internal view returns (bool) {
        return automatedMarketMakerPairs[_addr];
    }

    // 0: normal transfer
    // 1: buy from official LP
    // 2: sell to official LP
    // 3: add official LP
    // 4: remove official LP
    function _getTransferType(address _from, address _to) internal view returns (uint256) {
        if (_isLp(_from) && !_isLp(_to)) {
            return _inProgressLp ? 4 : 1;
        }

        if (!_isLp(_from) && _isLp(_to)) {
            return _inProgressLp ? 3 : 2;
        }

        return 0;
    }

    function _rawTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        if (_amount == 0) {
            return;
        }

        require(!_paused, "ERC20Pausable: token transfer while paused");
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _amount);

        uint256 senderBalance = _balances[_from];
        require(senderBalance >= _amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[_from] = senderBalance - _amount;
        }
        _balances[_to] += _amount;

        emit Transfer(_from, _to, _amount);

        _afterTokenTransfer(_from, _to, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        updateTodayOpenPrice();
        (bool _isUp, uint256 _changeRate) = getDailyPriceChange();
        uint256 _transferType = _getTransferType(_from, _to);
        
        // buy
        if (_transferType == 1) {
            require(!_whitelistBuyLock || _swapWhitelist[_to], "N3: forbidden to buy"); // buy Whitelist lock
        }

        // sell
        if (_transferType == 2) {
            // only can sell 99% of balance
            uint256 _balance = _balances[_from];
            if (_amount >= _balance) {
                _amount = _balance.mul(99).div(100);
            }
        }

        // add LP
        if (_transferType == 3) {
            require(!_whitelistLpLock || _swapWhitelist[_from], "N3: forbidden add LP"); // LP Whitelist lock
        }

        // remove LP
        if (_transferType == 4) {
            require(!_whitelistLpLock || _swapWhitelist[_to], "N3: forbidden remove LP"); // LP Whitelist lock
        }
  


        taxValue memory taxValueVar = taxValue({
            _amountTreasury:0,
            _amountGloryNFT:0,
            _amountCompensationNFT:0,
            _amountNFT:0,
            _amountFomo:0,
            _amountReferral:0,
            _amountNewToken:0
        });
       
        if (
            !isTaxExcluded[_from] &&
            !isTaxTransferTypeExcluded[_transferType] &&
            !(_transferType == 1 && isTaxExcluded[_to]) // buy from lp
        ) {

            taxValueVar._amountTreasury = _amount.mul(taxTreasury).div(10000);
            taxValueVar._amountGloryNFT = _amount.mul(taxGloryNFT).div(10000);
            taxValueVar._amountCompensationNFT = _amount.mul(taxCompensationNFT).div(10000);
            taxValueVar._amountNFT = _amount.mul(taxNFT).div(10000);
            taxValueVar._amountFomo = _amount.mul(taxFomo).div(10000);
            taxValueVar._amountReferral = _amount.mul(taxReferral).div(10000);
            taxValueVar._amountNewToken = _amount.mul(taxNewToken).div(10000);

            // additional sell tax if daily price drop rate > 20%
            if (_transferType == 2 && !_isUp && _changeRate > priceProtectionRate) {
                taxValueVar._amountFomo =taxValueVar._amountFomo.add(_amount.mul(taxPriceProtection).div(10000));
            }

            
        }

        uint256 amountTax = taxValueVar._amountTreasury + taxValueVar._amountGloryNFT + taxValueVar._amountCompensationNFT + taxValueVar._amountNFT + taxValueVar._amountFomo + taxValueVar._amountReferral + taxValueVar._amountNewToken;
        require(_amount > amountTax, "transfer amount is too small");

        
        _rawTransfer(_from, addressTreasury,        taxValueVar._amountTreasury);
        _rawTransfer(_from, addressGloryNFT,        taxValueVar._amountGloryNFT);
        _rawTransfer(_from, addressCompensationNFT, taxValueVar._amountCompensationNFT);
        _rawTransfer(_from, addressNFT,             taxValueVar._amountNFT);
        _rawTransfer(_from, addressFomo,            taxValueVar._amountFomo);
        _rawTransfer(_from, addressReferral,        taxValueVar._amountReferral);
        _rawTransfer(_from, addressNewToken,        taxValueVar._amountNewToken);
        _rawTransfer(_from, _to, _amount.sub(amountTax));

        IFomo(addressFomo).onTransfer(_from, _to, _amount, _transferType);
        IReferral(addressReferral).onTransfer(_from, _to, _amount, _transferType);

        if (taxValueVar._amountGloryNFT > 0) {
            INEOMASSNFT(addressGloryNFT).addReward(taxValueVar._amountGloryNFT);
        }
        if (taxValueVar._amountCompensationNFT > 0) {
            INEOMASSNFT(addressCompensationNFT).addReward(taxValueVar._amountCompensationNFT);
        }
        if (taxValueVar._amountNFT > 0) {
            INEOMASSNFT(addressNFT).addReward(taxValueVar._amountNFT);
        }
        
        if (taxValueVar._amountReferral > 0) {
            // if buy from LP, find referrer by _to/user
            IReferral(addressReferral).addReward(_transferType == 1 ? _to : _from, taxValueVar._amountReferral);
        }
    }

    function transferNoTax(address _to, uint256 _amount) public override onlyOperator {
        updateTodayOpenPrice();
        _rawTransfer(_msgSender(), _to, _amount);
    }

    function updateTodayOpenPrice() public {
        uint256 _dayTimeIndex = block.timestamp.div(86400);
        if (_dayTimeIndex <= todayTimeIndex) {
            return;
        }

        uint256 _price = getPrice();
        if (_price == 0) {
            return;
        }

        todayTimeIndex = _dayTimeIndex;
        todayOpenPrice = _price;
    }

    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) public lockLp {
        require(_tokenA != _tokenB, "N3: invalid _tokenA");
        require(_tokenA == address(this) || _tokenA == address(quoteToken), "N3: invalid _tokenA");
        require(_tokenB == address(this) || _tokenB == address(quoteToken), "N3: invalid _tokenB");

        (uint256 _amountMain, uint256 _amountQuote) = _tokenA == address(this)
            ? (_amountADesired, _amountBDesired)
            : (_amountBDesired, _amountADesired);
        (uint256 _amountMainMin, uint256 _amountQuoteMin) = _tokenA == address(this)
            ? (_amountAMin, _amountBMin)
            : (_amountBMin, _amountAMin);

        _rawTransfer(msg.sender, address(this), _amountMain);
        quoteToken.safeTransferFrom(msg.sender, address(this), _amountQuote);

        (uint256 _amountMainUsed, uint256 _amountQuoteUsed, ) = router.addLiquidity(
            address(this),
            address(quoteToken),
            _amountMain,
            _amountQuote,
            _amountMainMin,
            _amountQuoteMin,
            _to,
            _deadline
        );

        _rawTransfer(address(this), msg.sender, _amountMain.sub(_amountMainUsed));
        if (_amountQuote > _amountQuoteUsed) {
            quoteToken.safeTransfer(msg.sender, _amountQuote.sub(_amountQuoteUsed));
        }
    }

    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _liquidity,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _to,
        uint256 _deadline
    ) public lockLp {
        require(_tokenA != _tokenB, "N3: invalid _tokenA");
        require(_tokenA == address(this) || _tokenA == address(quoteToken), "N3: invalid _tokenA");
        require(_tokenB == address(this) || _tokenB == address(quoteToken), "N3: invalid _tokenB");

        (uint256 _amountMainMin, uint256 _amountQuoteMin) = _tokenA == address(this)
            ? (_amountAMin, _amountBMin)
            : (_amountBMin, _amountAMin);

        IERC20 _tokenLp = IERC20(address(pair));
        _tokenLp.safeTransferFrom(msg.sender, address(this), _liquidity);
        router.removeLiquidity(
            address(this),
            address(quoteToken),
            _liquidity,
            _amountMainMin,
            _amountQuoteMin,
            _to,
            _deadline
        );
    }

    // 1e18 units N3 token = how many units quote token
    function getPrice() public view override returns (uint256) {
        address _token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        (uint256 _main, uint256 _quote) = address(quoteToken) == _token0
            ? (_reserve1, _reserve0)
            : (_reserve0, _reserve1);
        return _main == 0 ? 0 : _quote.mul(1e18).div(_main);
    }

    // ‱ change rate, return 1000 means price change 10%
    function getDailyPriceChange() public view returns (bool _isUp, uint256 _changeRate) {
        if (todayOpenPrice == 0) {
            return (_isUp, _changeRate);
        }

        uint256 _lastPrice = getPrice();
        _isUp = _lastPrice > todayOpenPrice;
        uint256 _change = _isUp ? _lastPrice.sub(todayOpenPrice) : todayOpenPrice.sub(_lastPrice);
        _changeRate = _change.mul(10000).div(todayOpenPrice);
        return (_isUp, _changeRate);
    }

    // 1e18 units LP token value = how many units quote token
    function getLpPrice() public view override returns (uint256) {
        uint256 _total = pair.totalSupply();
        address _token0 = pair.token0();
        (uint256 _reserve0, uint256 _reserve1, ) = pair.getReserves();
        uint256 _quote = address(quoteToken) == _token0 ? _reserve0 : _reserve1;
        return _total == 0 ? 0 : _quote.mul(2).mul(1e18).div(_total);
    }

    function getLpAddress() public view override returns (address) {
        return address(pair);
    }

    function rescue(
        address _token,
        address payable _to,
        uint256 _amount
    ) public onlyOwner {
        if (_token == address(0)) {
            (bool success, ) = _to.call{ gas: 23000, value: _amount }("");
            require(success, "transferETH failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }
}