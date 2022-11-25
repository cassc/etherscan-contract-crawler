// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
interface ITaxCollector {
    function swapTaxTokens() external returns (bool);

    function updateTaxationAmount(bool, uint256) external;
    function updateManagementTaxationAmount(uint256) external;
}
contract VBTC is IERC20Upgradeable, OwnableUpgradeable {
    /* solhint-disable const-name-snakecase */

    string public constant name = "VBTC Token";
    string public constant symbol = "VBTC";

    uint8 public constant decimals = 18;

    /// @notice Percent amount of tax for the token trade on dex
    uint8 public constant devFundTax = 6;

    /// @notice Percent amount of tax for the token sell on dex
    uint8 public constant taxOnSell = 4;

    /// @notice Percent amount of tax for the token purchase on dex
    uint8 public constant taxOnPurchase = 1;

    /* solhint-disable const-name-snakecase */

    uint256 public constant MAX_SUPPLY = 250_000_000 ether;
    uint256 public totalSupply;
    uint256 public minted;

    address public managementAddress;
    address public taxCollector;

    mapping(address => mapping(address => uint256)) internal allowances;

    /// @dev Official record of token balances for each account
    mapping(address => uint256) internal balances;

    /// @notice A record of each DEX account
    mapping(address => bool) public isDex;

    /// @notice A record of addresses that are not taxed during trades
    mapping(address => bool) private _dexTaxExcempt;

    /// @notice A record of blacklisted addresses
    mapping(address => bool) private _isBlackListed;

    bool public isTradingPaused;

    bool public autoSwapTax;

    event DexAddressUpdated(address indexed dex, bool indexed isDex);
    event TaxExcemptAddressUpdated(address indexed addr, bool indexed isExcempt);
    event TaxCollectorUpdated(address indexed taxCollector);
    event BlacklistUpdated(address indexed user, bool indexed toBlcacklist);
    event MintFor(address indexed user, uint256 indexed amount);
    event TradingPaused(bool indexed paused);
    event ManagmentAddressUpdated(address indexed managmentAddress);
    event BNBWithdrawn(uint256 indexed amount);

    function initialize(
        address _managementAddress,
        address _taxCollectorAddress,
        address _preMintAddress,
        uint256 _preMintAmount
    ) external initializer {
        isTradingPaused = true;

        managementAddress = _managementAddress;
        taxCollector = _taxCollectorAddress;

        _dexTaxExcempt[address(this)] = true;
        _dexTaxExcempt[taxCollector] = true;

        _mint(_preMintAddress, _preMintAmount);

        __Ownable_init();
    }

    function updateDexAddress(address _dex, bool _isDex) external onlyOwner {
        isDex[_dex] = _isDex;
        emit DexAddressUpdated(_dex, _isDex);
    }

    function updateTaxExcemptAddress(address _addr, bool _isExcempt) external onlyOwner {
        _dexTaxExcempt[_addr] = _isExcempt;
        emit TaxExcemptAddressUpdated(_addr, _isExcempt);
    }

    function updateTaxCollector(address _taxCollector) external onlyOwner {
        taxCollector = _taxCollector;
        emit TaxCollectorUpdated(taxCollector);
    }

    function manageBlacklist(address[] calldata users, bool[] calldata _toBlackList)
        external
        onlyOwner
    {
        require(users.length == _toBlackList.length, "VBTC: Array mismatch");

        for (uint256 i; i < users.length; i++) {
            _isBlackListed[users[i]] = _toBlackList[i];
            emit BlacklistUpdated(users[i], _toBlackList[i]);
        }
    }

    function mintFor(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
        emit MintFor(account, amount);
    }

    function pauseTrading(bool _isPaused) external onlyOwner {
        isTradingPaused = _isPaused;
        emit TradingPaused(_isPaused);
    }

    function updateManagementAddress(address _address) external onlyOwner {
        managementAddress = _address;
        emit ManagmentAddressUpdated(_address);
    }

    function withdrawBnb() external onlyOwner {
        address payable to = payable(msg.sender);
        uint256 amount = address(this).balance;
        to.transfer(amount);
        emit BNBWithdrawn(amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }
   function updateAutoSwapTax(bool _autoSwapTax) public onlyOwner {
        autoSwapTax = _autoSwapTax;
    }
    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param _spender The address of the account which may transfer tokens
     * @param _value The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param _to The address of the destination account
     * @param _value The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address _to, uint256 _value) external override returns (bool) {
        _transferTokens(msg.sender, _to, _value);

        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param _from The address of the source account
     * @param _to The address of the destination account
     * @param _value The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool) {
        address spender = msg.sender;
        uint256 currentAllowance = allowances[_from][spender];

        if (spender != _from && currentAllowance != type(uint256).max) {
            require(currentAllowance >= _value, "VBTC: insufficient allowance");

            uint256 newAllowance = currentAllowance - _value;
            allowances[_from][spender] = newAllowance;

            emit Approval(_from, spender, newAllowance);
        }

        _transferTokens(_from, _to, _value);

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     */
    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);

        return true;
    }

    /**
     * @dev Destroys `_amount` tokens from `_from`, deducting from the caller's
     * allowance.
     */
    function burnFrom(address _from, uint256 _amount) external returns (bool) {
        require(_from != address(0), "VBTC: burn from the zero address");
        require(_amount <= allowances[_from][msg.sender], "VBTC: burn amount exceeds allowance");

        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _amount;

        _burn(_from, _amount);

        return true;
    }

    function _burn(address account, uint256 amount) private {
        require(amount <= balances[account], "VBTC: burn amount exceeds balance");

        balances[account] -= amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _transferTokens(
        address src,
        address dst,
        uint256 amount
    ) private {
        require(src != address(0), "VBTC: from address is not valid");
        require(dst != address(0), "VBTC: to address is not valid");

        require(
            !_isBlackListed[src] && !_isBlackListed[dst],
            "VBTC: cannot transfer to/from blacklisted account"
        );

        require(amount <= balances[src], "VBTC: insufficient balance");

        if(_dexTaxExcempt[src] == false) {
            if( isDex[dst] || isDex[src] ) {
                require(!isTradingPaused, "VBTC: only liq transfer allowed");
            }
        }
        if (
        (!isDex[dst] && !isDex[src]) ||
            (_dexTaxExcempt[dst] || _dexTaxExcempt[src]) ||
            src == taxCollector ||
            dst == taxCollector
        ) {
            balances[src] -= amount;
            balances[dst] += amount;

            emit Transfer(src, dst, amount);
        } else {
            require(!isTradingPaused, "VBTC: only liq transfer allowed");

            uint8 taxValue = isDex[src] ? taxOnPurchase : taxOnSell;

            uint256 tax = (amount * taxValue) / 100;
            uint256 teamTax = (amount * devFundTax) / 100;
            bool isBuyAction = isDex[src] ? true : false;

            balances[src] -= amount;

            balances[taxCollector] += tax;

            balances[taxCollector] += teamTax;

            ITaxCollector(taxCollector).updateManagementTaxationAmount(teamTax);
            if (balances[taxCollector] > 0 && !isBuyAction) {
                ITaxCollector(taxCollector).updateTaxationAmount(false, tax);
                if (autoSwapTax) {
                    ITaxCollector(taxCollector).swapTaxTokens();
                }
            } else {
                ITaxCollector(taxCollector).updateTaxationAmount(true, tax);
            }
           

            balances[dst] += (amount - tax - teamTax);

            emit Transfer(src, taxCollector, tax);
            emit Transfer(src, managementAddress, teamTax);
            emit Transfer(src, dst, (amount - tax - teamTax));
        }
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "VBTC: mint to the zero address");
        require(minted + amount <= MAX_SUPPLY, "VBTC: mint amount exceeds max supply");

        totalSupply += amount;
        minted += amount;
        balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }
    function readDexTaxExcempt(address _user) external view returns (bool){
        return _dexTaxExcempt[_user];
    }
}