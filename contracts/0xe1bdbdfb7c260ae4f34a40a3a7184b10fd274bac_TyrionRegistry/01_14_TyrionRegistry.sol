// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

struct Advertiser {
    uint256 id;
    address wallet;
    uint256 balance;
    uint256 referrer;
}

struct Publisher {
    uint256 id;
    address wallet;
    uint256 balance;
    uint256 referrer;
}

struct Referrer {
    uint256 id;
    address wallet;
    uint256 balance;
}

contract TyrionRegistry is OwnableUpgradeable {
    using SafeMath for uint256;

    mapping(uint256 => Advertiser) public advertisers;
    mapping(uint256 => Publisher) public publishers;
    mapping(uint256 => Referrer) public referrers;

    uint256 public nextAdvertiserId;
    uint256 public nextPublisherId;
    uint256 public nextReferrerId;

    address public brokerAddress;

    event RegisteredAdvertiser(uint256 indexed advertiserId, address wallet, uint256 indexed referrer);
    event RegisteredPublisher(uint256 indexed publisherId, address wallet, uint256 indexed referrer);
    event RegisteredReferrer(uint256 indexed referrerId, address wallet);

    modifier onlyOwnerOrBroker() {
        require(owner() == _msgSender() || brokerAddress == _msgSender(), "Caller is not the owner or broker");
        _;
    }

    function initialize() public initializer {
        nextAdvertiserId = 1;
        nextPublisherId = 1;
        nextReferrerId = 1;
        __Ownable_init();
    }

    function setBrokerAddress(address _brokerAddress) external onlyOwner {
        brokerAddress = _brokerAddress;
    }

    function registerAdvertiser(address advertiserWallet, uint256 referrerId) external returns (uint256 advertiserId) {
        advertiserId = nextAdvertiserId;
        advertisers[advertiserId] = Advertiser({
            id: advertiserId,
            wallet: advertiserWallet,
            balance: 0,
            referrer: referrerId
        });

        emit RegisteredAdvertiser(advertiserId, advertiserWallet, referrerId);
        nextAdvertiserId++;
    }

    function registerPublisher(address publisherWallet, uint256 referrerId) external returns (uint256 publisherId) {
        publisherId = nextPublisherId;
        publishers[publisherId] = Publisher({
            id: publisherId,
            wallet: publisherWallet,
            balance: 0,
            referrer: referrerId
        });

        emit RegisteredPublisher(publisherId, publisherWallet, referrerId);
        nextPublisherId++;
    }

    function registerReferrer(address referrerWallet) external returns (uint256 referrerId) {
        referrerId = nextReferrerId;
        referrers[nextReferrerId] = Referrer({
            id: nextReferrerId,
            wallet: referrerWallet,
            balance: 0
        });

        emit RegisteredReferrer(referrerId, referrerWallet);
        nextReferrerId++;
    }

    function modifyPublisherBalance(uint256 publisherId, int256 delta) external onlyOwnerOrBroker {
        if (delta > 0) {
            publishers[publisherId].balance += uint256(delta);
        } else if (delta < 0) {
            publishers[publisherId].balance -= uint256(-delta);
        }
    }

    function modifyAdvertiserBalance(uint256 advertiserId, int256 delta) external onlyOwnerOrBroker {
        if (delta > 0) {
            advertisers[advertiserId].balance += uint256(delta);
        } else if (delta < 0) {
            advertisers[advertiserId].balance -= uint256(-delta);
        }
    }

    function modifyReferrerBalance(uint256 referrerId, int256 delta) external onlyOwnerOrBroker {
        if (delta > 0) {
            referrers[referrerId].balance += uint256(delta);
        } else if (delta < 0) {
            referrers[referrerId].balance -= uint256(-delta);
        }
    }

    function getAdvertiserById(uint256 _advertiserId) external view returns (Advertiser memory) {
        return advertisers[_advertiserId];
    }

    function getPublisherById(uint256 _publisherId) external view returns (Publisher memory) {
        return publishers[_publisherId];
    }

    function getReferrerById(uint256 _referrerId) external view returns (Referrer memory) {
        return referrers[_referrerId];
    }
}