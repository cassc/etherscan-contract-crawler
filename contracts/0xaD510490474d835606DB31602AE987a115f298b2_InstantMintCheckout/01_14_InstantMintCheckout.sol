// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../registry/ITokenRegistry.sol";
import "./Checkout.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/**
 * @title {InstantMintCheckout} is an implementation of {Checkout} for which the {_postCheckoutAction}
 * instantly mints a new token in a {ITokenRegistry}
 */
contract InstantMintCheckout is Checkout {

    event TokenMinted(address indexed registry, address indexed receiver, bytes32 proofOfIntegrity, string checkoutId);

    /**
     * @dev post-checkout action data required to mint a token. This struct is formed by the calling application.
     */
    struct PostCheckoutCallData {
        bytes32 tokenProofOfIntegrity;  // the proof of integrity of the token to mint.
        address tokenRegistryAddress;   // the {ITokenRegistry} where the token will be minted post-checkout.
        address tokenReceiver;          // the account that will receive the newly minted token.
    }

    /**
     * @dev constructor.
     * @param paymentReceiver_ the address of the payment receiver account.
     * @param checkoutOracle_ the address of the checkout oracle account.
     */
    constructor(
        address paymentReceiver_,
        address checkoutOracle_
    ) Checkout(paymentReceiver_, checkoutOracle_) {}

    /**
     * @dev modifier to check that the token registry implements {ITokenRegistry}.
     */
    modifier onlyValidRegistry(address tokenRegistryAddress) {
        require(
            ERC165Checker.supportsInterface(tokenRegistryAddress, type(ITokenRegistry).interfaceId),
            "InstantMintCheckout: Target token registry contract does not match the interface requirements."
        );
        _;
    }

    /**
     * @dev helper function to encode {PostCheckoutCallData} from the input arguments so that it can be passed to
     * {Checkout._encodeCheckoutRequest} and {_postCheckoutAction} in the right format.
     * @param tokenProofOfIntegrity the proof of integrity of the token to mint.
     * @param tokenRegistryAddress the {ITokenRegistry} where the token will be minted post-checkout.
     * @param tokenReceiver the account that will receive the newly minted token.
     * 
     * Requirements:
     * 
     *      - {tokenRegistryAddress} must be a valid {ITokenRegistry}.
     *      - If {data} is the result of this function, ethers.utils.arrayify(data) must be called to
     *        appropriately pass it through as an input to {_encodeCheckoutRequest}.
     */
    function encodePostCheckoutCallData(
        bytes32 tokenProofOfIntegrity,
        address tokenRegistryAddress,
        address tokenReceiver
    ) public view onlyValidRegistry(tokenRegistryAddress) returns (bytes memory) {
        return abi.encode(
            PostCheckoutCallData(
                tokenProofOfIntegrity,
                tokenRegistryAddress,
                tokenReceiver
            )
        ); 
    }


    /* =========================================== POST-CHECKOUT ACTION =========================================== */

    /**
     * @dev a post-checkout function that mints a new token in the appropriate {ITokenRegistry}.
     * @param checkoutId the checkout id.
     * @param data the encoded input data to execute this function.
     * 
     * Requirements:
     * 
     *      - {data} must decode to {PostCheckoutCallData decoded}.
     *      - {decoded.tokenRegistryAddress} must be the address of a {ITokenRegistry} contract.
     *      - All the equirements from {ITokenRegistry.mintToken} must be met.
     * 
     */
     function _postCheckoutAction(string memory checkoutId, bytes memory data) internal override {
        PostCheckoutCallData memory decoded = abi.decode(data, (PostCheckoutCallData));
        try ITokenRegistry(decoded.tokenRegistryAddress).mintToken(decoded.tokenReceiver, decoded.tokenProofOfIntegrity) {
            emit TokenMinted(
                decoded.tokenRegistryAddress,
                decoded.tokenReceiver,
                decoded.tokenProofOfIntegrity,
                checkoutId
            );
        } catch Error(string memory reason) {
            revert(
                string(abi.encodePacked(
                    "InstantMintCheckout: Post-checkout action failure (", 
                    reason,
                    ")"
                ))
            );
        }
     }

}