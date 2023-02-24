// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
import "LibEnvelopTypes.sol";

interface IWNFT  {
    function wnftInfo(uint256 tokenId) 
        external view returns (ETypes.WNFT memory);
}