pragma solidity 0.8.16;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/ILiquidLocker.sol";

interface VoteEscrow {
    function balanceOf(address) external view returns(uint256);
    function locked(address) external view returns(uint128 amount, uint256 end);
    function locked__end(address) external view returns(uint256);
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;
}

contract LiquidLockerMock is ILiquidLocker {
    using SafeERC20 for IERC20;
    function _releaseFee() internal virtual view returns(uint256) { return 0; }
    function _feeBase() internal virtual view returns(uint256) { return 0; }

    function target() external virtual view returns(address) {
        return address(0);
    }

    function locked() external view virtual returns(uint256) {
        return _locked();
    }

    function _locked() internal view virtual returns(uint256) {
        return 0;
    }

    function lock(
        uint256 amount,
        uint256 unlockTime
    ) external virtual returns(uint256 actualAmountIn){
        if(amount == 0) revert ZeroAmount();
        // need to calculate actualAmountIn to achieve compatibility
        // with external abstract locker that could got fee on deposit
        uint256 lockedBefore = _locked();
        _lock(amount, unlockTime);
        actualAmountIn = _locked() - lockedBefore;
    }

    function _lock(uint256 amount, uint256 unlockTime) internal virtual {}

    function release(address token, uint256 amount, bytes memory payload) external virtual {
        if (IERC20(token).balanceOf(address(this)) < amount) {
            _release();
        }
        // need to calculate actualOutAmount to achieve compatibility
        // with external abstract locker that could got fee on release
        uint256 actualOutAmount = amount - (amount * _releaseFee() / _feeBase());
        IERC20(token).safeTransfer(msg.sender, actualOutAmount);
    }

    function _release() internal virtual {}

    function _unpackPayload(bytes memory payload) internal returns(ACTION action, bytes memory appendix) {
        action = ACTION(uint8(payload[0]));
        appendix = new bytes(payload.length - 1);
        for(uint i = 0; i < appendix.length;) {
            appendix[i] = payload[i+1];
            unchecked{
                ++i;
            }
        }
    }

    function exec(bytes calldata payload) external virtual {
        (ACTION action, bytes memory appendix) = _unpackPayload(payload);
        if (action == ACTION.VOTE){
            if(appendix.length != 96) revert WrongPayloadLength();
            (uint256 voteData, bool approving, address voteTarget) = abi.decode(appendix, (uint256,bool,address));
            _vote(voteData, approving, voteTarget);
        } else if (action == ACTION.VOTE_GAUGES) {
            if(appendix.length < 192) revert WrongPayloadLength();
            (address[] memory gauges, uint256[] memory weights) = abi.decode(appendix, (address[],uint256[]));
            _voteGauges(gauges, weights);
        } else if (action == ACTION.VOTE_PROPOSAL) {
            if(appendix.length != 128) revert WrongPayloadLength();
            (uint256 voteId, uint256 upPct, uint256 downPct, address voteTarget) = abi.decode(appendix, (uint256,uint256,uint256,address));
            _voteProposal(voteId, upPct, downPct, voteTarget);
        } else if (action == ACTION.CLAIM) {
            if(appendix.length > 0) revert WrongPayloadLength();
            _claim();
        } else {
            revert UnknownAction();
        }
        emit Executed(action);
    }

    function _vote(
        uint256 amountToVote,
        bool approving,
        address voteTarget
    ) internal virtual {}

    function _voteProposal(
        uint256 voteId,
        uint256 upPct,
        uint256 downPct,
        address voteTarget
    ) internal virtual {}

    function _voteGauges(
        address[] memory gauges,
        uint256[] memory weights
    ) internal virtual {}

    function _claim() internal virtual {}
}