// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./EquityRevenueHolder.sol";

contract ERHPaymentSplitter is
    Initializable,
    ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    event ERC20PaymentReleased(
        uint256 tokenId,
        IERC20Upgradeable indexed token,
        address to,
        uint256 amount
    );

    uint256 public totalShares;

    // ERC20 token address => total number of tokens released
    mapping(IERC20Upgradeable => uint256) public erc20TotalReleased;

    // ERC20 token address => share token ID => number of tokens released
    mapping(IERC20Upgradeable => mapping(uint256 => uint256))
        public erc20Released;

    EquityRevenueHolder public shareToken;
    IERC20Upgradeable public defaultErc20;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        EquityRevenueHolder _shareToken,
        IERC20Upgradeable _defaultErc20,
        address admin
    ) public initializer {
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        shareToken = _shareToken;
        totalShares = _shareToken.supplyCap();
        defaultErc20 = _defaultErc20;

        _grantRole(UPGRADER_ROLE, admin);
    }

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
     * @dev Triggers a transfer to owner of `tokenId` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, uint256 shareTokenId) public {
        uint256 payment = _pendingPayment(token, shareTokenId);

        require(
            payment != 0,
            "ERHPaymentSplitter: tokenId is not due payment"
        );

        _release(token, shareTokenId, payment);
    }

    function tryRelease(IERC20Upgradeable token, uint256 shareTokenId) public {
        uint256 payment = _pendingPayment(token, shareTokenId);

        if (payment > 0) {
            _release(token, shareTokenId, payment);
        }
    }

    function autoRelease(uint256 shareTokenId) public {
        tryRelease(defaultErc20, shareTokenId);
    }

    function autoReleaseAll() public {
        for (uint256 i = 0; i < totalShares; i++) {
            tryRelease(defaultErc20, i);
        }
    }

    /**
     * @dev internal logic for computing the pending payment of an
     * `shareTokenId` given the token historical balances and already
     * released amounts.
     */
    function _pendingPayment(
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

    function _release(
        IERC20Upgradeable token,
        uint256 shareTokenId,
        uint256 payment
    ) private {
        erc20Released[token][shareTokenId] += payment;
        erc20TotalReleased[token] += payment;

        address owner = shareToken.ownerOf(shareTokenId);
        token.safeTransfer(owner, payment);
        emit ERC20PaymentReleased(shareTokenId, token, owner, payment);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}