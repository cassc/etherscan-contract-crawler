/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface GMOOStub {
	function lockMoo(uint256 moo, uint256 price, bytes32 hash) external;
	function unlockMoo(uint256 moo, string memory password, address transfer) payable external;
}

interface KEEKStub {
    function lockKeek(uint256 keek, uint256 price, bytes32 hash) external;
	function unlockKeek(uint256 keek, string memory password, address transfer) payable external;
}

contract GMCafeMultiLock {

	GMOOStub constant GMOO = GMOOStub(0xE43D741e21d8Bf30545A88c46e4FF5681518eBad);
    KEEKStub constant KEEK = KEEKStub(0x01298589d7c2bD82f54Ca84060d58967772123F2);

    function multilock(bool lock, uint256[] calldata moos, uint256[] calldata keeks) external {
        unchecked {
            if (lock) {
                for (uint256 i; i < moos.length; ++i) {
                    GMOO.lockMoo(moos[i], 0, 0);
                }
                for (uint256 i; i < keeks.length; ++i) {
                    KEEK.lockKeek(keeks[i], 0, 0);
                }
            } else {
                for (uint256 i; i < moos.length; ++i) {
                    GMOO.unlockMoo(moos[i], '', address(0));
                }
                for (uint256 i; i < keeks.length; ++i) {
                    KEEK.unlockKeek(keeks[i], '', address(0));
                }
            }
        }
    }

}