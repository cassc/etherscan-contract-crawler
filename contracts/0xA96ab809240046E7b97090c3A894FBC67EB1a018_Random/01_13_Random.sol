// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract Random is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable {
    bytes32 public constant INFO_SETTER_ROLE = keccak256('INFO_SETTER_ROLE');
    uint256 internal nonce;

    struct RandomFeed {
        AggregatorV3Interface rateFeed;
        address balanceFeed;
    }

    RandomFeed public feed;

    function initialize(address _rateFeed, address _balanceFeed) public initializer {
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(INFO_SETTER_ROLE, _msgSender());
        nonce = 0;
        feed = RandomFeed({rateFeed: AggregatorV3Interface(_rateFeed), balanceFeed: _balanceFeed});
    }

    function setFeed(RandomFeed memory value) public virtual onlyRole(INFO_SETTER_ROLE) {
        feed = value;
    }

    function getRandomNumber() public returns (uint256) {
        return _getRandomNumber();
    }

    function _getRandomNumber() internal returns (uint256) {
        uint256 n1 = feed.balanceFeed.balance;
        (, int256 n2, , , ) = feed.rateFeed.latestRoundData();
        uint256 n3 = block.timestamp;
        uint256 n4 = nonce++;

        return uint256(keccak256(abi.encodePacked(n1, n2, n3, n4)));
    }

    // for test
    function getRandomNumberView(uint256 denominator) public view returns (uint256) {
        return _getRandomNumberView() % denominator;
    }

    function _getRandomNumberView() internal view returns (uint256) {
        uint256 n1 = feed.balanceFeed.balance;
        (, int256 n2, , , ) = feed.rateFeed.latestRoundData();
        uint256 n3 = block.timestamp;
        uint256 n4 = nonce;

        return uint256(keccak256(abi.encodePacked(n1, n2, n3, n4)));
    }
}