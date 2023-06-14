pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-2981
 */
abstract contract ERC2981 is ERC165 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;

    /// @notice Called with the sale price to determine how much royalty
    ///         is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @param _data - information used by extensions of this ERC.
    ///                Must not to be used by implementers of EIP-2981
    ///                alone.
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for _value sale price
    /// @return _royaltyPaymentData - information used by extensions of this ERC.
    ///                               Must not to be used by implementers of
    ///                               EIP-2981 alone.
    function royaltyInfo(uint256 _tokenId, uint256 _value, bytes calldata _data) external virtual returns (address _receiver, uint256 _royaltyAmount, bytes memory _royaltyPaymentData);

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981
        || super.supportsInterface(interfaceId);
    }
}