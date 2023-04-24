// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./EquityRevenueHolder.sol";

/*
 * Used for accumulating and distributing revenue share of the
 * EquityRevenueHolder token owners. It’s designed to be used with Chainlink
 * Automation to schedule automatic revenue distribution.
 */
contract ERHPaymentSplitter is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ===== CONSTANTS ===== */

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /* ===== GENERAL ===== */

    uint256 public totalShares;

    // ERC20 token address => total number of tokens released
    mapping(IERC20Upgradeable => uint256) public erc20TotalReleased;

    // ERC20 token address => share token ID => number of tokens released
    mapping(IERC20Upgradeable => mapping(uint256 => uint256))
        public erc20Released;

    EquityRevenueHolder public shareToken;
    IERC20Upgradeable[] public paymentTokens;

    /* ===== EVENTS ===== */

    event ERC20PaymentReleased(
        uint256 indexed tokenId,
        IERC20Upgradeable indexed token,
        address to,
        uint256 amount
    );

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        EquityRevenueHolder _shareToken,
        IERC20Upgradeable[] calldata _paymentTokens,
        address admin
    ) public initializer {
        __AccessControlEnumerable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        shareToken = _shareToken;
        totalShares = _shareToken.supplyCap();
        paymentTokens = _paymentTokens;

        _pause();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    /* ===== VIEWABLE ===== */

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee.
     * `token` should be the address of an IERC20 contract.
     */
    function released(IERC20Upgradeable token, uint256 shareTokenId)
        public
        view
        returns (uint256)
    {
        return erc20Released[token][shareTokenId];
    }

    /**
     * @dev Calculates the pending payment of an `shareTokenId` given the token
     * historical balances and already released amounts.
     */
    function pendingPayment(
        IERC20Upgradeable token,
        uint256 shareTokenId
    ) private view returns (uint256) {
        require(
            shareTokenId < totalShares,
            "ERHPaymentSplitter: invalid tokenId"
        );

        uint256 totalReceived = token.balanceOf(address(this)) +
            erc20TotalReleased[token];
        uint256 alreadyReleased = released(token, shareTokenId);

        return totalReceived / totalShares - alreadyReleased;
    }

    /* ===== FUNCTIONALITY ===== */

    /**
     * @dev Triggers transfers of the amount of payment tokens they are owed
     * to owner of `shareTokenId`, according to their percentage of the total
     * shares and their previous withdrawals.
     */
    function release(uint256 shareTokenId) public {
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            _release(paymentTokens[i], shareTokenId);
        }
    }

    function autoRelease(uint256 shareTokenId) public {
        for (uint256 i = 0; i < paymentTokens.length; i++) {
            _tryRelease(paymentTokens[i], shareTokenId);
        }
    }

    function autoReleaseAll() public {
        for (uint256 i = 0; i < totalShares; i++) {
            autoRelease(i);
        }
    }

    /* ===== MUTATIVE ===== */

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _pay(
        IERC20Upgradeable token,
        uint256 shareTokenId,
        uint256 payment
    ) private whenNotPaused {
        erc20Released[token][shareTokenId] += payment;
        erc20TotalReleased[token] += payment;

        address owner = shareToken.ownerOf(shareTokenId);
        token.safeTransfer(owner, payment);
        emit ERC20PaymentReleased(shareTokenId, token, owner, payment);
    }

    function _release(IERC20Upgradeable token, uint256 shareTokenId) private {
        uint256 payment = pendingPayment(token, shareTokenId);

        require(
            payment != 0,
            "ERHPaymentSplitter: tokenId is not due payment"
        );

        _pay(token, shareTokenId, payment);
    }

    function _tryRelease(IERC20Upgradeable token, uint256 shareTokenId) private {
        uint256 payment = pendingPayment(token, shareTokenId);

        if (payment > 0) {
            _pay(token, shareTokenId, payment);
        }
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}