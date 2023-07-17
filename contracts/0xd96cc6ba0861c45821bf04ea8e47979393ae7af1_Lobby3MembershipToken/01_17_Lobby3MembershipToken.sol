// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Lobby3 Membership Token
 * @author maikir
 * @notice This contract allows the distribution, minting and exchange of ERC-721 Lobby 3 Membership Tokens and managament and transfer of token sale proceeds to relevant beneficiary parties.
 *
 */
contract Lobby3MembershipToken is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;

  // Sale start time
  uint64 private _saleStart;
  uint64 private _saleEnd;

  // Base URI
  string private _uri;

  uint256 private immutable goldMaxSupply;

  Counters.Counter private goldIdCounter;
  Counters.Counter private _tokenIdCounter;

  //0.07 ETH
  uint256 public constant STANDARD_ETH_MINT_PRICE = 70000000000000000;
  //1 ETH
  uint256 public constant GOLD_ETH_MINT_PRICE = 1000000000000000000;
  //40 ETH
  uint256 public constant DIAMOND_ETH_MINT_PRICE = 40000000000000000000;

  //Payment Splitting / Vesting
  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);

  uint256 private _totalShares;
  uint256 private _totalReleased;

  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  address[] private _payees;

  constructor(
    string memory baseURI,
    uint256 goldMaxSupply_
  ) ERC721("Lobby3 Membership Token", "L3") {
    _uri = baseURI;
    goldMaxSupply = goldMaxSupply_;
  }

  /**
    * @dev Allows to enable minting of sale and create sale period.
    */
  function turnOnSaleState() external onlyOwner {
    _saleStart = uint64(block.timestamp);
    //10 day period
    _saleEnd = _saleStart + 864000;
  }

  /**
    * @dev Allows to disable minting of sale.
    */
  function turnOffSaleState() external onlyOwner {
    _saleStart = 0;
    _saleEnd = 0;
  }

  /**
    * @dev Allows owner to set the baseURI dynamically.
    * @param uri The base uri for the metadata store.
    */
  function setBaseURI(string memory uri) external onlyOwner {
    _uri = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return _uri;
  }

  function append(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }

  //MINTING

  /**
    * @dev Minting function for standard Lobby3 token.
    * @param to Address to mint token to.
    */
  function mintStandardETH(address to, uint256 numTokens) external payable {
    require(uint64(block.timestamp) < _saleEnd, "Sale period has not started or is over");
    require(
      !Address.isContract(msg.sender),
      "Caller must not be a contract"
    );
    require ((STANDARD_ETH_MINT_PRICE * numTokens) <= msg.value, "Eth value is incorrect");
    require(numTokens > 0, "Must mint at least 1 token");

    for (uint256 i=0; i < numTokens; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      string memory metadataIndex = append(Strings.toString(tokenId), '/uri/');
      _safeMint(to, tokenId);
      _setTokenURI(tokenId, metadataIndex);
      _tokenIdCounter.increment();
    }
  }

  /**
    * @dev Minting function for standard Lobby3 token.
    * @param to Address to mint token to.
    */
  function mintStandardETHBackup(address to, uint256 numTokens) external onlyOwner{
    require(uint64(block.timestamp) < _saleEnd, "Sale period has not started or is over");
    require(numTokens > 0, "Must mint at least 1 token");

    for (uint256 i=0; i < numTokens; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      string memory metadataIndex = append(Strings.toString(tokenId), '/uri/');
      _safeMint(to, tokenId);
      _setTokenURI(tokenId, metadataIndex);
      _tokenIdCounter.increment();
    }
  }

  /**
    * @dev Minting function for gold Lobby3 token.
    * @param to Address to mint token to.
    */
  function mintGoldETH(address to, uint256 numTokens) external payable {
    require(uint64(block.timestamp) < _saleEnd, "Sale period has not started or is over");
    require(
      !Address.isContract(msg.sender),
      "Caller must not be a contract"
    );
    require ((GOLD_ETH_MINT_PRICE * numTokens) <= msg.value, "Eth value is incorrect");
    require(numTokens > 0, "Must mint at least 1 token");

    for (uint256 i=0; i < numTokens; i++) {
      uint256 goldId = goldIdCounter.current();
      require(
        goldId < goldMaxSupply,
        "Token count exceeds gold limit"
      );
      uint256 tokenId = _tokenIdCounter.current();
      string memory metadataIndex = append(Strings.toString(tokenId), '/uri/');
      _safeMint(to, tokenId);
      _setTokenURI(tokenId, metadataIndex);
      goldIdCounter.increment();
      _tokenIdCounter.increment();
    }
  }

  /**
    * @dev Backup minting function for gold Lobby3 token for owner.
    * @param to Address to mint token to.
    */
  function mintGoldETHBackup(address to, uint256 numTokens) external onlyOwner{
    require(uint64(block.timestamp) < _saleEnd, "Sale period has not started or is over");
    require(numTokens > 0, "Must mint at least 1 token");

    for (uint256 i=0; i < numTokens; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      string memory metadataIndex = append(Strings.toString(tokenId), '/uri/');
      _safeMint(to, tokenId);
      _setTokenURI(tokenId, metadataIndex);
      goldIdCounter.increment();
      _tokenIdCounter.increment();
    }
  }

  /**
    * @dev Minting function for diamond Lobby3 token.
    * @param to Address to mint token to.
    */
  function mintDiamondETH(address to) external onlyOwner {
    uint256 tokenId = _tokenIdCounter.current();

    string memory metadataIndex = append(Strings.toString(tokenId), '/uri/');
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, metadataIndex);
    _tokenIdCounter.increment();
  }

  //Payments Splitting/Vesting

  /**
   * @dev Initializes payees and shares per payee. Each account in `payees` to the number of shares at the matching position in the `shares` array.
   */
  function setPayees(address[] memory payees, uint256[] memory shares_) public onlyOwner {
    require(payees.length == shares_.length, "Payees and shares length mismatch");
    require(payees.length > 0, "No payees");

    for (uint256 i = 0; i < payees.length; i++) {
      _addPayee(payees[i], shares_[i]);
    }
  }

  /**
   * @dev Getter for the total shares held by payees.
   */
  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) public view returns (uint256) {
    return _shares[account];
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) public view returns (uint256) {
    return _released[account];
  }

  /**
   * @dev Getter for the amount of Ether that is available to be released to an account/payee.
   */
  function releasable(address payable account) public view returns (uint256) {
    require(_shares[account] > 0, "Account has no shares");

    uint256 totalReceived = address(this).balance + totalReleased();
    uint256 payment = _pendingPayment(account, totalReceived, released(account));

    return payment;
  }

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  function release(address payable account) public {
    require(_shares[account] > 0, "Account has no shares");

    uint256 totalReceived = address(this).balance + totalReleased();
    uint256 payment = _pendingPayment(account, totalReceived, released(account));

    require(payment != 0, "Account is not due payment");

    _released[account] += payment;
    _totalReleased += payment;

    Address.sendValue(account, payment);
    emit PaymentReleased(account, payment);
  }

  /**
   * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
   * already released amounts.
   */
  function _pendingPayment(
    address account,
    uint256 totalReceived,
    uint256 alreadyReleased
  ) private view returns (uint256) {
    return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
  }

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param shares_ The number of shares owned by the payee.
   */
  function _addPayee(address account, uint256 shares_) private {
    require(account != address(0), "Account is the zero address");
    require(shares_ > 0, "Shares are 0");
    require(_shares[account] == 0, "Account already has shares");

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;
    emit PayeeAdded(account, shares_);
  }

  //ERC721 OVERRIDES
  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId)
    internal
    override(ERC721, ERC721URIStorage)
  {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}