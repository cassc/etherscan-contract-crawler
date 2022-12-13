// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSOW is ERC20, Ownable {
    using SafeERC20 for IERC20;

    address public immutable BURN_ADDRESS;
    address public immutable gnosisSafeWallet;
    address public TokenStrategy;
    // Transfer tax rate. (default 0%)
    uint16 public transferTaxRate;

    // Max transfer tax rate: 10%.
    uint16 public immutable MAXIMUM_TRANSFER_TAX_RATE;

    // Max transfer amount rate in basis points. (default is 0.1% of total supply)
    uint16 public maxTransferAmountRate;
    // Addresses that excluded from antiWhale
    mapping(address => bool) public _excludedFromAntiWhale;
    // Addresses that excluded from tax
    mapping(address => bool) public _excludedFromTax;
    mapping(address => bool) public blacklist;

    // Events
    event TransferTaxRateUpdated(address indexed operator, uint previousRate, uint newRate);
    event MaxTransferAmountRateUpdated(address indexed operator, uint previousRate, uint newRate);
    event SetTokenStrategy(address _by, address _TokenStrategy);
    event ExcludedFromAntiWhale(address _account, bool _excluded);
    event ExcludedFromTax(address _account, bool _excluded);
    event InCaseTokensGetStuck(IERC20 _token, uint _amount);

    modifier onlyGnosisSafeWallet() {
        require(gnosisSafeWallet == _msgSender(), "GnosisSafeWallet: caller is not the gnosisSafeWallet");
        _;
    }

    modifier antiWhale(address sender, address recipient, uint amount) {
        if (maxTransferAmount() > 0) {
            if (
                !_excludedFromAntiWhale[sender]
            && !_excludedFromAntiWhale[recipient]
            ) {
                require(amount <= maxTransferAmount(), "Token::antiWhale: Transfer amount exceeds the maxTransferAmount");
            }
        }
        _;
    }

    constructor(address _TokenStrategy, address _gnosisSafeWallet, string memory __name, string memory __symbol)
        ERC20(__name, __symbol) {
        require(_gnosisSafeWallet != address(0));
        _mint(_gnosisSafeWallet, 100_000_000 * 1 ether);
        gnosisSafeWallet = _gnosisSafeWallet;
        BURN_ADDRESS = address(0xdead);
        require(_TokenStrategy != address(0), "Token::constructor: invalid TokenStrategy");
        TokenStrategy = _TokenStrategy;

        transferTaxRate = 0; // 100 = 1%
        MAXIMUM_TRANSFER_TAX_RATE = 1000;
        maxTransferAmountRate = 50;

        _excludedFromAntiWhale[_msgSender()] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;
        _excludedFromAntiWhale[_gnosisSafeWallet] = true;

        _excludedFromTax[_msgSender()] = true;
        _excludedFromTax[_gnosisSafeWallet] = true;
        _excludedFromTax[TokenStrategy] = true;
        _excludedFromTax[address(this)] = true;
        _excludedFromAntiWhale[BURN_ADDRESS] = true;
    }
    function setBlacklist(address _user, bool _status) onlyOwner external {
        blacklist[_user] = _status;
    }
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint amount) internal virtual override antiWhale(sender, recipient, amount) {
        require(!blacklist[sender] && !blacklist[recipient], 'user blacklist');
        if (_excludedFromTax[sender] || recipient == BURN_ADDRESS || transferTaxRate == 0) {
            super._transfer(sender, recipient, amount);
        } else {
            // default tax is 1% of every transfer
            uint taxAmount = taxBaseOnAmount(amount);

            uint sendAmount = amount - taxAmount;

            if(taxAmount > 0) super._transfer(sender, TokenStrategy, taxAmount);

            super._transfer(sender, recipient, sendAmount);
        }
    }

    /**
     * @notice Withdraw unexpected tokens sent to the token contract
     */
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.safeTransfer(msg.sender, amount);
        emit InCaseTokensGetStuck(_token, amount);
    }
    function setTokenStrategy(address _TokenStrategy) external onlyGnosisSafeWallet {
        require(_TokenStrategy != address(0), "Token::constructor: invalid TokenStrategy");
        TokenStrategy = _TokenStrategy;
        emit SetTokenStrategy(_msgSender(), _TokenStrategy);
    }
    function taxBaseOnAmount(uint _transferAmount) public view returns(uint) {
        return _transferAmount * transferTaxRate / 10000;
    }

    /**
     * @dev Returns the max transfer amount.
     */
    function maxTransferAmount() public view returns (uint) {
        return totalSupply() * maxTransferAmountRate / 10000;
    }

    /**
     * @dev Update the transfer tax rate.
     * Can only be called by the gnosisSafeWallet.
     */
    function updateTransferTaxRate(uint16 _transferTaxRate) external onlyGnosisSafeWallet {
        require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "Token::updateTransferTaxRate: Transfer tax rate must not exceed the maximum rate.");
        emit TransferTaxRateUpdated(_msgSender(), transferTaxRate, _transferTaxRate);
        transferTaxRate = _transferTaxRate;
}

    /**
     * @dev Update the max transfer amount rate.
     * Can only be called by the gnosisSafeWallet.
     */function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) external onlyGnosisSafeWallet {
    require(_maxTransferAmountRate <= 10000, "Token::updateMaxTransferAmountRate: Max transfer amount rate must not exceed the maximum rate.");
    emit MaxTransferAmountRateUpdated(_msgSender(), maxTransferAmountRate, _maxTransferAmountRate);
    maxTransferAmountRate = _maxTransferAmountRate;
}

    /**
     * @dev Exclude or include an address from antiWhale.
     * Can only be called by the gnosisSafeWallet.
     */function setExcludedFromAntiWhale(address _account, bool _excluded) external onlyGnosisSafeWallet {
    require(_account != address(0), "Token::setExcludedFromAntiWhale: invalid account");
    _excludedFromAntiWhale[_account] = _excluded;
    emit ExcludedFromAntiWhale(_account, _excluded);
}

    /**
     * @dev Exclude or include an address from tax.
     * Can only be called by the gnosisSafeWallet.
     */
    function setExcludedFromTax(address _account, bool _excluded) external onlyGnosisSafeWallet {
        require(_account != address(0), "Token::setExcludedFromTax: invalid account");
        _excludedFromTax[_account] = _excluded;
        emit ExcludedFromTax(_account, _excluded);
    }

}