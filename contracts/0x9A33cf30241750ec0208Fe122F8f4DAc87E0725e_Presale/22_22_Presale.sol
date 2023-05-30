// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DroomCoin.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Presale is Ownable {
    DroomCoin public droomCoin;

    mapping(address => uint256) public claimedTokens;
    mapping(address => uint256) public ethContributed;

    uint256 public PRESALE_FINALIZED_BLOCK;
    uint256 public totalEthRaised;
    uint256 public vestingPeriod = 50400;

    uint256 public constant HARD_CAP = 150 ether;
    uint256 public constant MAX_PER_WALLET = 0.5 ether;
    uint256 public constant MIN_PER_WALLET = 0.05 ether;
    uint256 public constant TOTAL_SUPPLY = 69_000_000_000 ether;
    uint256 public constant LIQUIDITY_POOL = 31_050_000_000 ether; // 45%
    uint256 public constant PRESALE_ALLOCATION = 20_700_000_000 ether; // 30%

    enum SalePhase {
        Locked,
        Whitelist,
        Public
    }

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum CouponType {
        Whitelist
    }

    SalePhase public phase = SalePhase.Locked;
    address public couponSigner;

    error WhitelistSaleNotStarted();
    error PublicSaleNotStarted();
    error InvalidCoupon();
    error InvalidMaxAmount();
    error InvalidMinAmount();
    error HardCapReached();
    error SaleNotFinished();

    constructor() {
        couponSigner = 0x06662Affd29C057363F9CBEA2E44910642ad3bAf;
    }

    modifier saleConfigs(uint256 amount) {
        if (ethContributed[msg.sender] + amount > MAX_PER_WALLET)
            revert InvalidMaxAmount();
        if (ethContributed[msg.sender] + amount < MIN_PER_WALLET)
            revert InvalidMinAmount();
        if (address(this).balance > HARD_CAP) revert HardCapReached();
        _;
    }

    function setCouponSigner(address couponSigner_) external onlyOwner {
        couponSigner = couponSigner_;
    }

    function _isVerifiedCoupon(
        bytes32 digest_,
        Coupon memory coupon_
    ) internal view returns (bool) {
        address signer = ecrecover(digest_, coupon_.v, coupon_.r, coupon_.s);
        require(signer != address(0), "Zero Address");
        return signer == couponSigner;
    }

    function buyWhitelist(
        Coupon memory _coupon
    ) external payable saleConfigs(msg.value) {
        if (phase != SalePhase.Whitelist) revert WhitelistSaleNotStarted();
        bytes32 digest = keccak256(
            abi.encode(CouponType.Whitelist, msg.sender)
        );
        if (!(_isVerifiedCoupon(digest, _coupon))) revert InvalidCoupon();

        ethContributed[msg.sender] += msg.value;
    }

    function buyPublic() external payable saleConfigs(msg.value) {
        if (phase != SalePhase.Public) revert PublicSaleNotStarted();

        ethContributed[msg.sender] += msg.value;
    }

    function setSalePhase(SalePhase newPhase) external onlyOwner {
        phase = newPhase;
    }

    function setDroomCoin(address newDroomCoin) external onlyOwner {
        droomCoin = DroomCoin(newDroomCoin);
    }

    function getTotalContribution() public view returns (uint256) {
        return
            PRESALE_FINALIZED_BLOCK > 0
                ? totalEthRaised
                : address(this).balance;
    }

    function getEthContributed(address wallet) public view returns (uint256) {
        return ethContributed[wallet];
    }

    function getTokensClaimed(address wallet) public view returns (uint256) {
        return claimedTokens[wallet];
    }

    function getClaimableTokens(
        address wallet
    ) public view returns (uint256 claimable) {
        if (PRESALE_FINALIZED_BLOCK == 0) return 0;
        uint256 blocksElapsed = block.number - PRESALE_FINALIZED_BLOCK;
        uint256 amtEthContributed = getEthContributed(wallet);

        if (blocksElapsed > vestingPeriod) {
            return amtEthContributed;
        }

        claimable = amtEthContributed * 3;
        claimable += (amtEthContributed * 7 * blocksElapsed) / vestingPeriod;

        claimable = claimable / 10;
    }

    function getClaimableDroom(address wallet) external view returns (uint256) {
        if (PRESALE_FINALIZED_BLOCK == 0) return 0;
        uint256 claimableTokens = getClaimableTokens(wallet);
        uint256 unclaimedTokens = claimableTokens - claimedTokens[wallet];
        uint256 droomAmount = (unclaimedTokens * PRESALE_ALLOCATION) / HARD_CAP;

        return droomAmount;
    }

    function claimDroom() external {
        if (PRESALE_FINALIZED_BLOCK == 0) revert SaleNotFinished();
        uint256 claimableTokens = getClaimableTokens(msg.sender);

        uint256 previouslyClaimed = claimedTokens[msg.sender];
        claimedTokens[msg.sender] = claimableTokens;
        uint256 unclaimedTokens = claimableTokens - previouslyClaimed;
        uint256 droomAmount = (unclaimedTokens * PRESALE_ALLOCATION) / HARD_CAP;
        droomCoin.transfer(msg.sender, droomAmount);
    }

    function finalizeSale() external onlyOwner {
        PRESALE_FINALIZED_BLOCK = block.number;
        phase = SalePhase.Locked;

        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}