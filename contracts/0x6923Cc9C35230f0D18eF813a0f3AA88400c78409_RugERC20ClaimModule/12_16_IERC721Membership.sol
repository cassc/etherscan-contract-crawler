// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ITokenEnforceable} from "../TokenEnforceable/ITokenEnforceable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IERC721Membership {
    event RendererUpdated(address indexed implementation);

    // solhint-disable-next-line func-name-mixedcase
    function __ERC721Membership_init(
        string memory name_,
        string memory symbol_,
        address mintPolicy_,
        address burnPolicy_,
        address transferPolicy_,
        address renderer_
    ) external;

    function mintTo(address account) external returns (bool);

    function currentSupply() external view returns (uint256);
}

interface IERC721MembershipFull is
    IERC721,
    IERC721Metadata,
    ITokenEnforceable,
    IERC721Membership
{
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}