// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @title EnigmaNFT721
///
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "../utils/EIP712.sol";

contract AuthorizedMintingNFT is EIP712 {
    using ECDSAUpgradeable for bytes32;
    bytes32 private constant NFT_MINTING_VOUCHER_TYPE_HASH = keccak256("NFTMintingVoucher(string tokenURI)");

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EIP712(name, version) {}

    /**
     * @notice Internal function to verify a sign to mint tokens
     * Reverts if the sign verification fails.
     * @param tokenURI string memory URI of the token to be minted.
     * @param signature signature that authorizes the user to mint these tokens
     * @param authorizer address of the wallet that authorizes minters
     */
    function verifySign(
        string memory tokenURI,
        bytes memory signature,
        address authorizer
    ) internal view {
        bytes32 digest =
            _hashTypedDataV4(keccak256(abi.encode(NFT_MINTING_VOUCHER_TYPE_HASH, keccak256(bytes(tokenURI)))));
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(authorizer == signer, "Owner sign verification failed");
    }
}