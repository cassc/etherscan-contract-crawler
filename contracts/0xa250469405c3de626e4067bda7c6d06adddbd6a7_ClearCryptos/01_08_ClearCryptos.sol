// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title ClearCryptos Transparent Upgradeable Proxy
 * @author ClearCryptos Blockchain Team - G3NOM3
 * @dev This contract inherits OpenZeppelin extra secure and audited contracts
 * for implementing the ERC20 standard with fees.
 */
contract ClearCryptos is ERC20Upgradeable, OwnableUpgradeable {

    bool private s_initializedLiquidityProvider;
    bool private s_trading;

    uint8 private s_buyFee;
    uint8 private s_sellFee;
    uint8 private s_transferFee;
    address private s_feeAddress;

    mapping(address => bool) private s_isOperational;
    mapping(address => bool) private s_isLiquidityProvider;

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
    function getFeeState() external view virtual returns (
        uint8,
        uint8,
        uint8,
        address
    ) {
        return (
            s_buyFee,
            s_sellFee,
            s_transferFee,
            s_feeAddress
        );
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
    function isInitializedLiquidityProvider() external view virtual returns (bool) {
        return s_initializedLiquidityProvider;
    }

    /**
     * @dev Checks if the input address is an operations provider.
     *
     * @param _operationalAddress is a possible operations provider's address.
     */
    function isOperational(address _operationalAddress) external view virtual returns (bool) {
        return s_isOperational[_operationalAddress];
    }

    /**
     * @dev Checks if an address is a liquidity provider
     *
     * @param _liquidityprovider is a possible liquidity provider's address
     */
    function isLiquidityProvider(address _liquidityprovider) external view virtual returns (bool) {
        return s_isLiquidityProvider[_liquidityprovider];
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
    function setOperational(address _operationalAddress) external virtual onlyOwner {
        require(_operationalAddress != address(0), "Zero address cannot be operational");
        s_isOperational[_operationalAddress] = true;
    }

    /**
     * @dev Remove Operational Address
     *
     * @param _operationalAddress is an existing operations provider's address.
     */
    function removeOperational(address _operationalAddress) external virtual onlyOwner {
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
    function setLiquidityProvider(address _liquidityProvider) external virtual onlyOwner {
        require(_liquidityProvider != address(0), "Zero address cannot be a liquidity provider");
        s_isLiquidityProvider[_liquidityProvider] = true;
    }

    /**
     * @dev Remove Liquidity Provider / Decentralized Exchange Address.
     *
     * @param _liquidityProvider is an existing liquidity provider's address
     */
    function removeLiquidityProvider(address _liquidityProvider) external virtual onlyOwner {
        delete s_isLiquidityProvider[_liquidityProvider];
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
    function setInitializedLiquidityProvider(bool _initializedLiquidityProvider) external virtual onlyOwner {
        require(s_initializedLiquidityProvider != _initializedLiquidityProvider, "Value already set");
        s_initializedLiquidityProvider = _initializedLiquidityProvider;
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
        require(_buyFee < 20, 'Buy fee needs to be lower than 20%');
        require(_sellFee < 20, 'Sell fee needs to be lower than 20%');
        require(_transferFee < 20, 'Transfer fee needs to be lower than 20%');
        s_buyFee = _buyFee;
        s_sellFee = _sellFee;
        s_transferFee = _transferFee;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to` deducting a fee when necessary.
     * In case of operational transfers, no fee is deducted.
     *
     * In the case of fee deduction, 2 {Transfers} are triggered:
     * 1. from `from` to `s_feeAddress`: `amount` * fee / 100
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
            require(s_initializedLiquidityProvider, 'Liquidity Provider is initializing');

            if (s_isLiquidityProvider[to] || s_isLiquidityProvider[from]) {
                require(s_trading, 'Trading is Paused');
            }

            uint256 currentFee = 0;
            if(s_isLiquidityProvider[from]) {
                currentFee = s_buyFee;
            } else if(s_isLiquidityProvider[to]) {
                currentFee = s_sellFee;
            } else {
                currentFee = s_transferFee;
            }

            if (currentFee != 0) {
                uint256 feeAmount = tempAmount * currentFee / 100;
                super._transfer(from, s_feeAddress, feeAmount);
                tempAmount = tempAmount - feeAmount;
            }
        }

        super._transfer(from, to, tempAmount);
    }

}