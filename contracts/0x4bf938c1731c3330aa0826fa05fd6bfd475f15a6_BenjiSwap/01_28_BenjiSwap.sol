// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ERC20Storage} from "@animoca/ethereum-contracts/contracts/token/ERC20/libraries/ERC20Storage.sol";
import {PauseStorage} from "@animoca/ethereum-contracts/contracts/lifecycle/libraries/PauseStorage.sol";
import {Pause} from "@animoca/ethereum-contracts/contracts/lifecycle/Pause.sol";
import {ERC20Receiver} from "@animoca/ethereum-contracts/contracts/token/ERC20/ERC20Receiver.sol";
import {ContractOwnership} from "@animoca/ethereum-contracts/contracts/access/ContractOwnership.sol";

/**
 * @title BenjiSwap
 * @dev A smart contract that allows users to swap primateToken for benjiToken based on a pre-generated Merkle tree.
 * @dev Users can claim their share of benjiToken by providing a valid Merkle proof of their primateToken balance.
 **/
contract BenjiSwap is ERC20Receiver, Pause {
    using PauseStorage for PauseStorage.Layout;
    using MerkleProof for bytes32[];

    event TokenSwapped(address userAddress, uint256 amount);

    /// @notice The token to be swapped
    IERC20 public immutable primateToken;

    /// @notice The token to receive
    IERC20 public immutable benjiToken;

    /// @notice The address to receive primateToken
    address public immutable primateSink;

    /// @notice The address to send benjiToken from
    address public immutable benjiTreasury;

    /// @notice The Merkle root used to verify the Merkle proof
    bytes32 public immutable merkleRoot;

    /// @notice Mapping of claimed status of a user's token swap
    mapping(address => bool) public claimed;

    /**
     * @dev Constructor function for the BenjiSwap contract.
     * @param _primateToken The address of the token to be swapped.
     * @param _benjiToken The address of the token to receive.
     * @param _primateSink The address to receive primateToken.
     * @param _benjiTreasury The address to send benjiToken from.
     * @param _merkleRoot The Merkle root used to verify the Merkle proof.
     */
    constructor(
        IERC20 _primateToken,
        IERC20 _benjiToken,
        address _primateSink,
        address _benjiTreasury,
        bytes32 _merkleRoot
    ) Pause(false) ContractOwnership(msg.sender) {
        primateToken = _primateToken;
        benjiToken = _benjiToken;
        primateSink = _primateSink;
        benjiTreasury = _benjiTreasury;
        merkleRoot = _merkleRoot;
    }

    /**
     * @dev Validates a merkle proof for a user based on their address, the amount of tokens they want to swap and the merkle root.
     * @param account The address of the user.
     * @param amount The amount of tokens the user wants to swap.
     * @param merkleProof The merkle proof provided by the user.
     * @return A boolean indicating whether the proof is valid or not.
     */
    function verifyProof(address account, uint256 amount, bytes32[] memory merkleProof) internal view returns (bool) {
        bytes32 leafHash = keccak256(abi.encodePacked(account, amount));
        return merkleProof.verify(merkleRoot, leafHash);
    }

    /**
     * @notice On safely getting PRIMATE token, swap it for BENJI token.
     * @dev Reverts if the sender is not the PRIMATE token contract.
     * @dev Reverts if the swap is locked.
     * @dev Reverts if the tokens have already been claimed.
     * @dev Reverts if the token address is invalid.
     * @dev Reverts if the proof is invalid.
     */
    function onERC20Received(address, address from, uint256 value, bytes memory data) public virtual override returns (bytes4) {
        PauseStorage.layout().enforceIsNotPaused();
        require(msg.sender == address(primateToken), "BenjiSwap: Invalid token address");

        uint256 amount;
        bytes32[] memory merkleProof;

        (amount, merkleProof) = abi.decode(data, (uint256, bytes32[]));

        require(!claimed[from], "BenjiSwap: Already swapped");
        require(verifyProof(from, amount, merkleProof), "BenjiSwap: Invalid proof");

        uint256 amountToTransfer = value;
        claimed[from] = true;

        if (value > amount) {
            amountToTransfer = amount;
            // transfer back the excess received token to the user
            SafeERC20.safeTransfer(primateToken, from, value - amount);
        }

        // Transfer the old token to the sink
        SafeERC20.safeTransfer(primateToken, primateSink, amountToTransfer);

        // Transfer the new token from treasury to user wallet
        SafeERC20.safeTransferFrom(benjiToken, benjiTreasury, from, amountToTransfer);

        emit TokenSwapped(from, amountToTransfer);
        return ERC20Storage.ERC20_RECEIVED;
    }
}