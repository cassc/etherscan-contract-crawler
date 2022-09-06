// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @author Bella
/// @title Bella Community Access Token
/// @notice Smart contract to store, generate and manage access tokens for Community Creators on Bella using ERC1155 standard
contract CommunityToken is ERC1155, AccessControl, ERC1155Burnable, ERC1155Supply, ReentrancyGuard, ERC1155Holder, Pausable {

    // ERR-1-CT		Cannot remove approval to community token manager
    // ERR-2-CT		Community already generated
    // ERR-3-CT		Cannot set uri twice

    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    bytes32 private constant COMMUNITY_TOKEN_MANAGER_ROLE = keccak256("COMMUNITY_TOKEN_MANAGER_ROLE");
    
    mapping(uint => string) private tokenIdToUri;
    mapping(string => uint) public communityIdToTokenId;

    string public constant name = "BELLA Community Token";
    string public constant symbol = "BCT";

    string private _contractUri = "https://ipfs.io/ipfs/Qmaxr3rYRXXjQRZxP6xgjYQVgZcnQ14DcFbZB7p2cpTVUB";

    event CommunityGenerated(
        string communityId,
        uint indexed tokenId,
        uint supply,
        string metadata
    );

    constructor() ERC1155("") {    
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(COMMUNITY_TOKEN_MANAGER_ROLE, msg.sender);
    }

    // Public Functions

    /// Set Approval For All
    /// @param operator who want to set approval
    /// @param approved value for approval
    /// @notice ERC1155 function - https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#IERC1155-setApprovalForAll-address-bool-
    /// @dev the function has been overrided to avoid removal permission to manager contract
    function setApprovalForAll(address operator, bool approved) public override {
        require(!hasRole(COMMUNITY_TOKEN_MANAGER_ROLE, operator), "ERR-1-CT");
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    // Public Functions - view

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
        override(ERC1155Receiver, ERC1155, AccessControl)
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    // External Function ony DEFAULT_ADMIN_ROLE

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

    function setContractURI(string memory uriMetadata) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _contractUri = uriMetadata;
    }

    /// Set Pause On 
    /// @notice pause the smart contract
    function pause()
        external
        whenNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _pause();
    }

    /// Set Pause Off 
    /// @notice unpause the smart contract
    function unpause()
        external
        whenPaused
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _unpause();
    }

    // Extrnal function only COMMUNITY_TOKEN_MANAGER_ROLE

    /// @param communityId associated to tokenId
    /// @param supply for erc1155
    /// @param uriMetadata associated to NFT
    /// @notice function that mint an ERC1155 nft on smart contract
    function generateCommunity(string memory communityId, uint supply, string memory uriMetadata)
        external
        nonReentrant
        whenNotPaused
        onlyRole(COMMUNITY_TOKEN_MANAGER_ROLE)
    {
        require(communityIdToTokenId[communityId] == 0, "ERR-2-CT");

        uint tokenId = _generateTokenId();
        communityIdToTokenId[communityId] = tokenId;

        emit CommunityGenerated(communityId, tokenId, supply, uriMetadata);

        _mint(address(this), tokenId, supply, "");
        _setURI(tokenId, uriMetadata);
        _setApprovalForAll(address(this), msg.sender, true);
    }

    // Internal Functions

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
            revert("ERR-3-CT");
        }
        tokenIdToUri[tokenId] = _uriMetadata;
    }

    /// GenerateTokenId
    /// @notice function that generate the tokenId by a counter
    function _generateTokenId() private returns(uint) {
        _tokenId.increment();
        return _tokenId.current();
    }

}