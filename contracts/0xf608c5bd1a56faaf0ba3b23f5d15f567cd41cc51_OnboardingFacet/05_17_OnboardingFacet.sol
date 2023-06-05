// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {AppFacet} from "../../internals/AppFacet.sol";
import {BaseStorage} from "../../diamond/BaseStorage.sol";
import {OnboardingStorage} from "./OnboardingStorage.sol";

contract OnboardingFacet is AppFacet {
    using ECDSAUpgradeable for bytes32;

    function linkMintTo(
        address recipient,
        uint256 quantity,
        uint256 maxAmount,
        uint256 maxPerWallet,
        uint256 maxPerMint,
        uint256 expiration,
        string memory linkId,
        bytes calldata signature
    ) external payable {
        OnboardingStorage.Layout storage layout = OnboardingStorage.layout();
        BaseStorage.Layout storage baseLayout = BaseStorage.layout();
        require(
            !layout._isSignatureVerified[signature],
            "Signature already verified"
        );
        require(
            address(baseLayout._mintSigner) != address(0),
            "Mint signer not set"
        );
        require(quantity <= maxPerMint, "Exceeded max per mint");
        require(
            layout._mintedTokensPerLinkPerWallet[linkId][recipient] +
                quantity <=
                maxPerWallet,
            "Exceeded max per wallet"
        );
        require(
            maxAmount == 0
                ? true
                : layout._totalMintedPerLink[linkId] + quantity <= maxAmount,
            "Exceeded max supply"
        );
        require(expiration > block.timestamp, "Signature expired");
        require(
            keccak256(
                abi.encodePacked(
                    recipient,
                    maxAmount,
                    maxPerWallet,
                    maxPerMint,
                    expiration,
                    linkId
                )
            ).toEthSignedMessageHash().recover(signature) ==
                baseLayout._mintSigner,
            "Invalid signature"
        );

        layout._isSignatureVerified[signature] = true;
        unchecked {
            layout._totalMintedPerLink[linkId] += quantity;
            layout._mintedTokensPerLinkPerWallet[linkId][recipient] += quantity;
        }
        _mint(recipient, quantity);
    }

    function linkSupply(string memory linkId) external view returns (uint256) {
        return OnboardingStorage.layout()._totalMintedPerLink[linkId];
    }
}