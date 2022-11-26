// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./PriceCalculator.sol";
import "../../interfaces/shared/ISale.sol";
import "../../interfaces/shared/IEarlySaleReceiver.sol";

/// @title Contract which allows early investors to deposit ETH to reserve STK for the upcoming private sale
/// @notice Sends buy orders to the future StaakeSale contract
contract EarlySale is ISale, PriceCalculator, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR");

    uint256 public availableTokens;
    EnumerableSet.AddressSet private _investors;
    mapping(address => uint256) private _investorToAmount;
    mapping(address => uint256) private _investorToEthSpent;

    IEarlySaleReceiver public receiver;

    bool public isPublic = false;
    bool public isClosed = false;

    uint256 public immutable STK_PRICE_IN_USD;
    uint256 public immutable MIN_INVESTMENT;
    uint256 public immutable MAX_INVESTMENT;

    event TokenReserved(address indexed investor, uint256 eth, uint256 stk);

    constructor(
        address _priceFeed,
        uint256 _stkPriceInUSD,
        uint256 _remainingTokens,
        uint256 _minInvestment,
        uint256 _maxInvestment,
        address[] memory _earlyInvestors
    ) PriceCalculator(_priceFeed) {
        STK_PRICE_IN_USD = _stkPriceInUSD;
        availableTokens = _remainingTokens;
        MIN_INVESTMENT = _minInvestment;
        MAX_INVESTMENT = _maxInvestment;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < _earlyInvestors.length; i++)
            _grantRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice View the price of STK tokens in USD
     */
    function STK_USD_VALUE()
        public
        view
        override(ISale, PriceCalculator)
        returns (uint256)
    {
        return STK_PRICE_IN_USD;
    }

    /**
     * @notice View the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS()
        public
        pure
        override(ISale, PriceCalculator)
        returns (uint8)
    {
        return 18;
    }

    /**
     * @notice Reserves STK tokens at the current ETH/USD exchange rate
     */
    function buy() external payable {
        require(!isClosed, "early sale is closed");
        require(
            isPublic || hasRole(INVESTOR_ROLE, msg.sender),
            "early sale is private"
        );

        require(msg.value >= MIN_INVESTMENT, "amount should be at least 5 ETH");

        uint256 eth = _investorToEthSpent[msg.sender];
        require(eth + msg.value <= MAX_INVESTMENT, "max investment is 500 ETH");

        uint256 stk = getPriceConversion(msg.value);
        require(stk <= availableTokens, "not enough tokens available");

        _investors.add(msg.sender);
        _investorToAmount[msg.sender] += stk;
        _investorToEthSpent[msg.sender] += msg.value;
        availableTokens -= stk;

        emit TokenReserved(msg.sender, msg.value, stk);
    }

    /**
     * @notice Initializes the receiver of the STK buy orders
     * @notice Makes `withdrawAll()` available
     * @notice Contract must implement ERC165 and IEarlySaleReceiver
     * @param _address, contract address
     */
    function setReceiver(
        address _address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(receiver) == address(0), "address already set");
        require(
            ERC165Checker.supportsInterface(
                _address,
                type(IEarlySaleReceiver).interfaceId
            ),
            "address is not a compatible receiver"
        );

        receiver = IEarlySaleReceiver(_address);
    }

    /**
     * @notice Withdraws the ETH to the caller's address
     * @notice Ends the sale and locks the `buy` function
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!isClosed, "sale is already over");
        isClosed = true;
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Transfers a batch of buy orders to the receiver contract
     * @notice Withdraws the ETH to the caller's wallet and self-destructs if there are no buy orders left
     * @notice Ends the sale and locks the `buy` function
     * @notice Can only be called if the receiver address has been set
     */
    function sendBuyOrders(
        uint256 _count
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isClosed, "sale should be over");
        require(address(receiver) != address(0), "receiver not set yet");
        require(_count <= _investors.length(), "count above investor count");

        for (uint256 i = 0; i < _count; i++) {
            address investor = _investors.at(0);

            uint256 stk = _investorToAmount[investor];
            uint256 eth = _investorToEthSpent[investor];
            receiver.earlyDeposit(investor, eth, stk);

            _investors.remove(investor);
        }
    }

    /**
     * @notice Allows new addresses to invest (i.e. to call the `buy` function)
     * @param _earlyInvestors, array of addresses of the investors
     */
    function addToWhitelist(
        address[] calldata _earlyInvestors
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < _earlyInvestors.length; i++)
            _grantRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Revoke access to the `buy` function from investors
     * @param _earlyInvestors, array of addresses of the investors
     */
    function removeFromWhitelist(
        address[] calldata _earlyInvestors
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i; i < _earlyInvestors.length; i++)
            _revokeRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Set whether the sale is public or whitelist-only
     */
    function setIsPublic(bool _isPublic) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPublic = _isPublic;
    }

    /**
     * @notice View the number of distinct investors
     */
    function investorCount() external view returns (uint256) {
        return _investors.length();
    }

    /**
     * @notice View the total amount of STK a user has bought
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint256) {
        return _investorToAmount[_user];
    }

    /**
     * @notice View the total amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint256) {
        return _investorToEthSpent[_user];
    }
}