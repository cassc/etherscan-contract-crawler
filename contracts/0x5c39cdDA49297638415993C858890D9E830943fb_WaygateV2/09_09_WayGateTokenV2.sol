//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract WaygateV2 is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 constant NUMERATOR = 1000;
    uint256 private taxRate;
    uint256 public tokensTXLimit;

    mapping(address => uint256) burnWalletPercent;
    mapping(address => uint256) liquidityWalletPercent;
    mapping(address => uint256) developmentWalletPercent;
    mapping(address => uint256) marketingWalletPercent;

    address private BURN_WALLET;
    address private LIQUIDITY_WALLET;
    address private DEVELOPMENT_WALLET;
    address private MARKETING_WALLET;

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalSupply,
        uint256 _taxRate,
        address admin
    ) external initializer {
        require(_taxRate < NUMERATOR, "Taxable: Tax rate too high");
        require(_taxRate <= 200, "Taxable: Tax cannot be greater than 20%");

        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        __Pausable_init();
        _mint(admin, _totalSupply);
        taxRate = _taxRate;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setTaxRate(uint256 _taxRate) public onlyOwner whenNotPaused {
        require(_taxRate < NUMERATOR, "Taxable: Tax rate too high");
        require(_taxRate <= 200, "Taxable: Tax cannot be greater than 20%");
        taxRate = _taxRate;
    }

    function setTransactionLimit(uint256 _tokensTXLimit) public onlyOwner whenNotPaused {
        tokensTXLimit = _tokensTXLimit;
    }
    function getTransactionLimit() public view returns (uint256) {
        return tokensTXLimit;
    }

    function getTaxRate() public view returns (uint256) {
        return taxRate;
    }

    function getTaxRecievers()
        public
        view
        returns (
            address _BURN_WALLET,
            uint _BURN_WALLET_PERCENTAGE,
            address _LIQUIDITY_WALLET,
            uint _LIQUIDITY_WALLET_PERCENTAGE,
            address _DEVELOPMENT_WALLET,
            uint _DEVELOPMENT_WALLET_PERCENTAGE,
            address _MARKETING_WALLET,
            uint __MARKETING_WALLET_PERCENTAGE
        )
    {
        return (
            BURN_WALLET,
            burnWalletPercent[BURN_WALLET],
            LIQUIDITY_WALLET,
            liquidityWalletPercent[LIQUIDITY_WALLET],
            DEVELOPMENT_WALLET,
            developmentWalletPercent[DEVELOPMENT_WALLET],
            MARKETING_WALLET,
            marketingWalletPercent[MARKETING_WALLET]
        );
    }
        function setTaxReceivers(
        address _burnWallet,
        uint256 _burnWalletPercent,
        address _liquidityWallet,
        uint256 _liquidityWalletPercent,
        address _developmentWallet,
        uint256 _developmentWalletPercent,
        address _marketingWallet,
        uint256 _marketingWalletPercent
    ) external onlyOwner whenNotPaused{
        require(
            _burnWallet != address(0) &&
                _liquidityWallet != address(0) &&
                _developmentWallet != address(0) &&
                _marketingWallet != address(0),
            "Taxable: Tax reciever cannot be zero address"
        );
        require(
            _burnWalletPercent +
                _liquidityWalletPercent +
                _developmentWalletPercent +
                _marketingWalletPercent ==
                taxRate,
            "Tax Rate: Percentages Sum must be equal to Tax Rate"
        );
        BURN_WALLET = _burnWallet;
        burnWalletPercent[_burnWallet] = _burnWalletPercent;

        LIQUIDITY_WALLET = _liquidityWallet;
        liquidityWalletPercent[_liquidityWallet] = _liquidityWalletPercent;

        DEVELOPMENT_WALLET = _developmentWallet;
        developmentWalletPercent[
            _developmentWallet
        ] = _developmentWalletPercent;

        MARKETING_WALLET = _marketingWallet;
        marketingWalletPercent[_marketingWallet] = _marketingWalletPercent;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(balanceOf(to) + amount <= MAX_WALLET_SIZE, "TX Limit: Max Wallet Size for WAY Reached" );
        require(
            amount <= tokensTXLimit,
            "TX Limit: Max Tokens TX limit exceeded"
        );
        uint256 _taxAmount;
        uint256 _remainingAmount = amount;
        if (taxRate > 0) {
            require(
                BURN_WALLET != address(0) &&
                    LIQUIDITY_WALLET != address(0) &&
                    DEVELOPMENT_WALLET != address(0) &&
                    MARKETING_WALLET != address(0),
                "Taxable: Tax reciever cannot be zero address"
            );

            _taxAmount =
                (amount * burnWalletPercent[BURN_WALLET]) /
                NUMERATOR;
            _transfer(from, BURN_WALLET, _taxAmount);
            _remainingAmount -= _taxAmount;

            _taxAmount =
                (amount * liquidityWalletPercent[LIQUIDITY_WALLET]) /
                NUMERATOR;
            _transfer(from, LIQUIDITY_WALLET, _taxAmount);
            _remainingAmount -= _taxAmount;

            _taxAmount =
                (amount * developmentWalletPercent[DEVELOPMENT_WALLET]) /
                NUMERATOR;
            _transfer(from, DEVELOPMENT_WALLET, _taxAmount);
            _remainingAmount -= _taxAmount;

            _taxAmount =
                (amount * marketingWalletPercent[MARKETING_WALLET]) /
                NUMERATOR;
            _transfer(from, MARKETING_WALLET, _taxAmount);
            _remainingAmount -= _taxAmount;
        }
        address spender = _msgSender();
        _spendAllowance(from, spender, (amount));
        _transfer(from, to, _remainingAmount);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {}

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    uint private MAX_WALLET_SIZE;
    function setMaxWalletSize(uint _maxWalletSize) external onlyOwner {
        MAX_WALLET_SIZE = _maxWalletSize;
    }
}