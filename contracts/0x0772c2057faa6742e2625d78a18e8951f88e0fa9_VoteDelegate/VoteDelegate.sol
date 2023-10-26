/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2021 Dai Foundation

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

// VoteDelegate - delegate your vote
pragma solidity 0.6.12;

interface TokenLike {
    function approve(address, uint256) external returns (bool);
    function pull(address, uint256) external;
    function push(address, uint256) external;
}

interface ChiefLike {
    function GOV() external view returns (TokenLike);
    function IOU() external view returns (TokenLike);
    function lock(uint256) external;
    function free(uint256) external;
    function vote(address[] calldata) external returns (bytes32);
    function vote(bytes32) external;
}

interface PollingLike {
    function withdrawPoll(uint256) external;
    function vote(uint256, uint256) external;
    function withdrawPoll(uint256[] calldata) external;
    function vote(uint256[] calldata, uint256[] calldata) external;
}

contract VoteDelegate {
    mapping(address => uint256) public stake;
    address     public immutable delegate;
    TokenLike   public immutable gov;
    TokenLike   public immutable iou;
    ChiefLike   public immutable chief;
    PollingLike public immutable polling;
    uint256     public immutable expiration;

    event Lock(address indexed usr, uint256 wad);
    event Free(address indexed usr, uint256 wad);

    constructor(address _chief, address _polling, address _delegate) public {
        chief = ChiefLike(_chief);
        polling = PollingLike(_polling);
        delegate = _delegate;
        expiration = block.timestamp + 365 days;

        TokenLike _gov = gov = ChiefLike(_chief).GOV();
        TokenLike _iou = iou = ChiefLike(_chief).IOU();

        _gov.approve(_chief, type(uint256).max);
        _iou.approve(_chief, type(uint256).max);
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "VoteDelegate/add-overflow");
    }

    modifier delegate_auth() {
        require(msg.sender == delegate, "VoteDelegate/sender-not-delegate");
        _;
    }

    modifier live() {
        require(block.timestamp < expiration, "VoteDelegate/delegation-contract-expired");
        _;
    }

    function lock(uint256 wad) external live {
        stake[msg.sender] = add(stake[msg.sender], wad);
        gov.pull(msg.sender, wad);
        chief.lock(wad);
        iou.push(msg.sender, wad);

        emit Lock(msg.sender, wad);
    }

    function free(uint256 wad) external {
        require(stake[msg.sender] >= wad, "VoteDelegate/insufficient-stake");

        stake[msg.sender] -= wad;
        iou.pull(msg.sender, wad);
        chief.free(wad);
        gov.push(msg.sender, wad);

        emit Free(msg.sender, wad);
    }

    function vote(address[] memory yays) external delegate_auth live returns (bytes32 result) {
        result = chief.vote(yays);
    }

    function vote(bytes32 slate) external delegate_auth live {
        chief.vote(slate);
    }

    // Polling vote
    function votePoll(uint256 pollId, uint256 optionId) external delegate_auth live {
        polling.vote(pollId, optionId);
    }

    function votePoll(uint256[] calldata pollIds, uint256[] calldata optionIds) external delegate_auth live {
        polling.vote(pollIds, optionIds);
    }
}