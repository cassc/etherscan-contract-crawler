// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/*

*/
error InvalidTokenId();
error NotAuthorized();
error SoldOut();
error MaxMints();
error SaleNotStarted();
error ArraysDontMatch();
error CantMintZero();
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";




contract DuckPass is ERC1155, ERC1155Supply, Ownable {
    using ECDSA for bytes32;
    using Strings for uint;


  /*///////////////////////////////////////
                  VARIABLES
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  uint constant boneducksPassId = 0;
  uint public maxSupply = 3583;
  string public name;
  string public symbol;
  address private signer = 0x6884efd53b2650679996D3Ea206D116356dA08a9;
  enum SaleStatus{INACTIVE, ACTIVE}
  SaleStatus public saleStatus = SaleStatus.ACTIVE;
  string baseUri = "ipfs://QmaUBchiaSDxTEnxHP2a7JcrEzEaZXm6ofyo2hV7qYAdLG";

  //Mints carry over on each sale
  mapping(address => uint) public tokenMints;

  /*///////////////////////////////////////
                  CONSTRUCTOR
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  constructor() ERC1155("") {
    name = "Duck Survival Pass";
    symbol = "BDP";
    _mint(msg.sender,boneducksPassId,1,"");

  }


  /*///////////////////////////////////////
                    MINTING
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  function airdrop(address[] calldata accounts, uint[] calldata amounts) external onlyOwner {
    if(accounts.length != amounts.length) revert ArraysDontMatch();
    for(uint i; i<accounts.length; i++){
        if(totalSupply(boneducksPassId) + amounts[i] > maxSupply) revert SoldOut();
        _mint(accounts[i],boneducksPassId, amounts[i],"");
    }  
  }
  function verifyForSale(string memory phase,uint max,address account,bytes memory signature) internal view returns(bool) {
    bytes32 hash = keccak256(abi.encodePacked(phase,max,account));
    return signer == hash.toEthSignedMessageHash().recover(signature);
  }

  function mint(bytes memory signature) external  {
    if(totalSupply(boneducksPassId) + 1 > maxSupply) revert SoldOut();
    if(tokenMints[msg.sender] + 1 > 1) revert MaxMints();
    if(saleStatus != SaleStatus.ACTIVE) revert SaleNotStarted();
    if(!verifyForSale("BDC",1,msg.sender, signature)) revert NotAuthorized();
    tokenMints[msg.sender] += 1;
    _mint(msg.sender,boneducksPassId,1,"");
  }

 



  /*///////////////////////////////////////
                  SETTERS
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/

function setBaseURI(string memory newUri) public onlyOwner {
  baseUri = newUri;
}

  function turnClaimOn() external onlyOwner{
    saleStatus = SaleStatus.ACTIVE;
    }

    function turnAllSalesOff() external onlyOwner{
    saleStatus = SaleStatus.INACTIVE;
  }

  function setMaxSupply(uint max) external onlyOwner {
    maxSupply = max;
  }
  function setSigner(address newSigner) external onlyOwner {
    signer = newSigner;
  }




  /*///////////////////////////////////////
                  METDATA
  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
  function uri(uint _id) public override view returns (string memory) {
    if(_id != boneducksPassId) revert InvalidTokenId();
    return baseUri; 
  }



  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
  internal
  override(ERC1155, ERC1155Supply)
{
  super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
}


}