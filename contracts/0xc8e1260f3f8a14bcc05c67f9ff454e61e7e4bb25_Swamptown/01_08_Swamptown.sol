// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/INftContract.sol";
import "./interfaces/IStakingContract.sol";

contract Swamptown is ERC721A, Ownable {
  using Strings for uint256;

  uint public constant COLLECTION_SIZE = 10000;
  uint public constant HOLDER_MINT_PRICE = 0.01 ether;
  uint public constant PUBLIC_MINT_PRICE = 0.02 ether;

  IStakingContract public stakingAddress;
  INftContract public creatureAddress;
  INftContract public swamperAddress;

  mapping(address => bool) public claimedFreeMint;

  string public beginningUri = "";
  string public endingUri = "";

  constructor(
    string memory _beginningUri, 
    string memory _endingUri,
    address _staking,
    address _creature,
    address _swamper
  ) ERC721A("Swamptown", "Swamptown") {
    beginningUri = _beginningUri;
    endingUri = _endingUri;
    stakingAddress = IStakingContract(_staking);
    creatureAddress = INftContract(_creature);
    swamperAddress = INftContract(_swamper);
  }

  function publicMint(uint256 quantity) external payable checkMint(quantity) {
    require(msg.value >= quantity * PUBLIC_MINT_PRICE, "Ether value sent is not sufficient");
    _safeMint(msg.sender, quantity);
  }

  function holderMint(uint256 quantity) external payable checkMint(quantity) {
    require(stakingAddress.balanceOf(msg.sender) > 0 || creatureAddress.balanceOf(msg.sender) > 0 || swamperAddress.balanceOf(msg.sender) > 0, "Not a holder");
    require(msg.value >= quantity * HOLDER_MINT_PRICE, "Ether value sent is not sufficient");
    _safeMint(msg.sender, quantity);
  }

  function oneFreeHolderMint(uint256 quantity) external payable checkMint(quantity) {
    require(tx.origin == msg.sender, "sender does not match");
    require(claimedFreeMint[msg.sender] == false, "already claimed");
    require(stakingAddress.stakedCreaturesByOwner(msg.sender).length > 0 || creatureAddress.balanceOf(msg.sender) > 0, "Not a creature holder");
    require(msg.value >= (quantity-1) * HOLDER_MINT_PRICE, "Ether value sent is not sufficient");
    claimedFreeMint[msg.sender] = true;
    _safeMint(msg.sender, quantity);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(beginningUri, tokenId.toString(), endingUri));
  }

  function setURI(uint256 _mode, string memory _new_uri) public onlyOwner {
    if (_mode == 1) beginningUri = _new_uri;
    else if (_mode == 2) endingUri = _new_uri;
    else revert("wrong mode");
  }
  
  /// @notice Withdraw's contract's balance to the minter's address
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No balance");
    payable(owner()).transfer(balance);
  }

  modifier checkMint(uint256 quantity) {
    require(totalSupply() + quantity <= COLLECTION_SIZE, "reached max supply");
    require(quantity < 11, "Max quantity per tx exceeded");
    require(tx.origin == msg.sender, "sender does not match");
    _;
  }

}