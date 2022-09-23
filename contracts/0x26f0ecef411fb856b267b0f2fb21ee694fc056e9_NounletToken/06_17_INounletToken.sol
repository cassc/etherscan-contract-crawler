// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {INounsSeeder} from "./INounsSeeder.sol";

/// @dev Checkpoint information
struct Checkpoint {
    // Timestamp of checkpoint creation
    uint64 fromTimestamp;
    // Amount of votes
    uint192 votes;
}

/// @dev Interface for NounletToken contract
interface INounletToken is IERC165 {
    /// @dev Emitted when deadline for signature has passed
    error SignatureExpired(uint256 _timestamp, uint256 _deadline);
    /// @dev Emitted when caller is not required address
    error InvalidSender(address _required, address _provided);
    /// @dev Emitted when owner signature is invalid
    error InvalidSignature(address _signer, address _owner);

    /// @dev Event log for approving a spender of a token type
    /// @param _owner Address of the owner of the token type
    /// @param _operator Address of the spender of the token type
    /// @param _id ID of the token type
    /// @param _approved Approval status for the token type
    event SingleApproval(
        address indexed _owner,
        address indexed _operator,
        uint256 _id,
        bool _approved
    );

    function NOUNLET_REGISTRY() external pure returns (address);

    function NOUNS_DESCRIPTOR() external pure returns (address);

    function NOUNS_TOKEN_ID() external pure returns (uint256);

    function ROYALTY_BENEFICIARY() external pure returns (address);

    function batchBurn(address _from, uint256[] memory _ids) external;

    function generateSeed(uint256 _id) external view returns (INounsSeeder.Seed memory);

    function isApproved(
        address,
        address,
        uint256
    ) external view returns (bool);

    function mint(
        address _to,
        uint256 _id,
        bytes memory _data
    ) external;

    function permit(
        address _owner,
        address _operator,
        uint256 _id,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function permitAll(
        address _owner,
        address _operator,
        bool _approved,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function royaltyInfo(uint256 _id, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    function transferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    function setApprovalFor(
        address _operator,
        uint256 _id,
        bool _approved
    ) external;

    function supportsInterface(bytes4 _interfaceId) external view returns (bool);

    function uri(uint256 _id) external view returns (string memory);
}