// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT1155.sol";
import "../utils/BlockchainUtils.sol";
import "../utils/AuthorizedMintingNFT.sol";

/// @title EnigmaNFT1155
///
/// @dev This contract extends from BaseEnigmaNFT1155

contract EnigmaNFT1155 is BaseEnigmaNFT1155, AuthorizedMintingNFT {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;

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
     * @notice Initialize NFT1155 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the toke base uri
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_
    ) external initializer {
        super._initialize(name_, symbol_, tokenURIPrefix_);
    }

    /**
     * @notice public function to mint a new token.
     * @param uri_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     * @param sign_ bytes that authorize the minting of this token
     */
    function mint(
        string memory uri_,
        uint256 supply_,
        uint256 fee_,
        bytes memory sign_
    ) external {
        mintWithCustomRightsHolder(uri_, supply_, fee_, msg.sender, msg.sender, sign_);
    }

    /**
     * @notice public function to mint a new token.
     * @param uri_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ address that will receive the royalties
     * @param to_ address of the first receiver
     * @param sign_ bytes that authorize the minting of this token
     */
    function mintWithCustomRightsHolder(
        string memory uri_,
        uint256 supply_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        bytes memory sign_
    ) public returns (uint256) {
        verifySign(uri_, sign_, owner());
        uint256 tokenId = _mintNew(to_, _increaseNextId(), supply_, uri_, fee_, rightsHolder_);
        creators[tokenId] = msg.sender;
        return tokenId;
    }

    function getCreator(uint256 tokenId) external view virtual override returns (address) {
        return creators[tokenId];
    }
}