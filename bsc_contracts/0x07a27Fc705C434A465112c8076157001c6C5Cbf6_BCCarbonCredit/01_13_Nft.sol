// SPDX-License-Identifier: Unli
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BCCarbonCredit is ERC721, ERC721Burnable, Ownable {

    uint256 public tokenIdCounter = 0;
    address payable public  platfromfeeAccount; // the account that receives fees
    uint public  platfromFee = 10; // the fee percentage on sales 
   
    uint256 public mintPrice = 0.045 ether; 

    event publicMinting(
        uint indexed tokenId,
        uint price,
        address indexed cpo,
        address indexed buyer,
        uint platformfee,
        uint platformfeeAmount,
        uint cpoAmount
    );

    event privateMinting(
        uint indexed tokenId,
        address indexed cpo,
        address indexed buyer
    );

    constructor() ERC721("BC Carbon Credit", "BCCC") {}

        // editable platform Fee and platformFee Account 

    function setPlatformFeeAccount(address _platfromfeeAccount) external onlyOwner{
        platfromfeeAccount = payable(_platfromfeeAccount);

    }

    function setPlatformFeePercentage(uint _platfromFee) external onlyOwner{
        require(_platfromFee < 100, "Platform fee cannot be greater than 100%.");
        platfromFee = _platfromFee;

    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }


    function getMintPrice() view public returns(uint){
        return((mintPrice*(100 + platfromFee ))/100);
    }


    function _baseURI() internal pure override returns (string memory) {
        return "https://api.beachlab.app/nft/";
    }

    function mint(address to,address _cpo) public payable {
        uint price = getMintPrice();
        require(msg.value == price, "Incorrect minting price");
        tokenIdCounter++;
        _safeMint(to, tokenIdCounter);
        if (platfromFee > 0){
        uint platfromFeeAmount = msg.value * platfromFee/100 ;
        uint cpoAmount = msg.value - platfromFeeAmount;
        payable(_cpo).transfer(cpoAmount);
        platfromfeeAccount.transfer(platfromFeeAmount);

        emit publicMinting(tokenIdCounter,price,_cpo,to,platfromFee,platfromFeeAmount,cpoAmount);

        }else{
        payable(_cpo).transfer(msg.value);
        emit publicMinting(tokenIdCounter,price,_cpo,to,platfromFee,0,msg.value);
        }

    }

    

    function privateMint(address to,address _cpo) public onlyOwner {
    
     tokenIdCounter++;
    _safeMint(to, tokenIdCounter);

    emit privateMinting(
        tokenIdCounter,
        _cpo,
        to);
    }



    function retire(uint256 tokenId) public {
        require(_exists(tokenId), "Token ID does not exist");
        require(ownerOf(tokenId) == msg.sender, "Only the token owner can retire the token");

        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }



}