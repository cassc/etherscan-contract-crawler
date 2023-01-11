// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFeed.sol";
import "hardhat/console.sol";

import "./IAreumToken.sol";

contract AureumTrader is AccessControl {
    using Address for address;
    address public tokenBusd =
        address(0x000000000000000000000000000000000000007E);
    address public tokenUsdc =
        address(0x000000000000000000000000000000000000007E);
    address public tokenUsdt =
        address(0x000000000000000000000000000000000000007E);
    address public tokenAerum =
        address(0x000000000000000000000000000000000000007E);
    address public taxWallet =
        address(0x000000000000000000000000000000000000007E);
    address public mainWallet =
        address(0x000000000000000000000000000000000000007E);
    address public tickerContract =
        address(0x000000000000000000000000000000000000007E);

    uint256 private tax = 200;
    uint256 private decimalsFromFeedContract = 8;

    constructor(
        address tokenBusd_,
        address tokenUsdc_,
        address tokenUsdt_,
        address tokenAerum_,
        uint256 tax_,
        address taxWallet_,
        address owner_,
        address tickerContract_,
        address mainWallet_,
        uint256 decimalsFromFeedContract_
    ) {
        tokenBusd = tokenBusd_;
        tokenUsdc = tokenUsdc_;
        tokenUsdt = tokenUsdt_;
        tokenAerum = tokenAerum_;
        tax = tax_;
        taxWallet = taxWallet_;
        tickerContract = tickerContract_;
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
        mainWallet = mainWallet_;
        decimalsFromFeedContract = decimalsFromFeedContract_;
    }

    function getTokenAddress(uint256 usdId_) public view returns (address) {
        if (usdId_ == 1) {
            return tokenBusd;
        } else if (usdId_ == 2) {
            return tokenUsdc;
        } else if (usdId_ == 3) {
            return tokenUsdt;
        } else {
            revert("Invalid Stable!");
        }
    }

    function updateTokenUsd(uint256 usdId_, address newTokenAddress_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a owner"
        );
        if (usdId_ == 1) {
            tokenBusd = newTokenAddress_;
        } else if (usdId_ == 2) {
            tokenUsdc = newTokenAddress_;
        } else if (usdId_ == 3) {
            tokenUsdt = newTokenAddress_;
        } else {
            revert("Invalid Stable!");
        }
    }

    function getTaxWallet() public view returns (address) {
        return taxWallet;
    }

    function updateTaxWallet(address newTaxWallet_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a owner"
        );
        taxWallet = newTaxWallet_;
    }

    function getTickerContract() public view returns (address) {
        return tickerContract;
    }

    function updateTickerContract(address newTicker_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a owner"
        );
        tickerContract = newTicker_;
    }

    function getMainWallet() public view returns (address) {
        return mainWallet;
    }

    function updateMainWallet(address newMainWallet_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a owner"
        );
        mainWallet = newMainWallet_;
    }

    function getTokenNegociated() public view returns (address) {
        return tokenAerum;
    }

    function updateTokenNegociated(address newToken_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a owner"
        );
        tokenAerum = newToken_;
    }

    function getDecimalsFromFeedContract() public view returns (uint256) {
        return decimalsFromFeedContract;
    }

    function updateDecimalsFromFeedContract(uint256 newDecimal_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a owner"
        );
        decimalsFromFeedContract = newDecimal_;
    }

    function getTax() public view returns (uint256) {
        return tax;
    }

    function updateTax(uint256 newTax_) external {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a owner"
        );
        tax = newTax_;
    }

    function getValueOfPax() public view returns (int256) {
        (, int256 answer, , , ) = IFeed(tickerContract).latestRoundData();
        return answer;
    }

    function calculateValueToSellerToken(uint256 usdValue_)
        public
        view
        returns (uint256)
    {
        uint256 valueOfPax = uint256(getValueOfPax());
        console.log("valueOfPax", valueOfPax);
        // uint256 valueOfPaxNormalized = valueOfPax /
        //     uint256(10)**decimalsFromFeedContract;

        uint256 value1g = 283495;
        console.log("value1g", value1g);

        uint256 fulledPax = (usdValue_ * 10**14) / (valueOfPax / value1g);

        return fulledPax;
    }

    function calculateTokenQntToBuyWithUsd(uint256 usdValue_)
        public
        view
        returns (uint256)
    {
        require(usdValue_ > 0, "The value to spend must be > 0");

        uint256 amountOfUsdScaled = usdValue_ *
            uint256(10)**decimalsFromFeedContract;

        uint256 amountToBuyWithTax = calculateUsdValueWithTaxValue(
            amountOfUsdScaled
        );

        uint256 amountOfTokens = calculateValueToSellerToken(
            amountToBuyWithTax
        );

        return amountOfTokens;
    }

    function calculateUsdValueWithTaxValue(uint256 usdValue_)
        public
        view
        returns (uint256)
    {
        require((usdValue_ / 10000) * 10000 == usdValue_, "value too small");

        uint256 totalTax = (usdValue_ * tax) / 10000;
        return usdValue_ - totalTax;
    }

    function buyWithStable(uint256 usdValue_, uint256 stable) external payable {
        require(usdValue_ > 0, "The value to spend must be > 0");

        uint256 amountOfUsdScaled = usdValue_ * uint256(10)**18;

        uint256 amountToBuyWithTax = calculateUsdValueWithTaxValue(
            amountOfUsdScaled
        );

        uint256 amountOfTax = amountOfUsdScaled - amountToBuyWithTax;

        uint256 amountOfTokens = calculateValueToSellerToken(
            amountToBuyWithTax
        );

        if (stable == 1) {
            bool sentBusd = IERC20(tokenBusd).transferFrom(
                _msgSender(),
                address(mainWallet),
                amountToBuyWithTax
            );
            require(sentBusd, "Failed to transfer busd to tax wallet");

            bool sentBusdTax = IERC20(tokenBusd).transferFrom(
                _msgSender(),
                address(taxWallet),
                amountOfTax
            );
            require(sentBusdTax, "Failed to transfer busd to tax wallet");
        } else if (stable == 2) {
            bool sentUsdc = IERC20(tokenUsdc).transferFrom(
                _msgSender(),
                address(mainWallet),
                amountToBuyWithTax
            );
            require(sentUsdc, "Failed to transfer usdc to main wallet");

            bool sentUsdcTax = IERC20(tokenUsdc).transferFrom(
                _msgSender(),
                address(taxWallet),
                amountOfTax
            );
            require(sentUsdcTax, "Failed to transfer usdc to tax wallet");
        } else if (stable == 3) {
            bool sentUsdt = IERC20(tokenUsdt).transferFrom(
                _msgSender(),
                address(mainWallet),
                amountToBuyWithTax
            );
            require(sentUsdt, "Failed to transfer usdt to main wallet");

            bool sentUsdtTax = IERC20(tokenUsdt).transferFrom(
                _msgSender(),
                address(taxWallet),
                amountOfTax
            );
            require(sentUsdtTax, "Failed to transfer usdt to tax wallet");
        } else {
            revert("Invalid Stable!");
        }

        //Transfer token to the msg.sender
        IAreumToken(tokenAerum).mint(_msgSender(), amountOfTokens);
    }
}