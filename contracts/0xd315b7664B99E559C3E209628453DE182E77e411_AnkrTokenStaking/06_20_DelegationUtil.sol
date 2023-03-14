pragma solidity ^0.8.0;

struct DelegationOpDelegate {
    // @dev stores the last sum(delegated)-sum(undelegated)
    uint112 amount;
    uint64 epoch;
    // last epoch when reward was claimed
    uint64 claimEpoch;
}

struct DelegationOpUndelegate {
    uint112 amount;
    uint64 epoch;
}

struct ValidatorDelegation {
    DelegationOpDelegate[] delegateQueue;
    uint64 delegateGap;
    DelegationOpUndelegate[] undelegateQueue;
    uint64 undelegateGap;
    uint112 withdrawnAmount;
    uint64 withdrawnEpoch;
}

library DelegationUtil {

//    function add(
//        ValidatorDelegation storage self,
//        uint112 amount,
//        uint64 epoch
//    ) internal {
//        // if last pending delegate has the same next epoch then its safe to just increase total
//        // staked amount because it can't affect current validator set, but otherwise we must create
//        // new record in delegation queue with the last epoch (delegations are ordered by epoch)
//        if (self.delegateQueue.length > 0) {
//            DelegationOpDelegate storage recentDelegateOp = self.delegateQueue[self.delegateQueue.length - 1];
//            // if we already have pending snapshot for the next epoch then just increase new amount,
//            // otherwise create next pending snapshot. (tbh it can't be greater, but what we can do here instead?)
//            if (recentDelegateOp.epoch >= epoch) {
//                recentDelegateOp.amount += amount;
//            } else {
//                self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch : epoch, amount : recentDelegateOp.amount + amount}));
//            }
//        } else {
//            // there is no any delegations at al, lets create the first one
//            self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch : epoch, amount : amount}));
//        }
//    }

//    function addInitial(
//        ValidatorDelegation storage self,
//        uint112 amount,
//        uint64 epoch
//    ) internal {
//        require(self.delegateQueue.length == 0, "Delegation: already delegated");
//        self.delegateQueue.push(DelegationOpDelegate({amount : amount, epoch: epoch, claimEpoch : epoch}));
//    }

    // @dev before call check that queue is not empty
//    function shrinkDelegations(
//        ValidatorDelegation storage self,
//        uint112 amount,
//        uint64 epoch
//    ) internal {
//        // pull last item
//        DelegationOpDelegate storage recentDelegateOp = self.delegateQueue[self.delegateQueue.length - 1];
//        // calc next delegated amount
//        uint112 nextDelegatedAmount = recentDelegateOp.amount - amount;
//        if (nextDelegatedAmount == 0) {
//            delete self.delegateQueue[self.delegateQueue.length - 1];
//            self.delegateGap++;
//        } else if (recentDelegateOp.epoch >= epoch) {
//            // decrease total delegated amount for the next epoch
//            recentDelegateOp.amount = nextDelegatedAmount;
//        } else {
//            // there is no pending delegations, so lets create the new one with the new amount
//            self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch: epoch, amount : nextDelegatedAmount}));
//        }
//        // stash withdrawn amount
//        if (epoch > self.withdrawnEpoch) {
//            self.withdrawnEpoch = epoch;
//            self.withdrawnAmount = amount;
//        } else if (epoch == self.withdrawnEpoch) {
//            self.withdrawnAmount += amount;
//        }
//    }

//    function getWithdrawn(
//        ValidatorDelegation memory self,
//        uint64 epoch
//    ) internal pure returns (uint112) {
//        return epoch >= self.withdrawnEpoch ? 0 : self.withdrawnAmount;
//    }

//    function calcWithdrawalAmount(ValidatorDelegation memory self, uint64 beforeEpochExclude, bool checkEpoch) internal pure returns (uint256 amount) {
//        while (self.undelegateGap < self.undelegateQueue.length) {
//            DelegationOpUndelegate memory undelegateOp = self.undelegateQueue[self.undelegateGap];
//            if (checkEpoch && undelegateOp.epoch > beforeEpochExclude) {
//                break;
//            }
//            amount += uint256(undelegateOp.amount);
//            ++self.undelegateGap;
//        }
//    }

//    function getStaked(ValidatorDelegation memory self) internal pure returns (uint256) {
//        return self.delegateQueue[self.delegateQueue.length - 1].amount;
//    }

}