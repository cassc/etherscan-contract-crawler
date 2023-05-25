pragma solidity ^0.5.15;

contract IDCLRegistrar {
    /**
	 * @dev Allows to create a subdomain (e.g. "nacho.dcl.eth"), set its resolver, owner and target address
	 * @param _subdomain - subdomain  (e.g. "nacho")
	 * @param _beneficiary - address that will become owner of this new subdomain
	 */
    function register(string calldata _subdomain, address _beneficiary) external;

     /**
	 * @dev Re-claim the ownership of a subdomain (e.g. "nacho").
     * @notice After a subdomain is transferred by this contract, the owner in the ENS registry contract
     * is still the old owner. Therefore, the owner should call `reclaim` to update the owner of the subdomain.
	 * @param _tokenId - erc721 token id which represents the node (subdomain).
     * @param _owner - new owner.
     */
    function reclaim(uint256 _tokenId, address _owner) external;

    /**
     * @dev Transfer a name to a new owner.
     * @param _from - current owner of the node.
     * @param _to - new owner of the node.
     * @param _id - node id.
     */
    function transferFrom(address _from, address _to, uint256 _id) public;

    /**
	 * @dev Check whether a name is available to be registered or not
	 * @param _labelhash - hash of the name to check
     * @return whether the name is available or not
     */
    function available(bytes32 _labelhash) public view returns (bool);

}