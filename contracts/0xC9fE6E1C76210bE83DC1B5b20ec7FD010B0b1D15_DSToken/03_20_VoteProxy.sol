/// VoteProxy.sol



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

// vote w/ a hot or cold wallet using a proxy identity
pragma solidity >=0.4.24;

interface TokenLike {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external;
    function pull(address, uint256) external;
    function push(address, uint256) external;
}

interface ChiefLike {
    function GOV() external view returns (TokenLike);
    function IOU() external view returns (TokenLike);
    function deposits(address) external view returns (uint256);
    function lock(uint256) external;
    function free(uint256) external;
    function vote(address[] calldata) external returns (bytes32);
    function vote(bytes32) external;
}

contract VoteProxy {
    address   public cold;
    address   public hot;
    TokenLike public gov;
    TokenLike public iou;
    ChiefLike public chief;

    constructor(address _chief, address _cold, address _hot) public {
        chief = ChiefLike(_chief);
        cold = _cold;
        hot = _hot;

        gov = chief.GOV();
        iou = chief.IOU();
        gov.approve(address(chief), type(uint256).max);
        iou.approve(address(chief), type(uint256).max);
    }

    modifier auth() {
        require(msg.sender == hot || msg.sender == cold, "Sender must be a Cold or Hot Wallet");
        _;
    }

    function lock(uint256 wad) public auth {
        gov.pull(cold, wad);   // mkr from cold
        chief.lock(wad);       // mkr out, ious in
    }

    function free(uint256 wad) public auth {
        chief.free(wad);       // ious out, mkr in
        gov.push(cold, wad);   // mkr to cold
    }

    function freeAll() public auth {
        chief.free(chief.deposits(address(this)));
        gov.push(cold, gov.balanceOf(address(this)));
    }

    function vote(address[] memory yays) public auth returns (bytes32) {
        return chief.vote(yays);
    }

    function vote(bytes32 slate) public auth {
        chief.vote(slate);
    }
}