// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IApproval {
    error InvalidApprovalZeroAddress();
    error CallerNotOwnerOrApprovedOperator();

    /// @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    /// @param _owner owner address
    /// @param _approved approved address
    /// @param _tokenId NFT that approve for
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    /// @param _owner owner address
    /// @param _operator operator address
    /// @param _approved enables or disables the operator
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}