// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
///////////////////////////////////
//         Base NFT
///////////////////////////////////
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol" ;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol" ;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol" ;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol" ;
abstract contract BaseNFT is AccessControlEnumerable, ERC721Enumerable, ERC721Burnable, ERC721Pausable {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    string internal _baseTokenURI = "";
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    mapping(address => bool) public approvalWhite ;

    ////////////////////////////////////////
    //               events
    ////////////////////////////////////////
    event ApprovalWhiteEvent(address operator, bool status, string memo) ;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address managerAddr
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, managerAddr);
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        approvalWhite[managerAddr] = true ;
    }

    function setBaseTokenURI(string memory baseTokenURI) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
        _baseTokenURI = baseTokenURI ;
        return true ;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function changeApprovalWhite(address operator, bool status, string memory memo) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool){
        approvalWhite[operator] = status ;
        emit ApprovalWhiteEvent(operator, status, memo) ;
        return true ;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(ERC721) returns (bool) {
        return approvalWhite[_msgSender()] || super.isApprovedForAll(owner, operator) ;
    }

    /**
    * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Artillery: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Artillery: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerable, ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // single mint NFT
    function mint(uint256 tokenId, address owner) external returns(bool) {
        return _mintNFT(tokenId, owner) ;
    }

    // batch mint NFT
    function batchMint(uint256 [] memory tokenIds, address owner) external returns(bool) {
        for(uint256 i = 0 ;i < tokenIds.length; i++ ){
            _mintNFT(tokenIds[i], owner) ;
        }
        return true ;
    }

    // mint NFT
    function _mintNFT(uint256 tokenId, address owner)
    private onlyRole(MANAGER_ROLE) returns(bool) {
        _safeMint(owner, tokenId) ;
        return true ;
    }

    // batch query owner
    function batchOwnerOf(uint256 [] memory tokenIds) external view returns(address [] memory) {
        address [] memory owners = new address[](tokenIds.length) ;

        for(uint256 i = 0 ;i < tokenIds.length ; i++){
            owners[i] = ownerOf(tokenIds[i]) ;
        }

        return owners ;
    }

    // migration NFT
    function migration(uint256 tokenId, uint256 gene, address owner) external returns(bool) {
        return _migration(tokenId, gene, owner) ;
    }

    function batchMigration(uint256 [] memory tokenIds, uint256 [] memory gens, address owner) external returns(bool) {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            _migration(tokenIds[i], gens[i], owner) ;
        }
        return true ;
    }

    function _migration(uint256 tokenId, uint256 gene, address owner) internal virtual returns (bool) ;

    // burn NFT
    function batchBurn(uint256[] memory tokenIds) external returns(bool) {
        for(uint256 i = 0 ;i < tokenIds.length ; i++ ){
            burn(tokenIds[i]);
        }
        return true ;
    }

    // baseUri/address(this)/tokenID/genes
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return string(abi.encodePacked(_baseURI(),"/", Strings.toString(tokenId), "/", getSpecialSuffix(tokenId)));
    }

    // baseUri Special suffix
    function getSpecialSuffix(uint256 tokenId) internal view virtual returns (string memory){
        return "" ;
    }

    // batch transfer
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenId
    ) external returns (bool){
        for(uint256 i = 0; i < tokenId.length; i++) {
            safeTransferFrom(from, to, tokenId[i]) ;
        }
        return true ;
    }

}