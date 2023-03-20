// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

library Position {
    struct Info {
        uint256 tokenId;
        // duration in which fees can't be claimed
        uint256 cliff;
        // start timestamp
        uint256 start;
        // total lock duration
        uint256 duration;
        // allow fees to be claimed at feeReciever address
        bool allowFeeClaim;
        // allow owner to transfer ownership or update feeReciever
        bool allowBeneficiaryUpdate;
        // address to receive earned fees
        address feeReciever;
        // owner of the position
        address owner;
    }

    function isPositionValid(Info memory self) internal view {
        require(self.owner != address(0), "ULL::OWNER_ZERO_ADDRESS");
        require(self.duration >= self.cliff, "ULL::CLIFF_GT_DURATION");
        require(self.duration > 0, "ULL::INVALID_DURATION");
        require((self.start + self.duration) > block.timestamp, "ULL::INVALID_ENDING_TIME");
    }

    function isOwner(Info memory self) internal view {
        require(self.owner == msg.sender && self.allowBeneficiaryUpdate, "ULL::NOT_AUTHORIZED");
    }

    function isTokenIdValid(Info memory self, uint256 tokenId) internal pure {
        require(self.tokenId == tokenId, "ULL::INVALID_TOKEN_ID");
    }

    function isTokenUnlocked(Info memory self) internal view {
        require((self.start + self.duration) < block.timestamp, "ULL::NOT_UNLOCKED");
    }

    function isFeeClaimAllowed(Info memory self) internal view {
        require(self.allowFeeClaim, "ULL::FEE_CLAIM_NOT_ALLOWED");
        require((self.start + self.cliff) < block.timestamp, "ULL::CLIFF_NOT_ENDED");
    }
}