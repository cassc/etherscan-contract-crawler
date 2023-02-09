// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title PiggyBank
* @author Boobook
* @dev This contract acts like a safety deposit box for eth.
* Withdrawal is timelocked and set when minting.
* Additional deposits can occur at any time by any wallet.
* Tips are welcomed but not required.
* Tokens are ERC721 and can be transferred.
*/

contract PiggyBank is ERC721, Ownable {

  using Strings for uint256;
  uint256 public initialDeposit = 0.005 ether;
  string private _baseTokenURI; 
  uint256 public tipJar;

  event Withdrawn(uint256 tokenId, uint256 amount);
  event Minted(uint256 tokenId, uint256 tip, uint256 initialDeposit);
  event TipWithdraw();

  struct Account {
    uint40 readyTime;
    uint216 accountBalances;
  }

  Account[] private accounts;

  ///@dev Thrown when readyTime is not a future date
  error NotFutureDate();
  ///@dev Thrown when initialDeposit too low
  error InsufficientInitialDeposit();
  ///@dev Thrown when tokenId does not exist
  error TokenIdDoesNotExist();
  ///@dev Trown when address calling withdraw function is not the owner
  error NotAccountOwner();
  ///@dev Thrown when readyTime has not been reached
  error AccountStillTimeLocked();
  ///@dev Thrown if no eth in the account
  error NoEthLeft();
  ///@dev Thrown if no eth in tipJar
  error TipJarEmpty();
  ///@dev Thrown if address calling emptyTipJar is not contract owner
  error ReceiverRejected();
  ///@dev Thrown if address is Zero Address
  error ZeroAddress();

  constructor() ERC721("PiggyBank","PBANK"){}

  /** 
  * @notice Sets the minimum deposit amount required to mint a token
  * @param _initial the amount to set the initial deposit to
  */ 
  function setInitialDeposit(uint _initial) external onlyOwner {
    initialDeposit = _initial;
  }

  /**
  * @notice Creates an Eth bank stored as a transferable NFT
  * @param _readyTime the unix timestamp the Eth is locked until
  * @param tip an amount giving to contract owner as tip for the service
  */ 
  function formingDiamondHands(uint40 _readyTime, uint256 tip) external payable {
    if(_readyTime < block.timestamp) { revert NotFutureDate(); }
    if((msg.value - tip) < initialDeposit) {revert InsufficientInitialDeposit(); }
    uint216 _deposit = uint216(msg.value) - uint216(tip);
    tipJar += tip;
    accounts.push(Account(_readyTime, _deposit));
    uint256 tokenId = accounts.length - 1;
    _safeMint(msg.sender, tokenId);
    emit Minted(tokenId, tip, initialDeposit);
  }

  /**
  * @notice allows depositing additional funds to existing token
  * @param _tokenId id of token to deposit to
  * @dev deposit not restricted to token owner
  */ 
  function deposit(uint256 _tokenId) external payable {
    if(!_exists(_tokenId)) { revert TokenIdDoesNotExist(); }
    accounts[_tokenId].accountBalances += uint216(msg.value);
  }

  /** 
  * @notice allows owner of the token to withdraw deposited funds. 
  * @param _tokenId id of token to withdraw ETH from
  * @dev All funds are withdrawn at same time. No partial withdraw
  */ 
  function withdraw(uint256 _tokenId) external {
    address theOwner = ownerOf(_tokenId);
    if(theOwner != msg.sender) { revert NotAccountOwner(); }
    if(block.timestamp < accounts[_tokenId].readyTime) { revert AccountStillTimeLocked(); }
    if(accounts[_tokenId].accountBalances == 0) { revert NoEthLeft(); }
    uint256 amount = accounts[_tokenId].accountBalances;
    accounts[_tokenId].accountBalances = 0;
    payable(theOwner).transfer(amount);
    emit Withdrawn(_tokenId, amount);
  }

  /**
  * @notice returns the eth balance of a token 
  * @param _tokenId id of token to check balance of
  */ 
  function getAccountBalance(uint256 _tokenId) external view returns (uint) {
    if(!_exists(_tokenId)) { revert TokenIdDoesNotExist(); }
    return accounts[_tokenId].accountBalances;
  }

  /**
  * @notice returns the timestamp of the unlock date
  * @param _tokenId id of token to check when token unlocks
  */
  function getReadyTime(uint256 _tokenId) external view returns (uint) {
    if(!_exists(_tokenId)) { revert TokenIdDoesNotExist(); }
    return accounts[_tokenId].readyTime;
  }

  /** 
  * @notice returns base metadata URI 
  */
  function _baseURI() internal view virtual override returns(string memory) {
    return _baseTokenURI;
  }
  
  /**
  * @notice sets base metadata URI
  * @param baseURI base URI set by contract owner
  */
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  /**
  * @notice generates individual token metadata URI
  * @param tokenId id of token to generate URI from
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if(!_exists(tokenId)) { revert TokenIdDoesNotExist(); }
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";   
  }

  /** 
  * @notice List of tokens by Owner 
  * @param _owner address to check what tokens it owns
  * @dev Returns an array of tokens owned by 'owner'
  * This function loops through all tokens to return an array of tokens owned by 'owner'
  * It is meant to be called off chain
  */
  function getAccountsByOwner(address _owner) external view returns(uint256[] memory){
    uint256 number = balanceOf(_owner);
    uint256 [] memory result = new uint256[](number);
    uint256 counter = 0;
    for (uint256 i = 0; i < accounts.length; i++) {
      if(ownerOf(i) == _owner) {
        result[counter] = i;
        counter++;
      }
    }
    return result;
  }

  /**
  * @notice returns total supply of tokens minted
  */
  function totalSupply() public view returns (uint256) {
    return accounts.length;
  }

  /**
  * @dev Transfers ownership of the contract to a new account (`newOwner`).
  * Can only be called by the current owner.
  */

  function transferOwnership(address newOwner) public override virtual onlyOwner {
        if(newOwner == address(0)) { revert ZeroAddress(); }
        _transferOwnership(newOwner);
    }

  /**
  * @notice withdraw ETH tips from contract to owner of contract
  * withdraws full balance of tipJar
  */ 
  function emptyTipJar() external onlyOwner {
    if(tipJar == 0) { revert TipJarEmpty(); }
    (bool success,) = payable(msg.sender).call{value: tipJar}("");
    if(!success) { revert ReceiverRejected(); }
    tipJar = 0;
    emit TipWithdraw();
  }

  /**
  * @notice rescues any ERC20 or ERC721 sent to this contract by mistake
  * Borrowed from 0xTh0mas.eth RentADawg
  */
  function rescueTokens (address tokenAddress, bool erc20, uint256 id) external onlyOwner {
    if(erc20){
      IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    } else {
        IERC721(tokenAddress).transferFrom(address(this), msg.sender, id);
    }
  }
}