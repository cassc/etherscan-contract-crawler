// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../helpers/STOErrors.sol";
import "./STOTokenCheckpointsUpgradeable.sol";

/// @title STOTokenDividendUpgradeable Dividend Module with all Methods for Handle de Distribution of Dividend of STO Token
/// @custom:security-contact [email protected]
abstract contract STOTokenDividendUpgradeable is
    STOTokenCheckpointsUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    STOErrors
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;

    /// @dev Number of dividend distributions
    uint256 public numberOfDistributions;

    /// @dev Address of STOToken related to these dividends
    ISTOToken public stoRelatedToken;

    /// @dev Address of ERC20 Token used to payout dividends
    IERC20MetadataUpgradeable public paymentToken;

    /// @dev last block at which the user claimed dividends
    mapping(address => uint256) public lastClaimedBlock;

    /// @dev Struc to store the Dividend of STO Token
    struct DividendDistribution {
        /// @dev Total Amount of Dividend
        uint256 totalAmount;
        /// @dev Block number
        uint256 blockNumber;
    }

    /// @dev Mapping of distributions
    mapping(uint256 => DividendDistribution) public dividendDistributions;

    /// Events
    event NewDividendDistribution(address indexed token, uint256 totalAmount);

    event DividendClaimed(
        address indexed claimer,
        address indexed token,
        uint256 amountClaimed
    );

    event NewPaymentToken(
        address indexed OldPaymentToken,
        address indexed NewPaymentToken
    );

    /// @dev Init Dividend Feature
    function __STOTokenDividend_init(
        address stoToken,
        address newPaymentToken,
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        stoRelatedToken = ISTOToken(stoToken);
        paymentToken = IERC20MetadataUpgradeable(newPaymentToken);
        __STOTokenCheckpoints_init(_name, _symbol);
        __Ownable_init();
    }

    /// @dev Method to add a new dividends distribution among STOToken holders
    /// @param _totalAmount Total Amount of Dividend
    function addDistDividend(uint256 _totalAmount) external nonReentrant {
        address currentIssuer = ISTOToken(stoRelatedToken).issuer();
        address caller = _msgSender();

        if (currentIssuer != caller) revert CallerIsNotIssuer(caller);

        if (_totalAmount == 0) revert DividendAmountIsZero();

        /// Safe Transfer
        if (paymentToken.balanceOf(caller) < _totalAmount)
            revert InsufficientBalance(
                currentIssuer,
                address(paymentToken),
                _totalAmount
            );

        SafeERC20Upgradeable.safeTransferFrom(
            paymentToken,
            currentIssuer,
            address(this),
            _totalAmount
        );

        dividendDistributions[numberOfDistributions].totalAmount = _totalAmount;
        dividendDistributions[numberOfDistributions].blockNumber = block.number;

        numberOfDistributions++;

        emit NewDividendDistribution(address(paymentToken), _totalAmount);
    }

    /// @dev Method to Claim Dividend of STO Token
    function claimDividends() external nonReentrant {
        address currentClaimer = _msgSender();

        if (
            trackings(currentClaimer) == address(0) ||
            stoRelatedToken.balanceOf(currentClaimer) == 0 ||
            !stoRelatedToken.whitelist(currentClaimer)
        ) revert NotAvailableToClaim(currentClaimer);

        uint256 _amount = getMaxAmountToClaim(currentClaimer);

        if (_amount > paymentToken.balanceOf(address(this)))
            revert ExceedAmountAvailable(
                currentClaimer,
                paymentToken.balanceOf(address(this)),
                _amount
            );

        SafeERC20Upgradeable.safeTransfer(
            paymentToken,
            currentClaimer,
            _amount
        );

        lastClaimedBlock[currentClaimer] = block.number;

        emit DividendClaimed(currentClaimer, address(paymentToken), _amount);
    }

    /// @dev Method to change the payment token
    /// @dev This method is only available to the owner of the contract
    /// @param _newPaymentToken is the new payment token address
    function changePaymentToken(address _newPaymentToken) external onlyOwner {
		if (!_newPaymentToken.isContract()) revert InvalidPaymentToken(_newPaymentToken);
		emit NewPaymentToken(address(paymentToken), _newPaymentToken);
        paymentToken = IERC20MetadataUpgradeable(_newPaymentToken);
    }

    /// @dev Method to Check getting Max Amount of Dividend to Claim
    /// @param _claimer Address of Claimer of STO Token
    /// @return amount of Dividend to Claim
    function getMaxAmountToClaim(address _claimer)
        public
        view
        returns (uint256 amount)
    {
        uint256 index = getIndexToClaim(_claimer);
        if ((index == type(uint256).max) || (index == numberOfDistributions))
            revert NotAmountToClaim(_claimer);

        for (uint256 i = index; i < numberOfDistributions; i++) {
            uint256 blockNumber = dividendDistributions[i].blockNumber;
            uint256 pastBalance = getPastBalance(
                _claimer,
                dividendDistributions[i].blockNumber
            );
            uint256 pastTotalSupply = getPastTotalSupply(blockNumber);
            uint256 percentage = pastBalance.mulDiv(1 ether, pastTotalSupply);
            amount += percentage.mulDiv(
                dividendDistributions[i].totalAmount,
                1 ether
            );
        }
    }

    /// @dev Method to check the index of where start to claim dividend for the claimer
    /// @param _claimer address of the claimer of STOToken
    /// @return index after the entry point of claimer
    function getIndexToClaim(address _claimer) public view returns (uint256) {
        uint256 lastBlock = lastClaimedBlock[_claimer];
        for (uint256 i = numberOfDistributions - 1; i >= 0; i--) {
            if (dividendDistributions[i].blockNumber < lastBlock) return i + 1;
            if (i == 0) return i;
        }

        return type(uint256).max;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}