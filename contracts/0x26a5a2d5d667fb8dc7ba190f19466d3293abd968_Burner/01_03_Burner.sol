// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/[email protected]/token/ERC721/utils/ERC721Holder.sol";

contract Burner is ERC721Holder {

    address burnable;

    function setBurnable(address burnable_)
        external
    {
        burnable = burnable_;
    }

    function burn(uint256 tokenId)
    external
    returns (bytes memory)
    {
        (bool success, bytes memory r) = burnable.call(abi.encodeWithSignature("burn(uint256)", tokenId));

        if (!success) {
            revert();
        }

        return r;
    }
}