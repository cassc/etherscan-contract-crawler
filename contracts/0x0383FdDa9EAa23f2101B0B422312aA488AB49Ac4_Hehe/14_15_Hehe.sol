// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./HeheStorage.sol";

/**
 * Subset of the IDelegationRegistry with a method that checks if the
 * address is delegated to act on the user's behalf for a token contract
 */
interface IDelegationRegistry {
    function checkDelegateForContract(
        address delegate,
        address vault,
        address contract_
    ) external view returns (bool);
}

/**
 * Subset of the IOperatorFilterRegistry with only the methods that the main minting contract will call.
 * The owner of the collection is able to manage the registry subscription on the contract's behalf
 */
interface IOperatorFilterRegistry {
    function isOperatorAllowed(
        address registrant,
        address operator
    ) external returns (bool);
}

contract Hehe is ERC1155Upgradeable {
    using ECDSAUpgradeable for bytes32;

    HeheStorage public battlePassStorage;

    event Minted(
        address recipient,
        uint256 tokenId,
        uint256 valTokenId,
        uint256 amount,
        uint256 rewardLevel,
        bytes signature
    );

    /**
     * @dev Initializes the BattlePass contract with the given URI for metadata and BattlePassStorage contract.
     * @param initialUri The URI for the metadata.
     * @param _battlePassStorage The address of the BattlePassStorage contract.
     */
    function initialize(
        string memory initialUri,
        HeheStorage _battlePassStorage
    ) public initializer {
        __ERC1155_init(initialUri);
        battlePassStorage = _battlePassStorage;
    }

    /**
     * @dev Returns the metadata URI for a given token ID in the ERC-1155 token contract.
     * @param tokenId The token ID for which the metadata URI is being requested.
     * @return string memory The metadata URI for the specified token ID.
     */
    function uri(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return battlePassStorage.tokenURI(tokenId);
    }

    /**
     * @notice Allows users to mint tokens by providing a valid signature.
     * @param tokenId The ID of the token to be minted.
     * @param valTokenId The ID of the Valhalla token linked to this mint.
     * @param amount The number of tokens to be minted.
     * @param rewardLevel The reward level of the token.
     * @param signature The signature provided by the signer to validate the minting.
     * @param vault The protected wallet being requested from the delegated wallet. Use zero addr if not using a delegated wallet.
     */
    function mintSignature(
        uint256 tokenId,
        uint256 valTokenId,
        uint256 amount,
        uint256 rewardLevel,
        bytes memory signature,
        address vault
    ) external {
        address requester = msg.sender;

        if (vault != address(0)) {
            bool isDelegateValid = IDelegationRegistry(
                battlePassStorage.DELEGATION_REGISTRY_ADDRESS()
            ).checkDelegateForContract(
                    msg.sender,
                    vault,
                    battlePassStorage.battlePassAddress()
                );
            if (!isDelegateValid) revert InvalidDelegateVaultPairing();
            requester = vault;
        }

        uint256 newTotalMintedSupply = battlePassStorage.mintedSupply(tokenId) +
            amount;
        uint256 newValMintedSupply = battlePassStorage.valMintedSupply(
            valTokenId
        ) + amount;
        if (newValMintedSupply > battlePassStorage.maxValMintSupply())
            revert ExceedsMaxValMintAmount();

        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encode(
                    address(this),
                    tokenId,
                    valTokenId,
                    amount,
                    rewardLevel,
                    requester
                )
            )
        );

        if (battlePassStorage.signatureUsed(hash))
            revert SignatureAlreadyUsed();
        battlePassStorage.setSignatureUsed(hash);
        if (hash.recover(signature) != battlePassStorage.signerAddress())
            revert InvalidSignature();

        battlePassStorage.setMintedSupply(tokenId, newTotalMintedSupply);
        battlePassStorage.setValMintedSupply(valTokenId, newValMintedSupply);

        _mint(requester, tokenId, amount, "");

        emit Minted(
            requester,
            tokenId,
            valTokenId,
            amount,
            rewardLevel,
            signature
        );
    }

    /**
     * @dev Stops operators from being added as an approved address to transfer.
     * @param operator the address a wallet is trying to grant approval to.
     * @param approved Whether the operator will be approved or not.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        if (
            approved &&
            battlePassStorage.operatorFilterRegistryAddress() != address(0)
        ) {
            if (
                !IOperatorFilterRegistry(
                    battlePassStorage.operatorFilterRegistryAddress()
                ).isOperatorAllowed(
                        battlePassStorage.filterRegistrant(),
                        operator
                    )
            ) {
                revert OperatorNotAllowed();
            }
        }
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Stops operators that are not approved from doing transfers.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (battlePassStorage.operatorFilterRegistryAddress() != address(0)) {
            if (
                !IOperatorFilterRegistry(
                    battlePassStorage.operatorFilterRegistryAddress()
                ).isOperatorAllowed(
                        battlePassStorage.filterRegistrant(),
                        msg.sender
                    )
            ) {
                revert OperatorNotAllowed();
            }
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    error InvalidDelegateVaultPairing();
    error ExceedsMaxValMintAmount();
    error SignatureAlreadyUsed();
    error InvalidSignature();
    error OperatorNotAllowed();
}