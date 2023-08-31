// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {LibPRNG} from "solady/utils/LibPRNG.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {NightWatch} from "./NightWatch.sol";
import {NightWatchUtils} from "./NightWatchUtils.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

/// @title Night Watch Vendor
/// @notice Night Watch Vendor contract to sell Night Watch NFTs
/// @author @YigitDuman
contract NightWatchVendor is Owned(msg.sender), ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                               ADDRESSES
    //////////////////////////////////////////////////////////////*/
    NightWatch private _nightWatch;
    address private _vaultAddress;
    address private _signer;
    address private _partnerA;
    address private _partnerB;

    /*//////////////////////////////////////////////////////////////
                                 STATES
    //////////////////////////////////////////////////////////////*/
    // The price of a token
    uint256 public _price = 0.03 ether;

    // The state of the sale
    bool public _saleState = true;

    // The maximum amount of tokens that can be purchased per transaction
    uint8 public _maxPurchaseLimitPerTx = 10;

    // The total amount of tokens sold
    uint256 public _totalSold = 0;

    // The total amount of tokens needed for the sale to be complete
    // 782 tokens reserved for the creators. Thus the number 6043.
    uint256 public _soldOutAmount = 6043;

    // Unclaimed token amount mapping for addresses
    mapping(address => uint256) public _unclaimedTokens;

    // Used signatures mapping
    mapping(bytes32 => bool) private _usedSignatures;

    /*//////////////////////////////////////////////////////////////
                           ERRORS AND EVENTS
    //////////////////////////////////////////////////////////////*/

    error MaxPurchaseLimitExceeded();
    error InvalidSignature();
    error InvalidPrice();
    error NoFunds();
    error NoZeroAddress();
    error SignatureUsed();
    error SaleIsNotActive();
    error ReceiverCantBeVaultAddress();
    error ReceiverCantBeZeroAddress();
    error NoUnclaimedTokens();
    error UnclaimedTokensExist();
    error SoldOut();

    event Purchase(address indexed receiver, uint256 amount);
    event Claim(address indexed receiver, uint16[] tokens);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        NightWatch nightWatch,
        address vaultAddress,
        address signer,
        address partnerA,
        address partnerB,
        uint256 soldOutAmount
    ) {
        if (
            partnerA == address(0) ||
            partnerB == address(0) ||
            signer == address(0) ||
            vaultAddress == address(0)
        ) {
            revert NoZeroAddress();
        }

        _nightWatch = nightWatch;
        _vaultAddress = vaultAddress;
        _signer = signer;
        _partnerA = partnerA;
        _partnerB = partnerB;
        _soldOutAmount = soldOutAmount;
    }

    /*//////////////////////////////////////////////////////////////
                            CONTRACT STATES
    //////////////////////////////////////////////////////////////*/

    /// @notice Owner only function set vault address
    /// @param vaultAddress address of the vault
    function setVaultAddress(address vaultAddress) external onlyOwner {
        if (vaultAddress == address(0)) {
            revert NoZeroAddress();
        }
        _vaultAddress = vaultAddress;
    }

    /// @notice Owner only function set max purchase limit
    /// @param maxPurchaseLimitPerTx max purchase limit per transaction
    function setMaxPurchaseLimit(
        uint8 maxPurchaseLimitPerTx
    ) external onlyOwner {
        _maxPurchaseLimitPerTx = maxPurchaseLimitPerTx;
    }

    /// @notice Owner only function set price
    /// @param price price of a token
    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    /// @notice Owner only function toggle sale state
    function setSaleState(bool saleState) external onlyOwner {
        _saleState = saleState;
    }

    /// @notice Owner only function set NightWatch contract address
    /// @param nightWatch address of the NightWatch contract
    function setNightWatch(address nightWatch) external onlyOwner {
        _nightWatch = NightWatch(nightWatch);
    }

    /// @notice Owner only function set signer address
    /// @param signer address of the signer
    function setSigner(address signer) external onlyOwner {
        if (signer == address(0)) {
            revert NoZeroAddress();
        }
        _signer = signer;
    }

    /// @notice Owner only function set sold out amount
    /// @param soldOutAmount amount of tokens needed to be sold for the sale to end
    function setSoldOutAmount(uint256 soldOutAmount) external onlyOwner {
        _soldOutAmount = soldOutAmount;
    }

    /// @notice Owner only function set total sold amount in case of a migration
    /// @param totalSold amount of tokens sold
    function setTotalSold(uint256 totalSold) external onlyOwner {
        _totalSold = totalSold;
    }

    /// @notice Owner only function set partner A address
    function setPartnerAAddress(address partnerA) external onlyOwner {
        if (partnerA == address(0)) {
            revert NoZeroAddress();
        }

        _partnerA = partnerA;
    }

    /// @notice Owner only function set partner B address
    function setPartnerBAddress(address partnerB) external onlyOwner {
        if (partnerB == address(0)) {
            revert NoZeroAddress();
        }

        _partnerB = partnerB;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Purchase tokens
    /// @param amount amount of tokens to purchase
    /// @param receiver address of the receiver
    function purchaseTokens(uint256 amount, address receiver) external payable {
        // Check if sale is active
        if (!_saleState) revert SaleIsNotActive();

        // Check if sold out
        if (_totalSold + amount > _soldOutAmount) revert SoldOut();

        // Check if max purchase limit exceeded
        if (amount > _maxPurchaseLimitPerTx) revert MaxPurchaseLimitExceeded();

        // Check if the amount of ether sent is enough
        if (msg.value != _price * amount) revert InvalidPrice();

        // Check if the receiver is not the vaultAddress
        if (receiver == _vaultAddress) revert ReceiverCantBeVaultAddress();

        // Check if the receiver is not the zero address
        if (receiver == address(0)) revert ReceiverCantBeZeroAddress();

        // Check if the receiver has unclaimed tokens
        if (_unclaimedTokens[receiver] != 0) revert UnclaimedTokensExist();

        // Add the amount of tokens to the receiver
        _unclaimedTokens[receiver] += amount;

        // Add the amount of tokens to the total sold amount
        _totalSold += amount;

        // Emit purchase event
        emit Purchase(receiver, amount);
    }

    /// @notice Claim tokens
    /// @param receiver address of the receiver
    /// @param tokens array of token ids
    /// @param signature signature of the tokens and the receiver
    function claimTokens(
        address receiver,
        uint16[] calldata tokens,
        bytes calldata signature
    ) external nonReentrant {
        uint256 amount = tokens.length;

        // Check if the receiver has unclaimed tokens
        if (_unclaimedTokens[receiver] != amount) revert NoUnclaimedTokens();

        // Create eth signed message hash from tokens packed with the receiver address
        bytes32 signHash = ECDSA.toEthSignedMessageHash(
            abi.encodePacked(tokens, receiver)
        );

        // Check if the signature used already
        if (_usedSignatures[signHash]) revert SignatureUsed();

        // Recover the signer address from the signature provided
        address recoveredAddress = ECDSA.recoverCalldata(signHash, signature);

        // Ensure the randomness provided by the Night Watch API
        if (recoveredAddress != _signer) revert InvalidSignature();

        // Transfer all the tokens to the receiver
        for (uint256 i; i < amount; ) {
            _nightWatch.transferFrom(_vaultAddress, receiver, tokens[i]);
            unchecked {
                ++i;
            }
        }

        // Remove the unclaimed tokens from the receiver
        _unclaimedTokens[receiver] = 0;

        // Set the signature as used
        _usedSignatures[signHash] = true;

        // Emit claim event
        emit Claim(receiver, tokens);
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws the funds from the contract.
    function withdraw(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;

        // Revert if there are no funds
        if (balance == 0) {
            revert NoFunds();
        }

        // Limit the amount to the contract balance.
        if (amount > balance) {
            amount = balance;
        }

        // Split the funds between the partners with 65% and 35%.
        uint256 amount65 = (amount * 65) / 100;
        uint256 amount35 = amount - amount65;

        SafeTransferLib.safeTransferETH(_partnerA, amount65);
        SafeTransferLib.safeTransferETH(_partnerB, amount35);
    }

    /// @notice Withdraws the ERC20 funds from the contract.
    function withdrawERC20(
        uint256 amount,
        ERC20 token
    ) external onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));

        // Revert if there are no funds
        if (balance == 0) {
            revert NoFunds();
        }

        // Limit the amount to the contract balance.
        if (amount > balance) {
            amount = balance;
        }

        // Split the funds between the partners with 65% and 35%.
        uint256 amount65 = (amount * 65) / 100;
        uint256 amount35 = amount - amount65;

        token.transfer(_partnerA, amount65);
        token.transfer(_partnerB, amount35);
    }
}