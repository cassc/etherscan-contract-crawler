//SPDX-License-Identifier: Unlicense                                                                            
/* 

                               .!?:                                                                                                
                           .!Y#?:^~7YJ                                           
                           P5  !5Y  ..BP                                                                                    
                        YG.  ........   :#!                                         
                        :!YYYYYYYYYYYYYYJ~.                                         
                             ...........                                            
                        :!!!7YYYYYYYYYY?!!.                                         
                   .!JJJ???J~          :J???JJ~.                                    
                 ^7J~:::                  !?::!J7.                                  
                ?J7    .7Y???JJ~..      .:7JYY~.?Y!                                 
                #J   :??G#JJJ?.!5#?^ 77Y#[email protected]@&##@G!.                               
         .~JJJJ57: :[email protected]@@G?5~.7#GY#J7! [email protected]@@&[email protected]@5!.                             
       [email protected]:^?J^  [email protected]@@@&&@?  ....    [email protected]@@@@#@@&^!??:                           
       :@^ :[email protected]^[email protected]   P&@@@@@#7          Y&@@@@@#&&: [email protected]~                           
       :&^^&:!?J.J&.    ~JJJJ?.  .?J7 7J?. :JJJJJ:[email protected]^ [email protected]~                           
       :G!!G~G#  [email protected]~            :J!JP PP!J^       [email protected]: [email protected]~                           
         GG.7BB  ~J&PJJY~        .            [email protected]^!J?:                           
         :!YJBB    ^~~~PP?^.        .J:      5J~~^[email protected]:                             
             P#          [email protected]!               ..#?   [email protected]^                                                             
           .Y?~            ~77777777777777:       [email protected]:                                                             
           .#!                                      #?                              
           .#!             ~77777777! !777777.      B?                              
           .&!           ^B?~~~~~~~~!5!~~~~~~P!     #?                              
            J^           :5^         .       J~     J~ 

▓█████▄  █    ██  ███▄ ▄███▓ ██▓███      ▄▄▄       ██▓███  ▓█████   ██████ 
▒██▀ ██▌ ██  ▓██▒▓██▒▀█▀ ██▒▓██░  ██▒   ▒████▄    ▓██░  ██▒▓█   ▀ ▒██    ▒ 
░██   █▌▓██  ▒██░▓██    ▓██░▓██░ ██▓▒   ▒██  ▀█▄  ▓██░ ██▓▒▒███   ░ ▓██▄   
░▓█▄   ▌▓▓█  ░██░▒██    ▒██ ▒██▄█▓▒ ▒   ░██▄▄▄▄██ ▒██▄█▓▒ ▒▒▓█  ▄   ▒   ██▒
░▒████▓ ▒▒█████▓ ▒██▒   ░██▒▒██▒ ░  ░    ▓█   ▓██▒▒██▒ ░  ░░▒████▒▒██████▒▒
 ▒▒▓  ▒ ░▒▓▒ ▒ ▒ ░ ▒░   ░  ░▒▓▒░ ░  ░    ▒▒   ▓▒█░▒▓▒░ ░  ░░░ ▒░ ░▒ ▒▓▒ ▒ ░
 ░ ▒  ▒ ░░▒░ ░ ░ ░  ░      ░░▒ ░          ▒   ▒▒ ░░▒ ░      ░ ░  ░░ ░▒  ░ ░
 ░ ░  ░  ░░░ ░ ░ ░      ░   ░░            ░   ▒   ░░          ░   ░  ░  ░  
   ░       ░            ░                     ░  ░            ░  ░      ░  
 ░                                                                         
*/                                                                                  
                                                                                                                                                                                                                                                                                                                                                                                                                                
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DumpApes is ERC721A("Dump Apes", "DAPES"), Ownable, ReentrancyGuard{

    mapping(address => uint256) public _FreeDumpApesCount;
    mapping(address => uint256) public _DumpApesCount;
   
    uint256 public price = 0.005 ether;
    uint256 public MaxPerWallet = 3;
    uint256 public AllDumpApes = 10000;
    uint256 public TotalFreeDumpApes = 10000 ;
    
    string public uriPrefix = " ";
    string public uriSuffix = ".json";
    
     
    
    bool public Paused = true;
   
    uint public TotalFreeCount;

    constructor(){   
    }

    //Find Meeble include free Meeble 
    function DumpAllApes( uint256 _qty ) external payable nonReentrant {
        uint256 _AllDumpApes = totalSupply();
        require(!Paused, "Not yet, please wait to aump all that shit");
        require(_AllDumpApes + _qty <= AllDumpApes, "All Apes is Dumped");
        require(_DumpApesCount[msg.sender]+_qty <= MaxPerWallet, "Enough dont greedy, people want to Dump Apes");
        require(msg.sender == tx.origin, "Please be you self");
        //Free mint condition 
        uint _FreeCount = TotalFreeCount;
        
        if (_FreeCount < TotalFreeDumpApes){
        uint256 PayForCount = _qty ;
        uint256 FreeDumpApesCount = _FreeDumpApesCount[msg.sender];
            if(FreeDumpApesCount < 1)
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
                require(msg.value >= PayForCount * price, "Need more? Pay for it and dump this shit");
                
            _safeMint(msg.sender, _qty);
            _FreeDumpApesCount[msg.sender] = 1;
            _DumpApesCount[msg.sender] += _qty ;
        

        }
        else{
       require(msg.value >= _qty * price, "Need more? pay to Dump this shit");
        _safeMint(msg.sender, _qty);
        _DumpApesCount[msg.sender] = _qty;
        }
    }

     //Team also try to save Meeble 
    function TeamDumpApes() external onlyOwner {
        uint256 _AllDumpApes = totalSupply();
        require(_AllDumpApes+ 300 <= AllDumpApes, "Exceed Total DumpApes");
        require(_FreeDumpApesCount[msg.sender] <= 300 , "Team has already dumped apes");
        _FreeDumpApesCount[msg.sender] = 300;
        _safeMint(msg.sender, 300);
        
    }  

    function withdraw() public onlyOwner nonReentrant {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
    function LetsDumpItAll  () external onlyOwner {
        Paused = !Paused;      
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
     }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
       // if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI,_toString(tokenId+1),".json")) : '';
    }
    
    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }
     
 
}