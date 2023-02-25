// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Ukiyo is ERC20, ERC20Burnable, Ownable {
    uint256 public Max_Token;
    uint256 decimalfactor;
    uint256 autoLiquidityDistribution;
    uint256[4] public sellBuyTaxAmt = [100, 150, 100, 150];
    uint256 private vestingTotalAmount;
    uint256 public teamVestingAmount;
    uint32 public claimPeriodforTeam = uint32(block.timestamp + 730 days); //use 730 days for main net
    uint8 _decimals;

    address public treasury;
    address public exchange;
    address public IDOSale;
    address public IDOPartners;
    address public strategicPartnersandAdvisors;
    address public vault;
    address public PRWallet;
    address public taxWallet;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) public userInfoforTeam;

    bool public isBotProtectionDisabled;
    uint256 public maxTxnAmount = 324_676 * 10**8;
    uint256 public maxHolding = 781_500 * 10**8;
    mapping(address => bool) public isExempt;

    receive() external payable {}

    constructor(
        address _treasury,
        address _exchange,
        address _IDOSale,
        address _IDOPartners,
        address _strategicPartnersandAdvisors,
        address _vault,
        address _PRWallet,
        address _tax
    ) ERC20("ukiyo Token", "KXO") {
        _decimals = 8;
        decimalfactor = 10**uint256(_decimals);
        Max_Token = 521_000_000 * decimalfactor;
        treasury = _treasury;
        exchange = _exchange;
        IDOSale = _IDOSale;
        IDOPartners = _IDOPartners;
        strategicPartnersandAdvisors = _strategicPartnersandAdvisors;
        vault = _vault;
        PRWallet = _PRWallet;
        taxWallet = _tax;

        mint(treasury, (208_400_000 * decimalfactor)); //40%
        mint(address(this), (88_570_000 * decimalfactor)); //17% 2 years lock
        mint(exchange, (78_150_000 * decimalfactor)); //15%
        mint(IDOSale, (52_100_000 * decimalfactor)); //10% 6 months lock
        mint(IDOPartners, (20_840_000 * decimalfactor)); //4%
        mint(strategicPartnersandAdvisors, (20_840_000 * decimalfactor)); //4%
        mint(vault, (26_050_000 * decimalfactor)); //5%

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        teamVestingAmount = (88_570_000 * decimalfactor);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(
            Max_Token >= (totalSupply() + amount),
            "ERC20: Max Token limit exceeds"
        );
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * treasuryWalletAmount = sellBuyTaxAmt[0]
     * vaultAmount = sellBuyTaxAmt[1]
     * PRWalletAmount = sellBuyTaxAmt[2]
     * tax wallet = sellBuyTaxAmt[3]
     */
    function setSellBuyTaxAmt(uint16[4] memory _sellBuyTaxAmt)
        external
        onlyOwner
    {
        uint16 total = 0;
        for (uint8 i; i < _sellBuyTaxAmt.length; i++) {
            total += _sellBuyTaxAmt[i];
            require(total < 10000, "Invalid TAX");
            sellBuyTaxAmt[i] = _sellBuyTaxAmt[i];
        }
    }

    function _taxDistribution(uint256 _amount)
        internal
        view
        returns (
            uint256 _amountAfterTax,
            uint256 _treasuryWalletAmount,
            uint256 _vaultAmount,
            uint256 _PRWalletAmount,
            uint256 _tax
        )
    {
        _treasuryWalletAmount = (_amount * sellBuyTaxAmt[0]) / 10000; //1%
        _vaultAmount = (_amount * sellBuyTaxAmt[1]) / 10000; //1.5%
        _PRWalletAmount = (_amount * sellBuyTaxAmt[2]) / 10000; //1%
        _tax = (_amount * sellBuyTaxAmt[3]) / 10000; //1.5%

        _amountAfterTax = (_amount -
            (_tax + _vaultAmount + _PRWalletAmount + _treasuryWalletAmount));
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual override {
        require(_amount > 0, "Invalid Amount");

        _check(_sender, _recipient, _amount);

        if (isExcludedFromFee(_sender) || isExcludedFromFee(_recipient)) {
            super._transfer(_sender, _recipient, _amount);
        } else {
            (
                uint256 _userAmt,
                uint256 _treasuryWalletAmount,
                uint256 _vaultAmount,
                uint256 _PRWalletAmount,
                uint256 _tax
            ) = _taxDistribution(_amount);
            uint256 taxAmount = _amount - _userAmt;
            super._transfer(_sender, _recipient, _userAmt);
            super._transfer(_sender, address(this), taxAmount);
            super._transfer(address(this), treasury, _treasuryWalletAmount); // to Treasury Wallet (1%)
            super._transfer(address(this), vault, _vaultAmount); // to vault (1.5%)
            super._transfer(address(this), PRWallet, _PRWalletAmount); // to PR Wallet (1%)
            super._transfer(address(this), taxWallet, _tax); // to tax Wallet (1%)
        }
    }

    function setAmountsforTeam(address _teamAddress) external onlyOwner {
        userInfoforTeam[_teamAddress] = teamVestingAmount;
    }

    function claimforTeam() external {
        require(
            block.timestamp >= claimPeriodforTeam,
            "You Can't claim before 2 years"
        );
        require(
            userInfoforTeam[msg.sender] > 0,
            "Your account is not eligible for vesting amount claims"
        );
        super._transfer(address(this), msg.sender, userInfoforTeam[msg.sender]);
    }

    function _check(
        address from,
        address to,
        uint256 amount
    ) internal view{
        if (!isBotProtectionDisabled) {

            if (!isSpecialAddresses(from, to) && !isExempt[to]) {

                _checkMaxTxAmount(amount);

                _checkMaxHoldingLimit(to, amount);
            }
        }
    }

    function _checkMaxTxAmount(uint256 amount) internal view {
        require(amount <= maxTxnAmount, "Amount exceeds max");
    }

    function _checkMaxHoldingLimit(address to, uint256 amount) internal view {
        require(
            balanceOf(to) + amount <= maxHolding,
            "Max holding exceeded max"
        );
    }

    function isSpecialAddresses(address from, address to)
        public
        view
        returns (bool)
    {
        return (from == owner() ||
            to == owner() ||
            from == address(this) ||
            to == address(this));
    }

    function updateBotProtection(bool status) external onlyOwner {
        isBotProtectionDisabled = status;
    }

    function setMaxTxAmount(uint256 maxTxnAmount_) external onlyOwner {
        maxTxnAmount = maxTxnAmount_;
    }

    function setMaxHolding(uint256 maxHolding_) external onlyOwner {
        maxHolding = maxHolding_;
    }

    function setExempt(address user, bool status) public onlyOwner {
        isExempt[user] = status;
    }
}