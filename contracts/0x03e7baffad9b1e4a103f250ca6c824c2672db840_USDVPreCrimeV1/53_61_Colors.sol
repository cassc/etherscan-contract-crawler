// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import {Delta} from "../interfaces/IUSDV.sol";

library Colors {
    struct Info {
        uint32 maxKnownColor; // theta is not a known color
        mapping(uint32 color => ColorState) colorStates;
    }

    struct ColorState {
        uint64 colored; // restrict the overall token balance to be 1/2 * uint64.max
        int64 delta;
        int64 lastDelta; // delta checkpoint to prevent flashloan attack
        uint32 lastBlockNumber; // block number of the last checkpoint
        bool known;
    }

    error InvalidColor(uint32 color);
    error InvalidAmount();
    error NotDeltaZero();
    error Overflow();

    event ColorMinted(uint32 indexed color, uint64 amount);
    event ColorBurnt(uint32 indexed color, uint64 amount);
    event ColorAdded(uint32 indexed color);
    event Recolored(uint32 indexed fromColor, uint32 indexed toColor, uint64 amount);

    uint32 internal constant NIL = 0;
    uint32 internal constant THETA = type(uint32).max;
    uint64 internal constant INT64_MAX = uint64(type(int64).max);

    function addColor(Info storage _self, uint32 _color) internal {
        if (_color >= THETA || _color == NIL) revert InvalidColor(_color);
        // new color, that is used on side chains mainly to check if the color is known and valid
        if (!_self.colorStates[_color].known) {
            _self.colorStates[_color].known = true;
            if (_color > _self.maxKnownColor) {
                _self.maxKnownColor = _color;
            }
            emit ColorAdded(_color);
        }
    }

    // ----- ALL FOLLOWING FUNCTIONS SHOULD BE DELTA-ZERO IF USED EXTERNALLY-----

    /// @dev recoloring is swapping the delta between the fromColor and toColor
    function recolor(Info storage _self, uint32 _fromColor, uint32 _toColor, uint64 _amount) internal {
        if (_amount == 0) return;

        if (_amount > INT64_MAX) revert Overflow();
        int64 amountInt64 = int64(_amount);

        // handle from state
        ColorState memory fromState = _self.colorStates[_fromColor];
        _decrDelta(fromState, amountInt64);
        if (_fromColor != THETA) fromState.colored -= _amount;
        _self.colorStates[_fromColor] = fromState;

        // handle to state
        ColorState memory toState = _self.colorStates[_toColor];
        _decrDelta(toState, -amountInt64);
        if (_toColor != THETA) toState.colored += _amount;
        _self.colorStates[_toColor] = toState;

        emit Recolored(_fromColor, _toColor, _amount);
    }

    /// @dev used in both genesis mint() and cross-chain mint()
    /// @param _color to mint
    /// @param _amount to mint, can be zero (if only minting theta)
    /// @param _theta to recolor to color
    function mint(Info storage _self, uint32 _color, uint64 _amount, uint64 _theta) internal {
        if (_amount > INT64_MAX) revert Overflow();

        addColor(_self, _color);
        _self.colorStates[_color].colored += _amount;

        // in cross-chain send() minting, need to recolor from theta to color to compensate the difference
        recolor(_self, THETA, _color, _theta);

        emit ColorMinted(_color, _amount);
    }

    /// @dev used only in cross-chain send()
    function send(Info storage _self, uint32 _color, uint64 _amount) internal returns (uint64 theta) {
        if (_amount == 0) revert InvalidAmount();
        if (_amount > INT64_MAX) revert Overflow();

        ColorState memory state = _self.colorStates[_color];
        if (state.delta > 0) {
            // if delta is positive, burn from delta first
            // theta = min(delta, amount)
            uint64 delta = uint64(state.delta); // this casting is checked
            theta = delta >= _amount ? _amount : delta;
        }

        // only need to burn the amount - theta at the source chain
        uint64 minted = _amount - theta;
        if (minted > 0) {
            _burn(_self, _color, minted);
        }

        // recoloring color to theta
        recolor(_self, _color, THETA, theta); // recolor burntSurplus to theta
    }

    /// @dev deltas can include some surplus to mitigate the race condition
    /// @return used values all negative
    function burn(
        Info storage _self,
        uint32[] calldata _deficits,
        uint64 _amount,
        uint32 _color
    ) internal returns (Delta[] memory used) {
        if (_amount == 0) revert InvalidAmount();
        if (_amount > INT64_MAX) revert Overflow();

        _burn(_self, _color, _amount);

        uint64 burntSurplus;
        (burntSurplus, used) = extractDelta(_self, _color, _amount, _deficits);

        if (burntSurplus == 0) {
            used = new Delta[](1);
            // if not redeeming any surplus, then the list includes only the redeemed color and the amount
            used[0] = Delta(_color, -int64(_amount));
        } else {
            // the first delta in the delta list is the surplus (+delta) of the redeemed color
            // we need to return negative minted to indicate how much was burnt
            // burnt amount = [amount - surplus], negating it becomes [surplus - amount]
            used[0].amount -= int64(_amount);
        }
    }

    /// @notice decrement and extract deltas given amount and deficit colors
    /// @dev used in sync()/remint()/redeem()
    /// @param _color with or without surplus
    /// @param _amount with or without surplus, if includes surplus, surplus will be extracted and used as target to find deficits
    /// @param _deficits colors sorted in ascending order, used greedily to find deltas summing to surplus
    /// @return totalSurplus totalSurplus extracted from _amount
    /// @return used first element positive surplus, following elements negative deficits
    function extractDelta(
        Info storage _self,
        uint32 _color,
        uint64 _amount,
        uint32[] calldata _deficits
    ) internal returns (uint64 totalSurplus, Delta[] memory used) {
        if (_amount > INT64_MAX) revert Overflow();

        // 1. extract surplus from _amount
        int64 surplus = _clampDelta(_self, _color, int64(_amount));
        if (surplus == 0) return (0, used); // redeem could have 0 surplus

        totalSurplus = uint64(surplus); // return the clamped value

        // insert the surplus into the head of the delta list
        used = new Delta[](_deficits.length + 1);
        used[0] = Delta(_color, surplus);
        uint idx = 1; // next index to insert used

        // 2. extract deficits based on hint from _deficits param, with -surplus as target sum
        int64 remainingDeficit = -surplus; // negate it for the use of _clampDelta() as the cap
        uint32 lastColor = 0;
        for (uint i = 0; i < _deficits.length; i++) {
            uint32 deficitColor = _deficits[i];
            if (
                deficitColor <= lastColor || // no duplicate
                deficitColor == THETA || // no theta
                deficitColor == _color // cant overlap with _color. in theory it wont but safer to check
            ) revert InvalidColor(deficitColor);

            // use the remainingDeficit as the target, maximally uses deficitColor
            int64 deficit = _clampDelta(_self, deficitColor, remainingDeficit);
            if (deficit < 0) {
                used[idx++] = Delta(deficitColor, deficit);
                remainingDeficit -= deficit;

                if (remainingDeficit == 0) {
                    // change the length of the delta list to 'idx'
                    assembly {
                        mstore(used, idx)
                    }
                    return (totalSurplus, used);
                }
            }
            // update the color cursor
            lastColor = deficitColor;
        }
        revert NotDeltaZero();
    }

    /// @notice strictly delta-zero. no surplus delta
    /// @dev used ONLY in syncDeltaAck(() at the destination chain
    /// @dev this function does not change the colored circulation
    function syncDeltaAck(Info storage _self, Delta[] calldata _deltas) internal {
        int64 totalDelta = 0;
        for (uint i = 0; i < _deltas.length; i++) {
            Delta calldata delta = _deltas[i];
            if (delta.color != THETA) {
                addColor(_self, delta.color);
            }

            ColorState memory state = _self.colorStates[delta.color];
            _decrDelta(state, -delta.amount);
            _self.colorStates[delta.color] = state;

            totalDelta += delta.amount;
        }
        // delta-zero invariant
        if (totalDelta != 0) revert NotDeltaZero();
    }

    /// @dev compare two int64 and return the one with smaller absolute value
    /// @dev if the sign of the two int64 are different, return 0
    function absMinOrZero(int64 _a, int64 _b) internal pure returns (int64) {
        if (_a == 0 || _b == 0) return 0;

        int64 sign = _a ^ _b;
        if (sign < 0) return 0;

        if (_a > 0) {
            return _a < _b ? _a : _b;
        } else {
            return _a > _b ? _a : _b;
        }
    }

    // ==================== View ====================
    /// @dev returns deltas of known colors in range [_startColor, _endColor) and theta
    //  @dev if endIdx == 0, set endIdx = maxKnownColor
    function getDeltas(
        Info storage _self,
        uint32 _startColor,
        uint32 _endColor
    ) internal view returns (Delta[] memory deltas) {
        _endColor = _endColor == 0 ? _self.maxKnownColor + 1 : _endColor;

        uint32 index = 0;
        deltas = new Delta[](_endColor - _startColor + 1); // +1 for theta
        for (uint32 i = _startColor; i < _endColor; i++) {
            if (_self.colorStates[i].known) {
                deltas[index++] = Delta(i, _self.colorStates[i].delta);
            }
        }

        deltas[index++] = Delta(THETA, _self.colorStates[THETA].delta);
        assembly {
            mstore(deltas, index)
        }
    }

    /// @param _colors in ascending order
    function getDeltas(Info storage _self, uint32[] calldata _colors) internal view returns (Delta[] memory deltas) {
        deltas = new Delta[](_colors.length);
        uint32 lastColor = 0;
        uint32 index = 0;
        for (uint i = 0; i < _colors.length; i++) {
            uint32 color = _colors[i];
            if (color <= lastColor) revert InvalidColor(color);

            if (color == THETA) {
                deltas[index++] = Delta(THETA, _self.colorStates[THETA].delta);
            } else if (_self.colorStates[color].known) {
                deltas[index++] = Delta(color, _self.colorStates[color].delta);
            }

            lastColor = color;
        }
        assembly {
            mstore(deltas, index)
        }
    }

    // ==================== Non-Delta Zero ====================
    /// @notice clamp delta by delta budget
    /// @dev _target and color delta should be of the same sign, function returns 0 if they are not
    /// @dev used by sync and remint
    /// @param _color of delta to update
    /// @param _deltaTarget in surplus or deficit
    /// @return delta of surplus/deficit deducted
    function _clampDelta(Info storage _self, uint32 _color, int64 _deltaTarget) internal returns (int64 delta) {
        ColorState memory state = _self.colorStates[_color]; // don't need to check known here, as state will have no delta if it is unknown

        // 1. clamp by min(state.delta, state.lastDelta)
        // prevent flash loan.
        int64 deltaBudget = state.delta;
        // also skip if the delta == last delta
        if (state.lastBlockNumber == block.number && deltaBudget != state.lastDelta) {
            deltaBudget = absMinOrZero(deltaBudget, state.lastDelta);
            if (deltaBudget == 0) return 0;
        }

        delta = absMinOrZero(deltaBudget, _deltaTarget);
        if (delta == 0) return 0;

        _decrDelta(state, delta);

        _self.colorStates[_color] = state;
    }

    /// @dev update lastBlockNumber and lastDelta before changing delta
    function _decrDelta(ColorState memory state, int64 _loss) private view {
        if (block.number != state.lastBlockNumber) {
            state.lastBlockNumber = uint32(block.number);
            state.lastDelta = state.delta;
        }
        state.delta -= _loss;
    }

    function _burn(Info storage _self, uint32 _color, uint64 _amount) private {
        _self.colorStates[_color].colored -= _amount;
        emit ColorBurnt(_color, _amount);
    }
}