// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract DeployFee is Context {
    using SafeERC20 for IERC20Metadata;

    struct DeployFeeTemplate {
        uint256 FixedAmountFee;
        uint256 PercentageAmountFee;
    }

    //Payments Otions
    bytes32 public constant FIXED_PAYMENT_OPTION =
        keccak256("FIXED_PAYMENT_OPTION");
    bytes32 public constant PERCENTAGE_UPFRONT_PAYMENT_OPTION =
        keccak256("PERCENTAGE_UPFRONT_PAYMENT_OPTION");
    bytes32 public constant COMBINED_PAYMENT_OPTION =
        keccak256("COMBINED_PAYMENT_OPTION");

    //Selected Payment Option
    bytes32 public deployFeePaymentOption;

    //Payment Tokens
    IERC20Metadata[] public deployFeeTokens;

    //Deploy Fee Percentage, 1e18 == 100%
    uint256 public deployFeePercentageAmount;

    //Deploy Fee Fixed Amount 1e18 == 1 USD
    uint256 public deployFeeFixedAmount;

    mapping(address => uint256) internal discountAmount;

    //Deploy Fee Beneficiary, this address will collect the Fee
    address public deployFeeBeneficiary;

    mapping(address => DeployFeeTemplate) TokenFees;
    mapping(address => bool) public isPaymentToken;
    mapping(address => AggregatorV3Interface) public oracleFeedForToken;
    mapping(address => bool) internal isDiscountToken;

    //Chainlink Price Feed Oracles
    AggregatorV3Interface internal cryptoPriceFeed;
    AggregatorV3Interface[] internal tokenPriceFeeds;

    //Constant exponential value used to calculate the deploy fee
    uint256 constant EXP_VALUE = 1e18;

    /**
     * @notice Set up the DeployFee contract
     * @param _deployFeeFixedAmount Deploy Fee Fixed Amount 1e18 == 1 USD
     * @param _deployFeePercentageAmount Deploy Fee Percentage, 1e18 == 100%
     * @param _deployFeeBeneficiary Deploy Fee Beneficiary
     * @param _deployFeeTokens List Payment Token, it can be USDT, TUSD, USDC, etc.
     * @param _tokenPriceFeeds Feed of Payments Tokens, it can be USDT, TUSD, USDC, etc.
     * @param _cryptoPriceFeed Chainlink Price Feed Oracle
     * @param _deployFeePaymentOption Selected Payment Fee
     */
    function setupDeployFeeInternal(
        uint256 _deployFeeFixedAmount,
        uint256 _deployFeePercentageAmount,
        address _deployFeeBeneficiary,
        address[] memory _deployFeeTokens,
        address[] memory _tokenPriceFeeds,
        address _cryptoPriceFeed,
        bytes32 _deployFeePaymentOption
    ) internal {

        if (deployFeeTokens.length > 0) {
            for (uint256 i; i < deployFeeTokens.length;) {
                removeFeedAndToken(i);
                unchecked {
                    ++i;
                }
            }
        }

        changeActiveDeployFeesInternal(_deployFeeFixedAmount, _deployFeePercentageAmount);

        updateDeployFeeBeneficiaryInternal(_deployFeeBeneficiary);

        addNewFeedsAndTokens(_deployFeeTokens, _tokenPriceFeeds);

        updateCryptoFeedInternal(_cryptoPriceFeed);

        changeActivePaymentOptionInternal(_deployFeePaymentOption);
    }

    function changeActiveDeployFeesInternal(
        uint256 _newFixedAmount,
        uint256 _newPercentageAmount
    ) internal {
        require(
            _newFixedAmount > 0 || _newPercentageAmount > 0,
            "Percentage fee and Fixed fee cant be 0"
        );
        if (_newFixedAmount == 0) {
            deployFeePercentageAmount = _newPercentageAmount;
        } else if (_newPercentageAmount == 0) {
            deployFeeFixedAmount = _newFixedAmount;
        } else {
            deployFeeFixedAmount = _newFixedAmount;
            deployFeePercentageAmount = _newPercentageAmount;
        }
    }

    /**
     * @notice Changes the active payment option
     * @param _deployFeePaymentOption the new active payment option
     */
    function changeActivePaymentOptionInternal(bytes32 _deployFeePaymentOption)
        internal
    {
        require(
            _deployFeePaymentOption == FIXED_PAYMENT_OPTION ||
                _deployFeePaymentOption == PERCENTAGE_UPFRONT_PAYMENT_OPTION ||
                _deployFeePaymentOption == COMBINED_PAYMENT_OPTION
        );
        deployFeePaymentOption = _deployFeePaymentOption;
    }

    function updateDeployFeeBeneficiaryInternal(address _newDeployFeeBeneficiary) internal {
        require(_newDeployFeeBeneficiary != address(0), "ERROR: Cant set address 0");
        require(_newDeployFeeBeneficiary != deployFeeBeneficiary, "Cant set the same address");
        deployFeeBeneficiary = _newDeployFeeBeneficiary;
    }

    function updateTokenFeesInternal(
        address _updatedToken,
        uint256 _newFixedFee,
        uint256 _newPercentageFee
    ) internal {
        TokenFees[_updatedToken].FixedAmountFee = _newFixedFee;
        TokenFees[_updatedToken].PercentageAmountFee = _newPercentageFee;
    }

    /**
     * @notice called by LokrFactory, charge the deploy fee to the user
     * @param tokenAddress selected token address to pay the fee,
     * if its != deployFirstToken || deployFeeSecondToken will charge with the blockchain token
     */
    function chargeDeployFee(address tokenAddress) internal {
        if (isPaymentToken[tokenAddress]) {
            tokenChargeDeployFee(IERC20Metadata(tokenAddress));
        } else {
            cryptoChargeDeployFee();
        }
    }

    function chargeWithLockedToken(
        IERC20Metadata _lockedToken,
        uint256 _lockedAmount
    ) internal {
        (, uint256 requiredTokens) = calculateRequiredTokens(
            _lockedToken,
            _lockedAmount
        );
        _lockedToken.safeTransferFrom(
            _msgSender(),
            deployFeeBeneficiary,
            requiredTokens
        );
    }

    /**
     * @param paymentToken token to pay the deploy Fee
     */
    function tokenChargeDeployFee(IERC20Metadata paymentToken) internal {
        (uint256 requiredTokens, ) = calculateRequiredTokens(paymentToken, 0);
        paymentToken.safeTransferFrom(
            _msgSender(),
            deployFeeBeneficiary,
            requiredTokens
        );
    }

    function calculateRequiredTokens(
        IERC20Metadata paymentToken,
        uint256 lockedAmount
    )
        internal
        view
        returns (uint256 fixedTokenAmount, uint256 percentageTokenAmount)
    {
        uint256 tokenDecimals = 10**uint256(paymentToken.decimals());
        address paymentTokenAddress = address(paymentToken);

        if (isPaymentToken[paymentTokenAddress]) {
            AggregatorV3Interface tokenFeed = oracleFeedForToken[
                paymentTokenAddress
            ];
            uint256 priceFeedDecimals = 10**tokenFeed.decimals();
            (, int256 tokenUsdPrice, , , ) = tokenFeed.latestRoundData();
            if (tokenDecimals >= EXP_VALUE) {
                fixedTokenAmount =
                    (deployFeeFixedAmount *
                        (tokenDecimals / EXP_VALUE) *
                        priceFeedDecimals) /
                    uint256(tokenUsdPrice);
            } else {
                fixedTokenAmount =
                    ((deployFeeFixedAmount / (EXP_VALUE / tokenDecimals)) *
                        priceFeedDecimals) /
                    uint256(tokenUsdPrice);
            }
        } else {
            uint256 percentageFee = TokenFees[paymentTokenAddress]
                .PercentageAmountFee > 0
                ? TokenFees[paymentTokenAddress].PercentageAmountFee
                : deployFeePercentageAmount;
            if (tokenDecimals >= EXP_VALUE) {
                percentageTokenAmount =
                    ((lockedAmount * percentageFee) / EXP_VALUE) *
                    (tokenDecimals / EXP_VALUE);
            } else {
                percentageTokenAmount =
                    ((lockedAmount * percentageFee) / EXP_VALUE) /
                    (EXP_VALUE / tokenDecimals);
            }
        }

        if(isDiscountToken[paymentTokenAddress]) {
            fixedTokenAmount -= ( fixedTokenAmount * discountAmount[paymentTokenAddress] / EXP_VALUE );
            percentageTokenAmount -= ( percentageTokenAmount * discountAmount[paymentTokenAddress] / EXP_VALUE );
        }
    }

    /**
     * @notice charge the deploy fee with the blockchain token
     */
    function cryptoChargeDeployFee() internal {
        uint256 requiredETH = calculateRequiredCrypto();
        require(
            msg.value >= requiredETH,
            "ERROR: Msg.value is lower than expected"
        );
        bool sent = payable(deployFeeBeneficiary).send(requiredETH);
        require(sent, "ERROR: Failed to send Fee to Manager");
        uint256 ethExceeded = msg.value - requiredETH;
        if (ethExceeded > 1 gwei) {
            sent = payable(_msgSender()).send(ethExceeded);
            require(sent, "ERROR: Failed to return exceeded value");
        }
    }

    function calculateRequiredCrypto()
        internal
        view
        returns (uint256 fixedRequiredCrypto)
    {
        uint256 priceFeedDecimals = 10**uint256(cryptoPriceFeed.decimals());
        (, int256 cryptoUsdPrice, , , ) = cryptoPriceFeed.latestRoundData();
        if (priceFeedDecimals >= EXP_VALUE) {
            fixedRequiredCrypto =
                deployFeeFixedAmount /
                (uint256(cryptoUsdPrice) / EXP_VALUE);
        } else {
            fixedRequiredCrypto =
                (deployFeeFixedAmount * priceFeedDecimals) /
                uint256(cryptoUsdPrice);
        }
    }

    function setDiscountTokenInternal(
        address _discountToken,
        uint256 _discountAmount
    ) internal {
        require(_discountToken != address(0), "Cant set address 0");
        require(_discountAmount <= EXP_VALUE, "Discount cant be more than 100%");
        require(isPaymentToken[_discountToken], "This token is not supported");
        isDiscountToken[_discountToken] = true;
        discountAmount[_discountToken] = _discountAmount;
    }

    function removeDiscountTokenInternal(
        address _discountToken
    ) internal {
        require(isDiscountToken[_discountToken], "This is not a discount token");
        delete isDiscountToken[_discountToken];
        delete discountAmount[_discountToken];
    }

    function addNewFeedsAndTokens(
        address[] memory _deployFeeTokens,
        address[] memory _tokenPriceFeeds
    ) internal {
        require(
            _deployFeeTokens.length == _tokenPriceFeeds.length,
            "ERROR: INVALID TOKEN-FEED LENGTH"
        );
        for (uint256 i; i < _deployFeeTokens.length;) {
            if (
                _deployFeeTokens[i] != address(0) &&
                _tokenPriceFeeds[i] != address(0) &&
                !isPaymentToken[_deployFeeTokens[i]]
            ) {
                deployFeeTokens.push(IERC20Metadata(_deployFeeTokens[i]));
                tokenPriceFeeds.push(
                    AggregatorV3Interface(_tokenPriceFeeds[i])
                );
                oracleFeedForToken[_deployFeeTokens[i]] = AggregatorV3Interface(
                _tokenPriceFeeds[i]
                );
                isPaymentToken[_deployFeeTokens[i]] = true;
            }
            unchecked {
                ++i;
            }
        }
    }

    function removeFeedAndToken(uint256 _id) internal {
        require(_id < deployFeeTokens.length, "ERROR: ID DONT EXIST");
        delete isPaymentToken[address(deployFeeTokens[_id])];
        delete oracleFeedForToken[address(deployFeeTokens[_id])];
        if(_id < deployFeeTokens.length - 1) {
            for (uint256 i = _id; i < deployFeeTokens.length;) {
                deployFeeTokens[i] = deployFeeTokens[i + 1];
                tokenPriceFeeds[i] = tokenPriceFeeds[i + 1];
                unchecked {
                    ++i;
                }
            }
        }
        deployFeeTokens.pop();
        tokenPriceFeeds.pop();
    }

    function updateFeedsAndTokens(
        address[] memory _deployFeeTokens,
        address[] memory _tokenPriceFeeds,
        uint256[] memory _ids
    ) internal {
        require(
            _deployFeeTokens.length == _tokenPriceFeeds.length &&
                _tokenPriceFeeds.length == _ids.length,
            "ERROR: INVALID TOKEN-FEED LENGTH"
        );
        for (uint256 i; i < _deployFeeTokens.length;) {
            require(
                _deployFeeTokens[i] != address(0) &&
                    _tokenPriceFeeds[i] != address(0) &&
                    _ids[i] < _deployFeeTokens.length,
                "ERROR: Cant set Address(0)"
            );
            if (_deployFeeTokens[i] != address(deployFeeTokens[i])) {
                isPaymentToken[address(deployFeeTokens[_ids[i]])] = false;
                isPaymentToken[_deployFeeTokens[i]] = true;
                deployFeeTokens[_ids[i]] = IERC20Metadata(_deployFeeTokens[i]);
            }
            tokenPriceFeeds[_ids[i]] = AggregatorV3Interface(
                _tokenPriceFeeds[i]
            );
            oracleFeedForToken[_deployFeeTokens[i]] = AggregatorV3Interface(
                _tokenPriceFeeds[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function updateCryptoFeedInternal(address _newCryptoPriceFeed) internal {
        require(_newCryptoPriceFeed != address(0), "ERROR: Cant set Address 0 as feed");
        cryptoPriceFeed = AggregatorV3Interface(_newCryptoPriceFeed);
    }
}