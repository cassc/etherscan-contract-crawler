// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

contract SubscriptionManager is
    Initializable,
    UUPSUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20Upgradeable public token;
    address public recipientAddress;
    uint64 public minDuration;
    uint256 constant uUNIT = 1e18;

    struct SubscriptionStatus {
        uint8 subscriptionLevel;
        uint256 endTimestampScaled;
    }

    struct SubscriptionParameters {
        uint8 subscriptionLevel;
        uint256 durationScaled;
    }

    // Chain ID => DAO Address => Current Subscription
    mapping(uint256 => mapping(address => SubscriptionStatus))
        public subscriptions;

    // Subscription Level => Duration per 1 Token
    mapping(uint8 => uint64) public durationPerToken;

    // NFT Address => Token ID => Issuing Subscription
    mapping(address => mapping(uint256 => SubscriptionParameters))
        public receivableERC1155;

    event PaySubscription(
        uint256 indexed chainId,
        address indexed daoAddress,
        uint8 subscriptionLevel,
        uint256 timestamp
    );

    event PaySubscriptionWithERC1155(
        uint256 indexed chainId,
        address indexed daoAddress,
        address tokenAddress,
        uint256 tokenId,
        uint8 subscriptionLevel,
        uint256 timestamp
    );

    function initialize(
        IERC20Upgradeable _token,
        address _recipientAddress,
        uint64 _minDuration
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        token = _token;
        recipientAddress = _recipientAddress;
        minDuration = _minDuration;
    }

    function editToken(
        IERC20Upgradeable _token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token = _token;
    }

    function editMinDuration(
        uint64 _minDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minDuration = _minDuration;
    }

    function editRecipient(
        address _recipientAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        recipientAddress = _recipientAddress;
    }

    function editDurationPerToken(
        uint8 _subscriptionLevel,
        uint64 _timestamp
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        durationPerToken[_subscriptionLevel] = _timestamp;
    }

    function editReceivableERC1155(
        address _tokenAddress,
        uint256 _tokenId,
        uint8 _subscriptionLevel,
        uint64 _timestamp
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        receivableERC1155[_tokenAddress][_tokenId] = SubscriptionParameters({
            subscriptionLevel: _subscriptionLevel,
            durationScaled: _timestamp * uUNIT
        });
    }

    function setSubscriptionStatus(
        uint256 _chainId,
        address _dao,
        uint8 _level,
        uint64 _timestamp
    ) external onlyRole(MANAGER_ROLE) {
        subscriptions[_chainId][_dao] = SubscriptionStatus({
            subscriptionLevel: _level,
            endTimestampScaled: _timestamp * uUNIT
        });
    }

    function pay(
        uint256 _chainId,
        address _dao,
        uint8 _level,
        uint256 _tokenAmount
    ) external {
        SubscriptionStatus storage daoSubscription = subscriptions[_chainId][
            _dao
        ];

        require(
            daoSubscription.endTimestampScaled < block.timestamp * uUNIT ||
                (_level >= daoSubscription.subscriptionLevel),
            "SubscriptionManager: subscription can't be downgraded"
        );

        uint64 newLevelDuration = durationPerToken[_level];

        require(
            newLevelDuration > 0,
            "SubscriptionManager: invalid subscription level"
        );

        require(
            (_tokenAmount * newLevelDuration) >= uUNIT * (minDuration),
            "SubscriptionManager: subscription durationScaled is too low"
        );

        uint64 currentLevelDuration = durationPerToken[
            daoSubscription.subscriptionLevel
        ];

        uint256 alreadyPaidAmount = daoSubscription.endTimestampScaled >
            block.timestamp * uUNIT
            ? (daoSubscription.endTimestampScaled - block.timestamp * uUNIT) /
                currentLevelDuration
            : 0;

        uint256 newTimestampScaled = (newLevelDuration *
            (_tokenAmount + alreadyPaidAmount)) + block.timestamp * uUNIT;

        subscriptions[_chainId][_dao] = SubscriptionStatus({
            subscriptionLevel: _level,
            endTimestampScaled: newTimestampScaled
        });

        token.safeTransferFrom(msg.sender, recipientAddress, _tokenAmount);

        emit PaySubscription(_chainId, _dao, _level, newTimestampScaled);
    }

    function payWithERC1155(
        uint256 _chainId,
        address _dao,
        address _tokenAddress,
        uint256 _tokenId
    ) external {
        SubscriptionStatus storage daoSubscription = subscriptions[_chainId][
            _dao
        ];
        SubscriptionParameters storage tokenSubscription = receivableERC1155[
            _tokenAddress
        ][_tokenId];

        require(
            daoSubscription.endTimestampScaled < block.timestamp * uUNIT ||
                (tokenSubscription.subscriptionLevel >=
                    daoSubscription.subscriptionLevel),
            "SubscriptionManager: subscription can't be downgraded"
        );

        require(
            tokenSubscription.durationScaled > 0,
            "SubscriptionManager: unsupported ERC1155"
        );

        uint64 newLevelDuration = durationPerToken[
            tokenSubscription.subscriptionLevel
        ];

        uint64 currentLevelDuration = durationPerToken[
            daoSubscription.subscriptionLevel
        ];

        uint256 alreadyPaidAmount = daoSubscription.endTimestampScaled >
            block.timestamp * uUNIT
            ? (daoSubscription.endTimestampScaled - block.timestamp * uUNIT) /
                currentLevelDuration
            : 0;

        uint256 newTimestampScaled = (newLevelDuration * alreadyPaidAmount) +
            tokenSubscription.durationScaled +
            block.timestamp *
            uUNIT;

        subscriptions[_chainId][_dao] = SubscriptionStatus({
            subscriptionLevel: tokenSubscription.subscriptionLevel,
            endTimestampScaled: newTimestampScaled
        });

        IERC1155Upgradeable(_tokenAddress).safeTransferFrom(
            msg.sender,
            recipientAddress,
            _tokenId,
            1,
            hex""
        );

        emit PaySubscriptionWithERC1155(
            _chainId,
            _dao,
            _tokenAddress,
            _tokenId,
            tokenSubscription.subscriptionLevel,
            newTimestampScaled
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}