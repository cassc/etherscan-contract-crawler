// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
    @dev Base transactor to encapsulate reusable features: 
    - Access Control.
    - Pause.
    - Add/Remove payment tokens.
    - Set time to make a purchase after signing.
 */
abstract contract BaseTransactor is AccessControlEnumerable, Pausable {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
    address public constant ETH_CONSTANT = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event PaymentTokensAdded(address[] indexed paymentTokens);
    event PaymentTokensRemoved(address[] indexed paymentTokens);
    event SecondsToBuySet(uint256 oldSecondsToBuy, uint256 newSecondsToBuy);
    event EtherReceived(address indexed account, uint256 amount);

    address public immutable weth;
    uint256 public secondsToBuy;

    // Payment token address => true or false
    mapping(address => bool) public isAllowedToken;

    constructor(
        address adminAddress,
        address configuratorAddress,
        address signerAddress,
        uint256 secondsToBuyValue,
        address wethAddress,
        bool addEthAsPayment
    ) {
        require(wethAddress != address(0x0), "!weth");
        require(secondsToBuyValue > 0, "!seconds_buy");

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(SIGNER_ROLE, signerAddress);
        _setupRole(CONFIGURATOR_ROLE, configuratorAddress);
        _setupRole(CONFIGURATOR_ROLE, _msgSender());

        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());

        secondsToBuy = secondsToBuyValue;
        weth = wethAddress;

        if (addEthAsPayment) {
            address[] memory paymentTokensList = new address[](2);
            paymentTokensList[0] = ETH_CONSTANT;
            paymentTokensList[1] = wethAddress;
            _addPaymentTokens(paymentTokensList);
        }
    }

    function addPaymentTokens(
        address[] calldata paymentTokensList
    ) external onlyRole(CONFIGURATOR_ROLE) {
        require(paymentTokensList.length > 0, "tokens_list_empty");
        _addPaymentTokens(paymentTokensList);
    }

    function removePaymentTokens(
        address[] calldata paymentTokensList
    ) external onlyRole(CONFIGURATOR_ROLE) {
        require(paymentTokensList.length > 0, "tokens_list_empty");
        _removePaymentTokens(paymentTokensList);
    }

    function setSecondsToBuy(uint256 newSecondsToBuy) external onlyRole(CONFIGURATOR_ROLE) {
        uint256 oldSecondsToBuy = secondsToBuy;
        secondsToBuy = newSecondsToBuy;
        emit SecondsToBuySet(oldSecondsToBuy, newSecondsToBuy);
    }

    function pause() external onlyRole(CONFIGURATOR_ROLE) {
        super._pause();
    }

    function unpause() external onlyRole(CONFIGURATOR_ROLE) {
        super._unpause();
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
}