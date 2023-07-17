// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/BoringERC20.sol";

contract Redemption is Ownable, Pausable, ReentrancyGuard {
    using BoringERC20 for IERC20;
    IERC20 public fromToken;
    address[] public toTokens;
    uint256 public immutable fromDenominator;
    mapping(address => uint256) public exchangeRates;

    event Redeemed(
        address indexed user,
        address indexed toToken,
        uint256 amount
    );
    event TokenAdded(address indexed token, uint256 exchangeRate);
    event TokenRemoved(address indexed token);
    event ExchangeRateChanged(address indexed token, uint256 exchangeRate);

    constructor(
        IERC20 _fromToken,
        address[] memory _toTokens,
        uint256[] memory _exchangeRates
    ) {
        require(
            _toTokens.length == _exchangeRates.length,
            "Array lengths must be equal"
        );
        fromToken = _fromToken;
        fromDenominator = 10 ** fromToken.safeDecimals();
        toTokens = _toTokens;
        for (uint256 i = 0; i < toTokens.length; i++) {
            require(_exchangeRates[i] > 0, "Invalid exchange rate");
            exchangeRates[toTokens[i]] = _exchangeRates[i];
        }
    }

    /**
     * @dev Function for redeeming fromToken for other ERC20 tokens.
     * @param amount The amount of fromToken to be redeemed.
     */
    function redeem(uint256 amount) public whenNotPaused nonReentrant {
        require(
            fromToken.safeBalanceOf(msg.sender) >= amount,
            "Insufficient balance"
        );

        fromToken.safeTransferFrom(msg.sender, address(this), amount);

        for (uint256 i = 0; i < toTokens.length; i++) {
            uint256 toAmount = (amount * exchangeRates[toTokens[i]]) / fromDenominator;
            require(toAmount > 0, "Amount not enough");
            require(
                IERC20(toTokens[i]).safeBalanceOf(address(this)) >= toAmount,
                "Insufficient balance of contract"
            );
            IERC20(toTokens[i]).safeTransfer(msg.sender, toAmount);
            emit Redeemed(msg.sender, toTokens[i], toAmount);
        }
    }

    /**
     * @dev Function that allows the owner to add a new supported token.
     * @param token The address of the token being added.
     * @param exchangeRate The exchange rate of the new token.
     * @dev When setting exchangeRate, use the decimals of the token to be added(exchangeRate = Coefficient * 10**decimals )
     */
    function addToken(address token, uint256 exchangeRate) public onlyOwner {
        require(token != address(0), "Token address cannot be zero");
        require(exchangeRate > 0, "ExchangeRate cannot be 0");
        require(exchangeRates[token] == 0, "Token already exists");

        toTokens.push(token);
        exchangeRates[token] = exchangeRate;
        emit TokenAdded(token, exchangeRate);
    }

    /**
     * @dev Function that allows the owner to remove a supported token.
     * @param index The index of the token being removed.
     */
    function removeToken(uint256 index) public onlyOwner {
        address _token = toTokens[index];
        delete exchangeRates[_token];
        toTokens[index] = toTokens[toTokens.length - 1];
        toTokens.pop();
        emit TokenRemoved(_token);
    }

    /**
     * @dev Function that allows the owner to set the exchange rate of a supported token.
     * @param token The address of the token for which the exchange rate is being set.
     * @param exchangeRate The new exchange rate of the token.
     * @dev When setting exchangeRate, use the decimals of the token to be seted(exchangeRate = Coefficient * 10**decimals )
     */
    function setExchangeRate(
        address token,
        uint256 exchangeRate
    ) public onlyOwner {
        require(exchangeRate > 0, "Token rate cannot be zero");
        require(exchangeRates[token] > 0, "Token does not exist");
        exchangeRates[token] = exchangeRate;
        emit ExchangeRateChanged(token, exchangeRate);
    }

    /**
     * @dev Function that set pause and unpause.
     */
    function pause() public onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @dev Function for emergency withdrawal of tokens.
     * @param token Token address for emergency withdrawal.
     */
    function emergencyWithdraw(IERC20 token) external onlyOwner {
        token.safeTransfer(owner(), token.safeBalanceOf(address(this)));
    }

    /**
     * @dev Function for calculating the exchange of fromToken for other ERC20 tokens.
     * @param amount The amount of fromToken to be redeemed.
     */
    function calculateRedeem(
        uint256 amount
    ) external view returns (address[] memory, uint256[] memory) {
        uint[] memory toAmount = new uint[](toTokens.length);
        for (uint256 i = 0; i < toTokens.length; i++) {
            toAmount[i] = (amount * exchangeRates[toTokens[i]]) / fromDenominator;
            require(toAmount[i] > 0, "Amount not enough");
        }

        return (toTokens, toAmount);
    }
}