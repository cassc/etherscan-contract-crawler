/**
 *  SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract Z0Token is
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _supplyOwned;

    mapping(address => bool) private _excludedFromTaxes;

    mapping(address => bool) private _pair;

    address private constant _routerAddress =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    address private _mobilityAddress;

    address private _earlyInvestorsAddress;

    address private _strategicReserveAddress;

    address private _donateAddress;

    address private _airdropAddress;

    address private _pledgeAddress;

    uint256 private _assetManagementTax;
    address private _assetManagementTaxAddress;

    uint256 private _marketingTax;
    address private _marketingTaxAddress;

    uint256 private _pledgePoolTax;
    address private _pledgePoolTaxAddress;

    uint256 private _taxSwapThreshold;

    uint256 private constant _MAX_UINT = type(uint256).max;

    uint256 private _maxTransferLimit;

    IUniswapV2Factory private _factory;
    IUniswapV2Router02 private _router;

    bool private _inSwap;

    event AssetManagementTaxAddressChange(
        address indexed from,
        address indexed to
    );

    event MarketingTaxAddressChange(address indexed from, address indexed to);

    event PledgePoolTaxTaxAddressChange(
        address indexed from,
        address indexed to
    );

    event IncludeInTaxes(address indexed account);

    event ExcludeFromTaxes(address indexed account);

    event AddPair(address indexed pairAddress);

    event EnableTransferLimit(uint256 limit);

    event DisableTransferLimit(uint256 limit);

    event TaxSwapThresholdChange(uint256 threshold);

    event TaxesChange(
        uint256 rewardsTax,
        uint256 marketingTax,
        uint256 pledgePoolTax
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        __Ownable_init();

        __UUPSUpgradeable_init();

        _name = name_;
        _symbol = symbol_;

        _mint(_msgSender(), 10000000000 * 10**decimals());

        _maxTransferLimit = _totalSupply;

        _taxSwapThreshold = 1000000 * 10**decimals();

        _router = IUniswapV2Router02(_routerAddress);
        _factory = IUniswapV2Factory(_router.factory());
        addPair(_factory.createPair(address(this), _router.WETH()));

        excludeFromTaxes(address(this));
        excludeFromTaxes(_msgSender());

        _mobilityAddress = 0x55334DD899d09FdbEfb78E39c3A092213358066a;

        excludeFromTaxes(_mobilityAddress);

        _earlyInvestorsAddress = 0x3CAedd5c98914E89c06708309Dd5c85Dee68462b;

        excludeFromTaxes(_earlyInvestorsAddress);

        _strategicReserveAddress = 0x8658D03ab762f9Be3E218C8b500Cb83D27a23baf;
        excludeFromTaxes(_strategicReserveAddress);

        _donateAddress = 0xA6101575075120f6015e064ac552C425f88E5098;
        excludeFromTaxes(_donateAddress);

        _airdropAddress = 0xbBf75d72854411dF9feaE9fa3B27b54a1a7de740;
        excludeFromTaxes(_airdropAddress);

        _pledgeAddress = 0xfbDDD8AB9a3586913c03E89D65f5cA118dD94B2e;
        excludeFromTaxes(_pledgeAddress);

        _assetManagementTax = 0;
        _assetManagementTaxAddress = 0x6f7D6aC77a57AbC700a06c9Bf677585aa57270c4;
        excludeFromTaxes(_pledgePoolTaxAddress);

        _marketingTax = 0;
        _marketingTaxAddress = 0xDB9fFa1673Ea43A471524c6891470Fb339549670;
        excludeFromTaxes(_marketingTaxAddress);

        _pledgePoolTax = 0;
        _pledgePoolTaxAddress = 0x5db34744660Cc33bDF89AF703b1137a73b168B1C;
        excludeFromTaxes(_pledgePoolTaxAddress);

        transfer(
            _mobilityAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 15), 100)
        );

        transfer(
            _earlyInvestorsAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 30), 100)
        );

        transfer(
            _strategicReserveAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 10), 100)
        );

        transfer(
            _donateAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 2), 100)
        );

        transfer(
            _airdropAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 8), 100)
        );

        transfer(
            _pledgeAddress,
            SafeMath.div(SafeMath.mul(_totalSupply, 35), 100)
        );

        enableTransferLimit();
    }

    modifier swapLock() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = SafeMath.add(_totalSupply, amount);
        unchecked {
            _supplyOwned[account] = SafeMath.add(_supplyOwned[account], amount);
        }
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _supplyOwned[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _supplyOwned[account] = SafeMath.sub(accountBalance, amount);

            _totalSupply = SafeMath.sub(_totalSupply, amount);
        }

        emit Transfer(account, address(0), amount);
    }

    function assetManagementTax() public view returns (uint256) {
        return _assetManagementTax;
    }

    function marketingTax() public view returns (uint256) {
        return _marketingTax;
    }

    function pledgePoolTax() public view returns (uint256) {
        return _pledgePoolTax;
    }

    function totalTaxes() public view returns (uint256) {
        return
            SafeMath.add(
                SafeMath.add(_assetManagementTax, _marketingTax),
                _pledgePoolTax
            );
    }

    function taxSwapThreshold() public view returns (uint256) {
        return _taxSwapThreshold;
    }

    function excludedFromTaxes(address account) public view returns (bool) {
        return _excludedFromTaxes[account];
    }

    function pair(address account) public view returns (bool) {
        return _pair[account];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _supplyOwned[account];
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function setAssetManagementTaxAddress(address assetManagementTaxAddress)
        public
        onlyOwner
    {
        address _oldAssetManagementTaxAddress = _assetManagementTaxAddress;

        includeInTaxes(_oldAssetManagementTaxAddress);

        excludeFromTaxes(assetManagementTaxAddress);

        _assetManagementTaxAddress = assetManagementTaxAddress;

        emit AssetManagementTaxAddressChange(
            _oldAssetManagementTaxAddress,
            _assetManagementTaxAddress
        );
    }

    function setMarketingTaxAddress(address marketingTaxAddress)
        public
        onlyOwner
    {
        address _oldMarketingTaxAddress = _marketingTaxAddress;

        includeInTaxes(_oldMarketingTaxAddress);

        excludeFromTaxes(marketingTaxAddress);

        _marketingTaxAddress = marketingTaxAddress;

        emit MarketingTaxAddressChange(
            _oldMarketingTaxAddress,
            _marketingTaxAddress
        );
    }

    function setPledgePoolTaxAddress(address pledgePoolTaxAddress)
        public
        onlyOwner
    {
        address _oldPledgePoolTaxAddress = _pledgePoolTaxAddress;

        includeInTaxes(_oldPledgePoolTaxAddress);

        excludeFromTaxes(pledgePoolTaxAddress);

        _pledgePoolTaxAddress = pledgePoolTaxAddress;

        emit PledgePoolTaxTaxAddressChange(
            _oldPledgePoolTaxAddress,
            _pledgePoolTaxAddress
        );
    }

    function setTaxes(
        uint256 assetManagementTax_,
        uint256 marketingTax_,
        uint256 pledgePoolTax_
    ) public onlyOwner {
        require(
            assetManagementTax_ + marketingTax_ + pledgePoolTax_ <= 10,
            "Total taxes should never be more than 10%."
        );

        _assetManagementTax = assetManagementTax_;
        _marketingTax = marketingTax_;
        _pledgePoolTax = pledgePoolTax_;

        emit TaxesChange(_assetManagementTax, _marketingTax, _pledgePoolTax);
    }

    function includeInTaxes(address account) public onlyOwner {
        if (!_excludedFromTaxes[account]) return;
        _excludedFromTaxes[account] = false;

        emit IncludeInTaxes(account);
    }

    function excludeFromTaxes(address account) public onlyOwner {
        if (_excludedFromTaxes[account]) return;
        _excludedFromTaxes[account] = true;

        emit ExcludeFromTaxes(account);
    }

    function enableTransferLimit() public onlyOwner {
        require(
            _maxTransferLimit == _totalSupply,
            "Transfer limit already enabled"
        );

        _maxTransferLimit = SafeMath.div(_totalSupply, 500);

        emit EnableTransferLimit(_maxTransferLimit);
    }

    function disableTransferLimit() public onlyOwner {
        require(
            _maxTransferLimit != _totalSupply,
            "Transfer limit already disabled"
        );

        _maxTransferLimit = _totalSupply;

        emit DisableTransferLimit(_maxTransferLimit);
    }

    function addPair(address pairAddress) public onlyOwner {
        _pair[pairAddress] = true;

        emit AddPair(pairAddress);
    }

    function setTaxSwapThreshold(uint256 threshold) public onlyOwner {
        _taxSwapThreshold = threshold;

        emit TaxSwapThresholdChange(_taxSwapThreshold);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balanceOf(sender);
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (_inSwap) return _swapTransfer(sender, recipient, amount);

        if (_pair[recipient]) _swapTaxes();

        uint256 assetManagementTaxAmount = 0;
        uint256 marketingTaxAmount = 0;
        uint256 pledgePoolTaxAmount = 0;
        uint256 afterTaxAmount = amount;

        if (
            !_excludedFromTaxes[sender] &&
            !_excludedFromTaxes[recipient] &&
            (!_pair[sender] && !_pair[recipient])
        ) {
            require(
                amount <= _maxTransferLimit,
                "Transfer amount exceeds max transfer limit"
            );

            (
                assetManagementTaxAmount,
                marketingTaxAmount,
                pledgePoolTaxAmount,
                afterTaxAmount
            ) = _calculateTakeTaxes(amount);
        }

        if (assetManagementTaxAmount != 0) {
            _supplyOwned[_assetManagementTaxAddress] = SafeMath.add(
                _supplyOwned[_assetManagementTaxAddress],
                assetManagementTaxAmount
            );
        }

        emit Transfer(
            sender,
            _assetManagementTaxAddress,
            assetManagementTaxAmount
        );

        if (marketingTaxAmount != 0) {
            _supplyOwned[_marketingTaxAddress] = SafeMath.add(
                _supplyOwned[_marketingTaxAddress],
                marketingTaxAmount
            );
        }

        emit Transfer(sender, _marketingTaxAddress, marketingTaxAmount);

        if (pledgePoolTaxAmount != 0) {
            _supplyOwned[_pledgePoolTaxAddress] = SafeMath.add(
                _supplyOwned[_pledgePoolTaxAddress],
                pledgePoolTaxAmount
            );
        }

        emit Transfer(sender, _pledgePoolTaxAddress, pledgePoolTaxAmount);

        _supplyOwned[sender] = SafeMath.sub(_supplyOwned[sender], amount);

        _supplyOwned[recipient] = SafeMath.add(
            _supplyOwned[recipient],
            afterTaxAmount
        );

        emit Transfer(sender, recipient, afterTaxAmount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _swapTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        _supplyOwned[sender] = SafeMath.sub(_supplyOwned[sender], amount);
        _supplyOwned[recipient] = SafeMath.add(_supplyOwned[recipient], amount);

        emit Transfer(sender, recipient, amount);
    }

    function transferTaxes() public onlyOwner {
        uint256 contractBalance = balanceOf(address(this));

        uint256 assetManagementAmount = SafeMath.div(
            (
                SafeMath.mul(
                    SafeMath.mul(contractBalance, 10),
                    _assetManagementTax
                )
            ),
            100
        );

        uint256 marketingAmount = SafeMath.div(
            (SafeMath.mul(SafeMath.mul(contractBalance, 10), _marketingTax)),
            100
        );

        uint256 pledgePoolAmount = SafeMath.div(
            (SafeMath.mul(SafeMath.mul(contractBalance, 10), _pledgePoolTax)),
            100
        );

        _approve(
            address(this),
            _assetManagementTaxAddress,
            assetManagementAmount
        );
        _approve(address(this), _marketingTaxAddress, marketingAmount);
        _approve(address(this), _pledgePoolTaxAddress, pledgePoolAmount);

        _supplyOwned[address(this)] = SafeMath.sub(
            SafeMath.sub(
                SafeMath.sub(contractBalance, assetManagementAmount),
                marketingAmount
            ),
            pledgePoolAmount
        );

        _supplyOwned[_assetManagementTaxAddress] = SafeMath.add(
            _supplyOwned[_assetManagementTaxAddress],
            assetManagementAmount
        );
        _supplyOwned[_marketingTaxAddress] = SafeMath.add(
            _supplyOwned[_marketingTaxAddress],
            marketingAmount
        );
        _supplyOwned[_pledgePoolTaxAddress] = SafeMath.add(
            _supplyOwned[_pledgePoolTaxAddress],
            pledgePoolAmount
        );
    }

    function _swapTaxes() internal swapLock {
        uint256 contractBalance = balanceOf(address(this));

        if (
            contractBalance < _taxSwapThreshold ||
            (_assetManagementTax == 0 && _marketingTax == 0)
        ) return;

        _approve(address(this), address(_router), contractBalance);

        uint256 assetManagementAmount = SafeMath.div(
            (
                SafeMath.mul(
                    SafeMath.mul(contractBalance, 10),
                    _assetManagementTax
                )
            ),
            100
        );

        uint256 marketingAmount = SafeMath.div(
            (SafeMath.mul(SafeMath.mul(contractBalance, 10), _marketingTax)),
            100
        );

        uint256 pledgePoolAmount = SafeMath.div(
            (SafeMath.mul(SafeMath.mul(contractBalance, 10), _pledgePoolTax)),
            100
        );

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();

        _router.swapExactTokensForETH(
            assetManagementAmount,
            0,
            path,
            _assetManagementTaxAddress,
            block.timestamp
        );

        _router.swapExactTokensForETH(
            marketingAmount,
            0,
            path,
            _marketingTaxAddress,
            block.timestamp
        );

        _router.swapExactTokensForETH(
            pledgePoolAmount,
            0,
            path,
            _pledgePoolTaxAddress,
            block.timestamp
        );
    }

    function _calculateTakeTaxes(uint256 amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 assetManagementTaxAmount = SafeMath.div(
            SafeMath.mul(amount, _assetManagementTax),
            100
        );

        uint256 marketingTaxAmount = SafeMath.div(
            SafeMath.mul(amount, _marketingTax),
            100
        );

        uint256 pledgePoolTaxAmount = SafeMath.div(
            SafeMath.mul(amount, _pledgePoolTax),
            100
        );

        uint256 afterTaxAmount = SafeMath.sub(
            SafeMath.sub(
                SafeMath.sub(amount, assetManagementTaxAmount),
                marketingTaxAmount
            ),
            pledgePoolTaxAmount
        );
        return (
            assetManagementTaxAmount,
            marketingTaxAmount,
            pledgePoolTaxAmount,
            afterTaxAmount
        );
    }

    function _takeTaxes(uint256 amount) internal returns (uint256) {
        (
            uint256 assetManagementTaxAmount,
            uint256 marketingTaxAmount,
            uint256 pledgePoolTaxAmount,
            uint256 afterTaxAmount
        ) = _calculateTakeTaxes(amount);

        _supplyOwned[address(this)] = SafeMath.add(
            _supplyOwned[address(this)],
            SafeMath.add(
                SafeMath.add(marketingTaxAmount, pledgePoolTaxAmount),
                assetManagementTaxAmount
            )
        );

        return (afterTaxAmount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function getBlockHash(uint256 blockNumber)
        public
        view
        returns (bytes32 blockHash)
    {
        blockHash = blockhash(blockNumber);
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getCurrentBlockTimestamp()
        public
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    function getCurrentBlockPrevrandao()
        public
        view
        returns (uint256 prevrandao)
    {
        prevrandao = block.prevrandao;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}