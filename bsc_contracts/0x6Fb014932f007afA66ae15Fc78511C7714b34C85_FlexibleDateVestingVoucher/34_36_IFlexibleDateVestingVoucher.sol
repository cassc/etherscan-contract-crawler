// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@solv/v2-vnft-core/contracts/interface/IVNFT.sol";
import "@solv/v2-vnft-core/contracts/interface/optional/IVNFTMetadata.sol";
import "./IFlexibleDateVestingPool.sol";

interface IFlexibleDateVestingVoucher is IVNFT, IVNFTMetadata {

    struct FlexibleDateVestingVoucherSnapshot {
        IFlexibleDateVestingPool.SlotDetail slotSnapshot;
        uint256 tokenId;
        uint256 vestingAmount;
    }

    /** ===== Begin of events emited by FlexibleDateVestingVoucher ===== */
    event SetDescriptor(address oldDescriptor, address newDescriptor);

    event SetSolver(address oldSolver, address newSolver);

    event Claim(uint256 indexed tokenId, address to, uint256 claimAmount);
    /** ===== End of events emited by FlexibleDateVestingVoucher ===== */


    /** ===== Begin of interfaces of FlexibleDateVestingVoucher ===== */
    function mint(
        address issuer_,
        uint8 claimType_,
        uint64 latestStartTime_,
        uint64[] calldata terms_,
        uint32[] calldata percentages_,
        uint256 vestingAmount_
    ) 
        external 
        returns (uint256 slot, uint256 tokenId);

    function claim(uint256 tokenId_, uint256 claimAmount_) external;

    function claimTo(uint256 tokenId_, address to_, uint256 claimAmount_) external;

    function setStartTime(uint256 slot_, uint64 startTime_) external;

    function isClaimable(uint256 slot_) external view returns (bool);

    function underlying() external view returns (address);

    function underlyingVestingVoucher() external view returns (address);
    /** ===== End of interfaces of FlexibleDateVestingVoucher ===== */

}