// SPDX-License-Identifier: MIT
// vim: textwidth=119
pragma solidity 0.8.11;

///
interface IBoredBoxBatchSender_Functions {
    /// Transfer many tokens from contract to many recipients
    /// @param tokenContract Address to smart contract with tokens
    /// @param boxes Array of BoredBoxNFT token IDs
    /// @param tokenIds Array of numbers for token IDs to transfer from `tokenContracts`
    /// @param recipients Array of addresses to receive `tokenIds` assets
    /// @custom:throw "Not authorized"
    /// @custom:throw "Insufficient boxes provided"
    /// @custom:throw "Length missmatch between; boxes, tokenIds, and/or recipients"
    /// @custom:throw "Failed to recognize tokenContract"
    function batchTransfer(
        address tokenContract,
        uint256[] calldata boxes,
        uint256[] calldata tokenIds,
        address[] calldata recipients
    ) external payable;

    /// @param key Address to set `value` within `isAuthorized` mapping
    /// @param value Boolean state to set for given `key` within `isAuthorized` mapping
    /// @custom:throw "Not authorized"
    function setAuthorized(address key, bool value) external payable;

    /// Send amount of Ether from `this.balance` to some address
    /// @custom:throw "Not authorized"
    /// @custom:throw "Transfer failed"
    function withdraw(address payable to, uint256 amount) external payable;

    /// @param to Address to check for ERC721Receiver and onERC1155Receiver compatibility
    /// @return what receiver(s) are implemented for `to` address
    /// - `0` if not compatible
    /// - `1` if compatible with ERC721Receiver only
    /// - `2` if compatible with ERC1155Receiver only
    /// - `3` if compatible with both ERC721Receiver and ERC1155Receiver
    function canReceive(address to) external view returns (uint256);

    /// @param box BoredBoxNFT Token ID
    /// @param tokenContract Address to ERC{721,1155} contract
    /// @custom:throw "Not claimed"
    function claimed(uint256 box, address tokenContract) external view returns (uint256);
}

///
interface IBoredBoxBatchSender_Variables {
    /// @param account Address to check if authorized
    /// @return authorized Boolean authorization status
    function isAuthorized(address account) external view returns (bool authorized);
}

/* For external callers */
interface IBoredBoxBatchSender is IBoredBoxBatchSender_Variables, IBoredBoxBatchSender_Functions {

}