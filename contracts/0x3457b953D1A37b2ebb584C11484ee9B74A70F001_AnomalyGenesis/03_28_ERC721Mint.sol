// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721.sol";
import "./Admins.sol";

// @author: miinded.com

abstract contract ERC721Mint is ERC721, ERC2981, Admins, ReentrancyGuard, DefaultOperatorFilterer {

    /**
    @notice Max supply available for this contract
    */
    uint32 public MAX_SUPPLY = type(uint32).max;

    /**
    @notice Tracker for the total minted
    */
    uint32 public mintTracked;

    /**
    @notice Tracker for the total burned
    */
    uint32 public burnedTracker;

    /**
    @notice The number of the First token Id
    */
    uint8 public START_AT = 1;

    /**
    @notice The base URI for metadata for all tokens
    */
    string public baseTokenURI;


    /**
    @dev Verify if the contract is soldout
    */
    modifier notSoldOut(uint256 _count) {
        require(mintTracked + uint32(_count) <= MAX_SUPPLY, "Sold out!");
        _;
    }


    /**
    @notice Set the max supply of the contract
    @dev only internal, can't be change after contract deployment
    */
    function setMaxSupply(uint32 _maxSupply) internal {
        MAX_SUPPLY = _maxSupply;
    }

    /**
    @notice Set the number of the first token
    @dev only internal, can't be change after contract deployment
    */
    function setStartAt(uint8 _start) internal {
        START_AT = _start;
    }

    /**
    @notice Set the base URI for metadata of all tokens
    */
    function setBaseUri(string memory baseURI) public onlyOwnerOrAdmins {
        baseTokenURI = baseURI;
    }

    /**
    @notice Get all tokenIds for a wallet
    @dev This method can revert if the mintedTracked is > 30000.
        it is not recommended to call this method from another contract.
    */
    function walletOfOwner(address _owner) public view virtual returns (uint32[] memory) {
        uint256 count = balanceOf(_owner);
        uint256 key = 0;
        uint32[] memory tokensIds = new uint32[](count);

        for (uint32 tokenId = START_AT; tokenId < mintTracked + START_AT; tokenId++) {
            if (key == count) break;
            if (_owners[tokenId] != _owner) continue;

            tokensIds[key] = tokenId;
            key++;
        }
        return tokensIds;
    }

    /**
    @notice Get the base URI for metadata of all tokens
    */
    function _baseURI() internal override view returns(string memory){
        return baseTokenURI;
    }

    /**
    @notice Replace ERC721Enumerable.totalSupply()
    @return The total token available.
    */
    function totalSupply() public view returns (uint32) {
        return mintTracked - burnedTracker;
    }

    /**
    @notice Mint the next token
    @return the tokenId minted
    */
    function _mintToken(address wallet) internal returns(uint256){
        uint256 tokenId = uint256(mintTracked + START_AT);
        mintTracked += 1;
        _safeMint(wallet, tokenId);
        return tokenId;
    }

    /**
    @notice Mint the next tokens
    */
    function _mintTokens(address wallet, uint256 _count) internal{
        for (uint256 i = 0; i < _count; i++) {
            _mintToken(wallet);
        }
    }

    /**
    @notice Mint the specific token
    */
    function _mintTheToken(address wallet, uint256 tokenId) internal{
        mintTracked += 1;
        _safeMint(wallet, tokenId);
    }

    /**
    @notice Mint the tokens reserved for the team project
    @dev the tokens are minted to the owner of the contract
    */
    function reserve(address _to, uint32 _count) public virtual onlyOwnerOrAdmins {
        require(mintTracked + _count <= MAX_SUPPLY, "Sold out!");
        _mintTokens(_to, _count);
    }

    /**
    @notice Burn the token if is approve or owner
    */
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not owner nor approved");
        burnedTracker += 1;
        _burn(_tokenId);
    }

    /**
     * @notice Allows the owner to set default royalties following EIP-2981 royalty standard.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwnerOrAdmins {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
    @notice Add the Operator filter functions
    */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}