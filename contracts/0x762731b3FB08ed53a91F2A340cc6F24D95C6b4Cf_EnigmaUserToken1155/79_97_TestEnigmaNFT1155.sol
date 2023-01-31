// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../ERC1155/EnigmaNFT1155.sol";

/// @title TestEnigmaNFT1155
///
/// @dev This contract extends from BaseEnigmaNFT1155 for upgradeablity testing

contract TestEnigmaNFT1155 is EnigmaNFT1155 {
    event CollectibleCreated(uint256 tokenId);

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
    constructor(string memory name, string memory version) EnigmaNFT1155(name, version) {}

    /**
     * @notice public function to mint a new token.
     * @param uri_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     */
    function mint(
        string memory uri_,
        uint256 supply_,
        uint256 fee_
    ) external {
        uint256 tokenId = _mintNew(msg.sender, _increaseNextId(), supply_, uri_, fee_, msg.sender);
        creators[tokenId] = msg.sender;
        emit CollectibleCreated(tokenId);
    }
}