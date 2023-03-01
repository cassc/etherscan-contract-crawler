// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract SabetTKPBB is DefaultOperatorFilterer, ERC721A, Ownable {
  string public baseURI;
  address public signerAddress = 0x71688e5f22f818a31BC36BEcD1Fc83D198779b83;
  uint public saleState = 0;
  uint public maxAllowed = 5;

  using ECDSA for bytes32;

  constructor() ERC721A('TOKYO PUNKS | BAD BUNNIES by SABET', 'TKPBB') {}

  function mint(uint256 quantity, bytes memory signature) public payable {
    require(saleState > 0, 'Sale not started');
    require(quantity <= maxAllowed, 'Too many tokens');
    require(quantity > 0, 'Must mint at least 1 token');
    if (saleState < 3) {
      bytes32 inputHash = keccak256(
        abi.encodePacked(
          msg.sender,
          quantity
        )
      );
      bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
      address recoveredAddress = ethSignedMessageHash.recover(signature);
      require(recoveredAddress == signerAddress, 'Bad signature');
    }


    require(msg.value >= (quantity * (70000000000000000 + (saleState - 1) * 10000000000000000)), 'Incorrect value sent');


    _mint(msg.sender, quantity);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseUri(string memory baseuri_) public onlyOwner {
    baseURI = baseuri_;
  }

  function ownerMint(address to, uint256 quantity) public onlyOwner {
    _mint(to, quantity);
  }

  function setSignerAddress(address signerAddress_) public onlyOwner {
    signerAddress = signerAddress_;
  }

  function setSaleState(uint saleState_) public onlyOwner {
    saleState = saleState_;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}