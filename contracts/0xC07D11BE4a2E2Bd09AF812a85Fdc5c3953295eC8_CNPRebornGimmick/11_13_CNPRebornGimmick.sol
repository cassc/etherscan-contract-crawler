// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ICNPRebornGimmick.sol";
import "./Burnable.sol";
import "../ICNPReborn.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CNPRebornGimmick is ICNPRebornGimmick, AccessControl, Ownable {
    using Address for address payable;

    // ==================================================================
    // Constants
    // ==================================================================
    bytes32 public constant ADMIN = "ADMIN";

    // ==================================================================
    // Variables
    // ==================================================================
    bool public changePaused = true;
    bool public bornPaused = true;
    bool public rebornPaused = true;

    uint256 public gimmickCost = 0 ether;

    address payable public withdrawAddress;

    ICNPReborn private _reborn;
    Burnable private _couponContract;

    mapping(address => uint256) public playGimmickCount;

    constructor(address ownerAddress) {
        grantRole(ADMIN, msg.sender);
        withdrawAddress = payable(ownerAddress);
    }

    // ==================================================================
    // original
    // ==================================================================
    function _onlyAdultAndNotInCoolDownTime(uint256 tokenId) private view {
        require(
            _reborn.isAdult(tokenId) && !_reborn.inCoolDownTime(tokenId),
            "Only adults who are not on cool time may participate in the gimmick."
        );
    }

    modifier enoughEthForGimmick(uint256 amount) {
        require(msg.value >= gimmickCost * amount, "not enough eth.");
        _;
    }

    // == For gimmick of Change
    function change(uint256[] calldata tokenIds, uint256[] calldata couponIds)
        external
        payable
        enoughEthForGimmick(tokenIds.length)
    {
        require(!changePaused, "change is paused.");
        require(tokenIds.length == couponIds.length, "require coupon.");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _onlyAdultAndNotInCoolDownTime(tokenIds[i]);
        }

        _useCoupons(msg.sender, couponIds);

        playGimmickCount[msg.sender] += tokenIds.length;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _reborn.playGimmick(tokenIds[i]);
            emit Change(msg.sender, tokenIds[i]);
        }
    }

    // == For gimmick of Born
    function born(Parents[] calldata parents, uint256[] calldata couponIds)
        external
        payable
        enoughEthForGimmick(parents.length)
    {
        require(!bornPaused, "born is paused.");
        require(parents.length == couponIds.length, "require coupon.");
        for (uint256 i = 0; i < parents.length; i++) {
            _onlyAdultAndNotInCoolDownTime(parents[i].parent1);
            _onlyAdultAndNotInCoolDownTime(parents[i].parent2);
        }
        _useCoupons(msg.sender, couponIds);

        playGimmickCount[msg.sender] += parents.length;

        for (uint256 i = 0; i < parents.length; i++) {
            _reborn.playGimmick(parents[i].parent1);
            _reborn.playGimmick(parents[i].parent2);
            emit Born(msg.sender, parents[i].parent1, parents[i].parent2);
        }
    }

    // == For gimmick of Reborn
    // reborn is called by Reborn contract
    function reborn(
        address user,
        Parents[] calldata parents,
        uint256[] calldata couponIds
    ) external payable enoughEthForGimmick(parents.length) {
        require(!rebornPaused, "reborn is paused.");
        require(parents.length == couponIds.length, "require coupon.");
        require(msg.sender == address(_reborn), "only call by reborn.");

        for (uint256 i = 0; i < parents.length; i++) {
            _onlyAdultAndNotInCoolDownTime(parents[i].parent1);
            _onlyAdultAndNotInCoolDownTime(parents[i].parent2);
        }

        _useCoupons(user, couponIds);

        playGimmickCount[user] += parents.length;

        uint256 next = _reborn.nextTokenId();
        for (uint256 i = 0; i < parents.length; i++) {
            emit Reborn(
                user,
                parents[i].parent1,
                parents[i].parent2,
                next + 2 * i,
                next + 2 * i + 1
            );
        }
    }

    function _useCoupons(address from, uint256[] calldata burnTokenIds)
        private
    {
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            _useCoupon(from, burnTokenIds[i]);
        }
    }

    function _useCoupon(address from, uint256 burnTokenId) private {
        require(
            _couponContract.ownerOf(burnTokenId) == from,
            "you are not coupon holder."
        );
        _couponContract.burn(burnTokenId);
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    function setChangePaused(bool value) external onlyRole(ADMIN) {
        changePaused = value;
    }

    function setBornPaused(bool value) external onlyRole(ADMIN) {
        bornPaused = value;
    }

    function setRebornPaused(bool value) external onlyRole(ADMIN) {
        rebornPaused = value;
    }

    function withdraw() external onlyRole(ADMIN) {
        require(
            withdrawAddress != address(0),
            "withdraw address is 0 address."
        );
        withdrawAddress.sendValue(address(this).balance);
    }

    function setWithdrawAddress(address payable value)
        external
        onlyRole(ADMIN)
    {
        withdrawAddress = value;
    }

    function setGimmickCost(uint256 value) external onlyRole(ADMIN) {
        gimmickCost = value;
    }

    // ==================================================================
    // Operation outer contract
    // ==================================================================
    function setReborn(address value) external onlyRole(ADMIN) {
        _reborn = ICNPReborn(value);
    }

    function setCounponContract(address value) external onlyRole(ADMIN) {
        _couponContract = Burnable(value);
    }
}