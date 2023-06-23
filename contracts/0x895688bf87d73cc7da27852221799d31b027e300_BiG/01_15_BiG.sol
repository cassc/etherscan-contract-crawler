// SPDX-License-Identifier: MIT

//                                                                                                                        
//                                                                                                                        
//                                          #%%%&&%                                                                       
//                                       /((((((###%%      #%&&%%%%#(                                                     
//                                      ,,,******(#%%&&&&&&&&&&&&&&&&&&&&&&&,                                             
//                                      ...,,*%%%%&&&&&&&&&%%&&%%&&&&&&&&&&&&&&&/                                         
//                           #%%&&&&&&%#  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&&&*                                     
//                         ##%&&&&&&&&&&&%&%&&&%%%%%%%%%%%%%%%%%%%&&&&%%%%%&&&&&&&&&&&&#                                  
//                        (###(*,,,.*%%&&%&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&%#                               
//                       (((((//////*,#%%%&&&&&&%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&&&&&&&%                             
//                        (((((((#######%%&&&&%%%%%%%%%%%%%%%%%%%%&&&&&&&&&&&&%%%%%%%%%%%%%%&%%                           
//                          ((##((((####%&&&&%%%%%%%%&&&&&&&&&&&&&&&&&&&&&&&&@%%%%%%%%%%%%%&&&&&%                         
//                           ########%%%%&&%%%##(%&&&&&&&&&&&*,[email protected]/&&&&&&&&&&&&&%&&%&&%%%%%%%%&&&&&%                       
//                           #%###%%%%%%%%%%%%(//#%&&&&&&&&&&//***&&&&&&&&&&&&&%%%&&&&&&&&%%%%&&&&&%                      
//                           #%%%%%%%%%%%%%%%%#**/#%&&&&&&&&&&&&&&&&&&&&&&&&&&%%&%&&&&&&&&&&&%/,,,***/                    
//                            %%%%#%%%%%%%%%%%#(**/(#%%&&&&&&&&&&&&&&&&&&&&&&%%&&&&&&&&&&&&*,,,,,,,***,                   
//                            #######%%%%%#%%%%#(/**/((##%%&&&&&&&&&&&&&&%%%#%&&&&&&&&&&&(,,,,,,,...,**/                  
//                             ##((((#########%%#((,,,*//((###%%%%%%%##%%%%%&&&&&&&&&&&&,,,,,,,,....,...                  
//                             /((((((###################%%%%%%%%%%%%%&%#%&&&%%%%%%%%%#,,,,,,,.....  .*                   
//                              (/////(((((((#(############%%%%%%%%%#%%%%%%%%%%%%%%%%,,,,,,,,,....,,,,*.                  
//                              //***/////((((((((((###################%%%%%%%%%%%%,....,,,,,,,,,,,,,,*                   
//                               //*****///////(((((((((((###(((#########%%%%%%%%*......,,,,,,,,,..,,,*                   
//                                 **********///////////((((((((((((((#########/.........,,,,........,*                   
//                                    ****************//////////(((((((((((((*.......................,                    
//                                       /********************/////////////,...................,                          
//                                              .************************.................,.                              
//                                                    .......,.,*,.....                                                   
//                                                    ...   ....,......                                                   
//                                                    ....  ....,,,....                                                   
//                                               .   ...,, ... ..,.....                                                   
//                                                    ..,,.. . ..,,....                                                   
//                                                .   ...(............                                                    
//                                                ..*(,..............,                                                    
//                                                 .  .......,,.....,,                                                    
//                                                 ,  ......,,,.....,,                                                    
//                                                 ,  .......... ....,                                                    
//                                                 .  ..........,*/,.,****                                                
//                                                  ....,,,******/(##,,*//(                                               
//                                                                                                                        

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

interface MintPass1155 {
    function burnForCharacter(uint256 _qty, address _addr, uint256 _id) external;
}

contract BiG is ERC721A, Ownable, RevokableDefaultOperatorFilterer, ReentrancyGuard {

    event MintedCharacter(address wallet, uint256 tokenId, uint256 applicationId);
    event UpgradedCharacter(address wallet, uint256 tokenId, uint256 upgradeNumber);
    event MetadataUpdate(uint256 _tokenId);

    address private MINT_PASS = 0x7b390a46c868CCEbF2730121faf777129B47C97c;

    address public futureBurnContract;

    string public _metadata = "https://api.biginc.business/metadata/";

    uint256 constant MAX_SUPPLY = 15001;

    bool public mintActive = false;
    bool public burnActive = false;
    bool public upgradeActive = false;

    mapping(uint256 => uint256) public tokenToId;
    mapping(uint256 => uint256) public tokenToLevel;

    constructor() ERC721A("BiGiNCChar", "BiG")  {}

    function claim(uint256 applicationId, uint256 amount) public nonReentrant {
        if(msg.sender != owner()) require(mintActive, "Mint not active");

        uint16 tokenId = uint16(_totalMinted());
        require(tokenId + amount <= MAX_SUPPLY, "Minted out");
        require(amount <= 20, "Max per tx");

        MintPass1155(MINT_PASS).burnForCharacter(amount, msg.sender, applicationId);

        if(applicationId > 0) {
            for(uint i = 0; i < amount; i++)
                tokenToId[tokenId + i] = applicationId;
        }

        for(uint i = 0; i < amount; i++)
            emit MintedCharacter(msg.sender, tokenId + i, applicationId);

        _mint(msg.sender, amount);
    }

    function upgrade(uint256 tokenId) public nonReentrant {
        if(msg.sender != owner()) require(upgradeActive, "Upgrade not active");
        require(ownerOf(tokenId) == msg.sender, "Must be owner of token");

        uint id = tokenToId[tokenId];
        require(id == 0,"Must be from a general acceptance letter id");

        MintPass1155(MINT_PASS).burnForCharacter(1, msg.sender, 0);
        
        tokenToLevel[tokenId] += 1;

        emit UpgradedCharacter(msg.sender, tokenId, tokenToLevel[tokenId]);
        emit MetadataUpdate(tokenId);
    }

    function burn(uint256 tokenId) external  {
        require(burnActive, "Burn is not active");
        require(msg.sender == futureBurnContract, "Must be from future burn contract");
        _burn(tokenId, false);        
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return _metadata;
    }

    function setMetadata(string memory metadata) public onlyOwner {
        _metadata = metadata;
    }

    function setMintActive(bool _state) public onlyOwner {
        mintActive = _state;
    }

    function setBurnActive(bool _state) public onlyOwner {
        burnActive = _state;
    }

    function setUpgradeActive(bool _state) public onlyOwner {
        upgradeActive = _state;
    } 

    function setMintPassContract(address _contract) public onlyOwner {
        MINT_PASS = _contract;
    }

    function setFutureBurnContract(address _contract) public onlyOwner {
        futureBurnContract = _contract;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    function tokenData(uint256 tokenId) public view returns (bool, uint256, uint256) {
        uint256 tokenType = tokenToId[tokenId];
        uint256 tokenUpgrade = tokenToLevel[tokenId];
        bool exists = _exists(tokenId);

        return (exists, tokenType, tokenUpgrade);
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call {value: address(this).balance}("");
        require(success);
    }

    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}