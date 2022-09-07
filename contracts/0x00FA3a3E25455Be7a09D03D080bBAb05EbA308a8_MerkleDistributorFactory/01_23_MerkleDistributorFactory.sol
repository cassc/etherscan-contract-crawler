//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./MerkleDistributor.sol";

contract MerkleDistributorFactory {
    error EscrowTransferFailed();
    error ClaimDurationInvalid();

    event MerkleDistributorCreated(
        address albumSafeAddress,
        address token,
        bytes32 merkleRoot,
        address distributorAddress,
        uint256 amountToDistribute,
        uint256 claimDuration
    );

    address public immutable MERKLE_DISTRIBUTOR_MASTER_COPY;

    constructor() {
        MERKLE_DISTRIBUTOR_MASTER_COPY = address(new MerkleDistributor());
    }

    function saltDistributor(
        address sender,
        address albumSafeAddress,
        address token,
        bytes32 merkleRoot,
        uint256 claimDuration
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    sender,
                    albumSafeAddress,
                    token,
                    merkleRoot,
                    claimDuration
                )
            );
    }

    function predictMerkleDistributorAddress(
        address sender,
        address albumSafeAddress,
        address token,
        bytes32 merkleRoot,
        uint256 claimDuration
    ) public view returns (address predicted) {
        predicted = Clones.predictDeterministicAddress(
            MERKLE_DISTRIBUTOR_MASTER_COPY,
            saltDistributor(
                sender,
                albumSafeAddress,
                token,
                merkleRoot,
                claimDuration
            )
        );
    }

    function createMerkleDistributor(
        address albumSafeAddress,
        address token,
        bytes32 merkleRoot,
        uint256 amountToDistribute,
        uint256 claimDuration
    ) external returns (address created) {
        if (claimDuration <= 0) revert ClaimDurationInvalid();
        created = Clones.cloneDeterministic(
            MERKLE_DISTRIBUTOR_MASTER_COPY,
            saltDistributor(
                msg.sender,
                albumSafeAddress,
                token,
                merkleRoot,
                claimDuration
            )
        );
        MerkleDistributor(created).initialize(
            msg.sender,
            albumSafeAddress,
            token,
            merkleRoot,
            claimDuration
        );

        // Transfer tokens to albumSafe from distributor for escrow, reverts if transfer fails.
        if (
            !ERC20PresetMinterPauser(token).transferFrom(
                albumSafeAddress,
                created,
                amountToDistribute
            )
        ) revert EscrowTransferFailed();

        emit MerkleDistributorCreated(
            albumSafeAddress,
            token,
            merkleRoot,
            address(created),
            amountToDistribute,
            claimDuration
        );
    }
}