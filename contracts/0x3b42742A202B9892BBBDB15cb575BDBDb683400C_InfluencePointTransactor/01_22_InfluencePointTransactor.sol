// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../Signable.sol";
import "../../finance/PaymentSplitter.sol";
import "../../libs/GenericERC20BuyLib.sol";
import "../../tokens/interfaces/IWETH.sol";
import "../BaseTransactor.sol";

/**
    @dev This contract will be used as a store transactor for Influence Points.
 */
contract InfluencePointTransactor is Signable, ReentrancyGuard, PaymentSplitter, BaseTransactor {
    using SafeERC20 for IERC20;
    using GenericERC20BuyLib for GenericERC20BuyLib.GenericERC20Buy;

    event TokensBought(
        address indexed buyer,
        address indexed signer,
        address indexed paymentToken,
        uint256 purchaseId,
        uint256 quantity,
        uint256 totalPrice
    );

    event MinimumAmountSet(uint256 oldMinimumAmount, uint256 newMinimumAmount);
    uint256 public minimumAmount;

    // purchaseId => amountBought
    mapping(uint256 => uint256) public purchases;

    constructor(
        address adminAddress,
        address configuratorAddress,
        address signerAddress,
        address wethAddress,
        uint256 secondsToBuyValue,
        uint256 minimumAmountValue,
        bool addEthAsPayment,
        address[] memory payees,
        uint256[] memory shares
    )
        PaymentSplitter(payees, shares)
        BaseTransactor(
            adminAddress,
            configuratorAddress,
            signerAddress,
            secondsToBuyValue,
            wethAddress,
            addEthAsPayment
        )
    {
        require(wethAddress != address(0x0), "!weth");
        require(secondsToBuyValue > 0, "!seconds_buy");

        minimumAmount = minimumAmountValue;
    }

    receive() external payable {
        require(msg.value > 0, "!ether_amount");
        emit EtherReceived(msg.sender, msg.value);
    }

    function buyTokens(
        GenericERC20BuyLib.GenericERC20Buy calldata buy
    ) public payable whenNotPaused nonReentrant {
        require(buy.totalPrice > 0, "!total_price");
        require(buy.amount >= minimumAmount, "!minimumAmount");
        require(purchases[buy.purchaseId] == 0, "purchase_processed");
        require(isAllowedToken[buy.paymentToken], "!payment_token");
        require(buy.timestamp > block.timestamp - secondsToBuy, "too_late");

        address signer = buy.getSigner(msg.sender, address(this), _getChainId());
        require(hasRole(SIGNER_ROLE, signer), "!signer");

        _requireValidNonceAndSet(signer, buy.nonce);

        if (buy.paymentToken == ETH_CONSTANT) {
            require(msg.value == buy.totalPrice, "!value");
            IWETH(weth).deposit{value: msg.value}();
            releasePayment(IERC20(weth));
        } else {
            IERC20(buy.paymentToken).safeTransferFrom(msg.sender, address(this), buy.totalPrice);
            releasePayment(IERC20(buy.paymentToken));
        }

        purchases[buy.purchaseId] = buy.amount;

        emit TokensBought(
            msg.sender,
            signer,
            buy.paymentToken,
            buy.purchaseId,
            buy.amount,
            buy.totalPrice
        );
    }

    function setMinimumAmount(uint256 newMinimunAmount) external onlyRole(CONFIGURATOR_ROLE) {
        uint256 oldMinimumAmount = minimumAmount;
        minimumAmount = newMinimunAmount;
        emit MinimumAmountSet(oldMinimumAmount, newMinimunAmount);
    }

    function getPurchaseInfo(uint256 purchaseId) external view returns (uint256) {
        return purchases[purchaseId];
    }

    function addPayee(address newPayee, uint256 newShares) external onlyRole(CONFIGURATOR_ROLE) {
        _addPayee(newPayee, newShares);
    }

    function deletePayee(uint256 index) external onlyRole(CONFIGURATOR_ROLE) {
        _deletePayee(index);
    }
}