/**
 *  SPDX-License-Identifier: MIT
 *  
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@%@#@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@#@@##@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@##@@##@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@##@@###@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@&##@@&###@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@###@@#####@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@###@@@#####&@@@@@@@@@@@@@@@
 *@@@@@@@@@@%###%@@@#####%@@@@@@@@#@@@@@@@
 *@@@@@@@@%####@@@######@@@@@@@@##%@@@@@@@
 *@@@@@@&####@@@#######@@@@@@@@####@@@@@@@
 *@@@@@####@@@%#######@@@@@##@@####@@@@@@@
 *@@@@###@@@@#######@@@@@@&##@@@####@@@@@@
 *@@&##@@@@########@@@@@@@@###@@@#####@@@@
 *@@##@@@@########@@@@@@@@@@####@@@####@@@
 *@&#@@@@########@@@@@@@@@@@@@####&@####@@
 *@%#@@@@########@@@@@@@@@@@@@@%####@####@
 *@@@@@@&########@@@@@@@@@@@@@@@####&####@
 *@@@@@@&########@@@@@@@@@@@@@@@#########@
 *@@@@@@@#########@@@@@@@@@@@@@#########@@
 *@@@@@@@@###########@@@@@@############&@@
 *@@@@@@@@@###########################@@@@
 *@@@@@@@@@@@#######################@@@@@@
 *@@@@@@@@@@@@@@################%@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *
 *
 *  OnlyBurns (OBURN)
 *
 *  Tokenomics:
 *    - BUY:
 *      - 10% To service Wallet
 *    - SELL:
 *      - 10% to the Dead Wallet (burn)
 *    - Transfer wallet to wallet
 *      - NO taxes
 *    - Anti-snipe on first two blocks
 *
 *
 *  Discord: https://discord.gg/onlyburns
**/

pragma solidity 0.8.13;


import "ERC20.sol";
import "Ownable.sol";
import "Address.sol";
import "IUniswapV2Router02.sol";
import "IUniswapV2Factory.sol";

contract OnlyBurns is ERC20, Ownable {
    using Address for address;

    bool private _buyFeePermanentlyDisabled = false;
    bool private _sellFeePermanentlyDisabled = false;
    uint8 private _buyFee = 10;
    uint8 private _previousBuyFee = _buyFee;
    uint8 private _sellFee = 10;
    uint8 private _previousSellFee = _sellFee;
    
    mapping (address => bool) public _dexSwapAddresses;
    mapping (address => bool) private _addressesExemptFromFees;
    mapping (address => bool) private _blacklistedAddresses;

    bool private _dexTradingEnabled = false;
    bool private _tradingEnabled = false;
    uint private _blockAtEnableTrading;

    IUniswapV2Router02 public quickSwapRouter;
    address public quickSwapPair;
    address private _routerAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Quickswap
    address private _serviceWallet = 0x5e1027D4c3e991823Cf30d1f9051E9DB91e2B45C;
    address private _usdc = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    event EnableTrading();
    event RemoveFees();
    event RestoreFees();
    event UpdateServiceWallet(address indexed newAddress);
    event UpdateBuyFee(uint indexed previousBuyFee, uint indexed newBuyFee);
    event UpdateSellFee(uint indexed previousSellFee, uint indexed newSellFee);
    event ExemptAddressFromFees(address indexed newAddress, bool indexed value);
    event AddDexSwapAddress(address indexed pairAddress, bool indexed value);
    event AddOrRemoveUserFromBlacklist(address indexed user, bool indexed blacklisted);
    event dexTradingEnabledOrDisabled(bool indexed enabled);

    // Modifier

    modifier canTransfer(address sender, address recipient) {        
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(!_blacklistedAddresses[sender], "Sender is blacklisted from trading.");
        require(!_blacklistedAddresses[recipient], "Recipient is blacklisted from trading.");
        require(_tradingEnabled || sender == owner() || getAddressExemptFromFees(sender), "Trading is not enabled");
        
        if (!_dexTradingEnabled) {
            require((!_dexSwapAddresses[sender] || _addressesExemptFromFees[recipient]) && (_addressesExemptFromFees[sender] || !_dexSwapAddresses[recipient]), "DEX Trading is currently disabled. You must trade directly through the Only Burns DApp.");
        }

        if(block.number > _blockAtEnableTrading + 3 || sender == owner() || getAddressExemptFromFees(sender)) {
            _;
        }
        else {
            _buyFee = 99;
            _sellFee = 99;
            _;
            _buyFee = _previousBuyFee;
            _sellFee = _previousSellFee;
        }
    }

    // Constructor
    constructor(address initRouterAddress, address initServiceWallet, address initUSDCAddress) ERC20("OnlyBurns", "OBURN") {
        _routerAddress = initRouterAddress;
        _serviceWallet = initServiceWallet;
        _usdc = initUSDCAddress;

        initPair();

        exemptAddressFromFees(owner(), true);
        exemptAddressFromFees(address(this), true);
        exemptAddressFromFees(_serviceWallet, true);

        _mint(owner(), (1 * 10**12) * (10**18));
    }

    // Receive function

    receive() external payable {}

    // Internal

    function applyFees(address sender, address recipient) private view returns (bool) {
        bool dexSwapDetected = _dexSwapAddresses[sender] || _dexSwapAddresses[recipient];
        bool exemptAddressDetected = _addressesExemptFromFees[sender] || _addressesExemptFromFees[recipient];

        if( dexSwapDetected && !exemptAddressDetected ) {
            return true;
        }

        return false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint amount
    ) internal override canTransfer(sender, recipient) {
        if(_buyFeePermanentlyDisabled && _sellFeePermanentlyDisabled) {
            super._transfer(sender, recipient, amount);
        }
        else if(applyFees(sender, recipient)) {
            _tokenTransfer(sender, recipient, amount);
        }
        else {
            super._transfer(sender, recipient, amount);
        }
    }

    function initPair() internal {
        IUniswapV2Router02 _quickSwapRouter = IUniswapV2Router02(_routerAddress);
        address _quickSwapPair = IUniswapV2Factory(_quickSwapRouter.factory()).createPair(
            address(this), 
            _usdc
        );

        quickSwapPair = _quickSwapPair;
        quickSwapRouter = _quickSwapRouter;

        addDexSwapAddress(_quickSwapPair, true);
    }

    // External

    function buyFee() external view returns (uint8) {
        return _buyFee;
    }
    
    function sellFee() external view returns (uint8) {
        return _sellFee;
    }

    // Public

    function enableTrading() public onlyOwner {
        _tradingEnabled = true;
        _blockAtEnableTrading = block.number;

        emit EnableTrading();
    }

    function enableOrDisableDEXTrading(bool dexTradingEnabled) public onlyOwner {
        require(_dexTradingEnabled != dexTradingEnabled, "DEX Trading is already set to the value (true or false) supplied.");
        _dexTradingEnabled = dexTradingEnabled;
        emit dexTradingEnabledOrDisabled(dexTradingEnabled);
    }

    function exemptAddressFromFees(address excludedAddress, bool value) public onlyOwner {
        require(_addressesExemptFromFees[excludedAddress] != value, "Already set to this value");

        _addressesExemptFromFees[excludedAddress] = value;

        emit ExemptAddressFromFees(excludedAddress, value);
    }

    function blacklistOrUnblacklistUser(address user, bool blacklist) public onlyOwner {
        require(user != address(0), "Blacklist user cannot be the zero address.");
        require(_blacklistedAddresses[user] != blacklist, "Already set to this value.");
        _blacklistedAddresses[user] = blacklist;
        emit AddOrRemoveUserFromBlacklist(user, blacklist);
    }

    function getAddressExemptFromFees(address excludedAddress) public view returns (bool) {
        return _addressesExemptFromFees[excludedAddress];
    }

    function getAddressBlacklisted(address blacklistedAddress) public view returns (bool) {
        return _blacklistedAddresses[blacklistedAddress];
    }

    function getDexSwapAddress(address pairAddress) public view onlyOwner returns (bool) {
        return _dexSwapAddresses[pairAddress];
    }

    function removeFees() public onlyOwner {
        require(!_buyFeePermanentlyDisabled || !_sellFeePermanentlyDisabled, "Fees are permanently disabled");

        if (!_buyFeePermanentlyDisabled) {
            _previousBuyFee = _buyFee;
            _buyFee = 0;
        }

        if (!_sellFeePermanentlyDisabled) {
            _previousSellFee = _sellFee;
            _sellFee = 0;
        }

        emit RemoveFees();
    }

    function restoreFees() public onlyOwner {
        require(!_buyFeePermanentlyDisabled || !_sellFeePermanentlyDisabled, "Fees are permanently disabled");

        if(!_buyFeePermanentlyDisabled) 
            _buyFee = _previousBuyFee;

        if(!_sellFeePermanentlyDisabled)
            _sellFee = _previousSellFee;

        emit RestoreFees();
    }

    function serviceWallet() public view returns(address) {
        return _serviceWallet;
    }

    function addDexSwapAddress(address pairAddress, bool value) public onlyOwner {
        require(_dexSwapAddresses[pairAddress] != value, "Address already in-use");
        
        _dexSwapAddresses[pairAddress] = value;
        
        emit AddDexSwapAddress(pairAddress, value);
    }

    function totalSupply() public view virtual override returns (uint) {
        return super.totalSupply() - balanceOf(DEAD);
    }

    function updateBuyFee(uint8 value) public onlyOwner returns(uint8, uint8) {
        require(!_buyFeePermanentlyDisabled, "Buy fee is permanently disabled");
        require(value <= 10, "Cannot be higher than 10");
        require(value < _buyFee, "Cannot increase the fee");

        _previousBuyFee = _buyFee;
        _buyFee = value;

        if(_buyFee == 0)
            _buyFeePermanentlyDisabled = true;

        emit UpdateBuyFee(_previousBuyFee, value);

        return (_buyFee, _previousBuyFee);
    }

    function updateServiceWallet(address newServiceWallet) public onlyOwner {
        require(_serviceWallet != newServiceWallet, "Address is already in-use");

        _addressesExemptFromFees[_serviceWallet] = false; // Restore fee for old Service Wallet
        _addressesExemptFromFees[newServiceWallet] = true; // Exclude new Service Wallet

        _serviceWallet = newServiceWallet;

        emit UpdateServiceWallet(newServiceWallet);
    }

    function updateSellFee(uint8 value) public onlyOwner returns(uint8, uint8) {
        require(!_sellFeePermanentlyDisabled, "Sell fee is permanently disabled");
        require(value <= 10, "Cannot be higher than 10");
        require(value < _sellFee, "Cannot increase the fee");

        _previousSellFee = _sellFee;
        _sellFee = value;

        if(_sellFee == 0)
            _sellFeePermanentlyDisabled = true;

        emit UpdateSellFee(_previousSellFee, value);
        
        return (_sellFee, _previousSellFee);
    }

    // Private

    function _buyTransfer(
        address sender,
        address recipient,
        uint amount
    ) private {
        uint _totalFee = _calculateBuyFee(amount);
        uint _amountWithFee = amount - _totalFee;

        super._transfer(sender, recipient, _amountWithFee); // Send coin to buyer
        super._transfer(sender, _serviceWallet, _totalFee); // Send coin to Service Wallet

        emit Transfer(sender, recipient, amount);
    }

    function _calculateBuyFee(uint amount) private view returns (uint) {
        if (_buyFee == 0)
            return 0;

        return (amount * _buyFee) / 10**10;
    }

    function _calculateSellFee(uint amount) private view returns (uint) {
        if (_sellFee == 0)
            return 0;

        return (amount * _sellFee) / 10**10;
    }

    function _sellTransfer(
        address sender,
        address recipient,
        uint amount
    ) private {
        uint _totalFee = _calculateSellFee(amount);
        uint _amountWithFee = amount - _totalFee;

        super._transfer(sender, recipient, _amountWithFee); // Send coin to seller
        super._transfer(sender, DEAD, _totalFee); // Send coin to Dead Wallet

        emit Transfer(sender, recipient, amount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint amount
    ) private {
        if (_dexSwapAddresses[sender]) {
            _buyTransfer(sender, recipient, amount);
        } else if (_dexSwapAddresses[recipient]) {
            _sellTransfer(sender, recipient, amount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}