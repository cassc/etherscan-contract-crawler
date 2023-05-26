// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable2Step.sol";


interface ERC20 {
  function transferFrom(address account, address to, uint256 amount) external returns(bool);
}

contract LaundryMatts is ERC721, Ownable2Step {

  uint256 public constant START_TIME = 1680328800;
  uint256 public constant PRICE = 548.93 ether;

  address public beneficiary;

  string public videoMetadata;
  string public pictureMetadata;

  event Laundered_Money(address account);
  event Video_Metadata(string metadata);
  event Picture_Metadata(string metadata);
  event New_Beneficiary(address beneficiary);

  constructor(address _beneficiary) ERC721("One Million Dollars Laundered", "OMDL") {
    beneficiary = _beneficiary;
  }

  function mint() external payable {
    require(block.timestamp > START_TIME);
    require(msg.value >= PRICE);
    
    _mint(msg.sender, 1);
    _mint(msg.sender, 2);

    if(msg.value > PRICE) {
      payable(msg.sender).transfer(msg.value - PRICE);
    }

    payable(beneficiary).transfer(address(this).balance);

    emit Laundered_Money(msg.sender);
  }

  function tokenURI(uint256 tokenId) public view override returns(string memory) {
    if(tokenId == 1) return videoMetadata;
    if(tokenId == 2) return pictureMetadata;

    return "";
  }

  function changeBeneficiary(address newBeneficiary) external onlyOwner {
    require(newBeneficiary != address(0));

    beneficiary = newBeneficiary;

    emit New_Beneficiary(newBeneficiary);
  }

  function setVideoMetadata(string memory newMetadata) external onlyOwner {
    videoMetadata = newMetadata;

    emit Video_Metadata(newMetadata);
  }

  function setPictureMetadata(string memory newMetadata) external onlyOwner {
    pictureMetadata = newMetadata;
    
    emit Picture_Metadata(newMetadata);
  }
}