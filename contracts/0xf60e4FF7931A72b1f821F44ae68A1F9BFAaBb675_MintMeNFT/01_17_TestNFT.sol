// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract MintMeNFT is ERC721, Ownable,DefaultOperatorFilterer {
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    string internal baseTokenUri;
    bool internal claimPaused = true;
      address internal claimToken = 0x24E5d11156774F55D05D713Ff521B66d240CB5d9;
    uint256 internal amountClaim ;
    address payable public withdrawWallet;
    bool  public revealed;
    mapping(address => uint256) public walletMints;

    constructor() ERC721("piXeL PePe", "piXeLPePe") {
        mintPrice = 0.004 ether;
        totalSupply = 0;
        maxSupply = 4321;
        maxPerWallet = 5;
        withdrawWallet = payable(msg.sender);
        revealed = false;
        isPublicMintEnabled=true;
    }
    function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
    }
    function setIsPublucMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function setBasedTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }
     function claim() public {
    
    require(claimPaused == false , "claim paused");
    uint256 amount = IERC20(claimToken).balanceOf(msg.sender);
    require(amount > 0 , "you should be an owner of NFT");
    
    IERC20(claimToken).transfer(msg.sender,amountClaim * amount);
    }
    function claimPause(bool _pause) public onlyOwner{
    claimPaused = _pause;
   }
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }
    function tokenURI(uint256 tokenId_) public view override returns (string memory){
        require(_exists(tokenId_), "Token does not exist!");
        if(revealed == false)
        {
            return string(abi.encodePacked(baseTokenUri));
        }
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{value: address(this).balance } ('');
        require(success, "withdraw failed");
    }
    function mintOwner(uint256 quantity_) public onlyOwner {
        require(isPublicMintEnabled, "minting not enabled");
       
        require (totalSupply + quantity_ <= maxSupply, 'sold out');
       

        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
       
    }
    function mint(uint256 quantity_) public payable {
        require(isPublicMintEnabled, "minting not enabled");
        if(balanceOf(msg.sender)==0)
        {
        require(msg.value == (quantity_ - 1) * mintPrice, "wrong mint value");
        }
        else
        {
          require(msg.value == quantity_  * mintPrice, "wrong mint value");  
        }
        require (totalSupply + quantity_ <= maxSupply, "sold out");
       

        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
       
    }
}