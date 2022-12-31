// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "../utils/UUPSUpgradeableByRole.sol";
import "../interfaces/INash21Factory.sol";
import "../interfaces/INash21Guarantee.sol";
import "../interfaces/INash21Manager.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title The contract of Nash21Guarantee
/// @notice Handles payments of the Nash21 protocol, regarding tokens
/// @dev Gets payments from tenants and pays renters / token owners
contract Nash21Guarantee is /*INash21Guarantee,*/ UUPSUpgradeableByRole {
    bytes32 internal constant _GUARANTEE_ADMIN_ROLE = keccak256("GUARANTEE_ADMIN_ROLE");
    bytes32 internal constant _GUARANTEE_FUNDER_ROLE = keccak256("GUARANTEE_FUNDER_ROLE");

    // mapping(uint256 => uint256) private _paid;

    // mapping(uint256 => uint256) private _distributed;

    // mapping(bytes32 => address) private _feeds;

    // /** PUBLIC FUNCTIONS */

    // /// @inheritdoc INash21Guarantee
    // function paid (
    //     uint256 id
    // )
    //     external
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     return _paid[id];
    // }

    // /// @inheritdoc INash21Guarantee
    // function distributed (
    //     uint256 id
    // )
    //     external
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     return _distributed[id];
    // }

    // /// @inheritdoc INash21Guarantee
    // function feeds (
    //     bytes32 id
    // )
    //     external
    //     view
    //     returns (
    //         address
    //     )
    // {
    //     return _feeds[id];
    // }

    function extractFunds(address token, address to, uint256 amount)
        public
        onlyRole(_GUARANTEE_FUNDER_ROLE)
        whenNotPaused
    {
        IERC20(token).transfer(to, amount);
    }

    // /// @inheritdoc INash21Guarantee
    // function fund (
    //     address token,
    //     address from,
    //     uint256 amount
    // )
    //     public
    // {
    //     IERC20(token).transferFrom(from, address(this), amount);
    //     emit Fund(token, from, amount);
    // }

    // function _claim (
    //     uint256 id
    // )
    //     internal
    // {
    //     INash21Factory factoryInterface = INash21Factory(
    //         INash21Manager(manager).get(keccak256("FACTORY"))
    //     );

    //     address owner = factoryInterface.ownerOf(id);
    //     (
    //         ,
    //         uint256 value,
    //         bytes32 currency,
    //         uint256 startDate,
    //         uint256 endDate,
    //         ,
    //         address account,

    //     ) = factoryInterface.data(id);
    //     uint256 amount = _claimable(id, startDate, endDate, value);
    //     require(
    //         msg.sender == owner || msg.sender == account || msg.sender == INash21Manager(manager).get(keccak256("AUTOPAY")),
    //         "Nash21Guarantee: only owner, recipient or autopay"
    //     );
    //     require(amount > 0, "Nash21Guarantee: nothing to claim");
    //     _distributed[id] += amount;
    //     IERC20 tokenInterface = IERC20(
    //         INash21Manager(manager).get(keccak256("USDT"))
    //     );
    //     tokenInterface.transfer(account, _transformCurrency(currency, amount));
    //     emit Claim(id, account, amount, currency);
    // }

    // /// @inheritdoc INash21Guarantee
    // function claim (
    //     uint256 id
    // )
    //     public
    //     whenNotPaused
    // {
    //     _claim(id);
    // }

    // /// @inheritdoc INash21Guarantee
    // function claimBatch (
    //     uint256[] calldata ids
    // )
    //     public
    //     whenNotPaused
    // {
    //     for (uint256 i = 0; i < ids.length; i++) {
    //         _claim(ids[i]);
    //     }
    // }

    // /// @inheritdoc INash21Guarantee
    // function claimable (
    //     uint256 id
    // )
    //     external
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     return getReleased(id) - _distributed[id];
    // }

    // /// @inheritdoc INash21Guarantee
    // function getReleased (
    //     uint256 id
    // )
    //     public
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     INash21Factory factoryInterface = INash21Factory(
    //         INash21Manager(manager).get(keccak256("FACTORY"))
    //     );

    //     (
    //         ,
    //         uint256 value,
    //         ,
    //         uint256 startDate,
    //         uint256 endDate,
    //         ,
    //         ,

    //     ) = factoryInterface.data(id);
    //     return _getReleased(startDate, endDate, value);
    // }

    // /// @inheritdoc INash21Guarantee
    // function setFeeds (
    //     bytes32[] memory currencies,
    //     address[] memory feeds_
    // )
    //     public
    //     onlyRole (_GUARANTEE_ADMIN_ROLE)
    // {
    //     require(
    //         currencies.length == feeds_.length,
    //         "Nash21Guarantee: arrays are not the same size"
    //     );
    //     for (uint256 i = 0; i < currencies.length; i++) {
    //         bytes32 currency = currencies[i];
    //         address feed = feeds_[i];
    //         _setFeed(currency, feed);
    //     }
    // }

    // /// @inheritdoc INash21Guarantee
    // function transformCurrency (
    //     bytes32 currency,
    //     uint256 amount
    // )
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return _transformCurrency(currency, amount);
    // }

    // function _pay (
    //     uint256 id,
    //     uint256 amount
    // ) internal {
    //     INash21Factory factoryInterface = INash21Factory(
    //         INash21Manager(manager).get(keccak256("FACTORY"))
    //     );
    //     IERC20 tokenInterface = IERC20(
    //         INash21Manager(manager).get(keccak256("USDT"))
    //     );
    //     (uint256 originId, , , , , , , ) = factoryInterface.data(id);
    //     (, uint256 value, bytes32 currency, , , , , ) = factoryInterface.data(
    //         originId
    //     );
    //     uint256 left = value - _paid[originId];
    //     address account = msg.sender;

    //     if (amount < left) {
    //         _paid[originId] += amount;
    //         tokenInterface.transferFrom(
    //             account,
    //             address(this),
    //             transformCurrency(currency, amount)
    //         );
    //         emit Pay(originId, account, amount, currency);
    //     } else {
    //         require(left > 0, "Nash21Guarantee: token already paid");
    //         _paid[originId] += left;
    //         tokenInterface.transferFrom(
    //             account,
    //             address(this),
    //             transformCurrency(currency, left)
    //         );
    //         emit Pay(originId, account, left, currency);
    //     }
    // }

    // /// @inheritdoc INash21Guarantee
    // function pay (
    //     uint256 id,
    //     uint256 amount
    // )
    //     public
    //     whenNotPaused
    // {
    //     _pay(id, amount);
    // }

    // /// @inheritdoc INash21Guarantee
    // function payBatch(
    //     uint256[] calldata ids,
    //     uint256[] calldata amounts
    // )
    //     public
    //     whenNotPaused
    // {
    //     require(
    //         ids.length == amounts.length,
    //         "Nash21Guarantee: arrays are not the same size"
    //     );
    //     for (uint256 i = 0; i < ids.length; i++) {
    //         _pay(ids[i], amounts[i]);
    //     }
    // }

    // /// @inheritdoc INash21Guarantee
    // function split (
    //     uint256 id,
    //     uint256 timestamp
    // )
    //     public
    //     returns (
    //         uint256,
    //         uint256
    //     )
    // {
    //     address account = msg.sender;
    //     INash21Factory factoryInterface = INash21Factory(
    //         INash21Manager(manager).get(keccak256("FACTORY"))
    //     );

    //     (uint256 id1, uint256 id2) = factoryInterface.split(
    //         account,
    //         id,
    //         timestamp
    //     );
    //     (, uint256 value1, , , , , , ) = factoryInterface.data(id1);

    //     if (_distributed[id] > value1) {
    //         _distributed[id1] = value1;
    //         _distributed[id2] = _distributed[id] - value1;
    //     } else {
    //         _distributed[id1] = _distributed[id];
    //     }

    //     emit Split(id, account, timestamp, id1, id2);
    //     return (id1, id2);
    // }

    function initialize( /*bytes32 initialCurrency, address initialFeed*/ ) public initializer {
        __AccessControlProxyPausable_init(msg.sender);
        // _setFeed(initialCurrency, initialFeed);
    }

    // /** PRIVATE/INTERNAL FUNCTIONS */

    // function _setFeed (
    //     bytes32 currency,
    //     address feed
    // )
    //     internal
    // {
    //     _feeds[currency] = feed;
    //     emit NewFeed(currency, feed);
    // }

    // function _transformUsd (
    //     uint256 usd
    // )
    //     internal
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     AggregatorV3Interface aggregatorInterface = AggregatorV3Interface(
    //         INash21Manager(manager).get(keccak256("FEED_USDT_USD"))
    //     );
    //     IERC20Metadata tokenInterface = IERC20Metadata(
    //         INash21Manager(manager).get(keccak256("USDT"))
    //     );

    //     uint256 decimals = aggregatorInterface.decimals();
    //     (, int256 answer, , , ) = aggregatorInterface.latestRoundData();
    //     uint256 usdt18 = (usd * (10**decimals)) / uint256(answer);
    //     return (usdt18 * (10**tokenInterface.decimals())) / 1 ether;
    // }

    // function _claimable (
    //     uint256 id,
    //     uint256 startDate,
    //     uint256 endDate,
    //     uint256 value
    // )
    //     internal
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     return _getReleased(startDate, endDate, value) - _distributed[id];
    // }

    // function _getReleased (
    //     uint256 startDate,
    //     uint256 endDate,
    //     uint256 value
    // )
    //     internal
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     return
    //         block.timestamp > endDate ? value : block.timestamp > startDate
    //             ? (value * (block.timestamp - startDate)) /
    //                 (endDate - startDate)
    //             : 0;
    // }

    // function _transformCurrency (
    //     bytes32 currency,
    //     uint256 amount
    // )
    //     internal
    //     view
    //     returns (
    //         uint256
    //     )
    // {
    //     address feed = _feeds[currency];

    //     if (feed == address(0)) {
    //         return _transformUsd(amount);
    //     } else {
    //         AggregatorV3Interface aggregatorInterface = AggregatorV3Interface(
    //             _feeds[currency]
    //         );

    //         uint256 decimals = aggregatorInterface.decimals();
    //         (, int256 answer, , , ) = aggregatorInterface.latestRoundData();
    //         return _transformUsd((amount * uint256(answer)) / (10**decimals));
    //     }
    // }
}