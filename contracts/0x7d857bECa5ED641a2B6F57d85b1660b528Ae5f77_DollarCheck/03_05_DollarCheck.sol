// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DollarCheck is ERC721A, Ownable  {

    uint256 public lastMintTime;
    //Mint Price
    uint256 public constant Price =  0.0006 ether;
    bool public isPublicSaleActive = false;
    string baseURI;
    bool public combineactive = false;
    address payable mintForwarder;
   
    constructor(address controller_,address payable mintForwarder_) ERC721A("DollarCheck", "DCH") {
      // Set payment information
       mintForwarder = mintForwarder_;
      // Transfer ownership to controller
      transferOwnership(controller_);
    }

    modifier validMint() {
            require(block.timestamp <= lastMintTime , "time over");
    _;
    }
    //mint
    function mint(uint quantity) public payable validMint {
        if (msg.value < quantity*Price)
          revert erc721Error.NotEnoughETH();
        if(!isPublicSaleActive)
            revert erc721Error.PublicSaleNotActive();
        handleMint(msg.sender, quantity);
    }

    function handleMint(address recipient, uint quantity) internal {
            _mint(recipient,quantity );
    }

   
   function combine(uint[] memory _tokens) public {
        require(combineactive, "combining not active");
        require(_tokens.length == 2, "Exactly two tokens are allowed as input");
        for (uint i = 0; i < _tokens.length; i++) {
            require(ownerOf(_tokens[i]) == msg.sender, "must own all tokens");
        }
        for(uint i = 0; i <_tokens.length; i++){
                 _burn(_tokens[i]);
        }    
       _mint(msg.sender,1);
        
   }

  



    /* ========== FUNCTION ========== */

     //enable public mint
     function setPublicMint(bool _active) external onlyOwner {
       isPublicSaleActive = _active;
       lastMintTime = block.timestamp + 365 days;
    }

    //enable time 
    function setTimer() external onlyOwner {
       lastMintTime = block.timestamp + 1440 minutes;
    }

    function withdraw() public {
        (bool success_,) = mintForwarder.call{value : address(this).balance}("");
        if (!success_) revert erc721Error.WithdrawTransferFailed();
    }
    
    //Set baseURI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

   //Burn Token
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
    
    //BurnMultiple Token
    function burnMultiple(uint256[] memory _tokenID) external onlyOwner {
        uint256 _length = _tokenID.length;
        for (uint256 i = 0; i < _length; i++ ) {
        _burn(_tokenID[i]);
        }
    }

   //BurnMultiple more token
   function BurnMultiple(
    uint from,
    uint to
    ) external onlyOwner{
        for(uint i = from; i < to; i++) {
                 _burn(i);
        }
    }

    //enable combine
     function setCombine(bool _active) external onlyOwner {
       combineactive = _active;
    }
   

 
    /* ==========RETURN FUNCTION ========== */

   function TimeLeft() public  view returns (uint256) {
       uint256 nextMintTime = lastMintTime;
        uint256 left = nextMintTime - block.timestamp;
        return left;
    }
     
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

}


contract erc721Error {
    error PublicSaleNotActive();
    error NotEnoughETH();
    error TokenDoesNotExist();
    error WithdrawTransferFailed();
    error UserLimitReached();
}