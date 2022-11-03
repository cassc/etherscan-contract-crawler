// SPDX-License-Identifer: MIT

/// @title RARE Pass
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import "ERC721.sol";
import "EIP2981AllToken.sol";
import "Ownable.sol";

contract RAREPass is ERC721, EIP2981AllToken, Ownable {
    
    // state variables
    uint256 private _counter;
    address public creator;
    address public externalMinter;
    string private _baseTokenUri;
    bool public frozen;

    mapping(address => bool) private _blocklist;

    // events
    event MetadataUpdate(uint256 indexed tokenId);
    event BatchMetadataUpdate(uint256 indexed fromTokenId, uint256 indexed toTokenId);

    /// @param royaltyRecipient is the royalty recipient for all tokens
    /// @param royaltyPercentage is the royatly percentage for all tokens out of 10,000
    /// @param tokenCreator is the creator of the metadata
    /// @param minter is the external minter address
    /// @param tokenUri is the base uri to set
    constructor(address royaltyRecipient, uint256 royaltyPercentage, address tokenCreator, address minter, string memory tokenUri)
    ERC721("RarePass", "RAREPASS")
    EIP2981AllToken(royaltyRecipient, royaltyPercentage)
    Ownable()
    {
        creator = tokenCreator;
        externalMinter = minter;
        _baseTokenUri = tokenUri;
    }

    /// @notice function to freeze metadata
    /// @dev requires owner
    /// @dev cannot unfreeze metadata
    function freezeMetadata() external onlyOwner {
        frozen = true;
    }

    /// @notice sets the base uri
    /// @dev requires owner
    function setBaseUri(string memory newUri) external onlyOwner {
        require(!frozen, "metadata is frozen, cannot update");
        _baseTokenUri = newUri;

        emit BatchMetadataUpdate(1, 250);
    }

    /// @notice function to change the royalty info
    /// @dev requires owner
    /// @dev this is useful if the amount was set improperly at contract creation.
    /// @dev basis for percentage is out of 10_000
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external onlyOwner {
        _setRoyaltyInfo(newAddr, newPerc);
    }

    /// @notice function to set the external minter
    /// @dev requires owner
    function setExternalMinter(address newMinter) external onlyOwner {
        externalMinter = newMinter;
    }

    /// @notice function to add or remove address from the blocklist
    /// @dev requires owner
    function setBlocklist(address operator, bool status) external onlyOwner {
        _blocklist[operator] = status;
    }

    /// @notice external mint function
    /// @dev requires msg.sender to be the external mint address
    /// @dev mints one token to the recipient address
    function mintExternal(address recipient) external returns(uint256){
        require(msg.sender == externalMinter, "msg.sender must be externalMinter");
        
        _counter++;
        _safeMint(recipient, _counter);

        return(_counter);
    }

    /// @notice function to return total supply (current count of NFTs minted)
    function totalSupply() external view virtual returns (uint256) {
        return(_counter);
    }

    /// @notice function to override approve from ERC721 to add blocklist
    /// @dev reverts if to is on the blocklist
    function approve(address to, uint256 tokenId) public override {
        require(!_blocklist[to], "to is on the blocklist");
        ERC721.approve(to, tokenId);
    }

    /// @notice function to override setApprovalForAll from ERC721 to add blocklist
    /// @dev reverts if operator is on the blocklist or if revoking approval for any address
    function setApprovalForAll(address operator, bool approved) public override {
        require(!_blocklist[operator] || !approved, "operator is on the blocklist");
        ERC721.setApprovalForAll(operator, approved);
    }

    /// @notice overrides supportsInterface function
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, EIP2981AllToken) returns (bool) {
        return(interfaceId == 0x49064906 || ERC721.supportsInterface(interfaceId) || EIP2981AllToken.supportsInterface(interfaceId));
    }

    /// @notice override standard ERC721 base URI
    /// @dev doesn't require access control since it's internal
    /// @return string representing base URI
    function _baseURI() internal view override returns (string memory) {
        return(_baseTokenUri);
    }

}