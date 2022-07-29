// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "./interfaces/IHYFI_PriceCalculator.sol";
import "./interfaces/IHYFI_Referrals.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract HYFI_Presale is Initializable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IHYFI_PriceCalculator calc;
    IHYFI_Referrals referrals;

    mapping(address => BuyerData) buyerInfo;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalUnitAmount;
    uint256 public totalAmountSold;
    address internal collectorWallet;
    address[] internal _buyersAddressList;
    struct BuyerData {
        uint256 totalAmountBought;
        uint256 referralAmountBought;
        mapping(uint256 => uint256) referrals;
        uint256[] referralsList;
    }

    event AllUnitsSold(uint256 unitAmount, uint256 endTime);
    event CurrencyWithdrawn(address from, address to, uint256 amount);
    event ERC20Withdrawn(
        address from,
        address to,
        uint256 amount,
        address tokenAddress
    );
    event FundsRetrieved(address addr, uint256 amount);
    event UnitSold(
        address buyer,
        string token,
        uint256 amount,
        uint256 referral
    );

    modifier addressNotZero(address addr) {
        require(
            addr != address(0),
            "Passed parameter has zero address declared"
        );
        _;
    }

    modifier amountNotZero(uint256 amount) {
        require(amount > 0, "Passed amount is equal to zero");
        _;
    }

    modifier ongoingSale() {
        require(
            block.timestamp >= startTime,
            "You can not buy any units, sale has not started yet"
        );
        require(
            block.timestamp <= endTime,
            "You can no longer buy any units, time expired"
        );
        _;
    }

    modifier possiblePurchaseUntilHardcap(uint256 amount) {
        require(
            totalAmountSold + amount <= totalUnitAmount,
            "Hardcap is reached, can not buy that many units"
        );
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function initialize(
        address _priceCalculatorContractAddress,
        address _referralsContractAddress,
        address _collectorWallet,
        uint256 _startTime,
        uint256 _endTime
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        calc = IHYFI_PriceCalculator(_priceCalculatorContractAddress);
        referrals = IHYFI_Referrals(_referralsContractAddress);
        collectorWallet = _collectorWallet;
        startTime = _startTime;
        endTime = _endTime;
        totalUnitAmount = 10_000;
        totalAmountSold = 0;
    }

    function buyWithTokens(
        string memory token,
        bool buyWithHYFI,
        uint256 amount,
        uint256 referralCode
    )
        external
        virtual
        addressNotZero(msg.sender)
        amountNotZero(amount)
        ongoingSale
        possiblePurchaseUntilHardcap(amount)
    {
        require(
            keccak256(abi.encodePacked(token)) ==
                keccak256(abi.encodePacked("USDT")) ||
                keccak256(abi.encodePacked(token)) ==
                keccak256(abi.encodePacked("USDC")),
            "No stable coin provided"
        );
        uint256 discount = calc.discountPercentageCalculator(
            amount,
            msg.sender
        );
        if (buyWithHYFI) {
            _buyWithHYFIToken(token, amount, discount, referralCode);
            _updateData("HYFI", amount, msg.sender, referralCode);
        } else {
            _buyWithMainToken(token, amount, discount, referralCode);
            _updateData(token, amount, msg.sender, referralCode);
        }
    }

    function buyWithCurrency(uint256 amount, uint256 referralCode)
        external
        payable
        virtual
        addressNotZero(msg.sender)
        amountNotZero(amount)
        ongoingSale
        possiblePurchaseUntilHardcap(amount)
    {
        _buyWithCurrency(
            amount,
            calc.discountPercentageCalculator(amount, msg.sender),
            referralCode
        );
        _updateData("ETH", amount, msg.sender, referralCode);
    }

    function _buyWithMainToken(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 priceTotal = calc.simpleTokenPaymentCalculator(
            token,
            unitAmount,
            discount,
            referralCode
        );
        _buyWithERC20(calc.getTokenData(token).tokenAddress, priceTotal);
    }

    function _buyWithHYFIToken(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 HYFItokenPayment;
        uint256 stableCoinPaymentAmount;
        (stableCoinPaymentAmount, HYFItokenPayment) = calc
            .mixedTokenPaymentCalculator(
                token,
                unitAmount,
                discount,
                referralCode
            );
        _buyWithERC20(
            calc.getTokenData(token).tokenAddress,
            stableCoinPaymentAmount
        );
        _buyWithERC20(calc.getTokenData("HYFI").tokenAddress, HYFItokenPayment);
    }

    function _buyWithERC20(address tokenAddress, uint256 priceTotal)
        internal
        virtual
    {
        IERC20Upgradeable(tokenAddress).safeTransferFrom(
            msg.sender,
            collectorWallet,
            priceTotal
        );
    }

    function _buyWithCurrency(
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) internal virtual {
        uint256 priceTotal = calc.currencyPaymentCalculator(
            unitAmount,
            discount,
            referralCode
        );
        require(
            msg.value == priceTotal,
            "Buyer does not have enough funds to make this purchase"
        );
        (bool success, ) = payable(collectorWallet).call{
            gas: 200_000,
            value: priceTotal
        }("");
        require(success);
    }

    function _updateData(
        string memory token,
        uint256 unitAmount,
        address buyer,
        uint256 referralCode
    ) internal virtual {
        totalAmountSold += unitAmount;
        calc.setAmountBoughtWithReferral(token, unitAmount);
        if (buyerInfo[buyer].totalAmountBought == 0) {
            _buyersAddressList.push(buyer);
        }
        buyerInfo[buyer].totalAmountBought += unitAmount;
        if (totalAmountSold >= totalUnitAmount) {
            endTime = block.timestamp;
            emit AllUnitsSold(unitAmount, endTime);
        }
        if (referralCode != 0) {
            _updateReferral(unitAmount, referralCode, buyer);
        }
        emit UnitSold(buyer, token, unitAmount, referralCode);
    }

    function _updateReferral(
        uint256 amount,
        uint256 referralCode,
        address buyer
    ) internal virtual {
        /* If the buyer has yet to buy any units using this referral code,
           add the code to the buyer referral list (which referral codes did they use) */
        if (buyerInfo[buyer].referrals[referralCode] == 0) {
            buyerInfo[buyer].referralsList.push(referralCode);
        }
        // Add bought unit amount corresponding to the referral used  during the purchase
        buyerInfo[buyer].referrals[referralCode] += amount;
        referrals.updateAmountBoughtWithReferral(referralCode, amount);
        // Add to the total amount bought using referral code
        buyerInfo[buyer].referralAmountBought += amount;
    }

    function withdrawCurrency(address recipient, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        amountNotZero(amount)
        addressNotZero(recipient)
    {
        require(
            address(this).balance >= amount,
            "Contract does not have enough currency"
        );
        (bool success, ) = payable(recipient).call{gas: 200_000, value: amount}(
            ""
        );
        require(success);
        emit CurrencyWithdrawn(recipient, msg.sender, amount);
    }

    function withdrawERC20Tokens(
        address tokenAddress,
        address recipient,
        uint256 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        amountNotZero(amount)
        addressNotZero(recipient)
    {
        require(
            IERC20Upgradeable(tokenAddress).balanceOf(address(this)) >= amount,
            "Contract does not have enough ERC20 tokens"
        );
        IERC20Upgradeable(tokenAddress).safeTransfer(recipient, amount);

        emit ERC20Withdrawn(
            recipient,
            msg.sender,
            amount,
            address(tokenAddress)
        );
    }

    function setNewSaleTime(uint256 newStartTime, uint256 newEndTime)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        startTime = newStartTime;
        endTime = newEndTime;
    }

    function setCollectorWalletAddress(address newAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        collectorWallet = newAddress;
    }

    function setTotalUnitAmount(uint256 newAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        totalUnitAmount = newAmount;
    }

    function setNewPriceCalculatorImplementation(address newPriceCalculator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        calc = IHYFI_PriceCalculator(newPriceCalculator);
    }

    function setNewReferralImplementation(address newReferral)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        referrals = IHYFI_Referrals(newReferral);
    }

    function getBuyerData(address addr)
        external
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        return (
            buyerInfo[addr].totalAmountBought,
            buyerInfo[addr].referralAmountBought,
            buyerInfo[addr].referralsList
        );
    }

    function getBuyerReservedAmount(address addr)
        external
        view
        returns (uint256)
    {
        return buyerInfo[addr].totalAmountBought;
    }

    function getBuyerReferralData(address addr, uint256 referral)
        external
        view
        returns (uint256)
    {
        return (buyerInfo[addr].referrals[referral]);
    }

    function getTotalAmountOfBuyers() external view returns (uint256) {
        return (_buyersAddressList.length);
    }

    function getAllBuyers() external view returns (address[] memory) {
        return (_buyersAddressList);
    }
}