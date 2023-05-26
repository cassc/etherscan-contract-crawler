// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./interfaces/IDepositHandler.sol";
import "./interfaces/IPaymentModule.sol";
import "./vault/FungibleVestingVault.sol";
import "./vault/MultiVault.sol";
import "../common/interfaces/IVaultKey.sol";

contract VaultFactory is IDepositHandler {
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    enum VaultStatus {
        Inactive,
        Locked,
        Unlocked
    }
    mapping(uint256 => address) public vaultByKey;
    mapping(address => VaultStatus) public vaultStatus;

    address public owner;
    IVaultKey public keyNFT;
    IPaymentModule public paymentModule;
    uint256 public maxTokensPerVault;

    uint256 public vaultUnlockedLastBlock;
    uint256 public vaultCreatedLastBlock;

    event MaxTokensUpdated(uint256 indexed oldMax, uint256 indexed newMax);
    event PaymentModuleUpdated(address indexed oldModule, address indexed newModule);
    event VaultUnlocked(uint256 previousBlock, address indexed vault, uint256 timestamp, bool isCompletelyUnlocked);

    event VaultCreated(
        uint256 previousBlock,
        address indexed vault,
        uint256 key,
        address benefactor,
        address indexed beneficiary,
        address indexed referrer,
        uint256 unlockTimestamp,
        FungibleTokenDeposit[] fungibleTokenDeposits,
        NonFungibleTokenDeposit[] nonFungibleTokenDeposits,
        MultiTokenDeposit[] multiTokenDeposits,
        bool isVesting
    );

    event TokensBurned(
        address indexed benefactor,
        address indexed referrer,
        FungibleTokenDeposit[] fungibleTokenDeposits,
        NonFungibleTokenDeposit[] nonFungibleTokenDeposits,
        MultiTokenDeposit[] multiTokenDeposits
    );

    event VaultLockExtended(address indexed vault, uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp);

    constructor(
        address keyNFTAddress,
        address paymentModuleAddress,
        uint256 maxTokens
    ) {
        keyNFT = IVaultKey(keyNFTAddress);
        paymentModule = IPaymentModule(paymentModuleAddress);
        owner = msg.sender;
        maxTokensPerVault = maxTokens;
    }

    function setMaxTokensPerVault(uint256 newMax) external {
        require(msg.sender == owner, "VaultFactory:setMaxTokensPerVault:OWNER_ONLY");

        uint256 oldMax = maxTokensPerVault;
        maxTokensPerVault = newMax;

        emit MaxTokensUpdated(oldMax, newMax);
    }

    function createVault(
        address referrer,
        address beneficiary,
        uint256 unlockTimestamp,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting
    ) external payable {
        require(unlockTimestamp >= block.timestamp, "VaultFactory:createVault:UNLOCK_IN_PAST");
        require(
            fungibleTokenDeposits.length > 0 || nonFungibleTokenDeposits.length > 0 || multiTokenDeposits.length > 0,
            "VaultFactory:createVault:NO_DEPOSITS"
        );
        require(
            fungibleTokenDeposits.length + nonFungibleTokenDeposits.length + multiTokenDeposits.length <
                maxTokensPerVault,
            "VaultFactory:createVault:MAX_DEPOSITS_EXCEEDED"
        );
        require(msg.sender != referrer, "VaultFactory:createVault:SELF_REFERRAL");
        require(beneficiary != referrer, "VaultFactory:createVault:REFERRER_IS_BENEFICIARY");
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            require(fungibleTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }
        for (uint256 i = 0; i < multiTokenDeposits.length; i++) {
            require(multiTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }

        // Mint a key for the new vault.
        keyNFT.mintKey(beneficiary);
        uint256 keyId = keyNFT.lastMintedKeyId(beneficiary);

        // Early definition of vault address variable to allow usage by the
        // conditional branches of this function.
        address vault;

        if (isVesting) {
            require(
                nonFungibleTokenDeposits.length == 0 && multiTokenDeposits.length == 0,
                "VaultFactory:createVault:ONLY_FUNGIBLE_VESTING"
            );

            vault = _createVestingVault(keyId, unlockTimestamp, fungibleTokenDeposits);
        } else {
            vault = _createBatchVault(
                keyId,
                unlockTimestamp,
                fungibleTokenDeposits,
                nonFungibleTokenDeposits,
                multiTokenDeposits
            );
        }

        paymentModule.processPayment{ value: msg.value }(
            IPaymentModule.ProcessPaymentParams({
                vault: vault,
                user: msg.sender,
                referrer: referrer,
                fungibleTokenDeposits: fungibleTokenDeposits,
                nonFungibleTokenDeposits: nonFungibleTokenDeposits,
                multiTokenDeposits: multiTokenDeposits,
                isVesting: isVesting
            })
        );

        vaultByKey[keyId] = vault;
        vaultStatus[vault] = VaultStatus.Locked;

        emit VaultCreated(
            vaultCreatedLastBlock,
            vault,
            keyId,
            msg.sender,
            beneficiary,
            referrer,
            unlockTimestamp,
            fungibleTokenDeposits,
            nonFungibleTokenDeposits,
            multiTokenDeposits,
            isVesting
        );
        vaultCreatedLastBlock = block.number;
    }

    function burn(
        address referrer,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits
    ) external payable {
        require(
            fungibleTokenDeposits.length > 0 || nonFungibleTokenDeposits.length > 0 || multiTokenDeposits.length > 0,
            "VaultFactory:createVault:NO_DEPOSITS"
        );
        require(
            fungibleTokenDeposits.length + nonFungibleTokenDeposits.length + multiTokenDeposits.length <
                maxTokensPerVault,
            "VaultFactory:createVault:MAX_DEPOSITS_EXCEEDED"
        );
        require(msg.sender != referrer, "VaultFactory:createVault:SELF_REFERRAL");
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            require(fungibleTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }
        for (uint256 i = 0; i < multiTokenDeposits.length; i++) {
            require(multiTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }

        paymentModule.processPayment{ value: msg.value }(
            IPaymentModule.ProcessPaymentParams({
                vault: burnAddress,
                user: msg.sender,
                referrer: referrer,
                fungibleTokenDeposits: fungibleTokenDeposits,
                nonFungibleTokenDeposits: nonFungibleTokenDeposits,
                multiTokenDeposits: multiTokenDeposits,
                isVesting: false
            })
        );

        emit TokensBurned(msg.sender, referrer, fungibleTokenDeposits, nonFungibleTokenDeposits, multiTokenDeposits);
    }

    function notifyUnlock(bool isCompletelyUnlocked) external {
        require(vaultStatus[msg.sender] == VaultStatus.Locked, "VaultFactory:notifyUnlock:ALREADY_FULL_UNLOCKED");

        if (isCompletelyUnlocked) {
            vaultStatus[msg.sender] = VaultStatus.Unlocked;
        }

        emit VaultUnlocked(vaultUnlockedLastBlock, msg.sender, block.timestamp, isCompletelyUnlocked);
        vaultUnlockedLastBlock = block.number;
    }

    function updateOwner(address newOwner) external {
        require(msg.sender == owner, "VaultFactory:updateOwner:OWNER_ONLY");
        owner = newOwner;
    }

    function updatePaymentModule(address newModule) external {
        require(msg.sender == owner, "VaultFactory:updatePaymentModule:OWNER_ONLY");
        address oldModule = address(paymentModule);
        paymentModule = IPaymentModule(newModule);

        emit PaymentModuleUpdated(oldModule, newModule);
    }

    function lockExtended(uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp) external {
        require(vaultStatus[msg.sender] == VaultStatus.Locked, "VaultFactory:lockExtended:ALREADY_FULL_UNLOCKED");
        emit VaultLockExtended(msg.sender, oldUnlockTimestamp, newUnlockTimestamp);
    }

    function _createVestingVault(
        uint256 keyId,
        uint256 unlockTimestamp,
        FungibleTokenDeposit[] memory fungibleTokenDeposits
    ) private returns (address) {
        FungibleVestingVault vault = new FungibleVestingVault(
            address(keyNFT),
            keyId,
            unlockTimestamp,
            fungibleTokenDeposits
        );

        return address(vault);
    }

    function _createBatchVault(
        uint256 keyId,
        uint256 unlockTimestamp,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits
    ) private returns (address) {
        MultiVault vault = new MultiVault(
            address(keyNFT),
            keyId,
            unlockTimestamp,
            fungibleTokenDeposits,
            nonFungibleTokenDeposits,
            multiTokenDeposits
        );

        return address(vault);
    }
}