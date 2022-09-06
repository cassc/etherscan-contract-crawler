// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @title EarnLabs Subscription contract
/// @author 0xQruz
/// @notice Manage EarnLabs Subscriptions

contract NraeLabSubscriptions is Ownable, Pausable, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                             VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @notice The address of the token contract
    address public TOKEN;

    /// @notice The address of the contract that will be used to verify the passes
    address public VERIFIER;

    /// @notice Mapping of the address to the time of expiration
    mapping(address => uint256) public subscriptions;

    /// @notice address of treasury
    address public TREASURY;

    /// @notice Price of the monthly subscription (in tokens)
    uint256 public MONTHLY_PRICE = 5;

    /// @notice Price of the quarterly subscription (in tokens)
    uint256 public QUARTERLY_PRICE = 12;

    /// @notice Price of the yearly subscription (in tokens)
    uint256 public YEARLY_PRICE = 40;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /// @notice Constructor of the contract
    /// @param _token The address of the token contract
    /// @param _verifier The address of the contract that will be used to verify the passes
    /// @param _treasury The address of the treasury contract
    constructor(
        address _token,
        address _verifier,
        address _treasury
    ) {
        TOKEN = _token;
        VERIFIER = _verifier;
        TREASURY = _treasury;
    }

    /*///////////////////////////////////////////////////////////////
                             PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                             HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the token interface
    function getToken() private view returns (IERC20) {
        return IERC20(TOKEN);
    }

    /// @notice Get length of the subscription type
    function getSubcriptionMonths(uint256 _subType) public pure returns (uint256) {
        if (_subType == 0) return 1;
        else if (_subType == 1) return 3;
        else if (_subType == 2) return 12;
        else return 0;
    }

    /*///////////////////////////////////////////////////////////////
                             SUBSCRIPTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner update the monthly price of a EarnLabs subscription
    /// @param user The authorized user who triggered the update
    /// @param NEW_PRICE The price to subscribe to a EarnLabs pass for 1 month
    event SubscriptionMonthPriceUpdated(address indexed user, uint256 NEW_PRICE);

    /// @notice Emitted after the owner update the quarterly price of a EarnLabs subscription
    /// @param user The authorized user who triggered the update
    /// @param NEW_PRICE The price to subscribe to a EarnLabs pass for 3 months
    event SubscriptionQuarterlyPriceUpdated(address indexed user, uint256 NEW_PRICE);

    /// @notice Emitted after the owner update the yearly price of a EarnLabs subscription
    /// @param user The authorized user who triggered the update
    /// @param NEW_PRICE The price to subscribe to a EarnLabs pass for 1 year
    event SubscriptionYearlyPriceUpdated(address indexed user, uint256 NEW_PRICE);

    /// @notice Emitted after a user has subscribed to a EarnLabs pass
    /// @param user The user who purchased the pass subscription
    /// @param months The amount of month of the subscription
    /// @param price The price paid to subscribe to the pass
    event Subscribed(address indexed user, uint256 months, uint256 price);

    function setSubscriptionMonthlyPrice(uint256 _MONTHLY_PRICE) external onlyOwner {
        require(_MONTHLY_PRICE != 0, 'INVALID_PRICE');
        require(MONTHLY_PRICE != _MONTHLY_PRICE, 'SAME_PRICE');

        MONTHLY_PRICE = _MONTHLY_PRICE;

        emit SubscriptionMonthPriceUpdated(msg.sender, _MONTHLY_PRICE);
    }

    function setSubscriptionQuarterlyPrice(uint256 _QUARTERLY_PRICE) external onlyOwner {
        require(_QUARTERLY_PRICE != 0, 'INVALID_PRICE');
        require(QUARTERLY_PRICE != _QUARTERLY_PRICE, 'SAME_PRICE');

        QUARTERLY_PRICE = _QUARTERLY_PRICE;

        emit SubscriptionQuarterlyPriceUpdated(msg.sender, _QUARTERLY_PRICE);
    }

    function setSubscriptionYearlyPrice(uint256 _YEARLY_PRICE) external onlyOwner {
        require(_YEARLY_PRICE != 0, 'INVALID_PRICE');
        require(YEARLY_PRICE != _YEARLY_PRICE, 'SAME_PRICE');

        YEARLY_PRICE = _YEARLY_PRICE;

        emit SubscriptionYearlyPriceUpdated(msg.sender, _YEARLY_PRICE);
    }

    /// @notice Subscribe to EarnLabs
    /// @param _subType Type of subscription (0: monthly, 1: quarterly, 2: yearly)
    function subscribe(uint256 _subType) external whenNotPaused nonReentrant {
        uint256 months = getSubcriptionMonths(_subType);
        // Check that the user amount of months is valid
        require(months > 0, 'INVALID_SUB_TYPE');
        // check that the user has not an active pass
        require(!hasValidSubscription(msg.sender), 'SUBSCRIPTION_STILL_ACTIVE');
        uint256 totalPrice = 0;
        if (_subType == 0) {
            totalPrice = 1e18 * MONTHLY_PRICE;
        } else if (_subType == 1) {
            totalPrice = 1e18 * QUARTERLY_PRICE;
        } else if (_subType == 2) {
            totalPrice = 1e18 * YEARLY_PRICE;
        }

        // check if the user has sent enough funds to subscribe to the pass
        require(getToken().balanceOf(msg.sender) >= totalPrice, 'INSUFFICIENT_FUNDS');

        // Transfer the funds to the treasury
        bool result = getToken().transferFrom(msg.sender, address(this), totalPrice);
        require(result, 'TRANSFER_FAILED');

        // Update subscriptions
        subscriptions[msg.sender] = block.timestamp + (31 days * months);

        // emit the event
        emit Subscribed(msg.sender, months, totalPrice);
    }

    /// @notice Airdrop function
    /// @param _to The address to send the airdrop to
    /// @param _months The amount of months to airdrop
    function airdrop(address _to, uint256 _months) external nonReentrant onlyOwner {
        // Check that the user amount of months is valid
        require(_months > 0, 'INVALID_SUB_LENGTH');

        // Update subscriptions
        if (subscriptions[_to] < block.timestamp) {
            subscriptions[_to] = block.timestamp + (31 days * _months);
        } else {
            subscriptions[_to] += (31 days * _months);
        }

        emit Subscribed(msg.sender, _months, 0);
    }

    /// @notice Getter function to check validity of subscription
    /// @dev The function will also check if the wallet is holding the EarnLab : Access Pass (ERC721)
    /// @param _user The user to check the validity of the subscription
    /// @return True if the user has a valid subscription, false otherwise
    function hasValidSubscription(address _user) public view returns (bool) {
        return subscriptions[_user] > block.timestamp || IERC721(VERIFIER).balanceOf(_user) != 0;
    }

    /*///////////////////////////////////////////////////////////////
                             TREASURY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner pull the funds to the treasury address
    /// @param user The authorized user who triggered the withdraw
    /// @param treasury The treasury address to which the funds have been sent
    /// @param amount The amount withdrawn
    event TreasuryWithdraw(address indexed user, address treasury, uint256 amount);

    /// @notice Emitted after the owner pull the funds to the treasury address
    /// @param user The authorized user who triggered the withdraw
    /// @param newTreasury The new treasury address
    event TreasuryUpdated(address indexed user, address newTreasury);

    function setTreasury(address _treasury) external onlyOwner {
        // check that the new treasury address is valid
        require(_treasury != address(0), 'INVALID_TREASURY_ADDRESS');
        require(TREASURY != _treasury, 'SAME_TREASURY_ADDRESS');

        // update the treasury
        TREASURY = _treasury;

        // emit the event
        emit TreasuryUpdated(msg.sender, _treasury);
    }

    function withdrawTreasury() external onlyOwner {
        // calc the amount of balance that can be sent to the treasury
        uint256 amount = getToken().balanceOf(address(this));
        require(amount != 0, 'NO_TREASURY');

        // emit the event
        emit TreasuryWithdraw(msg.sender, TREASURY, amount);

        // Transfer to the treasury
        bool success = getToken().transfer(TREASURY, amount);
        require(success, 'WITHDRAW_FAIL');
    }
}