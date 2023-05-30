// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {PriceCalculator} from "contracts/sale/PriceCalculator.sol";
import {ISale} from "interfaces/shared/ISale.sol";
import {EarlySaleReceiver} from "abstracts/EarlySaleReceiver.sol";
import {SeedSaleSupplyProvider} from "abstracts/SeedSaleSupplyProvider.sol";

/// @title Contract which allows early investors to deposit ETH to reserve tokens for the upcoming private sale
/// @notice Sends buy orders to the future SpaaceSale contract
/// @notice Doesn't have a whitelist and the exchange rate (USD to $SPAACE) is constant
contract StrategicSale is
    ISale,
    PriceCalculator,
    SeedSaleSupplyProvider,
    AccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Amount {
        uint128 tokens;
        uint128 ethSpent;
    }

    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR");

    uint128 public availableTokens;
    EnumerableSet.AddressSet private _investors;

    mapping(address => Amount) private _investorToAmount;

    EarlySaleReceiver public receiver;

    bool public isClosed = false;

    uint128 private immutable tokenUsdPrice;
    uint128 public immutable MIN_INVESTMENT; // solhint-disable-line var-name-mixedcase
    uint128 public immutable MAX_INVESTMENT; // solhint-disable-line var-name-mixedcase

    event TokenReserved(address indexed investor, uint256 eth, uint256 tokens);
    event SupplyChanged(uint256 availableTokens);

    constructor(
        address _priceFeed,
        uint128 _tokenUsdPrice,
        uint128 _remainingTokens,
        uint128 _minInvestment,
        uint128 _maxInvestment
    ) PriceCalculator(_priceFeed) {
        tokenUsdPrice = _tokenUsdPrice;
        availableTokens = _remainingTokens;
        MIN_INVESTMENT = _minInvestment;
        MAX_INVESTMENT = _maxInvestment;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        emit SupplyChanged(_remainingTokens);
    }

    /**
     * @notice Reserves tokens at the current ETH/USD exchange rate
     */
    function buy() external payable {
        require(!isClosed, "strategic sale is closed");

        require(msg.value >= MIN_INVESTMENT, "minimum investment not reached");

        uint128 eth = _investorToAmount[msg.sender].ethSpent;
        require(
            eth + msg.value <= MAX_INVESTMENT,
            "maximum investment exceeded"
        );

        uint128 tokens = convertEthToTokens(uint128(msg.value));

        uint128 currentSupply = availableTokens;
        require(tokens <= availableTokens, "not enough tokens available");

        _investors.add(msg.sender);
        _investorToAmount[msg.sender].tokens += tokens;
        _investorToAmount[msg.sender].ethSpent += uint128(msg.value);

        currentSupply -= tokens;
        availableTokens = currentSupply;

        emit TokenReserved(msg.sender, msg.value, tokens);
        emit SupplyChanged(currentSupply);
    }

    /**
     * @notice Reduces the available token supply of the sale
     * @param _tokens, amount of $SPAACE reserved
     */
    function reduceSupply(
        uint128 _tokens
    ) external override onlyRole(DEPOSITOR_ROLE) {
        require(!isClosed, "sale is closed");

        uint128 currentSupply = availableTokens;
        require(_tokens <= currentSupply, "not enough tokens available");

        currentSupply -= _tokens;
        availableTokens = currentSupply;

        emit SupplyChanged(currentSupply);
    }

    /**
     * @notice Withdraws the ETH to the caller's address
     * @notice Ends the sale and locks the `buy` function
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isClosed, "sale is already over");
        isClosed = true;

        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "transfer failed");
    }

    /**
     * @notice Initializes the receiver of the tokens buy orders
     * @notice Makes `withdrawAll()` available
     * @notice Contract must implement ERC165 and EarlySaleReceiver
     * @param _address, contract address
     */
    function setReceiver(
        address _address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(receiver) == address(0), "address already set");
        require(
            ERC165Checker.supportsInterface(
                _address,
                type(EarlySaleReceiver).interfaceId
            ),
            "not a compatible receiver"
        );

        receiver = EarlySaleReceiver(_address);
    }

    /**
     * @notice Transfers a batch of buy orders to the receiver contract
     * @notice Can only be called if the receiver address has been set and the sale is closed
     * @param _count, the size of the batch to send
     */
    function sendBuyOrders(
        uint256 _count
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isClosed, "sale should be over");
        require(address(receiver) != address(0), "receiver not set yet");
        require(_count <= _investors.length(), "count above investor count");

        for (uint256 i; i < _count; ++i) {
            address investor = _investors.at(0);

            uint128 tokens = _investorToAmount[investor].tokens;
            uint128 eth = _investorToAmount[investor].ethSpent;
            receiver.earlyDeposit(investor, eth, tokens);

            _investors.remove(investor);
        }
    }

    /**
     * @notice View the number of distinct investors
     */
    function investorCount() external view returns (uint256) {
        return _investors.length();
    }

    /**
     * @notice View the total amount of tokens a user has bought
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint128) {
        return _investorToAmount[_user].tokens;
    }

    /**
     * @notice View the total amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint128) {
        return _investorToAmount[_user].ethSpent;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(SeedSaleSupplyProvider, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice View the price of the token in USD
     */
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_USD_PRICE()
        public
        view
        override(ISale, PriceCalculator)
        returns (uint128)
    {
        return tokenUsdPrice;
    }

    /**
     * @notice View the number of decimals (precision) for `TOKEN_USD_PRICE`
     */
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_USD_PRICE_DECIMALS()
        public
        pure
        override(ISale, PriceCalculator)
        returns (uint8)
    {
        return 18;
    }
}