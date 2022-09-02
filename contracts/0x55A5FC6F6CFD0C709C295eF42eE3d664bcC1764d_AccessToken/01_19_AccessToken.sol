// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @author Bella
/// @title Bella Access Token
/// @notice Smart contract to store, generate and manage access tokens for Bella communities using ERC1155 standards
contract AccessToken is ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply, ReentrancyGuard, ERC2981 {

    // ERR-1-AT		Access Token Manager address cannot be zero-address
    // ERR-2-AT		tokenId not valid
    // ERR-3-AT		Cannot remove approval to manager
    // ERR-4-AT		Cannot set uri twice

    bytes32 private constant ACCESS_TOKEN_MANAGER_ROLE = keccak256("ACCESS_TOKEN_MANAGER_ROLE");
    
    address private immutable managerContract;

    mapping(uint => string) private tokenIdToUri;

    string public constant name = "BELLA Access Token";
    string public constant symbol = "BLA";

    string private _contractUri = "https://ipfs.io/ipfs/QmS7ByhtVTTBvb2PGfJUA6tB7SX6kybJNR2Pp1WaukYTHk";

    event AccessTokenMinted (
        uint256 indexed tokenId,
        string channelId,
        address creator,
        uint256 tickets
    );

    constructor(address contractAddress) ERC1155("") {    
        require(contractAddress != address(0), "ERR-1-AT");
        managerContract = contractAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ACCESS_TOKEN_MANAGER_ROLE, contractAddress);
    }

    // Public functions

    /// Set Approval For All
    /// @param operator who want to set approval
    /// @param approved value for approval
    /// @notice ERC1155 function - https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155-setApprovalForAll-address-bool-
    /// @dev the function has been overrided to avoid removal permission to manager contract
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != managerContract, "ERR-3-AT");    
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // Public Functions view

    /// Contract Uri
    /// @notice return contractUri to align opensea standard
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    /// SupportsInterface
    /// @notice ERC165 function - documentation at https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165-supportsInterface-bytes4-
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl, ERC2981)
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    /// Returns uri for given 'tokenId'.
    /// @param tokenId within retrieve uri
    /// @notice ERC1155 function - documentation at https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155
    /// @dev the function has been overrided to align opensea metadata standard
    function uri(uint256 tokenId) 
        override 
        public 
        view 
        returns(string memory) 
    {
        return(tokenIdToUri[tokenId]);
    }

    // External functions only access token manager
    
    /// Lazy Mint for `accessToken`
    /// @param creator address of private channel owner
    /// @param tickets supply for token erc1155
    /// @param royaltyPercentage percentage for nft royalty
    /// @param uriMetadata metadata associated to NFT
    /// @param channelId channelId associated to NFT
    /// @notice mint a new erc1155 token with information received by access token manager
    function lazyMint(
        address creator, 
        uint tickets, 
        uint96 royaltyPercentage, 
        string memory uriMetadata, 
        uint tokenId, 
        string memory channelId
    ) 
        external
        nonReentrant
        onlyRole(ACCESS_TOKEN_MANAGER_ROLE) 
    {
        if (tokenId == 0){
            revert("ERR-2-AT");
        }

        _mint(creator, tokenId, tickets, "");
        _setApprovalForAll(creator, managerContract, true);
        _setTokenRoyalty(tokenId, creator, royaltyPercentage);
        _setURI(tokenId, uriMetadata);

        emit AccessTokenMinted(tokenId, channelId, creator, tickets);
    }

    // External functions only default admin role

    /// Store uri for given 'tokenId'
    /// @param tokenId to update
    /// @param uriMetadata to store
    /// @notice ERC1155 function - documentation at https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155
    function setURI(uint256 tokenId, string memory uriMetadata) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _setURI( tokenId, uriMetadata);
    }

    /// Set Contract Uri
    /// @param uriMetadata endpoint
    /// @notice update the metadata for smart contract
    function setContractURI(string memory uriMetadata) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _contractUri = uriMetadata;
    }

    // Internal functions

    /// @notice ERC1155 function - documentation at https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155
    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    )
        internal
        override(ERC1155, ERC1155Supply) 
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    // Private functions

    /// SetURI
    /// @notice ERC1155 function - documentation at https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155
    function _setURI(uint256 tokenId, string memory _uriMetadata) private {        
        if (bytes(tokenIdToUri[tokenId]).length>0){
            revert("ERR-4-AT");
        }
        tokenIdToUri[tokenId] = _uriMetadata;
    }

}