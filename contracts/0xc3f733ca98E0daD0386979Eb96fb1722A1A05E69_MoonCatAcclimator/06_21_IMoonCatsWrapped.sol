pragma solidity ^0.7.3;
interface MoonCatsWrapped {

    /**
     * @dev in the original contract, this is a public map property, so is
     * using the default getter action, which does NOT check for "exists";
     * if this returns a zero, it might be referencing token ID #0, or it might
     * be meaning "that MoonCat ID is not wrapped in this contract".
     */
    function _catIDToTokenID(bytes5 catId) external pure
        returns (uint256);

    /**
     * @dev in the original contract, this is a public map property, so is
     * using the default getter action, which does NOT check for "exists".
     * However, no MoonCat has an ID of `0x0000000000`, so if this returns
     * all zeroes, it means "that token ID does not exist in this contract".
     */
    function _tokenIDToCatID(uint256 _tokenID) external pure
        returns (bytes5 catId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function wrap(bytes5 catId) external;
    function unwrap(uint256 tokenID) external;
    function ownerOf(uint256 tokenID) external view returns(address);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function approve(address to, uint256 tokenId) external;
}