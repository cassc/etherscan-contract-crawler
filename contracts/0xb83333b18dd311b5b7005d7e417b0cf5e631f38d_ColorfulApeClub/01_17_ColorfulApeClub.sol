// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721EnumerableLite.sol';
import './Signed.sol';
import "./Strings.sol";

contract ColorfulApeClub is ERC721EnumerableLite, Signed {
  using Strings for uint;

  uint public maxTokenMint = 5;
  uint public maxTokenSupply = 1000; 
  uint public mintPrice = 0.05 ether;

  bool public isMainsaleActive = false;
  bool public isPresaleActive = false;
  string private _tokenURI_Prefix = '';

  address public devWallet = 0x3463de769F20EF015F3DedD6DCabDc8521e8B076;
  address public communityWallet = 0xf50F19De005d6f64D64DCD76Fc28540F15C19e25;
  address public adminWallet = 0x8a2Cea182C174Bd242b3c02cf550c4d412c026fD;

  mapping (address => bool) public whitelist;

  constructor()
    Delegated()
    ERC721B("Colorful Ape Club", "CAC", 0){
  }

  fallback() external payable {}

  receive() external payable {}

  function tokenURI(uint tokenId) external view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_tokenURI_Prefix, tokenId.toString() ));
  }

  function mintMainsale( uint quantity ) external payable {
    require( isMainsaleActive, "sale not active" );
    require( quantity <= maxTokenMint, "max mint is 10" );
    require( msg.value >= mintPrice * quantity, "underpaid" );

    uint supply = totalSupply();
    require( supply + quantity <= maxTokenSupply, "supply capped" );

    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++ );
    }
  }

  function mintPresale( uint quantity ) external payable {
    require( isPresaleActive, "sale not active" );
    require(whitelist[msg.sender] == true, "invalid address");
    require( quantity <= maxTokenMint, "max mint of 5" );
    require( msg.value >= mintPrice * quantity, "underpaid" );

    uint supply = totalSupply();
    require( supply + quantity <= maxTokenSupply, "supply capped" );

    for(uint i; i < quantity; ++i){
      _mint( msg.sender, supply++ );
    }
  }


  function setMainsaleStatus(bool isMainsaleActive_ ) external onlyDelegates{
    require( isMainsaleActive != isMainsaleActive_ , "invalid value" );
    isMainsaleActive = isMainsaleActive_;
  }

  function setPresaleStatus(bool isPresaleActive_ ) external onlyDelegates{
    require( isPresaleActive != isPresaleActive_ , "invalid value" );
    isPresaleActive = isPresaleActive_;
  }


  function setBaseURI( string calldata baseURI ) external onlyDelegates {
    _tokenURI_Prefix = baseURI;
  }

  function setValues(uint _maxTokenMint, uint _maxTokenSupply, uint _price ) external onlyDelegates {
    require( maxTokenMint != _maxTokenMint || maxTokenSupply != _maxTokenSupply || mintPrice != _price, "Values are not valid" );
    require(_maxTokenSupply >= totalSupply(), "supply must be larger than previous supply" );

    maxTokenMint = _maxTokenMint;
    maxTokenSupply = _maxTokenSupply;
    mintPrice = _price;
  }

  function finalize() external onlyOwner {
    selfdestruct(payable(owner()));
  }

  function withdrawFailsafe() external onlyOwner {
      (bool status,) = devWallet.call{value: address(this).balance}("");
      require(status, "failed withdraw");
  }

  function withdrawBalance() external onlyOwner {
      require(address(this).balance > 0, "no eth in the contract");

      uint256 ethBalanceContract = address(this).balance;

      (bool withdraw1,) = devWallet.call{value: ethBalanceContract * 10 / 100}("");
      (bool withdraw2,) = communityWallet.call{value: ethBalanceContract * 25 / 100}("");
      (bool withdraw3,) = adminWallet.call{value: ethBalanceContract * 65 / 100}("");

      require(withdraw1 && withdraw2 && withdraw3, "Failed withdraw");
  }

  function withdrawFirst() external onlyOwner {
      require(address(this).balance > 10 ether, "Not enough ether to withdraw");

      (bool firstWithdraw,) = devWallet.call{value: 10 ether}("");

      require(firstWithdraw, "Failed withdrawing inital");
  }

  function addAddresses(address[] memory addressArray) public onlyOwner {
      for(uint256 i=0; i<addressArray.length;i++) {
        whitelist[addressArray[i]] = true;
      }
  }

  function isWhitelisted(address passedInAddress) public view returns(bool) {
      return whitelist[passedInAddress];
  }

  function _beforeTokenTransfer(address from, address to, uint tokenId) internal override {
    if( from != address(0) )
      --_balances[from];

    if( to != address(0) )
      ++_balances[to];
  }

  function _mint(address to, uint tokenId) internal override {
    _beforeTokenTransfer( address(0), to, tokenId );

    _owners.push(to);
    emit Transfer(address(0), to, tokenId);
  }
}