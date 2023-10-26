// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract CryptoUnitySale is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    IERC20Metadata public immutable tokenAddr;
    address public CUT_BNB_PAIR;
    uint256 public tokenPrice; // Token Price in USD
    uint256 constant priceDecimals = 1e6; // ex : If token price is 100 => $0.0001
    mapping(address => AggregatorV3Interface) public priceFeeds; // Mapping of payment tokens to price feeds

    event TokenPurchased(
        address indexed buyer,
        address indexed paymentToken,
        uint256 payAmount,
        uint256 amount
    );

    constructor(IERC20Metadata _tokenAddr, uint256 _tokenPrice) {
        tokenAddr = _tokenAddr;
        tokenPrice = _tokenPrice;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addOperator(
        address _operator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(OPERATOR_ROLE, _operator);
    }

    // Add a price feed for a payment token
    function addPaymentToken(
        address _paymentToken,
        address _priceFeedAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        priceFeeds[_paymentToken] = AggregatorV3Interface(_priceFeedAddress);
    }

    function setTokenPrice(
        uint256 _tokenPrice
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenPrice = _tokenPrice; // Set the token price in wei
    }

    function setTokenPair(
        address _tokenPair
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        IUniswapV2Pair pair = IUniswapV2Pair(_tokenPair);
        require(
            address(pair.token0()) == address(tokenAddr) ||
                address(pair.token1()) == address(tokenAddr)
        );
        CUT_BNB_PAIR = _tokenPair; // Set the token price in wei
    }

    function purchaseTokensWithERC20(
        uint256 _paymentTokenAmount,
        address _paymentToken
    ) public {
        uint256 amount = getOutputFromInput(_paymentTokenAmount, _paymentToken);

        // Ensure the user sends enough payment tokens
        require(
            IERC20Metadata(_paymentToken).transferFrom(
                msg.sender,
                address(this),
                _paymentTokenAmount
            ),
            "Token transfer failed"
        );

        emit TokenPurchased(
            msg.sender,
            _paymentToken,
            _paymentTokenAmount,
            amount
        );
    }

    function purchaseTokensWithNative() public payable {
        uint256 amount = getOutputFromInput(msg.value, address(0));

        emit TokenPurchased(msg.sender, address(0), msg.value, amount);
    }

    function getOutputFromInput(
        uint256 _amount,
        address _token
    ) public view returns (uint256 estimate) {
        AggregatorV3Interface priceFeed = priceFeeds[_token];
        uint256 cutPrice = getTokenPrice();
        require(
            address(priceFeed) != address(0),
            "Price feed not set for this token"
        );

        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price from Chainlink");
        uint256 decimals = 1e18;
        if (_token != address(0)) {
            decimals = 10 ** IERC20Metadata(_token).decimals();
        }
        estimate =
            (((_amount * (10 ** 9)) /
                cutPrice) *
                priceDecimals *
                uint256(price)) /
            (10 ** priceFeed.decimals()) /
            decimals;
    }

    function getTokenPrice() public view returns (uint256 price) {
        price = tokenPrice;
        if (CUT_BNB_PAIR != address(0)) {
            IUniswapV2Pair pair = IUniswapV2Pair(CUT_BNB_PAIR);
            (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
            uint256 decimals = address(pair.token0()) == address(tokenAddr)
                ? IERC20Metadata(pair.token1()).decimals()
                : IERC20Metadata(pair.token0()).decimals();
            uint256 priceInBNB = address(pair.token0()) == address(tokenAddr)
                ? (reserve0 * (10 ** decimals)) / reserve1
                : (reserve1 * (10 ** decimals)) / reserve0;
            AggregatorV3Interface priceFeed = priceFeeds[address(0)];
            (, int256 bnbPrice, , , ) = priceFeed.latestRoundData();
            price = (priceInBNB * uint256(bnbPrice)) / (10 ** (priceFeed.decimals() + decimals - priceDecimals));
        }
    }

    // Withdraw native tokens from the contract
    function withdrawNativeTokens() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Withdraw ERC20 tokens from the contract
    function withdrawERC20Tokens(
        address _token,
        uint256 _amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            IERC20Metadata(_token).transfer(msg.sender, _amount),
            "Token transfer failed"
        );
    }
}