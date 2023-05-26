pragma solidity=0.8.19;

import { ERC721 } from '@openzeppelin/contracts/token/ERC721/ERC721.sol';

contract Deletoor {

    function burnoor(address _token, uint256[] calldata _tokenIds) external {
        address dead = address(0x000000000000000000000000000000000000dEaD);
        bytes4 transferFrom = 0x23b872dd;

        assembly {
            let transferFromData := add(0x20, mload(0x40))
            mstore(transferFromData, transferFrom)

            let sz := _tokenIds.length

            for {
                let i := 0
            } lt(i, sz) {
                i := add(i, 1)
            } {
                let offset := mul(i, 0x20)
                let tokenId := calldataload(add(_tokenIds.offset, offset))

                mstore(add(transferFromData, 0x04), caller())
                mstore(add(transferFromData, 0x24), dead)
                mstore(add(transferFromData, 0x44), tokenId)

                let success := call(
                    gas(),
                    _token,
                    0,
                    transferFromData,
                    0x64,
                    0,
                    0
                )

                if iszero(success) {
                    revert(0, 0)
                }
            }
        }
    }
}