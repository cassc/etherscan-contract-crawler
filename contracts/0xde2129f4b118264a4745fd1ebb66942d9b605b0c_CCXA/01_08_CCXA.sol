// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

/**
 * @title ClearCryptos Transparent Upgradeable Proxy
 * @author ClearCryptos Blockchain Team - G3NOM3
 * @dev This contract inherits OpenZeppelin extra secure and audited contracts
 * for implementing the ERC20 standard with fees.
 */
contract CCXA is ERC20Upgradeable, OwnableUpgradeable {
    bool private s_initializedLiquidityProvider;
    bool private s_trading;

    uint8 private s_buyFee;
    uint8 private s_sellFee;
    uint8 private s_transferFee;
    address private s_feeAddress;

    mapping(address => bool) private s_isOperational;
    mapping(address => bool) private s_isLiquidityProvider;
    mapping(address => bool) private s_isBlacklisted;

    bool private s_inSwap;
    bool private s_internalSwapEnabled;
    uint256 private s_swapThreshold;

    IUniswapV2Router02 private s_uniswapV2Router;

    mapping(address => uint32) private s_cooldowns;
    mapping(address => bool) private s_cooldownWhitelist;
    uint256 private s_cooldownTime;
    mapping(address => bool) private s_testingAddress;

    modifier lockTheSwap() {
        s_inSwap = true;
        _;
        s_inSwap = false;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _supply
    ) public initializer {
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _supply);
        __Ownable_init();
    }

    /**
     * @dev Returns the current storage values of the fee infrastructure.
     *
     * @return s_buyFee the fee applied in {buy} transactions.
     * @return s_sellFee the fee applied in {sell} transactions.
     * @return s_transferFee the fee applied in {wallet-to-wallet} transactions.
     * @return s_feeAddress the address that collects the fee.
     */
    function getFeeState()
        external
        view
        virtual
        returns (
            uint8,
            uint8,
            uint8,
            address
        )
    {
        return (s_buyFee, s_sellFee, s_transferFee, s_feeAddress);
    }

    /**
     * @dev Returns the current storage value of the trading state.
     *
     * @return s_trading is the trading state.
     */
    function isTrading() external view virtual returns (bool) {
        return s_trading;
    }

    /**
     * @dev If a new liquidity provider is set, the transfers need to be paused to
     * avoid vulnerability exploits and fee issues.
     *
     * @return s_initializedLiquidityProvider is the current liquidity provider initializing state.
     */
    function isInitializedLiquidityProvider()
        external
        view
        virtual
        returns (bool)
    {
        return s_initializedLiquidityProvider;
    }

    /**
     * @dev Checks if the input address is an operations provider.
     *
     * @param _operationalAddress is a possible operations provider's address.
     */
    function isOperational(address _operationalAddress)
        external
        view
        virtual
        returns (bool)
    {
        return s_isOperational[_operationalAddress];
    }

    /**
     * @dev Checks if an address is a liquidity provider
     *
     * @param _liquidityprovider is a possible liquidity provider's address
     */
    function isLiquidityProvider(address _liquidityprovider)
        external
        view
        virtual
        returns (bool)
    {
        return s_isLiquidityProvider[_liquidityprovider];
    }

    /**
     * @dev Checks if an address is blacklisted
     *
     * @param _blacklistedAddress is a possible blacklisted address
     */
    function isBlacklisted(address _blacklistedAddress)
        external
        view
        virtual
        returns (bool)
    {
        return s_isBlacklisted[_blacklistedAddress];
    }

    /**
     * @dev Add Operational Address. This address represents an operations provider like a
     * smart contracts infrastructure (e.g. staking, flash loan etc.)
     *
     * Requirements:
     *
     * - `_operationalAddress` cannot be the zero address.
     *
     * @param _operationalAddress is a new operations provider's address.
     */
    function setOperational(address _operationalAddress)
        external
        virtual
        onlyOwner
    {
        require(
            _operationalAddress != address(0),
            "Zero address cannot be operational"
        );
        s_isOperational[_operationalAddress] = true;
    }

    /**
     * @dev Remove Operational Address
     *
     * @param _operationalAddress is an existing operations provider's address.
     */
    function removeOperational(address _operationalAddress)
        external
        virtual
        onlyOwner
    {
        delete s_isOperational[_operationalAddress];
    }

    /**
     * @dev Add new Liquidity Provider / Decentralized Exchange.
     *
     * Requirements:
     *
     * - `_liquidityProvider` cannot be the zero address.
     *
     * @param _liquidityProvider is a new liquidity provider's address.
     */
    function setLiquidityProvider(address _liquidityProvider)
        external
        virtual
        onlyOwner
    {
        require(
            _liquidityProvider != address(0),
            "Zero address cannot be a liquidity provider"
        );
        s_isLiquidityProvider[_liquidityProvider] = true;
    }

    /**
     * @dev Remove Liquidity Provider / Decentralized Exchange Address.
     *
     * @param _liquidityProvider is an existing liquidity provider's address
     */
    function removeLiquidityProvider(address _liquidityProvider)
        external
        virtual
        onlyOwner
    {
        delete s_isLiquidityProvider[_liquidityProvider];
    }

    /**
     * @dev Add new Blacklisted Address
     *
     * Requirements:
     *
     * - `_blacklistedAddress` cannot be the zero address.
     *
     * @param _blacklistedAddress is a new blacklisted address.
     */
    function setBlacklisted(address _blacklistedAddress)
        external
        virtual
        onlyOwner
    {
        require(
            _blacklistedAddress != address(0),
            "Zero address cannot be blacklisted"
        );
        s_isBlacklisted[_blacklistedAddress] = true;
    }

    /**
     * @dev Remove Blacklisted Address
     *
     * @param _blacklistedAddress is an existing blacklisted address
     */
    function removeBlacklisted(address _blacklistedAddress)
        external
        virtual
        onlyOwner
    {
        delete s_isBlacklisted[_blacklistedAddress];
    }

    /**
     * @dev Set wallet for collecting fees.
     *
     * Requirements:
     *
     * - `_feeAddress` cannot be the zero address.
     *
     * @param _feeAddress is the new address that collects the fees.
     */
    function setFeeAddress(address _feeAddress) external virtual onlyOwner {
        require(_feeAddress != address(0), "Zero address cannot collect fees");
        s_feeAddress = _feeAddress;
    }

    /**
     * @dev Pause / Resume Trading.
     * This feature helps in mitigating unknown vulnerability exploits.
     *
     * Requirements:
     *
     * - `_trading` needs to have a different value from `s_trading`.
     *
     * @param _trading is the new trading state.
     */
    function setTrading(bool _trading) external virtual onlyOwner {
        require(s_trading != _trading, "Value already set");
        s_trading = _trading;
    }

    /**
     * @dev Pause / Resume transfers to initialize new liquidity provider.
     *
     * Requirements:
     *
     * - `_initializedLiquidityProvider` needs to have a different value from `s_initializedLiquidityProvider`.
     *
     * @param _initializedLiquidityProvider is the new liquidity provider initializing state.
     */
    function setInitializedLiquidityProvider(bool _initializedLiquidityProvider)
        external
        virtual
        onlyOwner
    {
        require(
            s_initializedLiquidityProvider != _initializedLiquidityProvider,
            "Value already set"
        );
        s_initializedLiquidityProvider = _initializedLiquidityProvider;
    }

    /**
     * @dev Returns the internal swapping state
     *
     * @return s_internalSwapEnabled is the internal swapping state
     */
    function internalSwapEnabled() external view virtual returns (bool) {
        return s_internalSwapEnabled;
    }

    /**
     * @dev Pause / Resume internal swaps of the fee
     *
     * @param _internalSwapEnabled is the new internal swapping state
     */
    function setInternalSwapEnabled(bool _internalSwapEnabled)
        external
        virtual
        onlyOwner
    {
        require(
            s_internalSwapEnabled != _internalSwapEnabled,
            "Value already set"
        );
        s_internalSwapEnabled = _internalSwapEnabled;
    }

    /**
     * @dev Returns the UniswapV2 router
     *
     * @return s_uniswapV2Router is the UniswapV2 router
     */
    function uniswapV2Router()
        external
        view
        virtual
        returns (IUniswapV2Router02)
    {
        return s_uniswapV2Router;
    }

    /**
     * @dev Set UniswapV2 router for internal swaps
     *
     * @param _uniswapV2Router is the new UniswapV2 router address
     */
    function setUniswapV2Router(address _uniswapV2Router)
        external
        virtual
        onlyOwner
    {
        require(
            _uniswapV2Router != address(0),
            "Zero address cannot be uniswap v2 router"
        );
        s_uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    /**
     * @dev Returns the threshold amount
     *
     * @return s_swapThreshold is the threshold amount
     */
    function swapThreshold() external view virtual returns (uint256) {
        return s_swapThreshold;
    }

    /**
     * @dev Set threshold for internal swaps
     *
     * @param _swapThreshold is the new threshold amount
     */
    function setSwapThreshold(uint256 _swapThreshold)
        external
        virtual
        onlyOwner
    {
        require(_swapThreshold < 400_000e18, "Wrong amount");
        s_swapThreshold = _swapThreshold;
    }

    /**
     * @dev Checks if the input address is an whitelisted regarding cooldown.
     *
     * @param _cooldownWhitelist is a possible cooldown whitelisted address.
     */
    function isCooldownWhitelist(address _cooldownWhitelist)
        external
        view
        virtual
        returns (bool)
    {
        return s_cooldownWhitelist[_cooldownWhitelist];
    }

    /**
     * @dev Whitelist address from the cooldown system
     *
     * @param _cooldownWhitelist is a new whitelisted address
     */
    function setCooldownWhitelist(address _cooldownWhitelist)
        external
        virtual
        onlyOwner
    {
        require(
            _cooldownWhitelist != address(0),
            "Zero address cannot be cooldown whitelist"
        );
        s_cooldownWhitelist[_cooldownWhitelist] = true;
    }

    /**
     * @dev Remove address from the whitelist cooldown system
     *
     * @param _cooldownWhitelist is a possible whitelisted address
     */
    function removeCooldownWhitelist(address _cooldownWhitelist)
        external
        virtual
        onlyOwner
    {
        delete s_cooldownWhitelist[_cooldownWhitelist];
    }

    /**
     * @dev Returns the cooldown time
     *
     * @return s_cooldownTime is the cooldown time
     */
    function cooldownTime() external view virtual returns (uint256) {
        return s_cooldownTime;
    }

    /**
     * @dev MEV / bots attack solution: Set cooldown time for sells and transfers
     *
     * @param _cooldownTime is the new cooldown time
     */
    function setCooldownTime(uint256 _cooldownTime) external virtual onlyOwner {
        require(
            _cooldownTime < 5 minutes,
            "The cooldown time needs to be lower than 5 minutes"
        );
        s_cooldownTime = _cooldownTime;
    }

    /**
     * @dev Set new testing address
     *
     * @param _testingAddress is a new testing address
     */
    function setTestingAddress(address _testingAddress)
        external
        virtual
        onlyOwner
    {
        require(
            _testingAddress != address(0),
            "Zero address cannot be cooldown whitelist"
        );
        s_testingAddress[_testingAddress] = true;
    }

    /**
     * @dev Remove testing address
     *
     * @param _testingAddress is a possible testing address
     */
    function removeTestingAddress(address _testingAddress)
        external
        virtual
        onlyOwner
    {
        delete s_testingAddress[_testingAddress];
    }

    /**
     * @dev Set new fees.
     *
     * Requirements:
     *
     * - `_buyFee` needs to be lower than 20%.
     * - `_sellFee` needs to be lower than 20%
     * - `_transferFee` needs to be lower than 20%
     *
     * @param _buyFee the fee applied in {buy} transactions.
     * @param _sellFee the fee applied in {sell} transactions.
     * @param _transferFee the fee applied in {wallet-to-wallet} transactions.
     */
    function setFee(
        uint8 _buyFee,
        uint8 _sellFee,
        uint8 _transferFee
    ) external virtual onlyOwner {
        require(_buyFee < 20, "Buy fee needs to be lower than 20%");
        require(_sellFee < 20, "Sell fee needs to be lower than 20%");
        require(_transferFee < 20, "Transfer fee needs to be lower than 20%");
        s_buyFee = _buyFee;
        s_sellFee = _sellFee;
        s_transferFee = _transferFee;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to` deducting a fee when necessary.
     * In case of operational transfers, no fee is deducted.
     *
     * In the case of fee deduction, 2 {Transfers} are triggered:
     * 1. from `from` to `contract address`: `amount` * fee / 100
     * 2. from `from` to `to`: `amount` - (`amount` * fee / 100)
     *
     * @param from is the sender address
     * @param to is the recipient address
     * @param amount is the transfered quantity of tokens
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        uint256 tempAmount = amount;
        if (!s_isOperational[from] && !s_isOperational[to]) {
            require(
                !s_isBlacklisted[from] && !s_isBlacklisted[to],
                "The sender or recipient is blacklisted"
            );
            require(
                s_initializedLiquidityProvider,
                "Liquidity Provider is initializing"
            );

            if (s_isLiquidityProvider[to] || s_isLiquidityProvider[from]) {
                require(s_trading, "Trading is Paused");
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overThreshold = contractTokenBalance > s_swapThreshold;

            if (
                s_swapThreshold > 0 &&
                overThreshold &&
                !s_inSwap &&
                !s_isLiquidityProvider[from] &&
                (s_internalSwapEnabled || s_testingAddress[from])
            ) {
                swapTokensForEth(s_swapThreshold);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(contractETHBalance);
                }
            }

            uint256 currentFee = 0;
            if (s_isLiquidityProvider[from]) {
                currentFee = s_buyFee;
            } else if (s_isLiquidityProvider[to]) {
                currentFee = s_sellFee;
            } else {
                currentFee = s_transferFee;
            }

            if (currentFee != 0) {
                uint256 feeAmount = (tempAmount * currentFee) / 100;
                super._transfer(from, address(this), feeAmount);
                tempAmount = tempAmount - feeAmount;
            }
        }

        super._transfer(from, to, tempAmount);
    }

    /**
     * @dev Check to see whether the `from` address is not included in the cooldown whitelist.
     * If not, make sure the cooldown period is not in effect; if it is, stop the transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override {
        if (!s_cooldownWhitelist[from]) {
            require(
                s_cooldowns[from] <= uint32(block.timestamp),
                "Please wait a bit before transferring or selling your tokens."
            );
        }
    }

    /**
     * @dev If the `to` address is not in the cooldown whitelist, add cooldown to it.
     */
    function _afterTokenTransfer(
        address,
        address to,
        uint256
    ) internal virtual override {
        if (!s_cooldownWhitelist[to]) {
            s_cooldowns[to] = uint32(block.timestamp + s_cooldownTime);
        }
    }

    /**
     * @dev function used for internally swap tokens (collected as fee) from within
     * the contract to ETH.
     *
     * @param amountTokens total of tokens used for swap
     */
    function swapTokensForEth(uint256 amountTokens) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = s_uniswapV2Router.WETH();
        _approve(address(this), address(s_uniswapV2Router), amountTokens);
        s_uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountTokens,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev send the ETH from within the contract to the fee wallet
     *
     * @param amountETH total of ETH to be sent to the fee address
     */
    function sendETHToFee(uint256 amountETH) private {
        payable(s_feeAddress).transfer(amountETH);
    }

    /**
     * @dev withdraw tokens from the contract and send to the owner
     *
     * @param amountTokens total of tokens to be withdrawn
     */
    function withdrawTokens(uint256 amountTokens) external virtual onlyOwner {
        require(
            amountTokens <= balanceOf(address(this)) && amountTokens > 0,
            "Wrong amount"
        );
        _transfer(address(this), owner(), amountTokens);
    }

    /**
     * @dev withdraw ETH from the contract and send to the owner
     */
    function withdrawETH() external virtual onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    /**
     * @dev manual swap of tokens from within the contract
     *
     * @param amountTokens total of tokens used for swap
     */
    function manualSwap(uint256 amountTokens) external virtual onlyOwner {
        require(
            amountTokens <= balanceOf(address(this)) &&
                amountTokens > 0 &&
                amountTokens < 45_000e18,
            "Wrong amount"
        );
        swapTokensForEth(amountTokens);
    }

    receive() external payable {}
}