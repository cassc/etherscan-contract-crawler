// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
 
import "@openzeppelin/[email protected]/token/ERC1155/ERC1155.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Strings.sol";
 
contract Desiverse is ERC1155, Ownable{
   using Strings for uint256;

   string public name = "Desiverse Founders Pass";
   string public tokenUri = "https://bafybeifkgtqmftnqer5kk7komdek5stkjdq653v3xncxgytiyk2bec7m24.ipfs.nftstorage.link/";
   uint256 private tokenPrice = 0.001 ether;
   uint256 public totalPasses = 1111;
   uint256 public tokenCounter = 1;

    struct TokenInfo {
       uint256 id;
       address owner;
       uint256 timestamp;
    }

    mapping(uint256 => TokenInfo) tokenInfos;
    uint256 transfered = 0;

   constructor() ERC1155(tokenUri) {}
 
   function setURI(string memory newuri) public onlyOwner {
       _setURI(newuri);
       tokenUri = newuri;
   }
 
   function mint(address account, uint256 id, uint256 amount, bytes memory data)
       public
       onlyOwner
   {
       _mint(account, id, amount, data);
   }

   function ownerMint(uint256 howMany) public onlyOwner {
       if(tokenCounter <= totalPasses){
            for (uint64 i = 0; i < howMany; i++) {
                uint256 tkId = tokenCounter;
                _mint(msg.sender, tkId, 1, "");
                tokenCounter++;
            }
       }
   }
 
   function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
       public
       onlyOwner
   {
       _mintBatch(to, ids, amounts, "");
   }

   function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) override virtual public {
       TokenInfo memory info = TokenInfo(id, to, block.timestamp);
       tokenInfos[transfered]=info;
       super.safeTransferFrom(from, to, id, amount, data);
       transfered++;
   }

   function getAllOwners() public view onlyOwner returns (TokenInfo[] memory){
        TokenInfo[] memory ret = new TokenInfo[](transfered);
        for (uint i = 0; i < transfered; i++) {
            ret[i] = tokenInfos[i];
        }
        return ret;
   }
 
   function uri(uint256 _tokenId) override public view returns (string memory){
      return string(abi.encodePacked(tokenUri, Strings.toString(_tokenId), ".json"));
   }

   function contractBalance() public view onlyOwner returns (uint256){
       return address(this).balance;
   }

   function withdraw(address to) public payable onlyOwner {
    // =============================================================================
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(to).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}