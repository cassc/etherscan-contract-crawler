// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

error AddressNotFound();
error MaxArray();
error DuplicateAddress();
error NotOwner();
error InvalidAddress();
error InvalidRegex();
error InvalidSelf();
error ProfileNotFound();

interface IProfileAuction {
    function nftProfileHelperAddress() external view returns (address);
}