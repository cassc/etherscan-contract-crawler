// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { MerkleProof } from "@openzeppelin/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/utils/structs/BitMaps.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import "./libraries/Errors.sol";

/// @title EarlyDrop
/// @notice Base contract for allowing airdrop distributions
contract EarlyDrop is Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                                USER-FACING STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Timestamp when claims will be allow from.
    uint256 public immutable kickOffTime;

    /// @notice ERC20 representation of the claimable token.
    IERC20 public claimToken;

    /// @notice Root of the tree.
    bytes32 public immutable merkleRoot;

    /// @notice Representation of the recipients within the Bitmaps.
    BitMaps.BitMap _chadRecipientList;

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event Claimed(address indexed recipient, uint256 claimedAmount, uint256 timestamp);

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param _merkleRoot The merkle root for the Merkle Tree.
    /// @param _kickOffTime The timestamp when the users could claim the token from.
    constructor(bytes32 _merkleRoot, uint256 _kickOffTime) Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
        kickOffTime = _kickOffTime;
    }

    /// @param _claimToken The address of the claimable token.
    function initialize(address _claimToken) external onlyOwner {
        claimToken = IERC20(_claimToken);
        renounceOwnership();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reverts if called by any account other than the admin.
    modifier periodStarted() {
        if (block.timestamp < kickOffTime) revert Errors.DistributionNotStarted(block.timestamp, kickOffTime);
        _;
    }

    /// @notice Helper to determine if specific index within tree has claim already
    /// @param _index Numeric index of the position in the tree
    function hasClaim(uint256 _index) public view returns (bool) {
        return BitMaps.get(_chadRecipientList, _index);
    }

    function claim(bytes32[] calldata _proof, uint256 _index, uint256 _amount) external periodStarted {
        if (BitMaps.get(_chadRecipientList, _index)) revert Errors.AddressClaimedAlready(msg.sender);

        _verifyProof(_proof, _index, _amount, msg.sender);

        BitMaps.setTo(_chadRecipientList, _index, true);

        bool success = claimToken.transfer(msg.sender, _amount);
        if (!success) revert Errors.TokenTransferFailure();

        emit Claimed(msg.sender, _amount, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _verifyProof(bytes32[] calldata _proof, uint256 _index, uint256 _amount, address _claimer) internal view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_claimer, _index, _amount))));
        if (!MerkleProof.verify(_proof, merkleRoot, leaf)) revert Errors.ProofNotValid();
    }
}