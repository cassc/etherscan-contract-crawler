// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SabetORGNLS is ERC721A, Ownable {
  string public baseURI;
  address public signerAddress = 0x71688e5f22f818a31BC36BEcD1Fc83D198779b83;
  mapping(address => bool) public alreadyMinted;

  using ECDSA for bytes32;

  constructor() ERC721A('ORGNLS by SABET', 'ORGNLS') {}

  function mint(uint256 quantity, uint256 maxAllowed, bytes memory signature) public {
    bytes32 inputHash = keccak256(
      abi.encodePacked(
        msg.sender,
        maxAllowed
      )
    );

    bytes32 ethSignedMessageHash = inputHash.toEthSignedMessageHash();
    address recoveredAddress = ethSignedMessageHash.recover(signature);
    require(recoveredAddress == signerAddress, 'Bad signature');

    require(alreadyMinted[msg.sender] == false, 'Already minted');

    alreadyMinted[msg.sender] = true;

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
}