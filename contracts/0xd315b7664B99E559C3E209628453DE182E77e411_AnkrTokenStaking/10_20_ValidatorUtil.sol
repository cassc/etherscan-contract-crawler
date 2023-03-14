pragma solidity ^0.8.0;

enum ValidatorStatus {
    NotFound,
    Active,
    Pending,
    Jail
}

struct Validator {
    address validatorAddress;
    address ownerAddress;
    ValidatorStatus status;
    uint64 changedAt;
    uint64 jailedBefore;
    uint64 claimedAt;
}

library ValidatorUtil {

//    function isActive(Validator memory self) internal pure returns (bool) {
//        return self.status == ValidatorStatus.Active;
//    }
//
//    function isOwner(
//        Validator memory self,
//        address addr
//    ) internal pure returns (bool) {
//        return self.ownerAddress == addr;
//    }

//    function create(
//        Validator storage self,
//        address validatorAddress,
//        address validatorOwner,
//        ValidatorStatus status,
//        uint64 epoch
//    ) internal {
//        require(self.status == ValidatorStatus.NotFound, "Validator: already exist");
//        self.validatorAddress = validatorAddress;
//        self.ownerAddress = validatorOwner;
//        self.status = status;
//        self.changedAt = epoch;
//    }

//    function activate(
//        Validator storage self
//    ) internal returns (Validator memory vldtr) {
//        require(self.status == ValidatorStatus.Pending, "Validator: bad status");
//        self.status = ValidatorStatus.Active;
//        return self;
//    }

//    function disable(
//        Validator storage self
//    ) internal returns (Validator memory vldtr) {
//        require(self.status == ValidatorStatus.Active || self.status == ValidatorStatus.Jail, "Validator: bad status");
//        self.status = ValidatorStatus.Pending;
//        return self;
//    }

//    function jail(
//        Validator storage self,
//        uint64 beforeEpoch
//    ) internal {
//        require(self.status != ValidatorStatus.NotFound, "Validator: not found");
//        self.jailedBefore = beforeEpoch;
//        self.status = ValidatorStatus.Jail;
//    }

//    function unJail(
//        Validator storage self,
//        uint64 epoch
//    ) internal {
//        // make sure validator is in jail
//        require(self.status == ValidatorStatus.Jail, "Validator: bad status");
//        // only validator owner
//        require(msg.sender == self.ownerAddress, "Validator: only owner");
//        require(epoch >= self.jailedBefore, "Validator: still in jail");
//        forceUnJail(self);
//    }

    // @dev release validator from jail
//    function forceUnJail(
//        Validator storage self
//    ) internal {
//        // update validator status
//        self.status = ValidatorStatus.Active;
//        self.jailedBefore = 0;
//    }
}