// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IBondPool.sol";

interface IBondVoucher {

    struct BondVoucherSnapshot {
        IBondPool.SlotDetail slotDetail;
        uint256 tokenId;
        uint256 parValue;
    }

    event SetDescriptor(address oldDescriptor, address newDescriptor);

    event SetSolver(address oldSolver, address newSolver);

    event Claim (
        uint256 indexed tokenId,
        address indexed to,
        uint256 claimUnits,
        uint256 claimCurrencyAmount, 
        uint256 claimTokenAmount
    );

    function mint(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_,
        uint256 tokenInAmount_
    ) 
        external 
        returns (uint256 slot, uint256 tokenId);

    function claimAll(uint256 tokenId_) external;
    
    function claim(uint256 tokenId_, uint256 claimUnits_) external;

    function claimTo(uint256 tokenId_, address to_, uint256 claimUnits_) external;

    function getSlot(
        address issuer_,
        address fundCurrency_,
        uint128 lowestPrice_,
        uint128 highestPrice_,
        uint64 effectiveTime_,
        uint64 maturity_
    ) 
        external
        view 
        returns (uint256 slot);

    function getSlotDetail(uint256 slot_) 
        external 
        view 
        returns (IBondPool.SlotDetail memory);

    function getIssuerSlots(address issuer_) 
        external 
        view 
        returns (uint256[] memory slots);

    function getSnapshot(uint256 tokenId_)
        external
        view
        returns (BondVoucherSnapshot memory);

    function underlying() external view returns (address);

}