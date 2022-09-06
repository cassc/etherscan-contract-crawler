/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// hevm: flattened sources of src/LerpFactory.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.12 <0.7.0;

////// src/Lerp.sol
//
/// Lerp.sol -- Linear Interpolation module
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity ^0.6.12; */

interface DenyLike {
    function deny(address) external;
}

interface FileLike {
    function file(bytes32, uint256) external;
}

interface FileIlkLike {
    function file(bytes32, bytes32, uint256) external;
}

// Perform linear interpolation on a dss administrative value over time

abstract contract BaseLerp {

    uint256 constant WAD = 10 ** 18;

    address immutable public target;
    bytes32 immutable public what;
    uint256 immutable public start;
    uint256 immutable public end;
    uint256 immutable public duration;

    bool              public done;
    uint256           public startTime;

    constructor(address target_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) public {
        require(duration_ != 0, "Lerp/no-zero-duration");
        require(duration_ <= 365 days, "Lerp/max-duration-one-year");
        require(startTime_ <= block.timestamp + 365 days, "Lerp/start-within-one-year");
        // This is not the exact upper bound, but it's a practical one
        // Ballparked from 2^256 / 10^18 and verified that this is less than that value
        require(start_ <= 10 ** 59, "Lerp/start-too-large");
        require(end_ <= 10 ** 59, "Lerp/end-too-large");
        target = target_;
        what = what_;
        startTime = startTime_;
        start = start_;
        end = end_;
        duration = duration_;
    }

    function tick() external returns (uint256 result) {
        require(!done, "Lerp/finished");
        if (block.timestamp >= startTime) {
            if (block.timestamp < startTime + duration) {
                // All bounds are constrained in the constructor so no need for safe-math
                // 0 <= t < WAD
                uint256 t = (block.timestamp - startTime) * WAD / duration;
                // y = (end - start) * t + start [Linear Interpolation]
                //   = end * t + start - start * t [Avoids overflow by moving the subtraction to the end]
                update(result = end * t / WAD + start - start * t / WAD);
            } else {
                // Set the end value and mark as done
                update(result = end);
                try DenyLike(target).deny(address(this)) {} catch {}
                done = true;
            }
        }
    }

    function update(uint256 value) virtual internal;

}

// Lerp that takes an ilk parameter

contract IlkLerp is BaseLerp {

    bytes32 immutable public ilk;

    constructor(address target_, bytes32 ilk_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) public BaseLerp(target_, what_, startTime_, start_, end_, duration_) {
        ilk = ilk_;
    }

    function update(uint256 value) override internal {
        FileIlkLike(target).file(ilk, what, value);
    }

}