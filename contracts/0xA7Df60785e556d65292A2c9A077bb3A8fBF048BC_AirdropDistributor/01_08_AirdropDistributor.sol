// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IAddressProvider} from "@gearbox-protocol/core-v2/contracts/interfaces/IAddressProvider.sol";
import {IAirdropDistributor, DistributionData, ClaimedData} from "./IAirdropDistributor.sol";

contract AirdropDistributor is Ownable, IAirdropDistributor {
    /// @dev Emits each time when call not by treasury
    error TreasuryOnlyException();

    /// @dev Emits if already claimed is forbidden
    error AlreadyClaimedFinishedException();

    /// @dev Returns the token distributed by the contract
    IERC20 public immutable override token;

    /// @dev DAO Treasury address
    address public immutable treasury;

    /// @dev The current merkle root of total claimable balances
    bytes32 public override merkleRoot;

    /// @dev The mapping that stores amounts already claimed by users
    mapping(address => uint256) public claimed;

    modifier treasuryOnly() {
        if (msg.sender != treasury) revert TreasuryOnlyException();
        _;
    }

    constructor(
        address addressProvider,
        bytes32 merkleRoot_,
        ClaimedData[] memory alreadyClaimed
    ) {
        token = IERC20(IAddressProvider(addressProvider).getGearToken());
        treasury = IAddressProvider(addressProvider).getTreasuryContract();
        merkleRoot = merkleRoot_;
        _updateHistoricClaims(alreadyClaimed);
    }

    function updateMerkleRoot(bytes32 newRoot) external treasuryOnly {
        bytes32 oldRoot = merkleRoot;
        merkleRoot = newRoot;
        emit RootUpdated(oldRoot, newRoot);
    }

    function emitDistributionEvents(DistributionData[] calldata data)
        external
        onlyOwner
    {
        uint256 len = data.length;
        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                emit TokenAllocated(
                    data[i].account,
                    data[i].campaignId,
                    data[i].amount
                );
            }
        }
    }

    function updateHistoricClaims(ClaimedData[] memory alreadyClaimed)
        external
        onlyOwner
    {
        _updateHistoricClaims(alreadyClaimed);
    }

    function _updateHistoricClaims(ClaimedData[] memory alreadyClaimed)
        internal
    {
        uint256 len = alreadyClaimed.length;
        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                emit Claimed(
                    alreadyClaimed[i].account,
                    alreadyClaimed[i].amount,
                    true
                );
            }
        }
    }

    function claim(
        uint256 index,
        address account,
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) external override {
        require(
            claimed[account] < totalAmount,
            "MerkleDistributor: Nothing to claim"
        );

        bytes32 node = keccak256(abi.encodePacked(index, account, totalAmount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        uint256 claimedAmount = totalAmount - claimed[account];
        claimed[account] += claimedAmount;
        token.transfer(account, claimedAmount);

        emit Claimed(account, claimedAmount, false);
    }
}