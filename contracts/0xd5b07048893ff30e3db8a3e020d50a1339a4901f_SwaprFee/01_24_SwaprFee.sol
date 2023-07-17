// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./common/BaseGovernanceWithUserUpgradable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IDIAOracleV2.sol";

/// @title Manages NFT listings and user funds
/// @author swapr
/// @notice Allows only signature based listings
/// @dev Can only be interacted from a recognised marketplace EOA
contract SwaprFee is BaseGovernanceWithUserUpgradable {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    /// @notice Struct type to encapsulate FeePricing data
    /// @dev depositType is to detect the listing type as proposed listing type
    /// @dev activeDepositType is to check if asset is already listed as current listing type
    struct FeePricing {
        uint256 fixedBaseFee;
        uint256 finalFeeCap; //Cap is USD, 1 USD == 1e18
        uint256 priceCap;
        uint128 percentBaseFee;
        uint128 finalFeePercentage;
        bool isFixedBaseFee;
        bool isPercentBaseFee;
        bool isFinalFeePercentage;
    }

    address public feeReceiver;
    bytes32 public constant SWAPRGL_ROLE = keccak256("SWAPRGL_ROLE");

    FeePricing public AuctionFee;
    FeePricing public OrderFee;

    IERC20MetadataUpgradeable[] public paymentTokens;
    IERC20MetadataUpgradeable public lkrToken;

    IDIAOracleV2 public lkrOracle;

    mapping(address => AggregatorV3Interface) public oracleFeedForToken;
    mapping(address => mapping(address => uint)) public paymentRecords;

    uint internal constant _EXP = 1e18;
    AggregatorV3Interface internal _cryptoPriceFeed;

    mapping(address => uint256) internal _discountAmount;

    event OrderFeeUpdated(uint256 indexed setAmount);
    event AuctionFeeUpdated(uint256 indexed setAmount);

    modifier onlySwapr() {
        require(hasRole(SWAPRGL_ROLE, _msgSender()), "ERROR: ONLY_SWAPR_ROLE");
        _;
    }
    
    /// @notice initialize the contract
    /// @param swaprGLAddress address of the SwaprGL contract
    function initialize(address swaprGLAddress) public initializer {
        require(swaprGLAddress != address(0), "Cant set address 0");
        __BaseGovernanceWithUser_init(_msgSender());
        //You can setup custom roles here in addition to the default gevernance roles
        _setupRole(SWAPRGL_ROLE, swaprGLAddress);
        //All state variables must be initialized here in sequence to prevent upgrade conflicts
        feeReceiver = _msgSender();
    }

    /// @notice set new account as fee receiver
    /// @param _feeReceiver address of the new fee receiver
    function setFeeReceiver(address _feeReceiver) external {
        _onlyAdmin();
        require(_feeReceiver != address(0), "Cant set address 0");
        feeReceiver = _feeReceiver;
    }

    /// @notice set the LKR token and oracle
    /// @param _lkrToken address of the LKR token
    /// @param _lkrOracle address of the LKR oracle
    /// @param __discountAmount discount amount for LKR token
    function setLKRToken(address _lkrToken, address _lkrOracle, uint256 __discountAmount) external {
        _onlyAdmin();
        require(_lkrToken != address(0), "Cant set address 0");
        require(_lkrOracle != address(0), "Cant set address 0");
        require(__discountAmount <= _EXP, "Discount cant be more than 100%");
        lkrToken = IERC20MetadataUpgradeable(_lkrToken);
        lkrOracle = IDIAOracleV2(_lkrOracle);
        _discountAmount[_lkrToken] = __discountAmount;
    }

    /// @notice add new payment accepted tokens
    /// @param _paymentTokens token used to pay the fee
    /// @param _tokenPriceFeeds price feeds for the tokens
    function addPaymentToken(address[] memory _paymentTokens, address[] memory _tokenPriceFeeds) external {
        _onlyAdmin();
        require(_paymentTokens.length == _tokenPriceFeeds.length, "INVALID_TOKEN-FEED_LENGTH");
        for (uint256 i; i < _paymentTokens.length; ) {
            if (!isTokenSupported(_paymentTokens[i]) && _paymentTokens[i] != address(0)) {
                paymentTokens.push(IERC20MetadataUpgradeable(_paymentTokens[i]));
                oracleFeedForToken[_paymentTokens[i]] = AggregatorV3Interface(_tokenPriceFeeds[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice remove existing payment accepted token
    /// @param _paymentToken token used to pay the fee
    function removePaymentToken(address _paymentToken) external {
        _onlyAdmin();
        (bool exists, uint idx) = _exists(_paymentToken);
        if (exists) {
            if (_paymentToken == address(0) && address(_cryptoPriceFeed) != address(0)) {
                delete _cryptoPriceFeed;
            } else if (_paymentToken == address(lkrToken) && address(lkrOracle) != address(0)) {
                delete lkrToken;
                delete lkrOracle;
            } else {
                delete paymentTokens[idx];
                delete oracleFeedForToken[_paymentToken];
            }
        }
    }

    /// @notice remove all existing payment accepted tokens
    function removeAllPaymentTokens() external {
        _onlyAdmin();
        delete paymentTokens;
        delete lkrToken;
        delete lkrOracle;
        delete _cryptoPriceFeed;
    }

    /// @notice get all payment accepted tokens
    /// @return _paymentTokens array of payment tokens
    /// @return _lkrToken address of the LKR token
    function getAllPaymentTokens()
        external
        view
        returns (IERC20MetadataUpgradeable[] memory _paymentTokens, IERC20MetadataUpgradeable _lkrToken)
    {
        _paymentTokens = paymentTokens;
        _lkrToken = lkrToken;
    }

    /// @notice set native token price feed
    /// @param _priceFeed address of the price feed
    function setNativeTokenPriceFeed(address _priceFeed) external {
        _onlyAdmin();
        require(_priceFeed != address(0), "Cant set address 0");
        _cryptoPriceFeed = AggregatorV3Interface(_priceFeed);
    }

    /// @notice returns the price feed for the given token
    /// @param token address of the token
    /// @return priceFeed price feed for the token
    function getTokenFeed(address token) public view returns (AggregatorV3Interface priceFeed) {
        if (token == address(0)) {
            priceFeed = _cryptoPriceFeed;
        } else {
            priceFeed = oracleFeedForToken[token];
        }
    }

    /// @notice check if the token is accepted as payment currency
    /// @param _paymentToken address of the token
    /// @return exists true if the token is accepted as payment currency
    function isTokenSupported(address _paymentToken) public view returns (bool exists) {
        (exists, ) = _exists(_paymentToken);
    }

    /// @notice adds an array of tokens as discount tokens
    /// @param _discountToken array of tokens to be added as discount tokens
    /// @param __discountAmount array of discount amounts for the tokens
    function addDiscountTokens(address[] memory _discountToken, uint256[] memory __discountAmount) external {
        _onlyAdmin();
        require(_discountToken.length == __discountAmount.length, "Invalid input");
        for (uint256 i; i < _discountToken.length; i++) {
            addDiscountToken(_discountToken[i], __discountAmount[i]);
        }
    }

    /// @notice adds a token as discount token
    /// @param _discountToken token to be added as discount token
    /// @param __discountAmount discount amount for the token
    function addDiscountToken(address _discountToken, uint256 __discountAmount) public {
        _onlyAdmin();
        require(_discountToken != address(0), "Cant set address 0");
        require(__discountAmount <= _EXP, "Discount cant be more than 100%");
        (bool exists, ) = _exists(_discountToken);
        require(exists, "This is not a payment token");
        _discountAmount[_discountToken] = __discountAmount;
    }

    /// @notice removes an array of tokens as discount tokens
    /// @param _discountToken array of tokens to be removed as discount tokens
    function removeDiscountTokens(address[] memory _discountToken) external {
        _onlyAdmin();
        for (uint256 i; i < _discountToken.length; i++) {
            removeDiscountToken(_discountToken[i]);
        }
    }

    /// @notice removes a token as discount token
    /// @param _discountToken token to be removed as discount token
    function removeDiscountToken(address _discountToken) public {
        _onlyAdmin();
        (bool exists, ) = _exists(_discountToken);
        require(exists, "This is not a payment token");
        require(_discountAmount[_discountToken] > 0, "Discount not set");
        delete _discountAmount[_discountToken];
    }

    /// @notice get discount amount for the given token
    /// @param _discountToken address of the token
    /// @return discountAmount discount amount for the token
    function getDiscountAmount(address _discountToken) external view returns (uint256 discountAmount) {
        discountAmount = _discountAmount[_discountToken];
    }

    /// @notice configure fee params for auction type listing
    /// @param data should contain FeePricing type data
    function configAuctionFee(bytes calldata data) external {
        _onlyAdmin();
        AuctionFee = _extractFeePricingInfo(data);
    }

    /// @notice configure fee params for order type listing
    /// @param data should contain FeePricing type data
    function configOrderFee(bytes calldata data) external {
        _onlyAdmin();
        OrderFee = _extractFeePricingInfo(data);
    }

    /// @notice get account of the beneficiary who will receive all the fee paid
    /// @return feeReceiver address of the fee receiver
    function getFeeReceiver() public view returns (address) {
        return feeReceiver;
    }

    /// @notice get applied base fee for the order type listing
    /// @param subjectAmount The amount to be priced for listing subject to the fee in percentage
    /// @param token supported payment token
    /// @return totalBaseFee base calculated fee
    /// @return percentBaseFee percentage of the base fee
    /// @return fixedBaseFee fixed base fee
    function getBaseOrderFee(
        uint subjectAmount,
        address token
    ) public view returns (uint totalBaseFee, uint percentBaseFee, uint fixedBaseFee) {
        (totalBaseFee, percentBaseFee, fixedBaseFee) = _getBaseFee(OrderFee, subjectAmount, token);
        if (OrderFee.priceCap > 0) {
            uint priceCapTokens = _calculatePriceCap(OrderFee, token);
            if (totalBaseFee > priceCapTokens) {
                totalBaseFee = priceCapTokens;
            }
        }
    }

    /// @notice set new fixed base fee for the order type listing
    /// @dev the input must be in _EXP format
    /// @param fixedBaseFee value to be charged in USD
    function setFixedBaseOrderFee(uint fixedBaseFee) external {
        _onlyAdmin();
        OrderFee.fixedBaseFee = fixedBaseFee;
        emit OrderFeeUpdated(fixedBaseFee);
    }

    /// @notice activate or deactivate fixedBaseFee
    /// @param active bool as true or false
    function switchFixedBaseOrderFee(bool active) external {
        _onlyAdmin();
        require(OrderFee.isFixedBaseFee != active, "Already set");
        OrderFee.isFixedBaseFee = active;
    }

    /// @notice set new percent base fee for the order type listing
    /// @dev the input must be in _EXP format max 1e18
    /// @param percentBaseFee value to be charged in Percentage
    function setPercentBaseOrderFee(uint128 percentBaseFee) external {
        _onlyAdmin();
        require(percentBaseFee <= _EXP, "Fee exceed 100%");
        OrderFee.percentBaseFee = percentBaseFee;
        emit OrderFeeUpdated(percentBaseFee);
    }

    /// @notice activate or deactivate percentBaseFee
    /// @param active bool as true or false
    function switchPercentBaseOrderFee(bool active) external {
        _onlyAdmin();
        require(OrderFee.isPercentBaseFee != active, "Already set");
        OrderFee.isPercentBaseFee = active;
    }

    /// @notice get applied base fee for the auction type listing
    /// @param subjectAmount The amount to be priced for listing subject to the fee in percentage
    /// @param token supported payment token
    /// @return baseFee base calculated fee
    /// @return percentBaseFee percentage of the base fee
    /// @return fixedBaseFee fixed base fee
    function getBaseAuctionFee(
        uint subjectAmount,
        address token
    ) public view returns (uint baseFee, uint percentBaseFee, uint fixedBaseFee) {
        (baseFee, percentBaseFee, fixedBaseFee) = _getBaseFee(AuctionFee, subjectAmount, token);
        if (AuctionFee.priceCap > 0) {
            uint priceCapTokens = _calculatePriceCap(AuctionFee, token);
            if (baseFee > priceCapTokens) {
                baseFee = priceCapTokens;
            }
        }
    }

    /// @notice set new fixed base fee for the auction type listing
    /// @dev the input must be in _EXP format
    /// @param fixedBaseFee value to be charged in USD
    function setFixedBaseAuctionFee(uint fixedBaseFee) external {
        _onlyAdmin();
        AuctionFee.fixedBaseFee = fixedBaseFee;
        emit AuctionFeeUpdated(fixedBaseFee);
    }

    /// @notice activate or deactivate fixedBaseFee
    /// @param active bool as true or false
    function switchFixedBaseAuctionFee(bool active) external {
        _onlyAdmin();
        require(AuctionFee.isFixedBaseFee != active, "Already set");
        AuctionFee.isFixedBaseFee = active;
    }

    /// @notice set new percent base fee for the auction type listing
    /// @dev the input must be in _EXP format max 1e18
    /// @param percentBaseFee value to be charged in Percentage
    function setPercentBaseAuctionFee(uint128 percentBaseFee) external {
        _onlyAdmin();
        require(percentBaseFee <= _EXP, "Fee exceed 100%");
        AuctionFee.percentBaseFee = percentBaseFee;
        emit AuctionFeeUpdated(percentBaseFee);
    }

    /// @notice activate or deactivate percentBaseFee
    /// @param active bool as true or false
    function switchPercentBaseAuctionFee(bool active) external {
        _onlyAdmin();
        require(AuctionFee.isPercentBaseFee != active, "Already set");
        AuctionFee.isPercentBaseFee = active;
    }

    /// @notice get applied base fee for the auction type listing
    /// @param subjectAmount The amount to be priced for listing subject to the fee in percentage
    /// @param token supported payment token
    /// @return finalFee final calculated fee
    function getFinalOrderFee(uint subjectAmount, address token) public view returns (uint finalFee) {
        finalFee = _getFinalFee(OrderFee, subjectAmount);
        if (_discountAmount[token] > 0) {
            finalFee -= (finalFee * _discountAmount[token]) / _EXP;
        }
        if (OrderFee.priceCap > 0) {
            uint priceCapTokens = _calculatePriceCap(OrderFee, token);
            if (finalFee > priceCapTokens) {
                finalFee = priceCapTokens;
            }
        }
        if (OrderFee.finalFeeCap > 0) {
            uint finalFeeCapTokens = _calculateFinalFeeCap(OrderFee, token);
            if (finalFee > finalFeeCapTokens) {
                finalFee = finalFeeCapTokens;
            }
        }
    }

    /// @notice set new final fee for the order type listing
    /// @dev the input must be in _EXP format max 1e18
    /// @dev charged only when a sale completed successfully
    /// @param finalFeePercentage value to be charged in Percentage
    function setFinalOrderFee(uint128 finalFeePercentage) external {
        _onlyAdmin();
        require(finalFeePercentage <= _EXP, "Fee exceed 100%");
        OrderFee.finalFeePercentage = finalFeePercentage;
        emit OrderFeeUpdated(finalFeePercentage);
    }

    /// @notice activate or deactivate finalFeePercentage
    /// @param active bool as true or false
    function switchFinalOrderFee(bool active) external {
        _onlyAdmin();
        require(OrderFee.isFinalFeePercentage != active, "Already set");
        OrderFee.isFinalFeePercentage = active;
    }

    /// @notice get applied base fee for the auction type listing
    /// @param subjectAmount The amount to be priced for listing subject to the fee in percentage
    /// @param token supported payment token
    /// @return finalFee final calculated fee
    function getFinalAuctionFee(uint subjectAmount, address token) public view returns (uint finalFee) {
        finalFee = _getFinalFee(AuctionFee, subjectAmount);
        if (_discountAmount[token] > 0) {
            finalFee -= (finalFee * _discountAmount[token]) / _EXP;
        }
        if (AuctionFee.priceCap > 0) {
            uint priceCapTokens = _calculatePriceCap(AuctionFee, token);
            if (finalFee > priceCapTokens) {
                finalFee = priceCapTokens;
            }
        }
        if (AuctionFee.finalFeeCap > 0) {
            uint finalFeeCapTokens = _calculateFinalFeeCap(AuctionFee, token);
            if (finalFee > finalFeeCapTokens) {
                finalFee = finalFeeCapTokens;
            }
        }
    }

    /// @notice set new final fee for the order type listing
    /// @dev the input must be in _EXP format max 1e18
    /// @dev charged only when a sale completed successfully
    /// @param finalFeePercentage value to be charged in Percentage
    function setFinalAuctionFee(uint128 finalFeePercentage) external {
        _onlyAdmin();
        require(finalFeePercentage <= _EXP, "Fee exceed 100%");
        AuctionFee.finalFeePercentage = finalFeePercentage;
        emit AuctionFeeUpdated(finalFeePercentage);
    }

    /// @notice activate or deactivate finalFeePercentage
    /// @param active bool as true or false
    function switchFinalAuctionFee(bool active) external {
        _onlyAdmin();
        require(AuctionFee.isFinalFeePercentage != active, "Already set");
        AuctionFee.isFinalFeePercentage = active;
    }

    /// @notice get the price cap for all the tokens
    /// @return priceCap maximum value to be charged
    function getOrderPriceCap() public view returns (uint priceCap) {
        priceCap = OrderFee.priceCap;
    }

    /// @notice set the price cap for all the tokens
    /// @dev charged only when a sale completed successfully
    /// @param priceCap value to be set as price cap
    function setOrderPriceCap(uint priceCap) external {
        _onlyAdmin();
        OrderFee.priceCap = priceCap;
    }

    /// @notice get the final fee cap for all the tokens
    /// @return finalFeeCap maximum value to be charged
    function getOrderFinalFeeCap() public view returns (uint finalFeeCap) {
        finalFeeCap = OrderFee.finalFeeCap;
    }

    /// @notice set the final fee cap for all the tokens
    /// @dev charged only when a sale completed successfully
    /// @param finalFeeCap value to be set as final fee cap
    function setOrderFinalFeeCap(uint finalFeeCap) external {
        _onlyAdmin();
        OrderFee.finalFeeCap = finalFeeCap;
    }

    /// @notice get the price cap for all the tokens
    /// @return priceCap maximum value to be charged
    function getAuctionPriceCap() public view returns (uint priceCap) {
        priceCap = AuctionFee.priceCap;
    }

    /// @notice set new final fee for the order type listing
    /// @dev charged only when a sale completed successfully
    /// @param priceCap value to be charged in Percentage
    function setAuctionPriceCap(uint priceCap) external {
        _onlyAdmin();
        AuctionFee.priceCap = priceCap;
    }

    /// @notice get the final fee cap for all the tokens
    /// @return finalFeeCap maximum value to be charged
    function getAuctionFinalFeeCap() public view returns (uint finalFeeCap) {
        finalFeeCap = AuctionFee.finalFeeCap;
    }

    /// @notice set the final fee cap for all the tokens
    /// @dev charged only when a sale completed successfully
    /// @param finalFeeCap value to be set as final fee cap
    function setAuctionFinalFeeCap(uint finalFeeCap) external {
        _onlyAdmin();
        AuctionFee.finalFeeCap = finalFeeCap;
    }

    /// @notice get total deposit of the given user for fee payment
    /// @param user The fee depositor
    /// @param token token address for balance
    /// @return balance balance of user against provided token, native balance incase of 0 address
    function getFeePaid(address user, address token) public view returns (uint balance) {
        balance = paymentRecords[user][token];
    }

    /// @notice To deposit funds for fee payment, can be used with combination of other functions or directly
    /// @param fee fee to be disposed
    /// @param paymentToken token used to pay the fee
    function payNow(uint fee, address paymentToken) public payable {
        if (isTokenSupported(paymentToken)) {
            if (fee > 0) {
                if (paymentToken == address(0)) {
                    require(msg.value >= fee, "ERROR: LOW_VALUE_OBSERVED");
                    payable(feeReceiver).transfer(fee);
                } else if (paymentToken == address(lkrToken)) {
                    uint allowance = lkrToken.allowance(_msgSender(), address(this));
                    require(allowance >= fee, "ERROR: INSUFFICIENT_ALLOWANCE");
                    lkrToken.safeTransferFrom(_msgSender(), feeReceiver, fee);
                } else {
                    IERC20MetadataUpgradeable fundToken = IERC20MetadataUpgradeable(paymentToken);
                    uint allowance = fundToken.allowance(_msgSender(), address(this));
                    require(allowance >= fee, "ERROR: INSUFFICIENT_ALLOWANCE");
                    fundToken.safeTransferFrom(_msgSender(), feeReceiver, fee);
                }
                paymentRecords[_msgSender()][paymentToken] += fee;
            }
        }
    }

    /// @notice Only for swapr to dispose or remove the fee deposits after listing or sale
    /// @param data should contain fee, user and paymentToken as encoded data
    function disposeFeeRecord(bytes calldata data) external onlySwapr {
        (uint fee, address user, address paymentToken) = abi.decode(data, (uint, address, address));
        if (paymentRecords[user][paymentToken] > fee) {
            paymentRecords[user][paymentToken] -= fee;
        } else {
            delete paymentRecords[user][paymentToken];
        }
    }

    /// @notice decodes the FeePricing type encoded data
    /// @param data encoded data
    /// @return feePricing FeePricing type
    function _extractFeePricingInfo(bytes memory data) internal pure returns (FeePricing memory feePricing) {
        feePricing = abi.decode(data, (FeePricing));
        require(feePricing.percentBaseFee <= _EXP, "BIGGER_THAN_MAX");
        require(feePricing.finalFeePercentage <= _EXP, "BIGGER_THAN_MAX");
    }

    /// @notice Internal function to help calculate the base fee from percentage
    /// @param feePricing refer to type FeePricing type
    /// @param subjectAmount amount to be calculated
    /// @param token token address for balance
    /// @return totalBaseFee total base calculated fee
    /// @return percentBaseFee percentage base calculated fee
    /// @return fixedBaseFee fixed base calculated fee
    function _getBaseFee(
        FeePricing memory feePricing,
        uint subjectAmount,
        address token
    ) internal view returns (uint totalBaseFee, uint percentBaseFee, uint fixedBaseFee) {
        require(feePricing.percentBaseFee <= _EXP, "BIGGER_THAN_MAX");
        require(isTokenSupported(token), "TOKEN_NOT_SUPPORTED");

        percentBaseFee = (subjectAmount * feePricing.percentBaseFee) / _EXP;

        if (token == address(0)) {
            uint baseRecount = ((feePricing.fixedBaseFee * _EXP) / _getPrice(_cryptoPriceFeed));
            fixedBaseFee = (baseRecount * _getFeedDecimals(_cryptoPriceFeed)) / _EXP;
        } else if (token == address(lkrToken)) {
            uint baseRecount = ((feePricing.fixedBaseFee * _EXP) / _getLkrPrice(lkrOracle));
            fixedBaseFee = (baseRecount * 10 ** 8) / _EXP;
        } else {
            uint baseRecount = ((feePricing.fixedBaseFee * _EXP) / _getPrice(oracleFeedForToken[token]));
            fixedBaseFee = (baseRecount * _getFeedDecimals(oracleFeedForToken[token])) / _EXP;
        }
        if (_discountAmount[token] > 0) {
            fixedBaseFee -= (fixedBaseFee * _discountAmount[token]) / _EXP;
            percentBaseFee -= (percentBaseFee * _discountAmount[token]) / _EXP;
        }
        if (feePricing.isFixedBaseFee && feePricing.isPercentBaseFee) {
            totalBaseFee = fixedBaseFee + percentBaseFee;
        }
        if (feePricing.isFixedBaseFee && !feePricing.isPercentBaseFee) {
            totalBaseFee = fixedBaseFee;
        }
        if (!feePricing.isFixedBaseFee && feePricing.isPercentBaseFee) {
            totalBaseFee = percentBaseFee;
        }
    }

    /// @notice Internal function to help calculate the final fee from percentage
    /// @param feePricing refer to type FeePricing type
    /// @param subjectAmount amount to be calculated
    /// @return finalFee final calculated fee
    function _getFinalFee(FeePricing memory feePricing, uint subjectAmount) internal pure returns (uint finalFee) {
        require(feePricing.finalFeePercentage <= _EXP, "BIGGER_THAN_MAX");
        if (feePricing.isFinalFeePercentage) {
            finalFee = (subjectAmount * feePricing.finalFeePercentage) / _EXP;
        }
    }

    /// @notice Internal function to check if the token is supported
    /// @param _paymentToken token address
    /// @return exists true if supported
    /// @return idx index of the token
    function _exists(address _paymentToken) internal view returns (bool exists, uint idx) {
        if (
            (_paymentToken == address(0) && address(_cryptoPriceFeed) != address(0)) ||
            (_paymentToken == address(lkrToken) && address(lkrOracle) != address(0))
        ) {
            return (true, 0);
        }
        for (uint i = 0; i < paymentTokens.length; i++) {
            if (paymentTokens[i] == IERC20MetadataUpgradeable(_paymentToken)) {
                idx = i;
                exists = true;
            }
        }
    }

    /// @notice Internal function to calculate the final fee price cap
    /// @param feePricing refer to type FeePricing type
    /// @param token address of the payment token
    /// @return priceCapTokens price cap in tokens
    function _calculateFinalFeeCap(
        FeePricing memory feePricing,
        address token
    ) internal view returns (uint priceCapTokens) {
        if (address(lkrToken) != address(0) && token == address(lkrToken)) {
            uint capRecount = ((feePricing.finalFeeCap * _EXP) / _getLkrPrice(lkrOracle));
            priceCapTokens = (capRecount * 10 ** 8) / _EXP;
        } else {
            uint capRecount = ((feePricing.finalFeeCap * _EXP) / _getPrice(getTokenFeed(token)));
            priceCapTokens = (capRecount * _getFeedDecimals(getTokenFeed(token))) / _EXP;
        }
    }

    /// @notice Internal function to calculate the price cap
    /// @param feePricing refer to type FeePricing type
    /// @param token address of the payment token
    /// @return priceCapTokens price cap in tokens
    function _calculatePriceCap(
        FeePricing memory feePricing,
        address token
    ) internal view returns (uint priceCapTokens) {
        if (address(lkrToken) != address(0) && token == address(lkrToken)) {
            uint capRecount = ((feePricing.priceCap * _EXP) / _getLkrPrice(lkrOracle));
            priceCapTokens = (capRecount * 10 ** 8) / _EXP;
        } else {
            uint capRecount = ((feePricing.priceCap * _EXP) / _getPrice(getTokenFeed(token)));
            priceCapTokens = (capRecount * _getFeedDecimals(getTokenFeed(token))) / _EXP;
        }
    }

    /// @notice Internal function to get the price of a token
    /// @param priceFeed price feed address
    /// @return price calculated price
    function _getPrice(AggregatorV3Interface priceFeed) internal view returns (uint) {
        (, int price, , uint timeStamp, ) = priceFeed.latestRoundData();
        require(timeStamp > 0, "Round not complete");
        require(price > 0, "Price is 0");
        return uint(price);
    }

    /// @notice Internal function to get the price of the LKR token
    /// @param priceFeed price feed address
    /// @return price calculated price
    function _getLkrPrice(IDIAOracleV2 priceFeed) internal view returns (uint) {
        (uint128 price, uint128 timeStamp) = priceFeed.getValue("LKR/USD");
        require(timeStamp > 0 && timeStamp <= block.timestamp, "Round not complete");
        require(price > 0, "Price is 0");
        return uint(price);
    }

    /// @notice Internal function to get the ammount of decimals of a price feed
    /// @param priceFeedDecimals price feed decimals
    function _getFeedDecimals(AggregatorV3Interface priceFeed) internal view returns (uint priceFeedDecimals) {
        priceFeedDecimals = 10 ** uint(priceFeed.decimals());
    }
}