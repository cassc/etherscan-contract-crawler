// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../../tokens/oaths/IOath.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../Signable.sol";
import "../../libs/GenericBuyV3Lib.sol";
import "../../tokens/interfaces/IWETH.sol";

/**
    @dev This contract will be used as a store transactor for the Oath tokens (ERC1238).
 */
contract OathStoreTransactor is AccessControlEnumerable, Signable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using GenericBuyV3Lib for GenericBuyV3Lib.GenericBuyV3;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");

    address public constant ETH_CONSTANT = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct PurchaseInfo {
        uint256 typeId;
        uint256 amount;
    }

    event TokensBought(
        address indexed buyer,
        address indexed signer,
        address indexed paymentToken,
        uint256 purchaseId,
        uint256 typeId,
        uint256 quantity,
        uint256 totalPrice
    );

    event PaymentTokensAdded(address[] indexed paymentTokens);
    event PaymentTokensRemoved(address[] indexed paymentTokens);
    event SecondsToBuySet(uint256 oldSecondsToBuy, uint256 newSecondsToBuy);
    event EtherReceived(address indexed account, uint256 amount);

    address public immutable multisig;

    address public immutable nft;

    // Payment token address => true or false
    mapping(address => bool) public isAllowedToken;

    // purchaseId => type id, total
    mapping(uint256 => PurchaseInfo) public purchases;

    uint256 public secondsToBuy;

    address public immutable weth;

    constructor(
        address adminAddress,
        address configuratorAddress,
        address signerAddress,
        address multisigAddress,
        address nftAddress,
        address wethAddress,
        uint256 secondsToBuyValue
    ) {
        require(wethAddress != address(0x0), "!weth");
        require(secondsToBuyValue > 0, "!seconds_buy");
        _setRoleAdmin(SIGNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONFIGURATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(SIGNER_ROLE, signerAddress);
        _setupRole(CONFIGURATOR_ROLE, configuratorAddress);
        _setupRole(CONFIGURATOR_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, configuratorAddress);

        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());

        multisig = multisigAddress;
        nft = nftAddress;
        secondsToBuy = secondsToBuyValue;
        weth = wethAddress;
        address[] memory paymentTokensList = new address[](2);
        paymentTokensList[0] = ETH_CONSTANT;
        paymentTokensList[1] = wethAddress;
        _addPaymentTokens(paymentTokensList);
    }

    receive() external payable {
        require(msg.value > 0, "!ether_amount");
        emit EtherReceived(msg.sender, msg.value);
    }

    function buyTokens(GenericBuyV3Lib.GenericBuyV3 calldata buy)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(buy.totalPrice > 0, "!total_price");
        require(buy.amount == 1, "!amount");
        require(purchases[buy.purchaseId].amount == 0, "purchase_processed");
        require(isAllowedToken[buy.paymentToken], "!payment_token");
        require(buy.timestamp > block.timestamp - secondsToBuy, "too_late");

        address signer = buy.getSigner(msg.sender, address(this), _getChainId());
        require(hasRole(SIGNER_ROLE, signer), "!signer");

        _requireValidNonceAndSet(signer, buy.nonce);

        address paymentToken = buy.paymentToken;
        if (paymentToken == ETH_CONSTANT) {
            require(msg.value == buy.totalPrice, "!value");
            IWETH(weth).deposit{value: msg.value}();
        } else {
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), buy.totalPrice);
        }
        IERC20(weth).safeTransfer(multisig, IERC20(weth).balanceOf(address(this)));

        IOath(nft).mint(msg.sender, buy.typeId, bytes(""));
        purchases[buy.purchaseId] = PurchaseInfo({typeId: buy.typeId, amount: buy.amount});

        emit TokensBought(
            msg.sender,
            signer,
            buy.paymentToken,
            buy.purchaseId,
            buy.typeId,
            buy.amount,
            buy.totalPrice
        );
    }

    function addPaymentTokens(address[] calldata paymentTokensList)
        external
        hasRoleAccount(CONFIGURATOR_ROLE, msg.sender)
    {
        require(paymentTokensList.length > 0, "tokens_list_empty");
        _addPaymentTokens(paymentTokensList);
    }

    function removePaymentTokens(address[] calldata paymentTokensList)
        external
        hasRoleAccount(CONFIGURATOR_ROLE, msg.sender)
    {
        require(paymentTokensList.length > 0, "tokens_list_empty");
        _removePaymentTokens(paymentTokensList);
    }

    function setSecondsToBuy(uint256 newSecondsToBuy)
        external
        hasRoleAccount(CONFIGURATOR_ROLE, msg.sender)
    {
        uint256 oldSecondsToBuy = secondsToBuy;
        secondsToBuy = newSecondsToBuy;
        emit SecondsToBuySet(oldSecondsToBuy, newSecondsToBuy);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external hasRoleAccount(PAUSER_ROLE, msg.sender) {
        super._pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external hasRoleAccount(PAUSER_ROLE, msg.sender) {
        super._unpause();
    }

    /** View Functions */

    function getPurchaseInfo(uint256 purchaseId)
        external
        view
        returns (uint256 typeId, uint256 amount)
    {
        typeId = purchases[purchaseId].typeId;
        amount = purchases[purchaseId].amount;
    }

    /** Internal Functions */

    function _addPaymentTokens(address[] memory paymentTokensList) internal {
        for (uint256 index = 0; index < paymentTokensList.length; index++) {
            isAllowedToken[paymentTokensList[index]] = true;
        }
        emit PaymentTokensAdded(paymentTokensList);
    }

    function _removePaymentTokens(address[] memory paymentTokensList) internal {
        for (uint256 index = 0; index < paymentTokensList.length; index++) {
            isAllowedToken[paymentTokensList[index]] = false;
        }
        emit PaymentTokensRemoved(paymentTokensList);
    }

    /** Modifiers */

    modifier hasRoleAccount(bytes32 role, address account) {
        require(hasRole(role, account), "!account_access");
        _;
    }
}