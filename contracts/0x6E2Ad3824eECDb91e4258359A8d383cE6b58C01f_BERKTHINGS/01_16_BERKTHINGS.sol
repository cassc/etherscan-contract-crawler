//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import './ERC2981ContractWideRoyalties.sol';

/*

berk aka princesscamel aka godbastard presents

artbasketshit things

random stuff / audio / video / audiovisual / conceptual / composition / intermedia / glitch / databending / codebending / noise / recontextualizing / remix / bullshit / fun

https://berkozdemir.com 

@berkozdemir


                       '*|||||||||l}ll}}ll}t                               }]*\;;\+=11?lilllll})||||||||*`          }illlll}}=                                         
                       '*|||||||||}lll}}ll}t                              '+;::::---:;;|+=1?il})||||||||*`          }illlll}}=                                         
                       '*|||||||||llll}}ll}t                           ':*|;;;;::::::::;;|||*)1+\|||||||*`          }ll}lll}}=                                         
                       '*|||||||||llll}}lllt                         -*)))))=)*|**+**+**===)=))*;;;|||||*`          }illlll}}=                                         
                       '*|||||||\|l}lll}ll}t                      `|)=)1ll1]>=)=))==1>==>>]>>1i?]==*;\||*`          }llllll}}=                                         
                       '*|||||||\|}ll}l}lllt                    .*?tr}}}tr}i1]=)+=)]111]]111illlliii]|;|+`          }ll}l}l}l=                                         
              .'''''''',}i????????uu333u33uL`                 .|ilrrvvttrtt}l]==]]1ill?ili?ir}ttvvttl=]=?.          u3u33333ot                                         
             `--,,-,-,";o3333cc33chZTZZZZZZP^               .|1rttttc3cItvt}}l1111>*)++==)1}trtr}t}}r}?1}:         .ahhZZhhhhL          ..........`                    
             `-,,----,_;o333cc3ccchTTZZZZZZP^             `*tcIt}}vc3cvvvccLooo&a&n3ccuouLcri?>1?1]???1i?l=~       .aZhZZZZhho          ..........`                    
             `--,----,";o3333c333chZZZhZhhZP^            "toIv}tuooLol}t>;;;+==):-"~-:--:)*)]rrl1i}}li1?lttr*'     .aZhZZhZhho          ..........`                    
             `--",---,";o333cc33cchZZZZZZZhP^           |cuuvtro&YoY&]]1;^^~:::-^^^`  `'''    *>=1}r}aoIvccvti^    .aThZZZZZZo          ..........`                    
                        .'.'''''''---------:           :vcvvIvcLLclr=``'`   '..-}tt;^^:IIIr}l=```````n&&utttrvr     ---------^                                         
                                                       }tcccu3o3a3|*:```````...-??i;,,:rr}}li=.``````tvvi))>YVu*                                                       
                                                     ^tcuu3ooLPOO*   `''^----::-~~^-:::-::----::::---...`   lVYVt                                                      
                                                    -33o333oonODD*   ...~---::::---:::::::----:---,,,```    l0&YO0'                                                    
                                                   iooocIt3uoLOOO*   ^^^,::::;;;::::::::::::::---_^^^       laat:=&3:                                                  
                                                  )uvvvrtYY3ooaaT;      `.''....^^^.'''`'`````              >YYt:--1&)                                                 
                                                 ]vvcItohY}uooV&0:       ` ``````''`                        )oot:-^.-Tv.                                               
                                                lvvcccYtti>>>====+\\|*++*++*|*|\:::|=)+;;;:::::::::::::::;;;1}}?-^^^.|Tt'                                              
                                              ^IIrtoTV}l}}>))))))=>=>1]]]>>==)=)|||=?i]***\;:;|||****+++)==>i}l}-^^^.`;a]                                              
                                             :tlrIo0};}+))=]]1l}}1+**+**|;;\|||)l}}}}}=::::::;|||)111}rr1)))tcco:`''^``}0:                                             
                                           .:1ivcnc+|]t*+)=>>]ill]++***|****|**)l}}}rt1:::;;;\**+)]>1Ivvl)))v3cu|```. `_&I.                                            
                                  ........-1Io&0l**+*=i||\)===1??>))+;;;)ii?=)+=ilitccr+*+)))=>]]>===3oot=)=cnLu+```` ` >a)..`                                         
                        `         .....`,loVv=\;|;:::=1;\:||||\||;:::-:::;\\::::---1ccl;;;:::::;;;::\=1?\---lvvr)' ``   ^Zv,.`                                         
                                  .....\cc?;-::----,:++;;:;;;;:::-,,-,-------__^.'`+u3i:---"",------:;|*-`'')}}]:^   ``  un:.`                                         
                        `         ...,1;.^--,,,_~,,-:+)))+:_~_",-"^~^....^^^...`   :cv>-_""_~_~~~_"--*=>;~~~```.++;. `   ia;.`                                         
                        ``````````~^"1+."--^..^^^^"-:;:==):^^~",-,~~^''.'''''''    ,}}+-_",,,-__",--:*==;"_^   `111.     =T*~'                                         
                        ----,,----;;r}^~,^.```^^..^_*;:::;)==)|||;::::::               ***:--::::)}}}          .oLL_     )a1\:                                         
                        ----------\=3-``^..'`''_...:;-:**|)1?1)+)|:::;;;               +));::::;;=ttr          .Y&V_     >&>|:                                         
                        ----------;1}  _-``````..^^;:-::;:+}}l===*:::;;;               ;;;:------\r}}          ^Zhh-     to+|:                                         
                        ----------:1] '-_`````''.^_-_,-:--)vttrrr:   ```               '..```````.:::```    ,::)&&&-    ^0I|\:                                         
                        ----------:?\ `-.`````''`.,..-:::;1cvv3uu~       ...`   ```               `'''''`  `133uLLn~    lai|\:                                         
                        ----------;}: `,.` `'`````~.-||;|:=cccuuu-   `'`berkberkberk-             ````'..````vaT}^"^`   ;DY=||:                                         
                        ----------;l- `^`` `.``'''',|||*|-*3ccuoo:   ~_berkberkberk;       ``````````'..````cOO] `     >PI|||:                                         
                        ----------:1:  '``  ```'.``.-:::-^|ooucc3;  `--,----_^^.```           `'''...```````cOP> ` ``  na1;\|:                                         
                        ----------;1*  ```  ```'....---^'`|LLo33u|```---~...```               `''....```````cOO]   `  -Oc);\|:                                         
                        ----------\*r   ````     .`._..'`.+VV&Zhh1..."""^...`                `...^~__```````oXX)      >Pc*;;\:                                         
                                  --?`  `` `      `......^)YnYaaa>...,,,^...```            ```...^^~^``````'ngd+     -DO0I=;. --:::::::-                               
                                  -->-  .``      ``...``..|3333c3*..^:::-~~^.''`          `'''.......````...&EE=     DDPaaa00V3c}=+|\;|:                               
                                `-}uVc` `````     `...```.*u333uu*''.^^^_---^..'   ```    ````'''```````.^~_aEm=    tOhaaa0V&aaYnLncl]):                               
                             -+}vuonna:           `.'`````*uu33uu*''`'''^:--_^^.``````     ```'''` ``'..^,--amm=   -bha0aaZaaTaanVVVnnoc:                              
                          `:vItc3n&a0aV`         `..`  ```*LooZhh?^^^^^^^""_~^^^...'''``````'`       _""-:::TO&;  :POhZZaahhZaaa0aTha&&0Yn3]^                          
                        -]3nVYoVV0ThZTho`   `     `'`    .]YLnOOO}__~__~~~^^^^^^......'```'''`       ---::::~    "@PPOOOZZTaZhhhZha0VVaZTaaaaY1.                       
                     ,1tc3LoLVLnn0hhhOPP3   ``    `      -}00&aaar:::^^^^^.................'.`    ```;\\\:,'     0OPOOOOZTTaZhhhhPhZaVY&&a&V&aaVol-                    
                  :rcoccuunYYV0V0ThhODOPO|     `  `      "]Ir}}}t?+);^^......''......^....````    ''.|*+'      '[email protected]&&&000&o>`                 
                +3Y&Y&YYLV0&0&&&[email protected]@r              ^^.^^` `}a0I''`````````'''^__^...       `-:-}c]    `;[email protected]&VV00aTTao`               
               tVL&a0YYYV000&[email protected]             .`   ` ^ca0r~^^.```````''...^:}l}*:::`  ^|||rv. ^[email protected]              
              vaaaZZT&&[email protected]:            ``     _l0Ou:::^````````'''..|HHqZLYv' `->===\|&[email protected]&)             
            '[email protected]            `    `-=thYt\--;::.```   :?iIYVV0TZu^.'-*;;[email protected]@OOPaaaaPODPZT000o:           
           :[email protected]@@SbSXXXdddo                 ^,=|IZTL*;1]=^```   |VVLvvv&hho"^-:::-`|[email protected]@DDPhTTPDDOTZTaaaVo3-         
          [email protected]\                ^-}+-ohh&tOOOYoLv\;;vZZo)=)LOhv:[email protected]@[email protected]@ZZZOhTaZTTThhZ&u.        
        [email protected]               `.~1\ ^vhPYPPhnu3};;;}ooI*+*oOo*,___"-^:[email protected]@[email protected]@SDPPDOZZhhhPOOOh0n_       
       :[email protected]@`                `+|   *aY0Y?:.`        ``'-;--,__~:i [email protected]@@@[email protected]^      
      [email protected]@@[email protected]` .'`           ^)|     *nTh0I:^         `'^^_~-\th- [email protected]@[email protected]@@[email protected]@@[email protected]&:     
      cahhOOOOhDXbbbbbbXSbbSbbbdXXgddgddddXXdgdS]':.`           :):`     `*naPTt:.     `'..~:=I0OOo [email protected]@[email protected]@@@@[email protected]@@[email protected]@[email protected];    
     [email protected]@@DXbXdXbSXbSbbddgXbdgggddddggdgdgdXa*             ,=|         |YZZ&v;~'  '~;>c&hPho) :[email protected]@[email protected]@DSbbXSbXDDDOOhPOPha-   
    cTZhhOOOSbbbXddXddbbSbbXXdddXdgdgddddddXgdggXbO`            `|).          ;YaZ0oi+}c&hZhac],` `[email protected]@[email protected]@[email protected]@OOOOhOOPZL   
  ^[email protected]            :*~            iaa0aTZhZo>-`  ` '[email protected]@[email protected]@OhOOOPOl  
 [email protected]@[email protected];           ~=-             :n0a&t;'        |[email protected]@[email protected]@[email protected]@[email protected]+ 
:&[email protected]@[email protected]           |-`             .i:`          `[email protected]@[email protected]@[email protected])


 /$$                           /$$                                                                                       
| $$                          | $$                                                                                       
| $$$$$$$   /$$$$$$   /$$$$$$ | $$   /$$                                                                                 
| $$__  $$ /$$__  $$ /$$__  $$| $$  /$$/                                                                                 
| $$  \ $$| $$$$$$$$| $$  \__/| $$$$$$/                                                                                  
| $$  | $$| $$_____/| $$      | $$_  $$                                                                                  
| $$$$$$$/|  $$$$$$$| $$      | $$ \  $$                                                                                 
|_______/  \_______/|__/      |__/  \__/                                                                                 
                                                                                                                                                                                                                                                                                                                                                                  
           /$$                                                                                                           
          | $$                                                                                                           
  /$$$$$$ | $$   /$$  /$$$$$$                                                                                            
 |____  $$| $$  /$$/ |____  $$                                                                                           
  /$$$$$$$| $$$$$$/   /$$$$$$$                                                                                           
 /$$__  $$| $$_  $$  /$$__  $$                                                                                           
|  $$$$$$$| $$ \  $$|  $$$$$$$                                                                                           
 \_______/|__/  \__/ \_______/                                                                                                                                                                                                                  
                                                                                                                                                                                                                                             
                     /$$                                                                                              /$$
                    |__/                                                                                             | $$
  /$$$$$$   /$$$$$$  /$$ /$$$$$$$   /$$$$$$$  /$$$$$$   /$$$$$$$ /$$$$$$$  /$$$$$$$  /$$$$$$  /$$$$$$/$$$$   /$$$$$$ | $$
 /$$__  $$ /$$__  $$| $$| $$__  $$ /$$_____/ /$$__  $$ /$$_____//$$_____/ /$$_____/ |____  $$| $$_  $$_  $$ /$$__  $$| $$
| $$  \ $$| $$  \__/| $$| $$  \ $$| $$      | $$$$$$$$|  $$$$$$|  $$$$$$ | $$        /$$$$$$$| $$ \ $$ \ $$| $$$$$$$$| $$
| $$  | $$| $$      | $$| $$  | $$| $$      | $$_____/ \____  $$\____  $$| $$       /$$__  $$| $$ | $$ | $$| $$_____/| $$
| $$$$$$$/| $$      | $$| $$  | $$|  $$$$$$$|  $$$$$$$ /$$$$$$$//$$$$$$$/|  $$$$$$$|  $$$$$$$| $$ | $$ | $$|  $$$$$$$| $$
| $$____/ |__/      |__/|__/  |__/ \_______/ \_______/|_______/|_______/  \_______/ \_______/|__/ |__/ |__/ \_______/|__/
| $$                                                                                                                     
| $$                                                                                                                     
|__/   

                     $$\                                   
                     $$ |                                  
 $$$$$$\   $$$$$$\ $$$$$$\                                 
 \____$$\ $$  __$$\\_$$  _|                                
 $$$$$$$ |$$ |  \__| $$ |                                  
$$  __$$ |$$ |       $$ |$$\                               
\$$$$$$$ |$$ |       \$$$$  |                              
 \_______|\__|        \____/                               
                                                                                                                                                                              
$$\                           $$\                  $$\     
$$ |                          $$ |                 $$ |    
$$$$$$$\   $$$$$$\   $$$$$$$\ $$ |  $$\  $$$$$$\ $$$$$$\   
$$  __$$\  \____$$\ $$  _____|$$ | $$  |$$  __$$\\_$$  _|  
$$ |  $$ | $$$$$$$ |\$$$$$$\  $$$$$$  / $$$$$$$$ | $$ |    
$$ |  $$ |$$  __$$ | \____$$\ $$  _$$<  $$   ____| $$ |$$\ 
$$$$$$$  |\$$$$$$$ |$$$$$$$  |$$ | \$$\ \$$$$$$$\  \$$$$  |
\_______/  \_______|\_______/ \__|  \__| \_______|  \____/                                                                                                                    
                                                           
          $$\       $$\   $$\                              
          $$ |      \__|  $$ |                             
 $$$$$$$\ $$$$$$$\  $$\ $$$$$$\                            
$$  _____|$$  __$$\ $$ |\_$$  _|                           
\$$$$$$\  $$ |  $$ |$$ |  $$ |                             
 \____$$\ $$ |  $$ |$$ |  $$ |$$\                          
$$$$$$$  |$$ |  $$ |$$ |  \$$$$  |                         
\_______/ \__|  \__|\__|   \____/                                                                                                                                                                  

*/

contract BERKTHINGS is ERC721Enumerable, ERC2981ContractWideRoyalties, Ownable {
    using Strings for uint256;
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIextended;
    string private _contractURI;
    constructor()
        ERC721("Berk aka PrincessCamel Things", "BERKTHINGS")
    {
        setRoyalties(0xc5E08104c19DAfd00Fe40737490Da9552Db5bfE5,1000);
    }
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setcontractURI(string memory _uri) external onlyOwner {
      _contractURI = _uri;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }
    
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
      
    // LEAVING THIS FUNCTION ON IN CASE SOMETHING FUCKS UP WITH METADATA WHICH IS A VERY LOW CHANCE BUT NOT ZERO
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }
    
    function mintShit(
        address to,
        uint tokenId,
        string memory _tokenURI
    ) external onlyOwner{
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }
   
}