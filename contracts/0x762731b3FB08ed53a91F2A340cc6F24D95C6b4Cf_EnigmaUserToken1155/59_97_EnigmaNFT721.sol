// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT721.sol";
import "../utils/BlockchainUtils.sol";
import "../utils/AuthorizedMintingNFT.sol";

/// @title EnigmaNFT721
///
/// @dev This contract extends from BaseEnigmaNFT721

contract EnigmaNFT721 is BaseEnigmaNFT721, AuthorizedMintingNFT {
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
    constructor(string memory name, string memory version) AuthorizedMintingNFT(name, version) {}

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param sign_ bytes that authorize the minting of this token
     */
    function createCollectible(
        string memory tokenURI_,
        uint256 fee_,
        bytes memory sign_
    ) external returns (uint256) {
        return createCollectibleWithCustomRightsHolder(tokenURI_, fee_, msg.sender, msg.sender, sign_);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param sign_ bytes that authorize the minting of this token
     */
    function createCollectibleWithCustomRightsHolder(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        bytes memory sign_
    ) public returns (uint256) {
        uint256 newItemId = tokenCounter;
        verifySign(tokenURI_, sign_, owner());
        tokenCounter = tokenCounter + 1;
        _safeMint(to_, newItemId, fee_, rightsHolder_);
        _setTokenURI(newItemId, tokenURI_);
        return newItemId;
    }
}