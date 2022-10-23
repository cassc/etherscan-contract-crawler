// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@oz-upgradeable/security/PausableUpgradeable.sol";
import {IERC721A} from "@erc721a/IERC721A.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IBattleZone} from "./interfaces/IBattleZone.sol";
import {IBeepBoop} from "./interfaces/IBeepBoop.sol";
import {IProxyYield} from "./interfaces/IProxyYield.sol";
import {ECDSA} from "@solady/utils/ECDSA.sol";

contract ProxyYield is
    IProxyYield,
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using ECDSA for bytes32;

    /// @notice $BOOP token
    IBeepBoop public beepBoop;

    /// @notice Battle Zone Token
    IBattleZone public battleZone;

    /// @notice Toggle claims
    bool public claimPaused;

    /// @notice Public tax pool
    uint256 public activeTaxCollectedAmount;

    /// @notice Public tax pool
    uint256 public reserveTaxCollectedAmount;

    /// @notice Tax recipient
    address public reserveTaxAddress;

    /// @notice Reserve tax amount
    uint256 public reserveTaxAmount;

    /// @notice Track released amount
    mapping(address => uint256) private _released;
    uint256 private _totalReleased;

    /// @notice Signer address
    address public signerAddress;

    /// @notice Battery NFT
    IERC721A batteryNft;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address beepBoop_,
        address staking_,
        address signerAddress_
    ) external initializer {
        beepBoop = IBeepBoop(beepBoop_);
        battleZone = IBattleZone(staking_);
        signerAddress = signerAddress_;
        reserveTaxAddress = msg.sender;
        reserveTaxAmount = 50;
        claimPaused = true;
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Withdraw $gBOOP to $BOOP
     */
    function withdraw(uint256 amount) public whenNotPaused {
        require(
            beepBoop.getUserBalance(msg.sender) >= amount,
            "Insufficient balance"
        );

        uint256 tax = (amount * getTaxRate(msg.sender)) / 100;
        beepBoop.spendBeepBoop(msg.sender, amount);

        // allocate a percentage to the reserve
        uint256 reserveTaxAmount_ = reserveTaxAmount;
        if (reserveTaxAmount_ != 0 && reserveTaxAddress != address(0)) {
            activeTaxCollectedAmount += (tax * (100 - reserveTaxAmount_)) / 100;
            reserveTaxCollectedAmount += (tax * reserveTaxAmount_) / 100;
        } else {
            activeTaxCollectedAmount += tax;
        }

        // mint fresh tokens to the wallet
        uint256 net = (amount - tax);
        if (net > 0) {
            beepBoop.mintFor(msg.sender, (amount - tax));
        }

        emit Withdraw(msg.sender, amount, tax);
    }

    function _validateSignature(
        bytes calldata signature,
        address sender,
        uint256 taxRate
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(sender, taxRate));
        address receivedAddress = dataHash.toEthSignedMessageHash().recover(
            signature
        );
        return (receivedAddress != address(0) &&
            receivedAddress == signerAddress);
    }

    /**
     * @notice Claim reserve as reserve recipient
     */
    function claimBeepBoopReserveTax() external {
        require(
            reserveTaxAddress == msg.sender || owner() == msg.sender,
            "Unauthorised"
        );
        beepBoop.mintFor(msg.sender, reserveTaxCollectedAmount);
        reserveTaxCollectedAmount = 0;
    }

    /**
     * @notice Claim beep boop tax up to what is releasable for the user
     */
    function claimBeepBoopTax() public {
        require(address(batteryNft) != address(0), "Battery NFT not present");
        require(claimPaused == false, "Tax claims are paused");

        uint256 payment = releasable(msg.sender);

        require(payment != 0, "Nothing owed");

        _totalReleased += payment;
        activeTaxCollectedAmount -= payment;
        unchecked {
            _released[msg.sender] += payment;
        }

        beepBoop.depositBeepBoopFor(msg.sender, payment);
        emit BribeClaim(msg.sender, payment);
    }

    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = activeTaxCollectedAmount + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        (, uint256[] memory batteries, , ) = battleZone.getStakerTokens(
            account
        );
        uint256 totalShares = batteryNft.balanceOf(address(battleZone));
        if (totalShares == 0) {
            return 0;
        }
        uint256 shareOfPot = (totalReceived * batteries.length) / totalShares;
        return alreadyReleased < shareOfPot ? shareOfPot - alreadyReleased : 0;
    }

    function getTaxRate(address user) public view returns (uint256) {
        // @todo To be updated
        return 100;
    }

    /**
     * Change the battle zone contract
     */
    function changeBattleZoneContract(address battleZone_) public onlyOwner {
        battleZone = IBattleZone(battleZone_);
    }

    /**
     * Change the battle zone contract
     */
    function changeBatteryContract(address battery_) public onlyOwner {
        batteryNft = IERC721A(battery_);
    }

    /**
     * @dev Function allows admin to update limit of tax on reserve.
     */
    function updateReserveTaxAmount(uint256 taxAmount) public onlyOwner {
        require(taxAmount <= 100, "Wrong value passed");
        reserveTaxAmount = taxAmount;
    }

    /**
     * @dev Function allows admin to update tax reserve recipient
     */
    function updateReserveTaxRecipient(address address_) public onlyOwner {
        reserveTaxAddress = address_;
    }

    function pause() public onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function toggleClaimPause() public onlyOwner {
        claimPaused = !claimPaused;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}