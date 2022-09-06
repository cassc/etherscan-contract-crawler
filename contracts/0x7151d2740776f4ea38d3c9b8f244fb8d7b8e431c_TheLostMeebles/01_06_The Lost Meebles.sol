//SPDX-License-Identifier: Unlicense                                                                            
/*                                                                                                    
                                        /////////                                         
                            ,,,,,*    ...       ...../****(                               
                    ##%*,,,,                               **(####%*                      
                    /,  /                                      %                          
                     ,//                                       /%%%                       
                    ((/              *#@##(*           .*#@#(/*./#%(                      
                   %%#/    /         /##/, #           ,/##/ *# ,./%*                     
                  %/        @         &&   &&/           &&  /&&   /%%                    
                 %/         @@         &&&&&              &&&&&     /%%*                  
              *%(.          ,(((                (%%%%             (./%*                  
               *%/             .*%***             *(%*          *(%* /%*                  
                 %/                    %%%%%%*    %%%%    %%%%%      /%*                  
                   (,.                                           ,//%                     
                    .*##...                                    *#/..                      
                       **(%,                                ,/#*                          
                       %,.                                  *(%                           
                    %%%,                                     ,/%                          
                   %*,                                       ,/((,                        
                 *%(.                                          /#(*                       
               *%%,                                              ,/%                      
              %%%,                                               ,//%                     
              %(,                                                  /((                    
             %,.                                                    /%                    
             %,.                                                     /% 
             
▄▄▄▄▄ ▄ .▄▄▄▄ .    ▄▄▌        .▄▄ · ▄▄▄▄▄    • ▌ ▄ ·. ▄▄▄ .▄▄▄ .▄▄▄▄· ▄▄▌  ▄▄▄ ..▄▄ · 
•██  ██▪▐█▀▄.▀·    ██•  ▪     ▐█ ▀. •██      ·██ ▐███▪▀▄.▀·▀▄.▀·▐█ ▀█▪██•  ▀▄.▀·▐█ ▀. 
 ▐█.▪██▀▐█▐▀▀▪▄    ██▪   ▄█▀▄ ▄▀▀▀█▄ ▐█.▪    ▐█ ▌▐▌▐█·▐▀▀▪▄▐▀▀▪▄▐█▀▀█▄██▪  ▐▀▀▪▄▄▀▀▀█▄
 ▐█▌·██▌▐▀▐█▄▄▌    ▐█▌▐▌▐█▌.▐▌▐█▄▪▐█ ▐█▌·    ██ ██▌▐█▌▐█▄▄▌▐█▄▄▌██▄▪▐█▐█▌▐▌▐█▄▄▌▐█▄▪▐█
 ▀▀▀ ▀▀▀ · ▀▀▀     .▀▀▀  ▀█▄▀▪ ▀▀▀▀  ▀▀▀     ▀▀  █▪▀▀▀ ▀▀▀  ▀▀▀ ·▀▀▀▀ .▀▀▀  ▀▀▀  ▀▀▀▀ 

*/                                                                                  
                                                                                                                                                                                                                                                                                                                                                                                                                                
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheLostMeebles is ERC721A("The Lost Meebles", "Meeble"), Ownable, ReentrancyGuard{

    mapping(address => uint256) public _FreeMeebleCount;
    mapping(address => uint256) public _MeebleCount;
   
    uint256 public price = 0.006969 ether;
    uint256 public MaxSavePerWallet = 6;
    uint256 public MeebleCreatures = 6969;
    uint256 public TotalFreeMeeble = 3000 ;
    
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMeebleUri = "https://bafybeigtnwxzfn7f7bhzgdh36isseoa5to5daz4tuzdeg66jsv5lubypwu.ipfs.dweb.link/";
     
    bool public revealed = false;
    bool public Paused = true;
   
    uint public TotalFreeCount;

    constructor(){   
    }

    //Find Meeble include free Meeble 
    function FindMeeble( uint256 _qty ) external payable nonReentrant {
        uint256 _MeebleCreatures = totalSupply();
        require(!Paused, "The meeble creatures is not ready to be found");
        require(_MeebleCreatures + _qty <= MeebleCreatures, "All lost Meeble has been found");
        require(_MeebleCount[msg.sender]+_qty <= MaxSavePerWallet, "You have found enough Meeble, let others find it ");
        require(msg.sender == tx.origin, "Please be you self");
        //Free mint condition 
        uint _FreeCount = TotalFreeCount;
        
        if (_FreeCount < TotalFreeMeeble){
        uint256 PayForCount = _qty ;
        uint256 FreeMeebleCount = _FreeMeebleCount[msg.sender];
            if(FreeMeebleCount < 1)
                {
                    if(_qty > 1)
                    {
                        PayForCount = _qty - 1 ;
                    }
                    else
                    {
                        PayForCount = 0;
                    }
                    TotalFreeCount += 1 ;
                }
                require(msg.value >= PayForCount * price, "You don't have enough Ether to save this Meeble amount");
                
            _safeMint(msg.sender, _qty);
            _FreeMeebleCount[msg.sender] = 1;
            _MeebleCount[msg.sender] += _qty ;
        

        }
        else{
       require(msg.value >= _qty * price, "You don't have enough Ether to save this Meeble amount");
        _safeMint(msg.sender, _qty);
        _MeebleCount[msg.sender] = _qty;
        }
    }

     //Team also try to save Meeble 
    function TeamSaveMeeble() external onlyOwner {
        uint256 _MeebleCreatures = totalSupply();
        require(_MeebleCreatures + 169 <= MeebleCreatures, "Exceed Total Meeble");
        require(_FreeMeebleCount[msg.sender] <= 169 , "Team has already found Meeble");

        _safeMint(msg.sender, 169);
        
    }  

    function withdraw() public onlyOwner nonReentrant {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
    function startfinding  () external onlyOwner {
        Paused = !Paused;      
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
     }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
       // if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return bytes(hiddenMeebleUri).length != 0 ? string(abi.encodePacked(hiddenMeebleUri,_toString(tokenId+1),".json")) : '';
        }
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI,_toString(tokenId+1),".json")) : '';
    }
    function setCover(string memory _hiddenMeebleUri) public onlyOwner {
        hiddenMeebleUri = _hiddenMeebleUri;
    }
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }
     
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }   
}