// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '../utils/WakumbaOwnedUpgradeable.sol';
import '../airdrop/SwordOfBravery.sol';
import '../staking/Faith.sol';

contract WakumbaBless is WakumbaOwnedUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    Faith private __faithContract;
    SwordOfBravery private __swordContract;

    mapping(address => uint32) private __claimedSwordQty;
    mapping(address => uint32) private __claimedFaithQty;

    uint256 private __totalClaimedFaith;
    uint256 private __totalClaimedSwords;

    // init
    function initialize(address swordAddress, address faithAddress) public initializer {
        __WakumbaOwned_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __swordContract = SwordOfBravery(swordAddress);
        __faithContract = Faith(faithAddress);
    }

    function setSwordContract(address addr) external onlyOwner {
        __swordContract = SwordOfBravery(addr);
    }

    function setFaithContract(address addr) external onlyOwner {
        __faithContract = Faith(addr);
    }

    function isValidSignature(
        string memory method,
        address addr,
        uint256 qty,
        uint256 limit,
        bytes32 nonce,
        bytes calldata signature
    ) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(method, addr, qty, limit, nonce));
        return owner() == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function airdropFaith(
        address to,
        uint32 qty,
        uint32 maxLimit,
        bytes32 nonce,
        bytes calldata signature
    ) public nonReentrant whenNotPaused {
        require(_msgSender() == to, 'Invalid caller');
        require(
            isValidSignature('airdropFaith', to, uint256(qty), uint256(maxLimit), nonce, signature),
            'Invalid signature'
        );
        __claimedFaithQty[_msgSender()] += qty;
        __faithContract.mint(
            to,
            uint256(qty) * 1e18 /* Contract Digits */
        );
        require(__claimedFaithQty[_msgSender()] <= maxLimit, 'max qty exceeded');
        __totalClaimedFaith = __totalClaimedFaith + qty;
    }

    function getClaimedFaithQty(address addr) external view returns (uint32) {
        return __claimedFaithQty[addr];
    }

    function getTotalClaimedFaith() external view returns (uint256) {
        return __totalClaimedFaith;
    }

    function airdropSword(
        address to,
        uint16 qty,
        uint16 maxLimit,
        bytes32 nonce,
        bytes calldata signature
    ) public nonReentrant whenNotPaused {
        require(_msgSender() == to, 'Invalid caller');
        require(
            isValidSignature('airdropSword', to, uint256(qty), uint256(maxLimit), nonce, signature),
            'Invalid signature'
        );
        __claimedSwordQty[_msgSender()] += qty;
        __swordContract.mint(
            to,
            0, /* Sword ID, only airdrop the common sword */
            qty,
            abi.encodePacked(maxLimit)
        );
        require(__claimedSwordQty[_msgSender()] <= maxLimit, 'max qty exceeded');
        __totalClaimedSwords = __totalClaimedSwords + qty;
    }

    function getClaimedSwordQty(address addr) external view returns (uint32) {
        return __claimedSwordQty[addr];
    }

    function getTotalClaimedSwords() external view returns (uint256) {
        return __totalClaimedSwords;
    }
}