// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
abstract contract RoyaltiesV1 is IERC2981 {
    uint256 public constant HUNDRED_PERCENT = 10000;
    // type(IERC2981).interfaceId == 0x2a55205a
    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId;
    }
}