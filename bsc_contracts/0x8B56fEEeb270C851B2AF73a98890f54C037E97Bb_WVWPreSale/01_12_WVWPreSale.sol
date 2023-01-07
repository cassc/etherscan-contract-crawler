// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20WVW is IERC20 {
    function decimals() external view returns (uint8);
}

contract WVWPreSale is AccessControl, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    IERC20WVW public token;
    uint256 private tokenPrice;

    address walletPreSale;
    address walletTeam;
    address walletLiquidityExchange;

    mapping(address => uint256) usersMaxSpend;
    uint256 maxSpend;
    uint256 minSpend;

    constructor(
        address _token,
        address _owner,
        uint256 _tokenPrice,
        address _walletPreSale,
        address _walletTeam,
        address _walletLiquidityExchange,
        uint256 _maxSpend,
        uint256 _minSpend
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        token = IERC20WVW(_token);
        walletPreSale = _walletPreSale;
        tokenPrice = _tokenPrice;
        walletTeam = _walletTeam;
        walletLiquidityExchange = _walletLiquidityExchange;
        maxSpend = _maxSpend;
        minSpend = _minSpend;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setTokenPrice(uint256 _newPrice)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenPrice = _newPrice;
    }

    function buyTokens(uint256 _tokenAmount)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(
            msg.value >= minSpend,
            "There is a minimum required to buy tokens."
        );
        require(
            (usersMaxSpend[msg.sender] + msg.value) <= maxSpend,
            "This wallet already bought the maximum tokens allowed."
        );
        uint256 formatToken = _tokenAmount * 10**token.decimals();
        require(token.balanceOf(walletPreSale) > formatToken, "Out of stock.");
        (bool safeMath, uint256 result) = _tokenAmount.tryMul(tokenPrice);
        require(safeMath, "Problem with safe math.");
        require(
            result == msg.value,
            "You have to send exactly the price to buy the tokens."
        );
        usersMaxSpend[msg.sender] = usersMaxSpend[msg.sender] + msg.value;
        paymentRulesWallets(msg.value);
        token.transferFrom(walletPreSale, msg.sender, formatToken);
    }

    function paymentRulesWallets(uint256 _value) private {
        sendMoneyToWalletTeam(_value);
        sendMoneyToWalletLiquidityExchange(_value);
    }   

    function sendMoneyToWalletTeam(uint256 value) private {
        // Send 30% to Team Wallet
        (bool multSuccess, uint256 multResult) = value.tryMul(3000);
        require(multSuccess, "Problem with safe math.");
        (bool divSuccess, uint256 divResult) = multResult.tryDiv(10_000);
        require(divSuccess, "Problem with safe math.");

        payable(walletTeam).transfer(divResult);
    }

    function sendMoneyToWalletLiquidityExchange(uint256 value) private {
        // Send 70% to Liquidity Wallet
        (bool multSuccess, uint256 multResult) = value.tryMul(7000);
        require(multSuccess, "Problem with safe math.");
        (bool divSuccess, uint256 divResult) = multResult.tryDiv(10_000);
        require(divSuccess, "Problem with safe math.");

        payable(walletLiquidityExchange).transfer(divResult);
    }

    function getTokenPrice() public view returns (uint256 _tokenPrice) {
        return tokenPrice;
    }

    function getSpentValue(address _address)
        public
        view
        returns (uint256 _spentValue)
    {
        return usersMaxSpend[_address];
    }

    function getMinWei()
        public
        view
        returns (uint256 _minValue)
    {
        return minSpend;
    }

    function getMaxWei()
        public
        view
        returns (uint256 _maxValue)
    {
        return maxSpend;
    }
    
}