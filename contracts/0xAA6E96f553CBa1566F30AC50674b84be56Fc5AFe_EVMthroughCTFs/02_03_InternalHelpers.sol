// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error NotOwner();
error CTFsQuantityDecreased();
error NotEnoughValueLocked();
error CTFNotSolved(uint256 ctfIndex);
error AlreadyClaimed(uint256 ctfIndex);
error AlreadyClaimedEverything();
error HasNotRunOutOfTime();

contract InternalHelpers {
    address internal _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (_owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        _owner = _newOwner;
    }

    function markClaimed(uint256 bitpackedClaimedCTFs, uint256 ctfIndex)
        internal
        pure
        returns (uint256)
    {
        return bitpackedClaimedCTFs | (0x1 << ctfIndex);
    }

    function hasClaimed(uint256 bitpackedClaimedCTFs, uint256 ctfIndex)
        internal
        pure
        returns (bool)
    {
        return ((bitpackedClaimedCTFs >> ctfIndex) & 0x1) == 0x1;
    }

    function _safeSend(address to, uint256 amount) internal {
        bool success = payable(to).send(amount);
        if (!success) {
            WETH weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            weth.deposit{value: amount}();
            require(weth.transfer(to, amount), "Payment failed");
        }
    }
}

interface WETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);
}