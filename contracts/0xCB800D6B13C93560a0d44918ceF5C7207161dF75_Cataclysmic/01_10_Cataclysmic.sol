// SPDX-License-Identifier: GPL-3.0

/*
                                                                       'lx;                                                                           
                                                            ....    .,oKWNc  .,;;,.    .'''.  ......                                                  
                                        ...';.  .,;:,.   .:O00KKkd:.lNMMMN:  :KWWNl.  :0NNO'.:kXKKK0xc,':dxdl'       ..                               
        ',.                ..',.'cldkOO0000XWkcdKWWWK;  c0NMMWMMMMO':XMMWk'  .oNMMK; :KWMXdo0WMMMWMMMMNxl0MMMXc     ;0KOxo' .....             .co.    
        lXKd;.   .       cOXNNNkxNMMMMMMW0kkolkNMMMMK:.lKWMXoc0MMWx.'0MMX:    .oNMMkc0MW0;,OMMMM0cl0MMNd.:XMMMXc   .dNMMMMO';0XXKx.    ... .;xXWK,    
        cNMMNKkxO0Oo.   :XMMMMXc.:lOWMMMO'  'kWMMMMMK;.xWMWx.'O0d:. ,KMMNc     .dNMWNWM0; .xWMMNl  ,l:,. ;KMMMMXl  'OWMMMMNl,OMMMX: .:d0X0k0NMMM0'    
        ;XMMMMMMMMMk.  :KMMMMWXc  .xMMMNo  .dWMMMMMMKccKMWO; ...    lNMMX:      .xWMMMXc   ,0MMNc        ;XMMMMMX:.cXMMMMMWd'xMMMK, cNMMMMWMMMMMO.    
       'kWMNxlxNMWKc  'OMMMMMN0c. .xWMWO.  'OMW0KWMWdc0MMk.        'OMMMK,       cNMMWO.   '0MMWXOxl:'.  :XMMWWMWOo0WMMMMMWx.oWMMNo.,KMMMKol0WMMk.    
      .kMMWo..dKd;.  .dNKOXMMK:   .xWMNc  ,kNNkxXMMXc:KMWo         ;KMMMO.       oWMMWl    .cOXWMMMMWN0c.:XMMXOXMMWMMMWXWMMO,;KMMMK;.dWMMX; ,0MMK;    
      lNMM0, .;.   .:kWK:cXMWd.   lXMMX:.lKW0c;OMMMK;cNMX:        .dNMMNl       .dWMMNl       .;ldxXMMMk.,KMMK:cXMMMMM0lkMMX:,0MMMNl ;KMMNc .lOd:.    
     :XMMNo        cNMXc.oWMN:   ;KMMWx.:KMMNKKNMMMKdOWMO.  .     :0WMMk.       .kWMMWo           .dWMMNc.dWMK;.dWMMMMk.cNMNl.lXMMMK;.kMMWk. ..       
    ;0MMWk.       'OWMOcoKMMX:  .xWMMK;.lXMMNKNMMMM0o0MMO'.o0d,.  :KMMWo        'OMMMWd      ,cl:. oWMMNl'kWMNl .kWMMXc.cNMWo..oWMMWd.;KWMXc          
   '0MMMNc       .xWMMWWMMMMX;  :XMMNo.cKMNx,.cXMMWklKMMO'.dWMNd..lNMMNc     .  :KMMW0;     lNMMk. lNMMWx:0MMX:  .kWWx. ;KMMO' ,0MMWk. lNMMO.         
  .oNMMNd.       :XMWNXKNMMMO. ,0MMMK,.xWM0,  'OMMNllNMMO:lKWMMk..xWMMNkcclodo' .kWMWx.    .xWMMO:;xWMMWd;OMM0,   ,00;  .xMMNo .xWMMk. oWMMX:         
 .oNMMWk. ..   .lKWXo,.'OMMMk. ;KMMWd;dXMNo   .c0WXloNMMWNWMWXO; .dWMMMMWW0x:.   'OWWo.     ;ONWMWWMWNXd..dNMNl    ';.   lNMWd..xWMM0, :XMMWo  ..     
 :XMMNo':kKOl..oNMNd.  .dWMWo .dWMM0;lNMWd.     .;c..cxkxolol,.   c0K0dcc;..      ,0K;       .';cllc:'.   .;dKd.         .kWMK:.oWMMNl .oWMMO. l0d,.  
.xMMNo.'0MMMXldNMWd.    'dKK:  ;OWNl 'OOc.                         ...             ,l'                       ..           .oXXc .oKWWx. ;KMMKc'oXMNk; 
lNMMNkx0WWXx;;0MNd.       .'.   .:l.  ..                                                                                    ,xc   .lKO'  ;ONMWNNWMMMO.
xWWNX0Okdc.  .oOc.                                                                                                           ..     .;.   .;cd0OkO0Kx,
,xd:,..        .                                                                                                                              .. ..'..
*/

pragma solidity ^0.8.0;

import './ERC721AQueryable.sol';
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract Cataclysmic is ERC721AQueryable, Ownable, ReentrancyGuard {
    
    using Strings for uint256;
    
    // limits
    uint256 public maxPerTransaction = 2;
    uint256 public maxPerWallet = 2;
    uint256 public maxTotalSupply = 3000;

    // sale states
    bool public isPublicLive = false;

    // prereveal status
    bool public isRevealed = false;
    
    // price
    uint256 public mintPrice = 0 ether;

    // metadata  
    string public baseURI;
    string public hiddenMetadataUri;

    // config
    mapping(address => uint256) public mintsPerWallet;
    address private withdrawAddress = address(0);

    constructor() ERC721A("Cataclysmic", "CATNIP") {}

    function EngineerDigitalCC0Genome(uint256 _amount) external nonReentrant {
        require(isPublicLive, "Cataclysmic Event Has Not Begun");
        require(_amount > 0, "At least 1 Cataclysmic Needed");
        require(totalSupply() + _amount <= maxTotalSupply, "Cataclysmic Event Clone Process Complete");
        require(_amount <= maxPerTransaction, "Max Clone Generater is 2");
        require(mintsPerWallet[_msgSender()] + _amount <= maxPerWallet, "Wallet has reached Max Clones Generated");

        _safeMint(_msgSender(), _amount);
        mintsPerWallet[_msgSender()] += _amount;
    }

    function EngineerDigitalCC0GenomePrivate(address _receiver, uint256 _amount) external onlyOwner {
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds total supply");
        _safeMint(_receiver, _amount);
    }

    function GenomeBegin() external onlyOwner {
        isPublicLive = !isPublicLive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external onlyOwner {
        require(withdrawAddress != address(0), "No withdraw address");
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        isRevealed = true;
    }

    function setWithdrawAddress(address _withdrawAddress) external onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    // overrides
    function tokenURI(uint256 id) public view override returns (string memory) {
        if (isRevealed) {
            return string(abi.encodePacked(baseURI, id.toString()));
        } else {
            return hiddenMetadataUri;
        }
    }
}