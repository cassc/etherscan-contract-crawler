// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic mechanism to verify token claims to make sure a token is minted only once against a context (reason).
 */
abstract contract ClaimContext {
    // Mapping from race address to winner whether claimed
    mapping(string => mapping(address => bool)) public _claimed;

    /**
     * @dev Determine whether a winner has claimed against a context
     *
     *
     * @param context Race/Event address, Lootbox or blueprint ID.
     * @param account Winner, cannot be the zero address.
     *
     * @return claimed
     */
    function getClaimed(string memory context, address account)
        public
        view
        returns (bool claimed)
    {
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        return _claimed[context][account];
    }

    function setContext(string memory _context, address _to) internal {
        _claimed[_context][_to] = true;
    }

    /**
     * @dev Validates whether the winner has already claimed against a context
     *
     * @param _context race address or other identifier
     * @param _to winner
     */
    modifier validClaim(string memory _context, address _to) {
        require(!getClaimed(_context, _to), "ClaimContext: Already Claimed");
        _;
    }
}