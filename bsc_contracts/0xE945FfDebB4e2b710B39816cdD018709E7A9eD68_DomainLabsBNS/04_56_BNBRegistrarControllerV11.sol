// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./BaseRegistrarImplementation.sol";
import "./StringUtils.sol";
import "../resolvers/Resolver.sol";
import "../referral/ReferralHub.sol";
import "../referral/ReferralVerifier.sol";
import "../giftcard/SidGiftCardLedger.sol";
import "../price-oracle/ISidPriceOracle.sol";
import "./IBNBRegistrarController.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ReferralInfo} from "../struct/SidStruct.sol";
import {RegInfo} from "../struct/SidStruct.sol";

/**
 * @dev Registrar with giftcard and referral support
 *
 */
contract BNBRegistrarControllerV11 is Ownable, ReentrancyGuard {
    using StringUtils for *;

    uint public constant MIN_REGISTRATION_DURATION = 365 days;

    BaseRegistrarImplementation base;
    SidGiftCardLedger giftCardLedger;
    ISidPriceOracle prices;
    ReferralHub referralHub;
    ReferralVerifier referralVerifier;
    address public beneficiary;

    uint public minCommitmentAge;
    uint public maxCommitmentAge;
    mapping(bytes32 => uint) public commitments;

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, uint cost, uint expires);
    event NewPriceOracle(address indexed oracle);

    constructor(
        BaseRegistrarImplementation _base,
        ISidPriceOracle _prices,
        SidGiftCardLedger _giftCardLedger,
        ReferralHub _referralHub,
        ReferralVerifier _referralVerifier,
        address _beneficiary,
        uint _minCommitmentAge,
        uint _maxCommitmentAge
    ) {
        require(_maxCommitmentAge > _minCommitmentAge);
        require(_beneficiary != address(0));
        base = _base;
        prices = _prices;
        giftCardLedger = _giftCardLedger;
        referralHub = _referralHub;
        referralVerifier = _referralVerifier;
        beneficiary = _beneficiary;
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function rentPrice(string calldata name, uint256 duration) public view returns (ISidPriceOracle.Price memory price) {
        bytes32 label = keccak256(bytes(name));
        price = prices.domainPriceInBNB(name, base.nameExpires(uint256(label)), duration);
    }

    function rentPriceWithPointRedemption(string calldata name, uint256 duration, address registerAddress) public view returns (ISidPriceOracle.Price memory price) {
        bytes32 label = keccak256(bytes(name));
        price = prices.domainPriceWithPointRedemptionInBNB(name, base.nameExpires(uint256(label)), duration, registerAddress);
    }

    function valid(string calldata name) public pure returns (bool) {
        // check unicode rune count, if rune count is >=3, byte length must be >=3.
        if (name.strlen() < 3) {
            return false;
        }
        bytes memory nb = bytes(name);
        // zero width for /u200b /u200c /u200d and U+FEFF
        for (uint256 i; i < nb.length - 2; i++) {
            if (bytes1(nb[i]) == 0xe2 && bytes1(nb[i + 1]) == 0x80) {
                if (bytes1(nb[i + 2]) == 0x8b || bytes1(nb[i + 2]) == 0x8c || bytes1(nb[i + 2]) == 0x8d) {
                    return false;
                }
            } else if (bytes1(nb[i]) == 0xef) {
                if (bytes1(nb[i + 1]) == 0xbb && bytes1(nb[i + 2]) == 0xbf) return false;
            }
        }
        return true;
    }

    function available(string calldata name) public view returns (bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label));
    }

    function makeCommitment(string calldata name, address owner, bytes32 secret) public pure returns (bytes32) {
        bytes32 label = keccak256(bytes(name));
        return keccak256(abi.encodePacked(label, owner, secret));
    }

    function commit(bytes32 commitment) public {
        require(commitments[commitment] + maxCommitmentAge < block.timestamp);
        commitments[commitment] = block.timestamp;
    }

    // because this function returns fund based on msg.value
    // it MUST be an external function to avoid accidental call that
    // returns incorrect amount, e.g., bulk register.
    function register(string calldata name, address owner, uint duration, bytes32 secret) external payable {
        uint256 cost = _registerWithConfigAndPoint(name, RegInfo(owner, duration, secret, address(0), false, msg.value), ReferralInfo(address(0), bytes32(0), 0, 0, bytes("")));
        // Refund any extra payment
        if (msg.value > cost) {
            (bool sent, ) = msg.sender.call{value: msg.value - cost}("");
            require(sent, "Failed to send Ether");
        }
    }

    // because this function returns fund based on msg.value
    // it MUST be an external function to avoid accidental call that
    // returns incorrect amount, e.g., bulk register.
    function registerWithConfig(string calldata name, address owner, uint duration, bytes32 secret, address resolver) external payable {
        uint256 cost = _registerWithConfigAndPoint(name, RegInfo(owner, duration, secret, resolver, false, msg.value), ReferralInfo(address(0), bytes32(0), 0, 0, bytes("")));
        // Refund any extra payment
        if (msg.value > cost) {
            (bool sent, ) = msg.sender.call{value: msg.value - cost}("");
            require(sent, "Failed to send Ether");
        }
    }

    // because this function returns fund based on msg.value
    // it MUST be an external function to avoid accidental call that
    // returns incorrect amount, e.g., bulk register.
    function registerWithConfigAndPoint(string calldata name, address owner, uint duration, bytes32 secret, address resolver, bool isUsePoints, ReferralInfo memory referralInfo) external payable {
        uint256 cost = _registerWithConfigAndPoint(name, RegInfo(owner, duration, secret, resolver, isUsePoints, msg.value), referralInfo);
        // Refund any extra payment
        if (msg.value > cost) {
            (bool sent, ) = msg.sender.call{value: msg.value - cost}("");
            require(sent, "Failed to send Ether");
        }
    }

    function _registerWithConfigAndPoint(string calldata name, RegInfo memory regInfo, ReferralInfo memory referralInfo) internal nonReentrant returns (uint256 cost) {
        bytes32 commitment = makeCommitment(name, regInfo.owner, regInfo.secret);
        cost = _consumeCommitment(name, regInfo.duration, commitment, regInfo.isUsePoints);

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        uint expires;
        if (regInfo.resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            expires = base.register(tokenId, address(this), regInfo.duration);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNode(), label));

            // Set the resolver
            base.sid().setResolver(nodehash, regInfo.resolver);

            Resolver(regInfo.resolver).setAddr(nodehash, regInfo.owner);

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, regInfo.owner);
            base.transferFrom(address(this), regInfo.owner, tokenId);
        } else {
            expires = base.register(tokenId, regInfo.owner, regInfo.duration);
        }

        emit NameRegistered(name, label, regInfo.owner, cost, expires);

        // Check if it is eligible for referral program
        if (referralInfo.referrerAddress != address(0)) {
            cost = _handleReferral(cost, referralInfo.referrerAddress, referralInfo.referrerNodehash, referralInfo.referralAmount, referralInfo.signedAt, referralInfo.signature);
        }
        return cost;
    }

    function _handleReferral(uint cost, address referrerAddress, bytes32 referrerNodehash, uint256 referralAmount, uint256 signedAt, bytes memory signature) internal returns (uint) {
        require(referralVerifier.verifyReferral(referrerAddress, referrerNodehash, referralAmount, signedAt, signature), "Invalid referral signature");
        uint256 referrerFee = 0;
        uint256 refereeFee = 0;
        if (referralHub.isPartner(referrerNodehash)) {
            (referrerFee, refereeFee) = referralHub.getReferralCommisionFee(cost, referrerNodehash);
        } else {
            (referrerFee, refereeFee) = referralVerifier.getReferralCommisionFee(cost, referralAmount);
        }
        referralHub.addNewReferralRecord(referrerNodehash);
        if (referrerFee > 0) {
            referralHub.deposit{value: referrerFee}(referrerAddress);
        }
        return cost - refereeFee;
    }

    // because this function returns fund based on msg.value
    // it MUST be an external function to avoid accidental call that
    // returns incorrect amount, e.g., bulk register.
    function renew(string calldata name, uint duration) external payable {
        uint256 cost = _renewWithPoint(name, duration, false, msg.value);
        // Refund any extra payment
        if (msg.value > cost) {
            (bool sent, ) = msg.sender.call{value: msg.value - cost}("");
            require(sent, "Failed to send Ether");
        }
    }

    // because this function returns fund based on msg.value
    // it MUST be an external function to avoid accidental call that
    // returns incorrect amount, e.g., bulk register.
    function renewWithPoint(string calldata name, uint duration, bool isUsePoints) external payable {
        uint256 cost = _renewWithPoint(name, duration, isUsePoints, msg.value);
        // Refund any extra payment
        if (msg.value > cost) {
            (bool sent, ) = msg.sender.call{value: msg.value - cost}("");
            require(sent, "Failed to send Ether");
        }
    }

    function _renewWithPoint(string calldata name, uint duration, bool isUsePoints, uint256 paid) internal nonReentrant returns (uint256 cost) {
        ISidPriceOracle.Price memory price;
        if (isUsePoints) {
            price = rentPriceWithPointRedemption(name, duration, msg.sender);
            //deduct points from gift card ledger
            giftCardLedger.deduct(msg.sender, price.usedPoint);
        } else {
            price = rentPrice(name, duration);
        }
        cost = (price.base + price.premium);
        require(paid >= cost);
        bytes32 label = keccak256(bytes(name));
        uint expires = base.renew(uint256(label), duration);
        emit NameRenewed(name, label, cost, expires);
        return cost;
    }

    function setPriceOracle(ISidPriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        require(_beneficiary != address(0));
        beneficiary = _beneficiary;
    }

    function setCommitmentAges(uint _minCommitmentAge, uint _maxCommitmentAge) public onlyOwner {
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool sent, ) = beneficiary.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function _consumeCommitment(string calldata name, uint duration, bytes32 commitment, bool usePoints) internal returns (uint256) {
        // Require a valid commitment
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);
        // If the commitment is too old, or the name is registered, stop
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);
        require(available(name));
        delete (commitments[commitment]);
        ISidPriceOracle.Price memory price;
        if (usePoints) {
            uint256 senderBalance = giftCardLedger.balanceOf(msg.sender);
            price = rentPriceWithPointRedemption(name, duration, msg.sender);
            // deduct points from gift card ledger
            giftCardLedger.deduct(msg.sender, price.usedPoint);
            assert(senderBalance == 0 || senderBalance > giftCardLedger.balanceOf(msg.sender));
        } else {
            price = rentPrice(name, duration);
        }
        uint cost = (price.base + price.premium);
        require(duration >= MIN_REGISTRATION_DURATION);
        require(msg.value >= cost);
        return cost;
    }

    function bulkRentPrice(string[] calldata names, uint256 duration) public view returns (uint256 total) {
        for (uint256 i = 0; i < names.length; i++) {
            ISidPriceOracle.Price memory price = rentPrice(names[i], duration);
            total += (price.base + price.premium);
        }
    }

    function bulkMakeCommitmentWithConfig(string[] calldata name, address owner, bytes32 secret) public pure returns (bytes32[] memory newCommitments) {
        newCommitments = new bytes32[](name.length);
        for (uint256 i = 0; i < name.length; i++) {
            newCommitments[i] = makeCommitment(name[i], owner, secret);
        }
        return newCommitments;
    }

    function bulkCommit(bytes32[] calldata newCommitments) external {
        for (uint256 i = 0; i < newCommitments.length; i++) {
            commit(newCommitments[i]);
        }
    }

    function bulkRegister(string[] calldata names, address owner, uint duration, bytes32 secret, address resolver, bool isUseGiftCard, ReferralInfo memory referralInfo) external payable {
        uint256 unspent = msg.value;
        for (uint256 i = 0; i < names.length; i++) {
            uint256 cost = _registerWithConfigAndPoint(names[i], RegInfo(owner, duration, secret, resolver, isUseGiftCard, unspent), referralInfo);
            unspent -= cost;
        }
        // Refund any extra payment
        if (unspent > 0) {
            (bool sent, ) = msg.sender.call{value: unspent}("");
            require(sent, "Failed to send Ether");
        }
    }
}