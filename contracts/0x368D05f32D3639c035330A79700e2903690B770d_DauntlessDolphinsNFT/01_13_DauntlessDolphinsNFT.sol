//SPDX-License-Identifier: MIT
/**
                                                     ,,,,                                                                   
                                                      ,,,,,,                                                              
                                                       ,,,,,,,,,                                                                
                                                        ,,,,,,,,,,,,,                                                            
                                                          ,,,,,,,,,,,,,,,                                                          
                                                           ,,,,,,,,,,,,,,,,                                                    
                                                             *,,,,,* ,,,,,,,,,,                                                     
                                                              &,,,,,,,,   % ,,,,,                                                          
                                                              ,*,,, ,,,,,,( ,,,,,                                                              
                                                              .%**,,,,,#@(/////////&@                                                  
                                                                .,*,,,,&//////////////#*                                            
                                                            @/////&&//////////////////////&                                         
                                                            %/////////////////////////////////&                                       
                                                        (/////////////////////////////////////&                                     
                                                        @///////////////////////////////////////&//                                   
                                                %///(///////////////////#//@@@//////////////&@@@@%                                 
                                            &//////@/////////////////////(@@@@@@@//////////@@@@@@@/                                 
                                        &/////////%/////////#/////////////@@@@@@@@///////////(#%%&@#@                                 
                                    @///////////%/////////##////////////////@@@@@%///////////////////////                        
                                    ///////(((///@//////###/////////////////////////////////////////////@.                        
                                            //////////####///////////////////       ////////////////////////////@                    
                                        [email protected]###(///////####//////////////////          #%%////////////////////#(&                      
                                            @///////#####////&/////////(              (#######&@@@@@%. .#*                          
                                            //////######////&/////////*@                  ,&##((((((((((%&%                         
                                            ////########////////////#@.            .,/.                  .                         
                                            %//(#######//(////////*&( ..              ..       ...                                  
                                            @/######@///////%/////....     *                         @@@@@@                             
                                            @/#######//////@//////@& ....... .     .               @@@@@@@@@@                      
                                            #//#####((////((/////@..........,/. .  &              @@@@     @@@@                  
                                            //#####///////#///@......     .  [email protected]                @@@.      @@@@                   
                                              //####%///////(///.. ..      .%. (  (                @@@      @@@@@                   
                                               @/#####%////////*.....             /                         @@@@@                    
                                                /#####///////**....    (##% /.                              @@@@                     
                                                //######/@///*@/ .,..            @                         @@@@                      
                                                 ///*#/%....  #,                                          @@@@                      
                                                %/#####//////// ...                                      @@@@*                      
                                                    #/#####///////*....         @                       *@@@
                                                    @/#####///////&...                                                        
                                                    (/#####///////(...       .                         @@@@@@.                     
                                                        ////////...      *                              @@@@             
                                                                                                                                    
                                                                                                                                                                                         
                                                        (((((((((((((((((((

               
$$$$$$$\                                 $$\     $$\                                     $$$$$$$\            $$\           $$\       $$\                     
$$  __$$\                                $$ |    $$ |                                    $$  __$$\           $$ |          $$ |      \__|                    
$$ |  $$ | $$$$$$\  $$\   $$\ $$$$$$$\ $$$$$$\   $$ | $$$$$$\   $$$$$$$\  $$$$$$$\       $$ |  $$ | $$$$$$\  $$ | $$$$$$\  $$$$$$$\  $$\ $$$$$$$\   $$$$$$$\ 
$$ |  $$ | \____$$\ $$ |  $$ |$$  __$$\\_$$  _|  $$ |$$  __$$\ $$  _____|$$  _____|      $$ |  $$ |$$  __$$\ $$ |$$  __$$\ $$  __$$\ $$ |$$  __$$\ $$  _____|
$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ |  $$ | $$ |    $$ |$$$$$$$$ |\$$$$$$\  \$$$$$$\        $$ |  $$ |$$ /  $$ |$$ |$$ /  $$ |$$ |  $$ |$$ |$$ |  $$ |\$$$$$$\  
$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |  $$ | $$ |$$\ $$ |$$   ____| \____$$\  \____$$\       $$ |  $$ |$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$ |$$ |  $$ | \____$$\ 
$$$$$$$  |\$$$$$$$ |\$$$$$$  |$$ |  $$ | \$$$$  |$$ |\$$$$$$$\ $$$$$$$  |$$$$$$$  |      $$$$$$$  |\$$$$$$  |$$ |$$$$$$$  |$$ |  $$ |$$ |$$ |  $$ |$$$$$$$  |
\_______/  \_______| \______/ \__|  \__|  \____/ \__| \_______|\_______/ \_______/       \_______/  \______/ \__|$$  ____/ \__|  \__|\__|\__|  \__|\_______/ 
                                                                                                                 $$ |                                        
                                                                                                                 $$ |                                        
                                                                                                                 \__|                                                                                                 
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract DauntlessDolphinsNFT is ERC721, ERC721Enumerable, Ownable{

    uint256 public constant MAXSUPPLY = 10000;
    uint256 public constant MAX_MINT_AMOUNT = 5;
    
    address public beneficiary;
    uint256 public totalNFTsoldAfterDrops = 0;
    uint256 public MINT_PRICE = 0.15 ether;
    uint256 public dropNumber = 0; 

    bool public normalMint = false; 

    mapping(address => mapping(uint256 => uint256)) public alreadyMinted;
    
    string private tokenBaseURI = ""; 
    string private hiddenPictureURI = ""; 

    constructor()
    ERC721("DauntlessDolphins", "DDC"){}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBeneficiary(address newBeneficiary) external onlyOwner{
        beneficiary = newBeneficiary;
    }

    function setBaseURI(
        string memory newBaseURI
    ) external onlyOwner{
        tokenBaseURI = newBaseURI;
    }

    function setHiddenPictureURI(
        string memory newBaseURI
    ) external onlyOwner{
        hiddenPictureURI = newBaseURI;
    }

    function setState(
        bool newState
    ) external onlyOwner{
        normalMint = newState;
    }

    function setDropNumber(
        uint256 drop
    ) external onlyOwner{
        dropNumber = drop;
    } 

    function setMINTPRICE(
        uint256 newPrice
    ) external onlyOwner{
        MINT_PRICE = newPrice;
    }

    function setTotalNFTsoldAfterDrops() onlyOwner external{
        totalNFTsoldAfterDrops = totalSupply();
    }

    function _baseURI() internal view override(ERC721) returns(string memory){
        return tokenBaseURI;
    } 

    function _HiddenURI() external view  returns(string memory){
        return hiddenPictureURI;
    } 
    
    function _getMintedAmount(address addy, uint256 drop) external view returns(uint256) {
        return alreadyMinted[addy][drop];
    }

    function tokenURI(uint256 tokenID) public view override(ERC721) returns(string memory){
        if(tokenID > totalNFTsoldAfterDrops){
            return hiddenPictureURI;
        }else{
            string memory result = super.tokenURI(tokenID);
            return bytes(tokenBaseURI).length > 0 ? string(abi.encodePacked(result, ".json")) : "";
        }
    }

    function mint(uint256 qty) external payable{
        uint256 soldNFT = totalSupply();
        require(normalMint == true , "Normal Mint is not active!");
        require(msg.value == qty*MINT_PRICE, "Ether Sent is incrrect!");
        require(qty <= 5 || qty >= 1, "Invalid Quantity");
        require(soldNFT + qty <= dropNumber*2000, "Sold Out");
        require(alreadyMinted[msg.sender][dropNumber] + qty <= MAX_MINT_AMOUNT, "NFT Mint limit reached/exceeded");

        alreadyMinted[msg.sender][dropNumber] += qty;
        for(uint256 i = 1; i <= qty; i++){
            _safeMint(msg.sender, soldNFT + i);
        }
    }
    
    function ownerMint(uint256 qty) onlyOwner external{
        uint256 soldNFT = totalSupply();
        for(uint256 i = 1; i <= qty; i++){
            _safeMint(msg.sender, soldNFT + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable (beneficiary).transfer(balance);
    }

}