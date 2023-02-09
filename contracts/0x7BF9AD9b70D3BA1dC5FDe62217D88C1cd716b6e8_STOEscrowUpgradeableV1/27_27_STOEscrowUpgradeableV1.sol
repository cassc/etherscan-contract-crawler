/// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../helpers/STOErrors.sol";
import "../interfaces/IRouter.sol";

/// @title STOEscrowUpgradeable
/// @custom:security-contact [email protected]
contract STOEscrowUpgradeableV1 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    STOErrors
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;

    /// @dev An issuance can be ACTIVE, WITHDRAWN (The issuance was successful and the issuer withdrawn),
    /// ROLLBACK (The issuance was not successful and the issuer has finalized it)
    enum IssuanceStatuses {
        ACTIVE,
        WITHDRAWN,
        ROLLBACK
    }

    /// @dev Issuance struct
    /// @param status Issuance status based on previous enum
    /// @param minTicket Min amount in USD (18 decimals) for issuance participation
    /// @param maxTicket Max amount in USD (18 decimals) for issuance participation
    /// @param startDate Unix timestamp of when the issuance will start
    /// @param endDate Unix timestamp of when the issuance will end
    /// @param hardCap Amount in USD (18 decimals) that can be collected at most
    /// @param softCap Amount in USD (18 decimals) that must be collected at least for an issuance to be succesfull
    /// @param raisedAmount Amount in USD (18 decimals) raised in the issuance so far
    /// @param issuanceAmount Amount of STO tokens issued
    /// @param priceInUSD Price in USD (18 decimals) of each STO token unit -> hardCap / issuanceAmount
    struct Issuance {
        IssuanceStatuses status;
        uint256 minTicket;
        uint256 maxTicket;
        uint256 startDate;
        uint256 endDate;
        uint256 hardCap;
        uint256 softCap;
        uint256 raisedAmount;
        uint256 issuanceAmount;
        uint256 priceInUSD;
    }

    /// @dev Struct to whitelist a new ERC20 token
    /// @param status status to enable or disable the token
    /// @param multiplier Multiplier of ERC20 token (1 ether = 1e18 by default, otherwise specified)
    struct ERC20Token {
        bool status;
        uint256 multiplier;
    }

    /// @dev Investor struct
    /// @param redeemed whether the user has redeemed the STO tokens or not
    /// @param redeemed whether the user has been refunded or not
    /// @param amountInPaymentToken Amount of payment Token used to buy STO tokens in the issuance
    /// @param amountInSTO Amount of STO tokens estimated in this issuance
    struct Investor {
        bool redeemed;
        bool refunded;
        uint256 amountInPaymentToken;
        uint256 amountInSTO;
    }

    /// @dev Address of the STO token related to this escrow service
    ISTOToken public stoRelatedToken;

    /// @dev Address of the ERC20 token used for the issuer to withdraw the funds or investors being refunded
    IERC20MetadataUpgradeable public paymentToken;

    /// @dev Address of Uniswap v2 router to swap whitelisted ERC20 tokens to paymentToken
    IRouter public router;

    /// @dev Address of the issuer of new STO token offerings
    address public issuer;

    ///@dev Treasury address
    address public treasuryAddress;

    /// @dev Array of Address ERC20 Token Whitelisted
    address[] private tokensERC20;

    /// @dev Fee for each withdraw in payment Token in each issuance. (from 1 to 10000, equivalent to 0.01% to 100%)
    uint256 public withdrawalFee;

    /// @dev Index of latest issuance
    uint256 public issuanceIndex;

    /// @dev Max fee limit in order to guarantee that fees for each withdraw doesn't exceed 100%
    uint256 public constant MAX_FEE_LIMIT = 1e4;

    /// @dev Mapping of ERC20 whitelisted tokens
    mapping(address => ERC20Token) public tokenERC20Whitelist;

    /// @dev Issuances by issuance index
    mapping(uint256 => Issuance) public issuances;

    /// @dev Issuance Index ---> Address of investor ---> Investor struct
    mapping(uint256 => mapping(address => Investor)) public investors;

    /// Events

    /// @dev Event to signal that a new offering has been created
    /// @param issuanceIndex index of the new issuance
    /// @param issuance Initial struct of the new issuance
    event NewOffering(uint256 indexed issuanceIndex, Issuance issuance);

    /// @dev Event to signal that the list of whitelisted ERC20 tokens has changed
    /// @param issuer Issuer address
    /// @param token Array of ERC20 tokens where whitelist changed
    /// @param multiplier Array of multipliers applied to each ERC20 token
    /// @param status Array of statuses applied to each ERC20 token
    event ERC20Whitelisted(
        address indexed issuer,
        address[] token,
        uint256[] multiplier,
        bool[] status
    );

    /// @dev Event to signal that an user redeemed his tokens
    /// @param investor User address
    /// @param issuanceIndex Index of the issuance
    /// @param amountInSTO Amount of STO token redeemed
    event Redeemed(
        address indexed investor,
        uint256 indexed issuanceIndex,
        uint256 indexed amountInSTO
    );

    /// @dev Event to signal that an user has been refunded
    /// @param investor User address
    /// @param issuanceIndex Index of the issuance
    /// @param amountInPaymentToken Amount of payment Token equivalent to the user investment that has been refunded
    event Refunded(
        address indexed investor,
        uint256 indexed issuanceIndex,
        uint256 indexed amountInPaymentToken
    );

    /// @dev Event to signal that an user made an offer to buy STO tokens
    /// @param investor User address
    /// @param ERC20Token ERC20 token used by the user
    /// @param issuanceIndex Index of the issuance
    /// @param amountInPaymentToken Amount of payment Token offered by the user
    event TicketOffered(
        address indexed investor,
        address indexed ERC20Token,
        uint256 indexed issuanceIndex,
        uint256 amountInPaymentToken
    );

    /// @dev Event to signal that the issuer has withdrawn all the funds collected in the issuance
    /// @param issuer Issuer address
    /// @param issuanceIndex Index of the issuance
    /// @param fee Brickken success fee (amount of paymentToken)
    /// @param amountInPaymentToken Amount of payment Token raised in the issuance
    event Withdrawn(
        address indexed issuer,
        uint256 indexed issuanceIndex,
        uint256 fee,
        uint256 indexed amountInPaymentToken
    );

    /// @dev Event to signal that an issuance has entered into rollback state, funds will be refunded
    /// @param issuer Issuer address
    /// @param issuanceIndex Index of the issuance
    /// @param amountInPaymentToken Amount of payment Token raised during the issuance
    event RollBack(
        address indexed issuer,
        uint256 indexed issuanceIndex,
        uint256 indexed amountInPaymentToken
    );

    /// @dev Event to signal that the issuer has changed
    /// @param issuer New issuer address
    event ChangeIssuer(address indexed issuer);

    /// @dev Event to signal that the payment Token address changed
    /// @param newPaymentTokenAddress payment Token address
    event ChangePaymentTokenAddress(address indexed newPaymentTokenAddress);

    /// @dev Event to signal that the router changed address
    /// @param newRouterAddress New router address
    event ChangeRouterAddress(address indexed newRouterAddress);

    /// @dev Event to signal that the success fee has changed, (from 1 to 10000, equivalent to 0.01% to 100%)
    /// @param oldFee Old fee percentage
    /// @param newFee New fee percentage
    event ChangeWithdrawalFee(uint256 indexed oldFee, uint256 indexed newFee);

    /// @dev Event to signal that the treasury address has changed
    /// @param oldTreasuryAddress Old treasury address
    /// @param newTreasuryAddress New treasury address
    event ChangeTreasuryAddress(
        address indexed oldTreasuryAddress,
        address indexed newTreasuryAddress
    );

    /// @dev modifier for check if the address is the issuer of the STO Escrow
    modifier onlyIssuer() {
        if (_msgSender() != issuer) revert CallerIsNotIssuer(_msgSender());
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _stoToken,
        address _newIssuer,
        address _owner,
        address _paymentToken,
        address _router,
        address _treasuryAddress
    ) public initializer {
        ///Prevent anyone from reinitializing the contract
        if (owner() != address(0) && _msgSender() != owner())
            revert CallerIsNotOwner(_msgSender());

        /// Prevent to initialize the contract with a zero address
        if (
            _stoToken == address(0) ||
            _newIssuer == address(0) ||
            _paymentToken == address(0) ||
            _router == address(0) ||
            _treasuryAddress == address(0)
        ) revert NotZeroAddress();

        /// Prevent to initialize the contract with not Contract Address
        if (
            !AddressUpgradeable.isContract(_stoToken) ||
            !AddressUpgradeable.isContract(_paymentToken) ||
            !AddressUpgradeable.isContract(_router)
        ) revert NotContractAddress();

        __ReentrancyGuard_init();
        __Ownable_init_unchained();
        _transferOwnership(_owner);

        stoRelatedToken = ISTOToken(_stoToken);
        paymentToken = IERC20MetadataUpgradeable(_paymentToken);

        //Automatically add the payment Token as mean of payment with 1 as multiplier
        tokenERC20Whitelist[address(paymentToken)].status = true;
        tokenERC20Whitelist[address(paymentToken)].multiplier = 1 ether;

        router = IRouter(_router);
        issuer = _newIssuer;
        treasuryAddress = _treasuryAddress;
        withdrawalFee = 300; /// 3%
    }

    /// @dev Method to change the issuer of the contract
    /// @param newIssuer The new issuer
    function changeIssuer(address newIssuer) external onlyOwner {
        issuer = newIssuer;

        emit ChangeIssuer(issuer);
    }

    /// @dev Method to change the payment Token related to this escrow contract
    /// @param newPaymentToken Address of new payment token
    /// This function should not be called with an active issuance going on
    function setPaymentToken(address newPaymentToken) external onlyOwner {
        tokenERC20Whitelist[address(paymentToken)].status = false;
        tokenERC20Whitelist[address(newPaymentToken)].status = true;
        tokenERC20Whitelist[address(newPaymentToken)].multiplier = 1 ether;

        paymentToken = IERC20MetadataUpgradeable(newPaymentToken);
        emit ChangePaymentTokenAddress(newPaymentToken);
    }

    /// @dev Method to change the Uniswap router address
    /// @param newRouter Address of the new router contract
    /// This function should not be called with an active issuance going on
    function setRouter(address newRouter) external onlyOwner {
        if (newRouter == address(0)) revert NotZeroAddress();
        if (!AddressUpgradeable.isContract(newRouter))
            revert NotContractAddress();
        address oldRouter = address(router);
        router = IRouter(newRouter);
        for (uint256 i = 0; i < tokensERC20.length; i++) {
            IERC20MetadataUpgradeable _token = IERC20MetadataUpgradeable(
                tokensERC20[i]
            );

            uint256 oldAllowance = _token.allowance(address(this), oldRouter);

            if (oldAllowance > 0) {
                SafeERC20Upgradeable.safeApprove(_token, oldRouter, 0);
            }

            uint256 currentAllowance = _token.allowance(
                address(this),
                address(router)
            );

            if (currentAllowance != type(uint256).max) {
                SafeERC20Upgradeable.safeApprove(
                    _token,
                    address(router),
                    type(uint256).max - currentAllowance
                );
            }
        }
        emit ChangeRouterAddress(newRouter);
    }

    /// @dev Method to change the list of whitelisted ERC20 tokens
    /// @param tokensToChange Array of ERC20 tokens to be changed in the whitelist
    /// @param multipliers Array of multipliers for each ERC20 token
    /// @param statuses Array of statuses for each ERC20 token
    function changeWhitelist(
        address[] calldata tokensToChange,
        uint256[] calldata multipliers,
        bool[] calldata statuses
    ) external onlyOwner {
        for (uint256 i = 0; i < tokensToChange.length; i++) {
            if (multipliers[i] == 0) revert InitialValueWrong(issuer);

            if (!tokensToChange[i].isContract())
                revert AddressIsNotContract(tokensToChange[i], issuer);

            if (!isTokenERC20(tokensToChange[i]))
                tokensERC20.push(tokensToChange[i]);

            uint256 allowance = IERC20Upgradeable(tokensToChange[i]).allowance(
                address(this),
                address(router)
            );

            if (statuses[i] && allowance != type(uint256).max) {
                SafeERC20Upgradeable.safeIncreaseAllowance(
                    IERC20Upgradeable(tokensToChange[i]),
                    address(router),
                    type(uint256).max - allowance
                );
            } else {
                SafeERC20Upgradeable.safeDecreaseAllowance(
                    IERC20Upgradeable(tokensToChange[i]),
                    address(router),
                    allowance
                );
            }

            tokenERC20Whitelist[tokensToChange[i]].status = statuses[i];
            tokenERC20Whitelist[tokensToChange[i]].multiplier = multipliers[i];
        }

        emit ERC20Whitelisted(issuer, tokensToChange, multipliers, statuses);
    }

    /// @dev Method to change the withdrawal fee (success fee)
    /// @param newFee Fee to be charged for withdrawal
    function changeWithdrawalFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_FEE_LIMIT) revert FeeOverLimits(newFee);
        uint256 oldFee = withdrawalFee;
        withdrawalFee = newFee;

        emit ChangeWithdrawalFee(oldFee, newFee);
    }

    /// @dev Method to change the treasury address
    /// @param _newTreasuryAddress Address of the new treasury
    function changeTreasuryAddress(
        address _newTreasuryAddress
    ) external onlyOwner {
        emit ChangeTreasuryAddress(treasuryAddress, _newTreasuryAddress);
        treasuryAddress = _newTreasuryAddress;
    }

    /// @dev Method to start a new offering
    /// @param newIssuance Struct with all the data of the new issuance
    function newOffering(Issuance memory newIssuance) external onlyIssuer {
        address caller = _msgSender();

        if (
            (issuanceIndex != 0) &&
            !(isWithdrawn(issuanceIndex) || isRollback(issuanceIndex))
        ) revert IssuanceNotFinalized(caller);

        if (
            newIssuance.maxTicket < newIssuance.minTicket ||
            newIssuance.startDate < block.timestamp ||
            newIssuance.endDate <= newIssuance.startDate ||
            newIssuance.hardCap < newIssuance.softCap ||
            newIssuance.raisedAmount != 0 ||
            newIssuance.issuanceAmount == 0 ||
            newIssuance.priceInUSD !=
            newIssuance.hardCap.mulDiv(1 ether, newIssuance.issuanceAmount)
        ) revert InitialValueWrong(caller);

        if (
            stoRelatedToken.maxSupply() > 0 &&
            newIssuance.issuanceAmount >
            (stoRelatedToken.maxSupply() - stoRelatedToken.totalSupply())
        ) revert MaxSupplyExceeded();

        issuanceIndex++;

        issuances[issuanceIndex] = Issuance({
            status: IssuanceStatuses.ACTIVE,
            minTicket: newIssuance.minTicket,
            maxTicket: newIssuance.maxTicket,
            startDate: newIssuance.startDate,
            endDate: newIssuance.endDate,
            hardCap: newIssuance.hardCap,
            softCap: newIssuance.softCap,
            raisedAmount: 0,
            issuanceAmount: newIssuance.issuanceAmount,
            priceInUSD: newIssuance.priceInUSD
        });

        emit NewOffering(issuanceIndex, issuances[issuanceIndex]);
    }

    /// @dev Method to finalize an issuance
    /// @dev Only the issuer or the owner can finalize it
    function finalizeIssuance() external nonReentrant {
        address caller = _msgSender();

        if (caller != issuer && caller != owner())
            revert CallerIsNotOwner(caller);

        _checkIssuanceCompleteness(caller, issuanceIndex);

        if (isSuccess(issuanceIndex)) {
            _withdraw();
        } else if (!isSuccess(issuanceIndex)) {
            _rollBack();
        }
    }

    /// @dev Method for the user to either redeem the STO tokens or be refunded in paymentTokens
    function getTokens(uint256 index) external nonReentrant {
        address caller = _msgSender();

        _checkIssuanceCompleteness(caller, index);

        if (isSuccess(index)) {
            _redeemToken(index);
        } else {
            _refundToken(index);
        }
    }

    /// @dev Method to offer a ticket in the current issuance
    /// @param tokenUsed ERC20 token to be used to buy the ticket
    /// @param amountOfTokens Amount of tokens to offer, exchanged for paymentToken. Decimals are the ones of the `tokenUsed`.
    function buyToken(
        address tokenUsed,
        uint256 amountOfTokens
    ) external nonReentrant {
        address caller = _msgSender();
        uint256 actualAmount;

        _checkValidStatus(caller, tokenUsed);

        // Auxiliary variables useful for the calculations
        uint256 paymentTokenScale = 10 ** paymentToken.decimals();
        uint256 stoRelatedTokenScale = 10 ** stoRelatedToken.decimals();

        if (tokenUsed != address(paymentToken)) {
            uint256 priceInPaymentToken = getPriceInPaymentToken(tokenUsed)
                .mulDiv( // Price in payment Token of the ERC20 used
                tokenERC20Whitelist[tokenUsed].multiplier, /// Discount the Price in case of BKN token
                1 ether,
                MathUpgradeable.Rounding.Up
            ); /// Rounding Up

            uint256 amountOfPaymentTokens = amountOfTokens.mulDiv( // Amount of paymentTokens equivalent to the amount passed in
                priceInPaymentToken,
                10 ** IERC20MetadataUpgradeable(tokenUsed).decimals(),
                MathUpgradeable.Rounding.Down
            ); ///Rounding Down

            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(tokenUsed),
                caller,
                address(this),
                amountOfTokens
            );

            uint256 previewBalance = paymentToken.balanceOf(address(this));

            _swapTokensForTokens(
                tokenUsed,
                amountOfTokens,
                amountOfPaymentTokens
            );

            uint256 balance = paymentToken.balanceOf(address(this));

            //Slippage user protection must be tested
            /*
                if (
                    (balance - previewBalance) <
                    amountOfPaymentTokens.sub(
                        amountOfPaymentTokens.mulDiv(
                            3,
                            1000,
                            MathUpgradeable.Rounding.Up
                        )
                    )
                )
                    revert SwapFailure(
                        caller,
                        _tokenERC20,
                        priceInPaymentToken,
                        balance - previewBalance
                    );
            */
            actualAmount = balance - previewBalance;

            _validateInputs(actualAmount, caller);
        } else {
            actualAmount = amountOfTokens;

            _validateInputs(actualAmount, caller);

            SafeERC20Upgradeable.safeTransferFrom(
                IERC20MetadataUpgradeable(tokenUsed),
                caller,
                address(this),
                actualAmount
            );
        }

        /// Logic to store the ticket to the investor
        if (!isInvestor(issuanceIndex, caller)) {
            investors[issuanceIndex][caller] = Investor({
                redeemed: false,
                refunded: false,
                amountInPaymentToken: actualAmount,
                amountInSTO: actualAmount
                    .mulDiv(
                        stoRelatedTokenScale,
                        paymentTokenScale,
                        MathUpgradeable.Rounding.Up
                    )
                    .mulDiv(
                        stoRelatedTokenScale,
                        issuances[issuanceIndex].priceInUSD,
                        MathUpgradeable.Rounding.Down
                    )
            });
        } else {
            uint256 newAmount = investors[issuanceIndex][caller]
                .amountInPaymentToken
                .add(actualAmount);
            investors[issuanceIndex][caller].amountInPaymentToken = newAmount;
            investors[issuanceIndex][caller].amountInSTO = newAmount
                .mulDiv(
                    stoRelatedTokenScale,
                    paymentTokenScale,
                    MathUpgradeable.Rounding.Up
                )
                .mulDiv(
                    stoRelatedTokenScale,
                    issuances[issuanceIndex].priceInUSD,
                    MathUpgradeable.Rounding.Down
                );
        }

        issuances[issuanceIndex].raisedAmount += actualAmount.mulDiv(
            stoRelatedTokenScale,
            paymentTokenScale,
            MathUpgradeable.Rounding.Up
        );

        emit TicketOffered(
            caller,
            tokenUsed,
            issuanceIndex,
            investors[issuanceIndex][caller].amountInPaymentToken
        );
    }

    /// @dev Method to getting the token Whitelisted
    /// @return result Array of whitelisted ERC20 tokens
    function getAllTokenERC20Whitelist()
        external
        view
        returns (address[] memory result)
    {
        uint256 index;
        for (uint256 i = 0; i < tokensERC20.length; i++) {
            if (tokenERC20Whitelist[tokensERC20[i]].status) {
                index++;
            }
        }
        result = new address[](index);
        index = 0;
        for (uint256 i = 0; i < tokensERC20.length; i++) {
            if (tokenERC20Whitelist[tokensERC20[i]].status) {
                result[index] = tokensERC20[i];
                index++;
            }
        }
    }

    /// Helpers

    /// @dev Method to estimate how many STO tokens are received based on amountOfTokens of tokenUsed
    /// @param tokenUsed Address of the ERC20 token used
    /// @param amountOfTokens Amount of tokenUsed tokens
    /// @return expectedAmount Amount of STO tokens expected to be received
    function getEstimationSTOToken(
        address tokenUsed,
        uint256 amountOfTokens
    ) public view returns (uint256 expectedAmount) {
        uint256 actualAmount;

        _checkValidStatus(_msgSender(), tokenUsed);

        uint256 paymentTokenScale = 10 ** paymentToken.decimals();
        uint256 stoRelatedTokenScale = 10 ** stoRelatedToken.decimals();

        if (tokenUsed != address(paymentToken)) {
            uint256 priceInPaymentToken = getPriceInPaymentToken(tokenUsed)
                .mulDiv( // Price in payment Token of the ERC20 used
                tokenERC20Whitelist[tokenUsed].multiplier, /// Discount the Price in case of BKN token
                1 ether,
                MathUpgradeable.Rounding.Up
            ); /// Rounding Up

            uint256 amountOfPaymentTokens = amountOfTokens.mulDiv( // Amount of paymentTokens equivalent to the amount passed in
                priceInPaymentToken,
                10 ** IERC20MetadataUpgradeable(tokenUsed).decimals(),
                MathUpgradeable.Rounding.Down
            ); ///Rounding Down

            actualAmount = amountOfPaymentTokens;
        } else {
            actualAmount = amountOfTokens;
        }
        expectedAmount = actualAmount
            .mulDiv(
                stoRelatedTokenScale,
                paymentTokenScale,
                MathUpgradeable.Rounding.Up
            )
            .mulDiv(
                stoRelatedTokenScale,
                issuances[issuanceIndex].priceInUSD,
                MathUpgradeable.Rounding.Down
            ); ///Rounding Down
    }

    /// @dev Method to validate it tokenContract is part of the list of whitelisted ERC20 tokens
    /// @param tokenContract is the ERC20 contract to validate
    /// @return flag indicating if the token is whitelisted
    function isTokenERC20(address tokenContract) public view returns (bool) {
        for (uint256 i = 0; i < tokensERC20.length; i++) {
            if (tokensERC20[i] == tokenContract) {
                return true;
            }
        }
        return false;
    }

    /// @dev Method to validate if an issuance has started
    /// @param issuanceIndexQueried Index of the issuance
    /// @return True if the issuance started
    function isStarted(
        uint256 issuanceIndexQueried
    ) public view returns (bool) {
        return block.timestamp >= issuances[issuanceIndexQueried].startDate;
    }

    /// @dev Method to validate if an issuance has ended
    /// @param issuanceIndexQueried Index of the issuance
    /// @return True if the issuance ended
    function isEnded(uint256 issuanceIndexQueried) public view returns (bool) {
        return block.timestamp >= issuances[issuanceIndexQueried].endDate;
    }

    /// @dev Method to validate if an issuance is active
    /// @param issuanceIndexQueried Index of the issuance
    /// @return True if the issuance is active
    function isActive(uint256 issuanceIndexQueried) public view returns (bool) {
        return
            isStarted(issuanceIndexQueried) && !isEnded(issuanceIndexQueried);
    }

    /// @dev Method to validate if an issuance was succesfull
    /// @param issuanceIndexQueried Index of the issuance
    /// @return True if the issuance was succesfull
    function isSuccess(
        uint256 issuanceIndexQueried
    ) public view returns (bool) {
        return
            issuances[issuanceIndexQueried].raisedAmount >= issuances[issuanceIndexQueried].softCap;
    }

    /// @dev Method validate if the issuance is in rollback state
    /// @param issuanceIndexQueried Index of the Issuance Process
    /// @return True if the issuance is in rollback state
    function isRollback(
        uint256 issuanceIndexQueried
    ) public view returns (bool) {
        return
            issuances[issuanceIndexQueried].status == IssuanceStatuses.ROLLBACK;
    }

    /// @dev Method to validate if the issuance reached hardCap
    /// @param issuanceIndexQueried Index of the Issuance Process
    /// @return True if the issuance raisedAmount is equal to hardCap
    function isHardcapReached(
        uint256 issuanceIndexQueried
    ) public view returns (bool) {
        return
            issuances[issuanceIndexQueried].raisedAmount == issuances[issuanceIndexQueried].hardCap;
    }

    /// @dev Method validate if the issuance is in withdrawn state
    /// @param issuanceIndexQueried Index of the Issuance Process
    /// @return True if the issuance is in withdrawn state
    function isWithdrawn(
        uint256 issuanceIndexQueried
    ) public view returns (bool) {
        return
            issuances[issuanceIndexQueried].status ==
            IssuanceStatuses.WITHDRAWN;
    }

    /// @dev Method if an user position has been redeemed or not
    /// @param issuanceIndexQueried Index of the issuance
    /// @param user Address of the user/investor
    /// @return True if the has reedemed the STO tokens
    function isRedeemed(
        uint256 issuanceIndexQueried,
        address user
    ) public view returns (bool) {
        return investors[issuanceIndexQueried][user].redeemed;
    }

    /// @dev Method if a user position has been refunded or not
    /// @param issuanceIndexQueried Index of the issuance
    /// @param user Address of the user/investor
    /// @return True if the has been refunded
    function isRefunded(
        uint256 issuanceIndexQueried,
        address user
    ) public view returns (bool) {
        return investors[issuanceIndexQueried][user].refunded;
    }

    /// @dev Method to validate if an user is an investor in the issuance
    /// @param issuanceIndexQueried Index of the issuance
    /// @param user Address of the user/investor
    /// @return True if the user has an opened position in the issuance
    function isInvestor(
        uint256 issuanceIndexQueried,
        address user
    ) public view returns (bool) {
        return
            investors[issuanceIndexQueried][user].amountInSTO > 0 &&
            investors[issuanceIndexQueried][user].amountInPaymentToken > 0 &&
            !investors[issuanceIndexQueried][user].redeemed;
    }

    /// @dev Method to calculate amount of STO tokens avaialable to be bought
    /// @dev It is equal or less to the max ticket allowed per investor in the issuance
    function amountAvailable(
        uint256 issuanceIndexQueried
    ) public view returns (uint256) {
        if (isActive(issuanceIndexQueried)) {
            return
                issuances[issuanceIndexQueried].hardCap.sub(
                    issuances[issuanceIndexQueried].raisedAmount
                ) > issuances[issuanceIndexQueried].maxTicket
                    ? issuances[issuanceIndexQueried].maxTicket
                    : issuances[issuanceIndexQueried].hardCap.sub(
                        issuances[issuanceIndexQueried].raisedAmount
                    );
        } else {
            return 0;
        }
    }

    /// @dev Method to get the price of 1 token of tokenAddress if swapped for paymentToken
    /// @param tokenAddress ERC20 token address of a whitelisted ERC20 token
    /// @return price Price in payment Token equivalent with its decimals
    function getPriceInPaymentToken(
        address tokenAddress
    ) public view returns (uint256 price) {
        if (tokenAddress == address(paymentToken)) return 1;

        address[] memory path = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        path[0] = address(tokenAddress);
        path[1] = address(paymentToken);
        amounts = router.getAmountsOut(
            1 * 10 ** IERC20MetadataUpgradeable(tokenAddress).decimals(),
            path
        );

        price = amounts[1];
    }

    /// Internal methods

    /// @dev Internal method to check whether the issuance is started AND ended
    function _checkIssuanceCompleteness(
        address caller,
        uint256 index
    ) internal view {
        if (issuanceIndex == 0) revert IssuanceNotStarted(caller);

        if (!isStarted(index)) revert IssuanceNotStarted(caller);

        if (!isEnded(index) && !isHardcapReached(index))
            revert IssuanceNotEnded(caller, issuances[issuanceIndex].endDate);
    }

    /// @dev Internal method to check whether the issuance is valid status and that the caller and the token are whitelisted
    function _checkValidStatus(
        address caller,
        address tokenUsed
    ) internal view {
        if (!stoRelatedToken.whitelist(caller))
            revert UserIsNotWhitelisted(caller);

        if (issuanceIndex == 0) revert IssuanceNotStarted(caller);

        if (!isStarted(issuanceIndex)) revert IssuanceNotStarted(caller);

        if (isEnded(issuanceIndex))
            revert IssuanceEnded(caller, issuances[issuanceIndex].endDate);

        if (!tokenERC20Whitelist[tokenUsed].status)
            revert TokenIsNotWhitelisted(tokenUsed, caller);

        if (
            issuances[issuanceIndex].raisedAmount ==
            issuances[issuanceIndex].hardCap
        ) revert HardCapRaised();
    }

    function _validateInputs(uint256 amount, address caller) internal view {
        // Auxiliary variables useful for the calculations
        uint256 paymentTokenScale = 10 ** paymentToken.decimals();
        uint256 stoRelatedTokenScale = 10 ** stoRelatedToken.decimals();
        uint256 scaledMinTicket = issuances[issuanceIndex].minTicket.mulDiv(
            paymentTokenScale,
            stoRelatedTokenScale
        );
        uint256 scaledMaxTicket = issuances[issuanceIndex].maxTicket.mulDiv(
            paymentTokenScale,
            stoRelatedTokenScale
        );
        uint256 scaledRaisedAmount = issuances[issuanceIndex]
            .raisedAmount
            .mulDiv(paymentTokenScale, stoRelatedTokenScale);
        uint256 scaledHardCap = issuances[issuanceIndex].hardCap.mulDiv(
            paymentTokenScale,
            stoRelatedTokenScale
        );
        uint256 scaledIssuanceAmount = issuances[issuanceIndex]
            .issuanceAmount
            .mulDiv(paymentTokenScale, stoRelatedTokenScale);

        if (
            (amount < scaledMinTicket) &&
            (scaledIssuanceAmount - scaledRaisedAmount) >= scaledMinTicket
        ) revert InsufficientAmount(caller, amount, scaledMinTicket);

        if (amount > scaledMaxTicket)
            revert AmountExceeded(caller, amount, scaledMaxTicket);

        if (
            (isInvestor(issuanceIndex, caller)) &&
            (investors[issuanceIndex][caller].amountInPaymentToken.add(amount) >
                scaledMaxTicket)
        )
            revert AmountExceeded(
                caller,
                investors[issuanceIndex][caller].amountInPaymentToken.add(
                    amount
                ),
                scaledMaxTicket
            );

        if (amount.add(scaledRaisedAmount) > scaledHardCap)
            revert HardCapExceeded(
                caller,
                amount,
                amountAvailable(issuanceIndex).mulDiv(
                    paymentTokenScale,
                    stoRelatedTokenScale
                )
            );
    }

    /// @dev Internal method for the investor to redeem the STO tokens bought
    function _redeemToken(uint256 index) internal {
        address caller = _msgSender();

        if (isRedeemed(index, caller)) revert RedeemedAlready(caller, index);

        if (!isInvestor(index, caller)) revert NotInvestor(caller, index);

        if (!isWithdrawn(index)) revert IssuanceNotWithdrawn(issuer);

        stoRelatedToken.mint(caller, investors[index][caller].amountInSTO);

        investors[index][caller].redeemed = true;

        emit Redeemed(caller, index, investors[index][caller].amountInSTO);
    }

    /// @dev Internal method for the investor to be refunded during paymentToken
    function _refundToken(uint256 index) internal {
        address caller = _msgSender();

        if (isRefunded(index, caller)) revert RefundedAlready(caller, index);

        if (!isInvestor(index, caller)) revert NotInvestor(caller, index);

        if (!isRollback(index)) revert IssuanceNotInRollback(index);

        /// Add Logic to refund the USDC for each issuance investor
        SafeERC20Upgradeable.safeTransfer(
            paymentToken,
            caller,
            investors[index][caller].amountInPaymentToken
        );

        investors[index][caller].refunded = true;

        emit Refunded(
            caller,
            index,
            investors[index][caller].amountInPaymentToken
        );
    }

    /// @dev Internal method to withdraw the payment Token funds after a successfull issuance
    /// @dev Only the issuer or owner can initialize this, the issuer will always receive the payment Token funds
    /// @dev Brickken is getting a successfull fee
    function _withdraw() internal {
        if (isWithdrawn(issuanceIndex)) revert IssuanceWasWithdrawn(issuer);

        uint256 amount = issuances[issuanceIndex].raisedAmount.mulDiv(
            10 ** paymentToken.decimals(),
            10 ** stoRelatedToken.decimals()
        );

        uint256 fee = amount.mulDiv(
            withdrawalFee,
            MAX_FEE_LIMIT,
            MathUpgradeable.Rounding.Up
        );

        SafeERC20Upgradeable.safeTransfer(paymentToken, treasuryAddress, fee);

        SafeERC20Upgradeable.safeTransfer(paymentToken, issuer, amount - fee);

        issuances[issuanceIndex].status = IssuanceStatuses.WITHDRAWN;

        emit Withdrawn(issuer, issuanceIndex, fee, amount - fee);
    }

    /// @dev Internal method to rollback the payment Token funds after an unsuccessfull issuance
    /// @dev Only the issuer or the owner can initialize this
    function _rollBack() internal {
        if (isRollback(issuanceIndex)) revert IssuanceWasRollbacked(issuer);

        issuances[issuanceIndex].status = IssuanceStatuses.ROLLBACK;

        emit RollBack(
            issuer,
            issuanceIndex,
            issuances[issuanceIndex].raisedAmount
        );
    }

    /// @dev Internal method to swap ERC20 whitelisted tokens for payment Token
    /// @param tokenAddress ERC20 token address of the whitelisted address
    /// @param tokenAmount Amount of tokens to be swapped with UniSwap v2 router to payment Token
    function _swapTokensForTokens(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expectedAmount
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = address(paymentToken);

        /// do the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            expectedAmount.mulDiv(0.90 ether, 1 ether), // Allow for up to 10% max slippage
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[42] private __gap;
}