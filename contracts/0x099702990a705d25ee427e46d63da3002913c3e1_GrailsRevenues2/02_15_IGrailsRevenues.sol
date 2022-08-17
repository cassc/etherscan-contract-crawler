// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IGrailsRevenues is IERC165 {
    /**
    @notice Returns the address to which revenues for the specified Grail should
    be sent.
     */
    function receiver(uint8 grailId) external view returns (address);

    /**
    @notice Returns the royalty basis points for the specified Grail.
     */
    function royaltyBasisPoints(uint8 grailId) external view returns (uint256);

    /**
    @dev Single-word representation of a share of the balance to be disbursed.
     */
    struct Disbursement {
        uint8 grailId;
        uint248 value;
    }

    /**
    @notice Disburses the revenues amongst artists based on the specified split.
    @dev This is a workaround because OpenSea doesn't support ERC2981 and also
    doesn't allow for multiple royalty recipients in a collection. As a result,
    there is some level of off-chain trust that is unavoidable, but can at least
    be audited.
    @param shares Individual values SHOULD sum to the current balance of the
    contract to allow for a clear audit trail.
     */
    function disburseBalance(Disbursement[] calldata shares) external;
}