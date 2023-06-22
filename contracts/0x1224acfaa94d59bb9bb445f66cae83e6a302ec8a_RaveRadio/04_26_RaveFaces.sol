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

import "./IRave.sol";
import "./IBackStagePass.sol";

contract RaveFaces is
  ERC721AQueryable,
  RevokableDefaultOperatorFilterer,
  Ownable,
  ReentrancyGuard
{
  using SafeMath for uint256;
  uint256 private _mintCost;
  uint256 private _maxSupply;
  bool private _isPublicMintEnabled;
  bool private _isPresaleMintEnabled;
  bool private _isSaleClosed;

  uint256 private _ethSupply;

  address raveAddress;
  address backStagePassAddress;

  uint256 public startingIndex;

  string private _tokenBaseURI = "ipfs://QmVQ...../"; // FIXME: initial IPFS hash goes here

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
   * @dev Initializes the contract setting the `tokenName` and `symbol` of the nft,
   * `cost` of each mint call, and maximum `supply`.
   * Note: `cost` is in wei.
   */

  constructor() ERC721A("RaveFaces NFTs", "RaveFaces") Ownable() {
    _mintCost = 0.01 ether;
    _maxSupply = 5000;
    _isPublicMintEnabled = false;
    _isPresaleMintEnabled = false;
    _isSaleClosed = false;
    _ethSupply = 2000;
  }

  /**
   * @dev Sets the  ERC20 address
   * @param _raveAddress The RAVE token address
   */

  function setRaveAddress(address _raveAddress) public onlyOwner {
    raveAddress = _raveAddress;
  }

  /**
   * @dev Sets the BackStagePass address
   * @param _backStagePassAddress The RAVE token address
   */

  function setBackStagePassAddress(address _backStagePassAddress)
    public
    onlyOwner
  {
    backStagePassAddress = _backStagePassAddress;
  }

  // TODO: add multiplier
  /**
   * @dev Returns the current rave cost of mint.
   */
  function currentRaveCost() public view returns (uint256) {
    uint256 _totalSupply = totalSupply();

    if (_totalSupply <= 2000) return 2000000000000000000;
    if (_totalSupply > 2000 && _totalSupply <= 3000) return 2000000000000000000;
    if (_totalSupply > 3000 && _totalSupply <= 4000) return 4000000000000000000;
    if (_totalSupply > 4000 && _totalSupply <= 5000) return 8000000000000000000;
    if (_totalSupply > 5000 && _totalSupply <= 10000)
      return 16000000000000000000;

    revert();
  }

  function currentRaveRewardForBackStagePassBurn()
    public
    view
    returns (uint256)
  {
    return currentRaveCost();
  }

  /**
   * @dev Changes contract state to enable public access to `mintTokens` function
   * Can only be called by the current owner.
   */
  function allowPublicMint() public onlyOwner {
    _isPublicMintEnabled = true;
  }

  /**
   * @dev Changes contract state to disable public access to `mintTokens` function
   * Can only be called by the current owner.
   */
  function denyPublicMint() public onlyOwner {
    _isPublicMintEnabled = false;
  }

  /**
   * @dev Changes contract state to enable public access to `burnBackStagePassForMint` function
   * Can only be called by the current owner.
   */
  function allowPresaleMint() public onlyOwner {
    _isPresaleMintEnabled = true;
  }

  /**
   * @dev Changes contract state to disable public access to `burnBackStagePassForMint` function
   * Can only be called by the current owner.
   */
  function denyPresaleMint() public onlyOwner {
    _isPresaleMintEnabled = false;
  }

  /**
   * @dev Changes contract state to enable public access to `burnBackStagePassForRave` function
   * Can only be called by the current owner.
   */
  function closeSale() public onlyOwner {
    _isSaleClosed = true;
  }

  /**
   * @dev Changes contract state to disable public access to `burnBackStagePassForRave` function
   * Can only be called by the current owner.
   */
  function reOpenSale() public onlyOwner {
    _isSaleClosed = false;
  }

  /**
   * @dev Mint `count` tokens if requirements are satisfied.
   *
   */
  function mintTokens(uint256 count) public payable nonReentrant {
    require(_isPublicMintEnabled, "Mint disabled");
    require(
      count > 0 && count <= 20,
      "You can mint minimum 1, maximum 20 NFTs"
    );

    require(
      count.add(totalSupply()) < (_ethSupply + 5),
      "No more RaveFaces for ETH"
    );

    require(
      owner() == msg.sender || msg.value >= _mintCost.mul(count),
      "Ether value sent is below the price"
    );

    _safeMint(msg.sender, count);
  }

  /**
   * @dev Mint one token for $RAVE
   *
   */
  function mintTokenForRave() public payable nonReentrant {
    require(_isPublicMintEnabled, "Mint disabled");

    require(totalSupply() >= _ethSupply, "You can only mint for ETH for now!");
    require(totalSupply() < (_maxSupply + 1), "Exceeds max supply");

    IRave(raveAddress).burnFrom(msg.sender, currentRaveCost());

    _safeMint(msg.sender, 1);
  }

  /**
   * @dev Mint a token to each Address of `recipients`.
   * Can only be called if requirements are satisfied.
   */
  function mintTokensToArtists(address[] calldata recipients)
    public
    payable
    nonReentrant
  {
    require(recipients.length > 0, "Missing recipient addresses");
    require(owner() == msg.sender || _isPublicMintEnabled, "Mint disabled");
    require(
      recipients.length > 0 && recipients.length <= 20,
      "You can drop minimum 1, maximum 20 NFTs"
    );
    require(
      recipients.length.add(totalSupply()) < (_maxSupply + 1),
      "Exceeds max supply"
    );
    require(
      owner() == msg.sender || msg.value >= _mintCost.mul(recipients.length),
      "Ether value sent is below the price"
    );
    require(owner() == msg.sender); // don't let users to mint for others
    for (uint256 i = 0; i < recipients.length; i++) {
      _safeMint(recipients[i], 1);
    }
  }

  /**
   * @dev Burns BackStagePass and mints RaveFaces NFTs and gives $RAVE rewards.
   * @param _tokenId The token to burn.
   */
  function burnBackStagePassForMint(uint256 _tokenId) public payable {
    require(owner() == msg.sender || _isPresaleMintEnabled, "Presale disabled");
    require(totalSupply() < (_maxSupply + 1), "Exceeds max supply");
    require(
      msg.value >= _mintCost.mul(1),
      "Ether value sent is below the price"
    );

    IBackStagePass(backStagePassAddress).burn(_tokenId);

    _safeMint(msg.sender, 1);

    IRave(raveAddress).mint(
      msg.sender,
      currentRaveRewardForBackStagePassBurn()
    );
  }

  /**
   * @dev Burns BackStagePass for $RAVE tokens.
   * @param _tokenId The BackStagePass token id to burn.
   */
  function burnBackStagePassForRave(uint256 _tokenId) public payable {
    require(
      owner() == msg.sender || _isSaleClosed,
      "You cannot burn for RAVE until the sale is not closed"
    );

    IBackStagePass(backStagePassAddress).burn(_tokenId);

    IRave(raveAddress).mint(
      msg.sender,
      currentRaveRewardForBackStagePassBurn()
    );
  }

  /**
   * @dev Update the cost to mint a token.
   * Can only be called by the current owner.
   */
  function setCost(uint256 cost) public onlyOwner {
    _mintCost = cost;
  }

  /**
   * @dev Update the max supply.
   * Can only be called by the current owner.
   */
  function setMaxSupply(uint256 max) public onlyOwner {
    _maxSupply = max;
  }

  /**
   * @dev Update the max eth supply.
   * Can only be called by the current owner.
   */
  function setEthSupply(uint256 max) public onlyOwner {
    _ethSupply = max;
  }

  /**
   * @dev Transfers contract balance to contract owner.
   * Can only be called by the current owner.
   */
  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  function getCost() public view returns (uint256) {
    return _mintCost;
  }

  function getMaxSupply() public view returns (uint256) {
    return _maxSupply;
  }

  function getCurrentSupply() public view returns (uint256) {
    return totalSupply();
  }

  function getMintStatus() public view returns (bool) {
    return _isPublicMintEnabled;
  }

  function getPresaleStatus() public view returns (bool) {
    return _isPresaleMintEnabled;
  }

  function getSaleClosedStatus() public view returns (bool) {
    return _isSaleClosed;
  }

  function getEthSupply() public view returns (uint256) {
    return _ethSupply;
  }

  function setBaseURI(string calldata URI) external onlyOwner {
    _tokenBaseURI = URI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _tokenBaseURI;
  }

  /**
   * @dev Maps the token id to an art id based on the startingIndex
   */
  function tokenIdToArtId(uint256 tokenId) public view returns (uint256) {
    return (tokenId + startingIndex) % _maxSupply;
  }

  /**
   * @dev This function does the reveal. setBaseURI function should be called with the unrevealed metadadata directory
   * before calling this function.
   */
  function finalizeStartingIndex() public onlyOwner {
    require(startingIndex == 0, "Starting index is already set");

    startingIndex = block.timestamp % _maxSupply;

    if (startingIndex == 0) {
      startingIndex = startingIndex.add(1);
    }
  }

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token. It has been overriden due
   * the tokenIdToArtId function, which maps the token ids to art ids.
   */

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721A, IERC721A)
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenIdToArtId(tokenId))))
        : "";
  }
}