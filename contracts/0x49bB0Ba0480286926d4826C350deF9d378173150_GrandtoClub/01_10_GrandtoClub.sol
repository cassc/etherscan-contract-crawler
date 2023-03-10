//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./IERC20.sol";
import "./blacklist.sol";
import "./safeMath.sol";
import "./ownable.sol";
import "./address.sol";
import "./liquifier.sol";
import "./IERC20Metadata.sol";

abstract contract Tokenomics {
    using SafeMath for uint256;

    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
 
    address public developerFEEAddress =
        0xb280eB22334f4c3b0cC2fE6C5665FE11B15AE5e3;

    uint256 public _devFee = 0; // 0%
    uint256 public _liqFee = 50; // 5%

    string internal constant NAME = "GrandtoClub";
    string internal constant SYMBOL = "GTC";

    uint16 internal constant FEES_DIVISOR = 10**3;
    uint8 internal constant DECIMALS = 18;
    uint256 internal constant ZEROES = 10**DECIMALS;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal constant TOTAL_SUPPLY = 100000000 * ZEROES; // 10 MM

    uint256 public MXTX = 1500000;
    uint256 public maxTransactionAmount = MXTX * ZEROES; // 1.50% of the total supply //1500000

    uint256 public MXWL = 1500000;

    uint256 public maxWalletBalance = MXWL * ZEROES; // 1.50% of the total supply //1500000

    uint256 public numberOfTokensToSwapToLiquidity =
        TOTAL_SUPPLY / 10000; // 0.1% of the total supply //10k in contract before liq

    // --------------------- Fees Settings ------------------- //

    enum FeeType {
        Liquidity,
        ExternalToETH
    }
    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    uint256 internal sumOfFees;

    constructor() {
        _addFees();
    }

    function _addFee(
        FeeType name,
        uint256 value,
        address recipient
    ) private {
        fees.push(Fee(name, value, recipient, 0));
        sumOfFees += value;
    }

    function _addFees() private {

        _addFee(FeeType.Liquidity, _liqFee, address(this)); //2%
        _addFee(FeeType.ExternalToETH, _devFee, developerFEEAddress); //2%
    }

    function _getFeesCount() internal view returns (uint256) {
        return fees.length;
    }

    function _getFeeStruct(uint256 index) private view returns (Fee storage) {
        require(
            index >= 0 && index < fees.length,
            "FeesSettings._getFeeStruct: Fee index out of bounds"
        );
        return fees[index];
    }

    function _getFee(uint256 index)
        internal
        view
        returns (
            FeeType,
            uint256,
            address,
            uint256
        )
    {
        Fee memory fee = _getFeeStruct(index);
        return (fee.name, fee.value, fee.recipient, fee.total);
    }

    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    // function getCollectedFeeTotal(uint256 index) external view returns (uint256){
    function getCollectedFeeTotal(uint256 index)
        internal
        view
        returns (uint256)
    {
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
}

abstract contract Base is
    IERC20,
    IERC20Metadata,
    Ownable,
    Tokenomics,
    Blacklist
{
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal _isExcludedFromFee;

    constructor() {
        _balances[owner()] = TOTAL_SUPPLY;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[developerFEEAddress] = true;
        _isExcludedFromFee[uniswapV2Router] = true;
        _isExcludedFromFee[address(this)] = true;

        _addToWhitelistedSenders(owner());
        _addToWhitelistedSenders(developerFEEAddress);
        _addToWhitelistedSenders(address(this));
        _addToWhitelistedSenders(uniswapV2Router);

        _addToWhitelistedRecipients(owner());
        _addToWhitelistedRecipients(developerFEEAddress);
        _addToWhitelistedRecipients(address(this));
        _addToWhitelistedRecipients(uniswapV2Router);

        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
    }
    
    function changeMaxTxAmount(uint256 newAmount) public onlyOwner {
        MXTX = newAmount;
    }
       function changeMaxWalletAMount(uint256 newAmount) public onlyOwner {
        MXWL = newAmount;
    }

      function changeDevFeeAddress(address _newDevFeeAddress) public onlyOwner {
        developerFEEAddress = _newDevFeeAddress;
    }

    function changeDevFee(uint256 _newDevFee) public onlyOwner {
        uint256 _sumOfFees = _liqFee + _newDevFee;
        require(_sumOfFees <= 50, "Total fees cannot be more than 5%");
        _devFee = _newDevFee;
    }

    function changeLiqFee(uint256 _newLiqFee) public onlyOwner {
        uint256 _sumOfFees = _devFee + _newLiqFee;
        require(_sumOfFees <= 50, "Total fees cannot be more than 5%");
        _liqFee = _newLiqFee;
    }

    function blackListWallets(address _wallet, bool _status) public onlyOwner {
        antiBot._blacklistedUsers[_wallet] = _status; // true or false
    }

    // BLACKLIST ARRAY OF ADDRESSES EG: ["0X000...","0X000","0X000"],true
    function blackListWalletsBulk(address[] memory _wallets, bool _status)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            antiBot._blacklistedUsers[_wallets[i]] = _status;
        }
    }

    function removeBlackListWallet(address _wallet) public onlyOwner {
        antiBot._blacklistedUsers[_wallet] = false;
    }

    function removeBlackListWalletBulk(address[] memory _wallets)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _wallets.length; i++) {
            antiBot._blacklistedUsers[_wallets[i]] = false;
        }
    }

    /** Functions required by IERC20Metadata **/
    function name() external pure override returns (string memory) {
        return NAME;
    }

    function symbol() external pure override returns (string memory) {
        return SYMBOL;
    }

    function decimals() external pure override returns (uint8) {
        return DECIMALS;
    }

    /** Functions required by IERC20 **/
    function totalSupply() external pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
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
    ) external override returns (bool) {
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

    function setExcludedFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "BaseRfiToken: approve from the zero address"
        );
        require(
            spender != address(0),
            "BaseRfiToken: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    address[] private whitelistedSenders;
    address[] private whitelistedRecipients;

    function _isUnlimitedSender(address account) public view returns (bool) {
        // check if the provided address is in the whitelisted senders array or is the owner
        for (uint256 i = 0; i < whitelistedSenders.length; i++) {
            if (account == whitelistedSenders[i] || account == owner()) {
                return true;
            }
        }
        return false;
    }

    function _isUnlimitedRecipient(address account) public view returns (bool) {
        // check if the provided address is in the whitelisted recipients array or is the owner
        for (uint256 i = 0; i < whitelistedRecipients.length; i++) {
            if (account == whitelistedRecipients[i] || account == owner()) {
                return true;
            }
        }
        return false;
    }

    function _addToWhitelistedSenders(address account) internal {
        whitelistedSenders.push(account);
    }

    function addToWhitelistedSenders(address account) external onlyOwner {
        whitelistedSenders.push(account);
    }

    function removeFromWhitelistedSenders(address account) external onlyOwner {
        for (uint256 i = 0; i < whitelistedSenders.length; i++) {
            if (whitelistedSenders[i] == account) {
                whitelistedSenders[i] = whitelistedSenders[
                    whitelistedSenders.length - 1
                ];
                whitelistedSenders.pop();
                break;
            }
        }
    }

    function _addToWhitelistedRecipients(address account) internal {
        whitelistedRecipients.push(account);
    }

    function addToWhitelistedRecipients(address account) external onlyOwner {
        whitelistedRecipients.push(account);
    }

    function removeFromWhitelistedRecipients(address account)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < whitelistedRecipients.length; i++) {
            if (whitelistedRecipients[i] == account) {
                whitelistedRecipients[i] = whitelistedRecipients[
                    whitelistedRecipients.length - 1
                ];
                whitelistedRecipients.pop();
                break;
            }
        }
    }

    bool public tradeStarted = false;

    // once enabled, can never be turned off
    function EnableTrading() external onlyOwner {
        tradeStarted = true;
    }

    modifier isTradeStarted(address from, address to) {
        if (!tradeStarted) {
            require(
                _isUnlimitedSender(from) || _isUnlimitedRecipient(to),
                "trade not started"
            );
        }

        _;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private isTradeStarted(sender, recipient) {
        require(
            sender != address(0),
            "BaseRfiToken: transfer from the zero address"
        );
        require(
            recipient != address(0),
            "BaseRfiToken: transfer to the zero address"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            !antiBot._blacklistedUsers[recipient] &&
                !antiBot._blacklistedUsers[sender],
            "You are not allowed"
        );

        // indicates whether or not feee should be deducted from the transfer
        bool takeFee = true;

        if (
            amount > maxTransactionAmount &&
            !_isUnlimitedSender(sender) &&
            !_isUnlimitedRecipient(recipient)
        ) {
            revert("Transfer amount exceeds the maxTxAmount.");
        }

        if (
            maxWalletBalance > 0 &&
            !_isUnlimitedSender(sender) &&
            !_isUnlimitedRecipient(recipient) &&
            !_isV2Pair(recipient)
        ) {
            uint256 recipientBalance = balanceOf(recipient);
            require(
                recipientBalance + amount <= maxWalletBalance,
                "New balance would exceed the maxWalletBalance"
            );
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        _beforeTokenTransfer(sender, recipient, amount, takeFee);
        _transferTokens(sender, recipient, amount, takeFee);
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        uint256 sumOfFees = _getSumOfFees(sender, amount);
        if (!takeFee) {
            sumOfFees = 0;
        }

        (uint256 tAmount, uint256 tTransferAmount) = _getValues(
            amount,
            sumOfFees
        );

        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);

        _takeFees(amount, sumOfFees);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeFees(uint256 amount, uint256 sumOfFees) private {
        if (sumOfFees > 0) {
            _takeTransactionFees(amount);
        }
    }

    function _getValues(uint256 tAmount, uint256 feesSum)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 tTotalFees = tAmount.mul(feesSum).div(FEES_DIVISOR);
        uint256 tTransferAmount = tAmount.sub(tTotalFees);

        return (tAmount, tTransferAmount);
    }

    function _getCurrentSupply() internal pure returns (uint256) {
        uint256 tSupply = TOTAL_SUPPLY;
        return (tSupply);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _beforeTokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) internal virtual;

    function _getSumOfFees(address sender, uint256 amount)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev A delegate which should return true if the given address is the V2 Pair and false otherwise
     */
    function _isV2Pair(address account) internal view virtual returns (bool);

    /**
     * @dev Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     */
    function _takeTransactionFees(uint256 amount) internal virtual;
}

abstract contract Grandto is Base, Liquifier {
    using SafeMath for uint256;

    // constructor(string memory _name, string memory _symbol, uint8 _decimals){
    constructor(Env _env) {
        initializeLiquiditySwapper(
            _env,
            maxTransactionAmount,
            numberOfTokensToSwapToLiquidity
        );
    }

    function _isV2Pair(address account) internal view override returns (bool) {
        return (account == _pair);
    }

    function _getSumOfFees(address sender, uint256 amount)
        internal
        view
        override
        returns (uint256)
    {
        return _getAntiwhaleFees(balanceOf(sender), amount);
    }

    function _getAntiwhaleFees(uint256, uint256)
        internal
        view
        returns (uint256)
    {
        return sumOfFees;
    }

    // function _beforeTokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal override {
    function _beforeTokenTransfer(
        address sender,
        address,
        uint256,
        bool
    ) internal override {
        uint256 contractTokenBalance = balanceOf(address(this));
        liquify(contractTokenBalance, sender);
    }

    function _takeTransactionFees(uint256 amount) internal override {
        uint256 feesCount = _getFeesCount();
        for (uint256 index = 0; index < feesCount; index++) {
            (FeeType name, uint256 value, address recipient, ) = _getFee(index);
            // no need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
            if (value == 0) continue;
            else if (name == FeeType.ExternalToETH) {
                _takeFee(amount, value, recipient, index);
            } else {
                _takeFee(amount, value, recipient, index);
            }
        }
    }

    function _takeFee(
        uint256 amount,
        uint256 fee,
        address recipient,
        uint256 index
    ) private {
        uint256 tAmount = amount.mul(fee).div(FEES_DIVISOR);

        _balances[recipient] = _balances[recipient].add(tAmount);
        _addFeeCollectedAmount(index, tAmount);
    }

    function _approveDelegate(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        _approve(owner, spender, amount);
    }
}

contract GrandtoClub is Grandto {
    constructor() Grandto(Env.MainnetV2) {
        // pre-approve the initial liquidity supply (to safe a bit of time)
        _approve(owner(), address(_router), ~uint256(0));
    }
}