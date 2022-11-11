// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./PriceCalculator.sol";
import "../interfaces/shared/ISale.sol";
import "../interfaces/shared/IEarlySaleReceiver.sol";
import "./library/IterableMapping.sol";

/// @title Contract which allows early investors to deposit ETH to reserve STK for the upcoming private sale
/// @notice Sends purchase orders to StaakeSale contract when the Staake team calls `withdrawAll`
contract EarlySale is ISale, PriceCalculator, AccessControl {
    using IterableMapping for IterableMapping.Map;

    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR");

    IEarlySaleReceiver public receiver;

    IterableMapping.Map private investorToAmount;
    mapping(address => uint256) private investorToSpentEth;
    uint256 public availableToken;

    bool public isPublic = true;

    uint256 public immutable MIN_INVESTMENT;
    uint256 public immutable MAX_INVESTMENT;

    event TokenReserved(address indexed owner, uint256 amount, uint256 stk);

    constructor(
        address _priceFeed,
        uint256 _availableToken,
        address[] memory _earlyInvestors,
        uint256 _minInvestment,
        uint256 _maxInvestment
    ) PriceCalculator(_priceFeed) {
        availableToken = _availableToken;
        MIN_INVESTMENT = _minInvestment;
        MAX_INVESTMENT = _maxInvestment;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint8 i; i < _earlyInvestors.length; i++)
            _grantRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Buys STK tokens
     */
    function buy() external payable {
        require(
            isPublic || hasRole(INVESTOR_ROLE, msg.sender),
            "early sale is private"
        );
        require(msg.value >= MIN_INVESTMENT, "amount should be at least 5 ETH");
        require(
            investorToSpentEth[msg.sender] + msg.value <= MAX_INVESTMENT,
            "max investment is 50 ETH"
        );

        uint256 stk = getPriceConversion(msg.value);
        require(stk <= availableToken, "not enough tokens available");

        investorToAmount.increment(msg.sender, stk);
        investorToSpentEth[msg.sender] += msg.value;
        availableToken -= stk;

        emit TokenReserved(msg.sender, msg.value, stk);
    }

    /**
     * @notice Initializes the receiver of the STK buy orders
     * @notice Makes `withdrawAll()` available
     * @notice Contract must implement ERC165 and IEarlySaleReceiver
     * @param _address, contract address
     */
    function setReceiver(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(receiver) == address(0), "address already set");
        require(
            ERC165Checker.supportsInterface(
                _address,
                type(IEarlySaleReceiver).interfaceId
            ),
            "address is not a compatible contract"
        );

        receiver = IEarlySaleReceiver(_address);
    }

    /**
     * @notice Withdraws all the ETH to the caller's wallet
     * @notice Closes the sale on this call order
     * @notice Can only be called if the receiver address has been set
     * @notice Transfers each buy order to the receiver contract
     * @notice This function can only be called ONCE, and the code of this smart contract is self-destroyed right after
     */
    function withdrawAll() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(receiver) != address(0), "receiver not set yet");

        for (uint8 i = 0; i < investorToAmount.size(); i++) {
            address investor = investorToAmount.getKeyAtIndex(i);
            uint256 eth = investorToSpentEth[investor];
            uint256 stk = investorToAmount.get(investor);
            receiver.earlyDeposit(investor, eth, stk);
        }

        selfdestruct(payable(msg.sender));
    }

    /**
     * @notice Allows new addresses to invest (i.e. to call the `buy` function)
     * @param _earlyInvestors, array of addresses of the investors
     */
    function addToWhitelist(address[] memory _earlyInvestors)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint8 i; i < _earlyInvestors.length; i++)
            _grantRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Revoke access to the `buy` function from investors
     * @param _earlyInvestors, array of addresses of the investors
     */
    function removeFromWhitelist(address[] memory _earlyInvestors)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint8 i; i < _earlyInvestors.length; i++)
            _revokeRole(INVESTOR_ROLE, _earlyInvestors[i]);
    }

    /**
     * @notice Toggles whether the sale is public or whitelist-only
     */
    function toggleIsPublic() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPublic = !isPublic;
    }

    /**
     * @notice View the amount of STK a user currently has reserved
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint256) {
        return investorToAmount.get(_user);
    }

    /**
     * @notice View the amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint256) {
        return investorToSpentEth[_user];
    }
}