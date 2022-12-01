// SPDX-License-Identifier: MIT

/*
                                                                                                                                                                        
RRRRRRRRRRRRRRRRR                                                          FFFFFFFFFFFFFFFFFFFFFF                                                                        
R::::::::::::::::R                                                         F::::::::::::::::::::F                                                                        
R::::::RRRRRR:::::R                                                        F::::::::::::::::::::F                                                                        
RR:::::R     R:::::R                                                       FF::::::FFFFFFFFF::::F                                                                        
  R::::R     R:::::R  aaaaaaaaaaaaavvvvvvv           vvvvvvv eeeeeeeeeeee    F:::::F       FFFFFFaaaaaaaaaaaaa      cccccccccccccccc    eeeeeeeeeeee        ssssssssss   
  R::::R     R:::::R  a::::::::::::av:::::v         v:::::vee::::::::::::ee  F:::::F             a::::::::::::a   cc:::::::::::::::c  ee::::::::::::ee    ss::::::::::s  
  R::::RRRRRR:::::R   aaaaaaaaa:::::av:::::v       v:::::ve::::::eeeee:::::eeF::::::FFFFFFFFFF   aaaaaaaaa:::::a c:::::::::::::::::c e::::::eeeee:::::eess:::::::::::::s 
  R:::::::::::::RR             a::::a v:::::v     v:::::ve::::::e     e:::::eF:::::::::::::::F            a::::ac:::::::cccccc:::::ce::::::e     e:::::es::::::ssss:::::s
  R::::RRRRRR:::::R     aaaaaaa:::::a  v:::::v   v:::::v e:::::::eeeee::::::eF:::::::::::::::F     aaaaaaa:::::ac::::::c     ccccccce:::::::eeeee::::::e s:::::s  ssssss 
  R::::R     R:::::R  aa::::::::::::a   v:::::v v:::::v  e:::::::::::::::::e F::::::FFFFFFFFFF   aa::::::::::::ac:::::c             e:::::::::::::::::e    s::::::s      
  R::::R     R:::::R a::::aaaa::::::a    v:::::v:::::v   e::::::eeeeeeeeeee  F:::::F            a::::aaaa::::::ac:::::c             e::::::eeeeeeeeeee        s::::::s   
  R::::R     R:::::Ra::::a    a:::::a     v:::::::::v    e:::::::e           F:::::F           a::::a    a:::::ac::::::c     ccccccce:::::::e           ssssss   s:::::s 
RR:::::R     R:::::Ra::::a    a:::::a      v:::::::v     e::::::::e        FF:::::::FF         a::::a    a:::::ac:::::::cccccc:::::ce::::::::e          s:::::ssss::::::s
R::::::R     R:::::Ra:::::aaaa::::::a       v:::::v       e::::::::eeeeeeeeF::::::::FF         a:::::aaaa::::::a c:::::::::::::::::c e::::::::eeeeeeee  s::::::::::::::s 
R::::::R     R:::::R a::::::::::aa:::a       v:::v         ee:::::::::::::eF::::::::FF          a::::::::::aa:::a cc:::::::::::::::c  ee:::::::::::::e   s:::::::::::ss  
RRRRRRRR     RRRRRRR  aaaaaaaaaa  aaaa        vvv            eeeeeeeeeeeeeeFFFFFFFFFFF           aaaaaaaaaa  aaaa   cccccccccccccccc    eeeeeeeeeeeeee    sssssssssss    
                                                                                                                                                                         
*/

pragma solidity ^0.8.4;

import { RevokableOperatorFilterer } from "./RevokableOperatorFilterer.sol";
import { RevokableDefaultOperatorFilterer } from "./RevokableDefaultOperatorFilterer.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

contract BackStagePass is
  ERC721AQueryable,
  ERC721ABurnable,
  RevokableDefaultOperatorFilterer,
  Ownable,
  ReentrancyGuard
{
  using SafeMath for uint256;
  uint256 private _maxSupply;
  bool private _isPublicMintEnabled;

  string private _tokenBaseURI =
    "ipfs://QmcRoBAZL2VqyjSpeLfqi46T1ZifoUFxqEQSn2KqGCGmYU/";

  function setApprovalForAll(address operator, bool approved)
    public
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    payable
    override(ERC721A, IERC721A)
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function owner()
    public
    view
    virtual
    override(Ownable, RevokableOperatorFilterer)
    returns (address)
  {
    return Ownable.owner();
  }

  /**
   * @dev Initializes the contract setting the `tokenName` and `symbol` of the nft, and maximum `supply` of the nft.
   */

  constructor()
    ERC721A("RaveFaces Backstage Pass", "RF Backstage Pass")
    Ownable()
  {
    _maxSupply = 500;
    _isPublicMintEnabled = false;
  }

  /**
   * @dev     Changes contract state to enable public access to `mintTokens` function
   * Can only be called by the current owner.
   */
  function allowPublicMint() public onlyOwner {
    _isPublicMintEnabled = true;
  }

  /**
   * @dev     Changes contract state to disable public access to `mintTokens` function
   * Can only be called by the current owner.
   */
  function denyPublicMint() public onlyOwner {
    _isPublicMintEnabled = false;
  }

  /**
   * @dev     Mint a token to each Address of `recipients`.
   * Can only be called if requirements are satisfied.
   */
  function mintTokensTo(address[] calldata recipients)
    public
    payable
    nonReentrant
  {
    require(recipients.length > 0, "Missing recipient addresses");
    require(owner() == msg.sender, "Only owner can airdrop");
    require(
      recipients.length > 0 && recipients.length <= 20,
      "You can drop minimum 1, maximum 20 NFTs"
    );
    require(
      recipients.length.add(totalSupply()) < (_maxSupply + 1),
      "Exceeds max supply"
    );

    for (uint256 i = 0; i < recipients.length; i++) {
      _safeMint(recipients[i], 1);
    }
  }

  /**
   * @dev     Mint `count` tokens if requirements are satisfied.
   */
  function freeMint() public payable nonReentrant {
    require(owner() == msg.sender || _isPublicMintEnabled, "Mint disabled");

    require(totalSupply() + 1 <= _maxSupply, "Exceed max free supply");

    _safeMint(msg.sender, 1);
  }

  /**
   * @dev     Update the max supply.
   * Can only be called by the current owner.
   */
  function setMaxSupply(uint256 max) public onlyOwner {
    _maxSupply = max;
  }

  /**
   * @dev     Transfers contract balance to contract owner.
   * Can only be called by the current owner.
   */
  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /**
   * @dev     Returns the maximum supply of the collection
   * @return  uint256  maximumSupply
   */
  function getMaxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  /**
   * @dev     Returns the current supply of the collection
   * @return  uint256  totalSupply
   */
  function getCurrentSupply() public view returns (uint256) {
    return totalSupply();
  }

  /**
   * @dev     Returns the status of the public mint. If true then users are able to mint.
   * @return  bool  isPublicMintEnabled
   */
  function getMintStatus() public view returns (bool) {
    return _isPublicMintEnabled;
  }

  /**
   * @dev     Changes the Metadata URI location.
   * @param   URI  New URI for the metadata directory
   * Can only be called by the current owner.
   */
  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }
}