// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./lib/IDelegationRegistry.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract _0xth0mas {
    error NotThomasTokenOwner();
    error ClaimNotAvailable();

    event RedeemedContractReview(address indexed redeemer, uint256 indexed timestamp);

    address constant public GUTTER_PUNKS = 0x9a54988016E97Fdc388D1b084BcbfE32De91b70c;
    uint256 constant public THOMAS_TOKEN_ID = 75;
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
    uint256 public nextAvailable;

    constructor() { nextAvailable = block.timestamp; }

    function redeemContractReview() external {
        address thomasTokenOwner = IERC721(GUTTER_PUNKS).ownerOf(THOMAS_TOKEN_ID);
        if(msg.sender != thomasTokenOwner && !delegateCash.checkDelegateForToken(msg.sender, thomasTokenOwner, GUTTER_PUNKS, THOMAS_TOKEN_ID)) { revert NotThomasTokenOwner(); }
        if(block.timestamp < nextAvailable) { revert ClaimNotAvailable(); }

        emit RedeemedContractReview(msg.sender, block.timestamp);
        nextAvailable = block.timestamp + 30 days; 
    }
}