// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './IERC721MicDollFreeMint.sol';

contract MicDollAirdrop is Pausable {
  uint constant  public totalAirDropMicDoll = 5000;
  address public micDollContractAdress;
  address public operator;
  uint public micDollClaimedCount;
  mapping(address => bool) public recipientsPhase1;
  mapping(address => bool) public recipientsPhase2;

  event claimedInfo(address indexed account, uint indexed tokenId);
  event OperatorTransferred(address indexed oldOperator, address indexed newOperator);

  constructor() {
    operator = msg.sender;
    micDollContractAdress = address(0);
    micDollClaimedCount = 0;
    _pause();
  }


  //must initialize MicDoll address firstly before tranfer micdoll into this airdrop contract
  function initMicDollContractAddress(address _micDollContractAddress) external {
    require(msg.sender == operator, 'only operator');
    require(micDollContractAdress  == address(0), 'MicDoll address have been initialized');
    micDollContractAdress=_micDollContractAddress;
  }

  //add user into RecipientsPhase1 list
  function addRecipientsPhase1(address[] memory _recipientsPhase1) external {
    require(msg.sender == operator, 'only operator');
    for(uint i = 0; i < _recipientsPhase1.length; i++) {
      recipientsPhase1[_recipientsPhase1[i]] = true;
    }
  }

  //remove user from RecipientsPhase1 list
  function removeRecipientsPhase1(address[] memory _recipientsPhase1) external {
    require(msg.sender == operator, 'only operator');
    for(uint i = 0; i < _recipientsPhase1.length; i++) {
      recipientsPhase1[_recipientsPhase1[i]] = false;
    }
  }

  //add user into RecipientsPhase2 list
    function addRecipientsPhase2(address[] memory _recipientsPhase2) external {
    require(msg.sender == operator, 'only operator');
    for(uint i = 0; i < _recipientsPhase2.length; i++) {
      recipientsPhase2[_recipientsPhase2[i]] = true;
    }
  }

  //remove user from RecipientsPhase2 list
  function removeRecipientsPhase2(address[] memory _recipientsPhase2) external {
    require(msg.sender == operator, 'only operator');
    for(uint i = 0; i < _recipientsPhase2.length; i++) {
      recipientsPhase2[_recipientsPhase2[i]] = false;
    }
  }
  
  //get the Remainder DropNum which can be claimed from now
  function getMicDollRemainCount() external view returns (uint){
    if(micDollContractAdress == address(0)){
      return 0;
    } else {
      return totalAirDropMicDoll - micDollClaimedCount;
    }
  }


  //claim MicDoll
  function claim() external whenNotPaused returns(uint){
    require(msg.sender.code.length == 0, "only EOA allowed");
    require(micDollContractAdress  != address(0), 'MicDoll address have not  been initialized by operator');
    require(totalAirDropMicDoll - micDollClaimedCount > 0, 'There are no airdrop micdoll is available now');

    if(micDollClaimedCount < 4000){
      require(recipientsPhase1[msg.sender] == true, 'recipient is not in the whitelist');
      recipientsPhase1[msg.sender] = false;
    } else {
      require(recipientsPhase2[msg.sender] == true, 'recipient is not in the whitelist');
      recipientsPhase2[msg.sender] = false;
    }

    uint tokenId = IERC721MicDollFreeMint(micDollContractAdress).freemint(msg.sender);
    emit claimedInfo(msg.sender,tokenId);
    micDollClaimedCount++;

    if(micDollClaimedCount==4000){
      _pause();
    }
    return tokenId;
  }
  
  //transfer operator
  function transferOperator(address newOperator) public {
      require(msg.sender == operator, 'only operator');
      require(newOperator != address(0), "new newOperator is the zero address");
      address oldOperator = operator;
      operator = newOperator;
      emit OperatorTransferred(oldOperator, newOperator);
  }

  //stop airdrop claim
  function pause() public {
    require(msg.sender == operator, 'only operator');
    _pause();
  }

  //start airdrop claim
  function unpause() public {
    require(msg.sender == operator, 'only operator');
    _unpause();
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }
}