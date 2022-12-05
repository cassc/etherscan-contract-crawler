// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// https://ipfs.io/ipfs/QmbUB8nqEby2aUrHxcL2Snn3Grfzkh9SaqsK6H6QzFKxyL

contract LfgERC721Test is ERC721, Ownable {
  
  // Required base URI
  string public baseURI = "";
  string public _tempURI = "";
	
  uint256 public mintsRemaining;
  uint256 private _totalSupply;
	
  constructor(string memory name_, string memory symbol_, string memory tempURI, uint256 totalSupply_) ERC721(name_, symbol_) {
	  _tempURI = tempURI;
	  mintsRemaining = _totalSupply = totalSupply_;
  }

  function setBaseURI(string memory uri) external onlyOwner {
	  baseURI = uri;
  }
  
  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  } 
  
  /**
   * @dev See {IERC721Metadata-tokenURI}.
   * if baseURI has been set then return normal tokan URI of baseURI + tokenId
   * if baseURI has not been set then return _tempURI
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	  // using local _requireMinted
	  _requireMinted(tokenId);
	  
      // if token actually exists return normal tokenURI
      if(bytes(baseURI).length > 0) return super.tokenURI(tokenId);
      
      return _tempURI;
  }  
  
  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual returns (uint256) {
      return _totalSupply;
  } 
  
  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner_) public view virtual override returns (uint256) {
	  //check if owner_ is also contract owner
	  if(owner_==owner()) {
		  //is contract owner so return total left unminted plus mints that owner actually minted
		  return mintsRemaining + super.balanceOf(owner_);
	  }
	  //not the owner of the contract so just return balance of this token owner
	  return super.balanceOf(owner_);
  }  
  
  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override(ERC721) returns (address) {
     if(_exists(tokenId)) return super.ownerOf(tokenId);
     
     //token id doesn't exist yet so return contract owner
     return owner();
  }  
  
  function _transfer(address from, address to, uint256 tokenId) internal virtual override {
      // check if token exists yet or is gasless
      if(_exists(tokenId)) {
          // if token exists call normal transfer
          super._transfer(from,to,tokenId);
      } else {
          // if token doesn't exist yet, mint directly to recipient of transfer
          super._mint(to,tokenId);
          // subtract 1 from internal actual mint counter
          mintsRemaining--;
      }
  }  
  
  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
      address owner = ownerOf(tokenId);
      require(to != owner, "ERC721: approval to current owner");
      require(
          _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
          "ERC721: approve caller is not token owner or approved for all"
      );
      _approve(to, tokenId);
  } 
  
  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual override {
      _tokenApprovals[tokenId] = to;
      emit Approval(ownerOf(tokenId), to, tokenId);
  }  
  
 
  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual override {
      require(_exists(tokenId) || tokenId <= _totalSupply, "ERC721: invalid token ID");
  }  
  
  /**
    * @dev Returns whether `spender` is allowed to manage `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` does not have to exist, could be gasless
    */
   function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override(ERC721) returns (bool) {
	   // need to call local ownerOf here because of gasless owner possiblitiy
	   address owner = ownerOf(tokenId);
       return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
   }
   
   /**
    * @dev See {IERC721-getApproved}.
    */
   function getApproved(uint256 tokenId) public view virtual override returns (address) {
       _requireMinted(tokenId);

       return _tokenApprovals[tokenId];
   }

   
   
//  function baseURI() public pure returns (string memory) {
//    return "ipfs://portion.io/images/";
//  }

//  function tokenURI(uint256 tokenId) public pure override returns (string memory) {
//    return "ipfs://QmVrcjjJfYHKhCG6uBZUgUMWRxw5XxVWNN71xzkuvDkNgW/"+tokenId;
//  }

}