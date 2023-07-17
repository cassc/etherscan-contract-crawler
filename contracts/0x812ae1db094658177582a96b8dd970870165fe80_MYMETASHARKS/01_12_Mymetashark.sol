//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// oldNFT 0x0B5Beca80CA90E1658cBfb5f72FFD2f47e14cE70 // geroli 0xe7dF6AAC7BC1965Ede1e5cB7c087A30A57Bc4C71
// new geroli 0x9cc6cd03d8ebbf90beb2683c8b449c24abf0ff62
//base uri  ipfs://QmPgzJks7HMKUzGR5swTYxNJAryujmqM94ZysTpFV6fCsN/
contract MYMETASHARKS  is ERC721,Ownable {

    IERC721 public GhettoSharkhood ;

    using Strings for uint256;

    string public baseTokenURI;
    string public SaleTokenURI;

    uint256 private constant TotalSupply = 10000;
    uint256 private constant TotalSwap = 2400;
    uint256 public hasSwap = 0;
    uint256 public TotalMint = 2400;

    uint256 public salePrice = 0.05 ether;
    bool private setSwap = false;
    bool private setPublicState = false;

    mapping(uint256 => bool)public Check_NFT_id_mint;

    constructor() ERC721("MYMETASHARKS", "MYMETASHARKS"){
        GhettoSharkhood = IERC721(0x0B5Beca80CA90E1658cBfb5f72FFD2f47e14cE70);
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory){
        if(_tokenId <= 2400){
           return string(abi.encodePacked(baseTokenURI,_tokenId.toString(),".json"));
        }
        else{
            return string(abi.encodePacked(SaleTokenURI,_tokenId.toString(),".json"));
        }
    }

    function totalSupply() public pure returns(uint256){
        return TotalSupply;
    }

    //onlyOwner function
    function setBaseURI(string memory baseURI) external onlyOwner{
        baseTokenURI = baseURI;
    }
     function setSaleTokenURI(string memory baseURI) external onlyOwner{
        SaleTokenURI = baseURI;
    }

    function setSwapStart(bool state) external onlyOwner{
        setSwap = state;
    }

     function setPublicSale(bool state) external onlyOwner{
        setPublicState = state;
     }

    function setPayAmount(uint256 amount) external onlyOwner{
        salePrice = amount;
    }


    function OwnerMint(uint256 amount,address receiver) external onlyOwner{
        require(TotalMint + amount <= TotalSupply,"sold out");
        for(uint256 a = 0;a<amount;a++){
            TotalMint++;

            _mint(receiver,TotalMint);
        }
    }

    // user function
    function ChooseShark(uint256[] calldata input,uint256[] calldata choose) external {
        require(setSwap,"Not start");
        uint256 inputAmount = input.length;
        require(input.length == choose.length,"Swap balance oblique");
        require(inputAmount > 0,"Can't not input under 1");

        for(uint256 a = 0 ;a < inputAmount;a++){
            require(GhettoSharkhood.ownerOf(input[a]) == msg.sender,"Not your NFT");

            if(Check_NFT_id_mint[choose[a]]){
                revert("NFT had been choose");
            }

            Check_NFT_id_mint[choose[a]] = true;
            GhettoSharkhood.transferFrom(msg.sender, address(this), input[a]);
            _mint(msg.sender, choose[a]);

        }

        hasSwap += inputAmount;
    }

    function mintNFT(uint256 amount)external payable{
        require(setPublicState,"Not start yet");
        require(salePrice * amount  == msg.value,"Incorrect payment");
        require(TotalMint + amount <= TotalSupply,"sold out");

        for(uint256 a = 0;a<amount;a++){
            TotalMint++;

            _mint(msg.sender,TotalMint);
        }


    }







}