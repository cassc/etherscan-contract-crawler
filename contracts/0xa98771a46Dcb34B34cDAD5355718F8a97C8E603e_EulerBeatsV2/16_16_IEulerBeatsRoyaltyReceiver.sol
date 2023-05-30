// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


import "@openzeppelin/contracts/introspection/ERC165.sol";


interface IEulerBeatsRoyaltyReceiver is IERC165 {

    /**
        @dev Handles the receipt of a royalty payout for the given original EulerBeat.
        The royalty amount is the ether in msg.value.
        To accept the royalty, this must return
        `bytes4(keccak256("royaltyReceived(address,uint256,address)"))`
        Implementors should take care to do the bare minimum in this function as it is
        called as part of the mintPrint function, and will raise the gas required for minting prints.
        @param tokenAddress The token address of the EulerBeats contract that the royalty was paid from
        @param tokenId The ID of token the royalty was paid for.  This is always the original token id, not print token ids
        @param tokenOwner The current owner of the specified token
        @return `bytes4(keccak256("royaltyReceived(address,uint256,address)"))` if royalty accepted
    */
    function royaltyReceived(
        address tokenAddress,
        uint256 tokenId,
        address tokenOwner
    )
        external payable
        returns(bytes4);

}