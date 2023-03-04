// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7b3e7b7055d6e1226d4920ca7d7c446c0c0bfff5/contracts/utils/cryptography/MerkleProof.sol";

contract BbooomNft is ERC721,Ownable,DefaultOperatorFilterer {


  // Constants
    uint256 public  MINT_PRICE = 77000000000000000;
    bool public MINT_STATUS = false;
    bytes32 public merkleRoot;
    mapping(address => bool) use;
    uint constant public TOKEN_LIMIT = 5400;
    uint[TOKEN_LIMIT]  indices;
    uint  nonce;
    uint  index;
    struct drop_data{
        address drop_address;
        uint256 tokenId; 
    }

  /// @dev Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;

    constructor() ERC721("BBOOOM", "BBOOOM") {
          baseTokenURI = "ipfs://bafybeigsvava7nahkjiaypnxvw6cdzkx2bxznomuyj3egywiy75ly5bxam/";
    }

    function drop(drop_data[] calldata dropDataList) public onlyOwner{
        for(uint i = 0; i< dropDataList.length; i++){
            uint256 tokenId = randomIndex(dropDataList[i].tokenId);
            _safeMint(dropDataList[i].drop_address,tokenId);
            use[dropDataList[i].drop_address] = true;
        }
    }

    function mint(bytes32[] calldata _merkleProof) public payable returns (uint256){
        require(!use[msg.sender], "You have already minted");
        require(MINT_STATUS,"Mint is not turned on");
        require(checkMerkle(_merkleProof, _msgSender()), "Invalid merkle proof");
        require(msg.value >= MINT_PRICE, "Transaction value did not equal the mint price");
        uint256 newItemId = randomIndex(0);
       _safeMint(msg.sender,newItemId);
        use[msg.sender] = true;
        return newItemId;
    }



    function getMerkleLeaf(address _address) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_address));
    }

    function checkMerkle(bytes32[] calldata _merkleProof, address _address) private view returns (bool)
    {
        return MerkleProof.verify(_merkleProof, merkleRoot, getMerkleLeaf(_address));
    }

  function randomIndex(uint tokenId) public returns (uint) {
        uint totalSize = TOKEN_LIMIT - nonce;
        if(tokenId == 0){
            index = uint(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % totalSize;
        }else{
            index = tokenId -1;
        }
        uint value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }
        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value+1;
  }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner{
    baseTokenURI = _baseTokenURI;
  }

   function setMintStatus(bool status) public onlyOwner{
    MINT_STATUS = status;
  }
   function setPrice(uint256 price) public onlyOwner{
    MINT_PRICE = price;
  }
  

  /// @dev Overridden in order to make it an onlyOwner function
  function withdrawPayments() public onlyOwner virtual {
      address payee = owner();
      uint256 payment = address(this).balance;
      payable(payee).transfer(payment);
  }


   function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


}