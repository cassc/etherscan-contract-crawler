// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

/**
 *__/\\\______________/\\\_____/\\\\\\\\\_______/\\\\\\\\\______/\\\\\\\\\\\\\___
 * _\/\\\_____________\/\\\___/\\\\\\\\\\\\\___/\\\///////\\\___\/\\\/////////\\\_
 *  _\/\\\_____________\/\\\__/\\\/////////\\\_\/\\\_____\/\\\___\/\\\_______\/\\\_
 *   _\//\\\____/\\\____/\\\__\/\\\_______\/\\\_\/\\\\\\\\\\\/____\/\\\\\\\\\\\\\/__
 *    __\//\\\__/\\\\\__/\\\___\/\\\\\\\\\\\\\\\_\/\\\//////\\\____\/\\\/////////____
 *     ___\//\\\/\\\/\\\/\\\____\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
 *      ____\//\\\\\\//\\\\\_____\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
 *       _____\//\\\__\//\\\______\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\_____________
 *        ______\///____\///_______\///________\///__\///________\///__\///______________
 **/

// Openzeppelin
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

// helpers
import './helpers/WarpBase.sol';

contract WarpToken is ERC20, WarpBase {
    //** ====== VARIABLES ======== */

    // Tax
    mapping(address => bool) public isExcludedFromFee; // done
    mapping(address => bool) public pairs;
    mapping(address => bool) public routers;
    uint256 salesTax;
    uint256 public totalFrozen;

    // Protection
    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist; // Whitelisters will only be contracts and owner etc.
    mapping(address => bool) callers;

    //** ======= MODIFIERS ======= */

    modifier onlyCallers() {
        require(callers[msg.sender], 'Not a caller');
        _;
    }

    modifier isBlackedListed(address sender, address recipient) {
        require(blacklist[sender] == false, 'ERC20: Account is blacklisted from transferring');
        _;
    }

    //** ======= INITIALIZE ======= */
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        paused = false;
        salesTax = 0;

        whitelist[msg.sender] = true;
        isExcludedFromFee[msg.sender] = true;

        _mint(msg.sender, 1000000000 * 10**decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /** ====== MINT & BURN ======== */
    function mint(address account_, uint256 amount_) external onlyCallers {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        totalFrozen += amount;
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender) - amount_;

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);

        totalFrozen += amount_;
    }

    /**
     * @dev See {IERC20-transfer}..
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        isBlackedListed(msg.sender, recipient)
        returns (bool)
    {
        (uint256 taxed, uint256 amountLeft) = getTaxAmount(msg.sender, recipient, amount);
        if (taxed > 0) {
            _burn(msg.sender, taxed);
            totalFrozen += taxed;
        }
        return super.transfer(recipient, amountLeft);
    }

    /**
     * @dev See {IERC20-transfer-from}..
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused isBlackedListed(sender, recipient) returns (bool) {
        (uint256 taxed, uint256 amountLeft) = getTaxAmount(sender, recipient, amount);
        if (taxed > 0) {
            _burn(sender, taxed);
            totalFrozen += taxed;
        }

        super.transferFrom(sender, recipient, amountLeft);
        return true;
    }

    /** @dev get tax 
        @param sender {address}
        @param recipient {address}
        @param amount {uint256}
    */
    function getTaxAmount(
        address sender,
        address recipient,
        uint256 amount
    ) internal view returns (uint256 taxed, uint256 amountLeft) {
        if (pairs[recipient] == true && isExcludedFromFee[sender] == false) {
            // Sell & Liquidity provision
            // note: For liquidity provision we will use warpIn so liquidity doesn't get taxed.
            taxed = (amount * salesTax) / 100;
            amountLeft = amount - taxed;
        } else {
            // Everything else.
            taxed = 0;
            amountLeft = amount;
        }
    }

    /** @notice get sell tax */
    function getTax() external view returns (uint256) {
        return salesTax;
    }

    /** @dev Is the contract paused? */
    function getPaused() external view returns (bool) {
        return paused;
    }

    /** ======= SETTERS ======= */

    /** Exclude 
        Description: When an account is excluded from fee, we remove fees then restore fees
        @param account {address}
     */
    function setExcludeForAccount(address account, bool exclude) external onlyOwner {
        isExcludedFromFee[account] = exclude;

        emit SetExcludeAccount(msg.sender, account, exclude);
    }

    /** @dev set sales tax {onlyOwner}
        @param tax {uint256}
     */
    function setSalesTax(uint256 tax) external onlyOwner {
        require(tax <= 20, 'Max tax of 20');
        salesTax = tax;

        emit SetSalesTax(msg.sender, tax);
    }

    /** @dev setup pair for sells tax */
    function setPair(address _pair, bool _isPair) external onlyOwner {
        pairs[_pair] = _isPair;

        emit SetPair(msg.sender, _pair, _isPair);
    }

    /** @dev setup router for sells tax */
    function setRouter(address _router, bool _isRouter) external onlyOwner {
        routers[_router] = _isRouter;

        emit SetRouter(msg.sender, _router, _isRouter);
    }

    /** @dev set blacklisted addresses */
    function setBlackListedAddresses(address[] calldata accounts, bool[] calldata blacklisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklist[accounts[i]] = blacklisted[i];

            emit SetBlackListed(msg.sender, accounts[i], blacklisted[i]);
        }
    }

    /** @dev set whitelisted addresses */
    function setWhiteListedAddresses(address[] calldata accounts, bool[] calldata whitelisted)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = whitelisted[i];

            emit SetWhiteListed(msg.sender, accounts[i], whitelisted[i]);
        }
    }

    /** @dev set whitelisted addresses */
    function setCaller(address _caller, bool _isCaller) external onlyOwner {
        callers[_caller] = _isCaller;

        emit SetCaller(msg.sender, _caller, _isCaller);
    }

    /** @dev Toggle pause boolean */
    function togglePause() external onlyOwner {
        if (paused) paused = false;
        else paused = true;

        emit TogglePause(msg.sender, paused);
    }

    //** ======= Events ======= */
    event SetTimeLimited(address sender, bool timelimited);
    event SetTimeBetweenTransfers(address sender, uint256 time);
    event SetPair(address sender, address pair, bool isPair);
    event SetRouter(address sender, address router, bool isRouter);
    event SetBlackListed(address sender, address blacklisted, bool isBlackedlisted);
    event SetWhiteListed(address sender, address whitelisted, bool isWhitelisted);
    event SetExcludeAccount(address sender, address account, bool exclude);
    event SetCaller(address sender, address caller, bool isCaller);
    event TogglePause(address sender, bool paused);
    event SetSalesTax(address sender, uint256 tax);
}