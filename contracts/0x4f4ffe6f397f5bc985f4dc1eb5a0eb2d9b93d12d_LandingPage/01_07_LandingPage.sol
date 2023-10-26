// SPDX-License-Identifier: Mit
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LandingPage is Ownable {
    using SafeERC20 for IERC20;

    uint256 private constant PAYMENT_CURRENCY_PERCENTAGE = 60;
    uint256 private constant VISE_TOKEN_DECIMALS = 10 ** 18;
    uint256 private priceInUsdt;
    uint256 public commissionPercentage;

    IERC20 public usdt;
    IERC20 public viseToken;

    event EtherWithdrawn(address to, uint256 amount);
    event ERC20Withdrawn(IERC20 token, address to, uint256 amount);
    event BoughtWithUsdt(
        address buyer,
        uint256 usdtAmount,
        uint256 tokenAmount,
        bool hasInvitationAddress
    );
    event UsdtCommissionDistributed(
        address buyer,
        address recipient,
        uint256 paymentCurrencyAmount,
        uint256 tokenAmount
    );
    event PriceInUsdtChanged(uint256 oldPrice, uint256 newPrice);
    event CommissionPercentageChanged(
        uint256 oldPercentage,
        uint256 newPercentage
    );

    /// @dev Initializes the contract with the given parameters.
    /// @param _priceInUsdt The price of 1 token in USDT.
    /// @param _usdt The address of the USDT token contract.
    constructor(address _owner, uint256 _priceInUsdt, IERC20 _viseToken, IERC20 _usdt) {
        priceInUsdt = _priceInUsdt;
        usdt = _usdt;
        viseToken = _viseToken;
        commissionPercentage = 8;
        _transferOwnership(_owner);
    }

    /// @dev Allows the contract owner to change the commission percentage for transactions.
    ///
    /// This function allows the contract owner to adjust the commission percentage within a specified range
    /// (5% to 10%). The commission percentage is used to calculate the commission for transactions.
    ///
    /// Requirements:
    /// - The caller must be the contract owner.
    /// - The new percentage must be within the valid range (5% to 10%).
    ///
    /// @param _newPercentage The new commission percentage to set.
    ///
    function changeCommissionPercentage(
        uint256 _newPercentage
    ) external onlyOwner {
        require(
            _newPercentage >= 5 && _newPercentage <= 10,
            "Out of range: must be 5-10%"
        );
        uint256 oldPercentage = commissionPercentage;
        commissionPercentage = _newPercentage;
        emit CommissionPercentageChanged(oldPercentage, commissionPercentage);
    }

    /// @dev Allows the owner to change the price of 1 token in USDT.
    /// @param _price The new price of 1 token in USDT.
    function changePriceInUsdt(uint256 _price) external onlyOwner {
        uint256 oldPrice = priceInUsdt;
        priceInUsdt = _price;
        emit PriceInUsdtChanged(oldPrice, _price);
    }

    /// @dev Allows users to buy tokens with USDT, specifying an inviting address.
    /// @param _usdtAmount The amount of USDT to spend on tokens.
    /// @param _invitingAddress The address that invited the buyer.
    function buyWithUsdt(
        uint256 _usdtAmount,
        address _invitingAddress
    ) external {
        require(
            msg.sender != _invitingAddress,
            "You cannot invite yourself to buy tokens."
        );
        _buyWithUsdt(_usdtAmount, true);
        _distributeCommission(_invitingAddress, _usdtAmount);
    }

    /// @dev Allows users to buy tokens with USDT without specifying an inviting address.
    /// @param _usdtAmount The amount of USDT to spend on tokens.
    function buyWithUsdt(uint256 _usdtAmount) external {
        _buyWithUsdt(_usdtAmount, false);
    }

    ///@dev Distributes commissions, including tokens and USDT to the specified address.
    ///@param _to The address to which commissions will be distributed.
    ///@param _tokenAmount The amount of tokens to be minted and sent.
    ///@param _usdtAmount The amount of USDT to be transferred.
    ///@dev Only the contract owner can call this function.
    function distributeCommission(
        address _to,
        uint256 _tokenAmount,
        uint256 _usdtAmount
    ) external onlyOwner {
        if (_tokenAmount > 0) {
            viseToken.safeTransfer(_to, _tokenAmount);
        }
        if (_usdtAmount > 0) {
            usdt.safeTransfer(_to, _usdtAmount);
        }
    }

    /// @dev Allows the owner to withdraw ETH from the contract.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient founds");
        address payable to = payable(msg.sender);
        to.transfer(_amount);
        emit EtherWithdrawn(to, _amount);
    }

    /// @dev Allows the owner to withdraw a specified amount of ERC20 tokens from the contract.
    /// @param _tokenAddress The address of the ERC20 token to withdraw.
    /// @param _amount The amount of ERC20 tokens to withdraw.
    function withdrawERC20(
        IERC20 _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        _tokenAddress.safeTransfer(msg.sender, _amount);
        emit ERC20Withdrawn(_tokenAddress, msg.sender, _amount);
    }

    /// @dev Retrieves the current price of 1 token in USDT (Tether).
    /// @return The price of 1 token in USDT, represented as a uint256.
    function getPriceInUsdt() public view returns (uint256) {
        return priceInUsdt;
    }

    ///@dev Internal function for buying tokens with USDT.
    ///@dev Requires that the sent USDT amount is equal to or greater than `priceInUsdt`.
    ///@param _usdtAmount The amount of USDT to spend on tokens.
    function _buyWithUsdt(
        uint256 _usdtAmount,
        bool _hasInvitationAddress
    ) internal {
        require(_usdtAmount >= priceInUsdt, "Not paid enough");
        usdt.safeTransferFrom(msg.sender, address(this), _usdtAmount);
        uint256 xTokenAmount = (_usdtAmount * VISE_TOKEN_DECIMALS) /
            priceInUsdt;
        viseToken.safeTransfer(msg.sender, xTokenAmount);
        emit BoughtWithUsdt(
            msg.sender,
            _usdtAmount,
            xTokenAmount,
            _hasInvitationAddress
        );
    }

    /// @dev Distributes commission in tokens and payment currency (USDT).
    /// @param _to The address to receive the commission.
    /// @param _amount The total payment currency amount (USDT).
    function _distributeCommission(address _to, uint256 _amount) internal {
        (
            uint256 tokenAmount,
            uint256 paymentCurrencyAmount
        ) = _calculateCommission(_amount);
        viseToken.safeTransfer(_to, tokenAmount);
        usdt.safeTransfer(_to, paymentCurrencyAmount);
        emit UsdtCommissionDistributed(
            msg.sender,
            _to,
            paymentCurrencyAmount,
            tokenAmount
        );
    }

    /// @dev Calculates the commission in tokens and payment currency (USDT).
    /// @param _amount The total payment currency amount (USDT).
    function _calculateCommission(
        uint256 _amount
    )
        internal
        view
        returns (uint256 tokenAmount, uint256 paymentCurrencyAmount)
    {
        uint256 commission = (_amount * commissionPercentage) / 100;
        paymentCurrencyAmount =
            (commission * PAYMENT_CURRENCY_PERCENTAGE) /
            100;
        uint256 currencyToTokenAmount = commission - paymentCurrencyAmount;
        tokenAmount =
            (currencyToTokenAmount * VISE_TOKEN_DECIMALS) /
            priceInUsdt;
    }
}