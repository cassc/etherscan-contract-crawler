pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITickets is IERC721 {
    /**
     * @notice  Returns the tier of the given token
     * @param   tokenID    TokenID to query
     * @return  0 if token nonexistent, 1 through 4 otherwise
     */
    function ticketTier(uint256 tokenID) external view returns (uint8);
}