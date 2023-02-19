// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";

interface ITerraformsData {
  function ownerOf(uint256 tokenId) 
    external 
    view
    returns (address);

  function balanceOf(address owner) 
    external 
    view
    returns (uint256);

  function tokenOfOwnerByIndex(address owner, uint256 index) 
    external 
    view
    returns (uint256);
}

interface ITerraformsDataHelper {
  function chromaString(uint256 tokenId) 
    external 
    view
    returns (string memory);

  function resourceString(uint256 tokenId) 
    external 
    view
    returns (string memory);

  function biomeString(uint256 tokenId) 
    external 
    view
    returns (string memory);

  function zoneNameString(uint256 tokenId) 
    external 
    view
    returns (string memory);

  function zoneColorsString(uint256 tokenId) 
    external 
    view
    returns (string memory);

  function heightmapIndicesString(uint256 tokenId) 
    external 
    view
    returns (string memory);

  function terrainValuesString(uint256 tokenId) 
    external 
    view
    returns (string memory);
}

interface ITerraflowsSVG {
    function tokenSVG(uint256, bool) external view returns (string memory);
}

/// @title  Flow field representation of the Terraforms by Mathcastles onchain place (not affiliated with Mathcastles)
/// @author yeetljuice
contract Terraflows is ERC721, Ownable {
    /// @notice Sale information
    uint256 public immutable DEPLOY_TIMESTAMP; 
    uint public constant TERRAFORM_OWNER_PRICE = 0.01 ether;
    uint public constant NONTERRAFORM_OWNER_PRICE = 0.05 ether;

    /// @notice External contracts   
    ITerraformsData terraformsContract = ITerraformsData(0x4E1f41613c9084FdB9E34E11fAE9412427480e56);
    address public terraflowSVG;
    address public terraformsDataHelper;

    /// @notice Blend fraction data 
    event BlendUpdate(uint256 indexed _tokenId, uint8 _oldValue, uint8 _newValue);
    mapping (uint => uint8) public blend;

    /// @notice The amount each address can claim from the contract 
    mapping (address => uint) public claimableBalance; 

    constructor(address _terraflowSVG, address _terraformsDataHelper) ERC721("Terraflows", "terraflows") {
      DEPLOY_TIMESTAMP = block.timestamp;
      terraflowSVG = _terraflowSVG;
      terraformsDataHelper = _terraformsDataHelper;
    }

    /// @notice Get the unminted terraflows corresponding to terraforms held at a specific address
    /// @param holdingAddress The address to get the unminted terraflows associated with
    function getUnmintedTerraflows(address holdingAddress) public view returns (string memory unminted) {
      uint256 addressBalance = terraformsContract.balanceOf(holdingAddress);
      uint256 i = 0; 
      uint256 tid;
      while (i < addressBalance) {
        tid = terraformsContract.tokenOfOwnerByIndex(holdingAddress, i);
        if (!_exists(tid)) {
          if (bytes(unminted).length == 0) {
            unminted = string.concat('[', Strings.toString(tid));
          } else {
            unminted = string.concat(unminted, ',', Strings.toString(tid));
          }
        }
        i++;
      }
      if (bytes(unminted).length == 0) {
        unminted = '[]';
      } else {
        unminted = string.concat(unminted, ']');
      }
    }

    /// @notice **MINTS TO MINTING ADDRESS (msg.sender)** Mint the terraflows associated with the terraform tokenIds to the minting wallet. (Costs NONTERRAFORM_OWNER_PRICE per terraform)
    /// @param tokenIds The terraform tokenIds to mint the corresponding terraflows of
    function mintTerraflows(uint256[] memory tokenIds) public payable {
      require(block.timestamp - DEPLOY_TIMESTAMP > 7 days, 'Non-terraform owner must wait 7 days from contract deployment');
      uint256 numTokens = tokenIds.length;
      require(msg.value >= numTokens * NONTERRAFORM_OWNER_PRICE, 'Mint cost is numTokens * NONTERRAFORM_OWNER_PRICE');
      claimableBalance[owner()] += msg.value - 0.02 ether * numTokens;
      for (uint256 i=0; i < numTokens; i++) {
        uint256 tokenId = tokenIds[i];
        require(!_exists(tokenId), string.concat("Terraflow already minted: ", Strings.toString(tokenId)));
        claimableBalance[terraformsContract.ownerOf(tokenId)] += 0.02 ether;
        _safeMint(msg.sender, tokenId);
      }
    }

    /// @notice **MINTS TO WALLET HOLDING TERRAFORM**. Mint the terraflows associated with the terraform tokenIds to the wallet holding the terraform token. (Costs TERRAFORM_OWNER_PRICE per terraform)
    /// @param tokenIds The terraform tokenIds to mint the corresponding terraflows of
    function mintTerraflowsToHoldingAddress(uint256[] memory tokenIds) public payable {
      uint256 numTokens = tokenIds.length;
      require(msg.value >= numTokens * TERRAFORM_OWNER_PRICE, 'Mint cost is numTokens * TERRAFORM_OWNER_PRICE');
      claimableBalance[owner()] += msg.value;
      for (uint256 i=0; i < numTokens; i++) {
        uint256 tokenId = tokenIds[i];
        require(!_exists(tokenId), string.concat("Terraflow already minted: ", Strings.toString(tokenId)));
        _safeMint(terraformsContract.ownerOf(tokenId), tokenId);
      }
    }

    /// @notice Set the amount of blend applied to the heightmap colour of the terraform
    /// @param tokenId The tokenId to set the blend of
    /// @param blendVal The blend value to set the amount of heightmap colour blend (0: random -> 100: fully respects terraform heightmap colour.)
    function setBlend(uint tokenId, uint8 blendVal) public {
      require(msg.sender == ownerOf(tokenId), "Only the token owner can update the blend");
      require(blendVal <= 100, "Blend must be between 0 and 100");
      emit BlendUpdate(tokenId, blend[tokenId], blendVal);
      blend[tokenId] = blendVal;
    }

    /// @notice Claim funds from the contract associated with the calling address
    function withdrawBalance() public payable {
      uint balance = claimableBalance[msg.sender];
      claimableBalance[msg.sender] = 0;
      (bool success, ) = payable(msg.sender).call{
        value: balance
      }("");
      require(success);
    }

    /// @notice Claim all remaining funds from the contract (can only be called 1 year after deployment)
    function withdrawAll() public payable onlyOwner {
      require(block.timestamp - DEPLOY_TIMESTAMP > 365 days);
        (bool success, ) = payable(owner()).call{
          value: address(this).balance
        }("");
        require(success);
    }

    /// @dev Set a new terraflowSVG address
    function setTokenSVGAddr(address _address) public onlyOwner {
      terraflowSVG = _address;
    }

    /// @dev Set a new terraformsDataHelper address
    function setTerraformsDataHelperAddr(address _address) public onlyOwner {
      terraformsDataHelper = _address;
    }

    /// @notice Get the terraflow SVG
    /// @param tokenId The terraflow tokenID to get SVG for
    /// @param encoded True to get b64 encoded. False for plain text.
    function tokenSVG(uint256 tokenId, bool encoded) public view returns (string memory) {
      return ITerraflowsSVG(terraflowSVG).tokenSVG(tokenId, encoded);
    }

    /// @notice Get the terraflow HTML
    /// @param tokenId The terraflow tokenID to get HTML for
    /// @param encoded True to get b64 encoded. False for plain text.
    function tokenHTML(uint256 tokenId, bool encoded)  public view returns (string memory) {
      string memory html = string.concat('<html><head></head><body><canvas id="terraflows" width="418.14" height="600" style="height:100%;padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0;"></canvas></body><script>',tokenJS(tokenId), '</script></html>');
      if (!encoded) {
        return html;
      }
      return string.concat(
        'data:text/html;base64,',
        Base64.encode(abi.encodePacked(html))
      );
    }

    /// @notice Get the terraflow JS
    /// @param tokenId The terraflow tokenID to get HTML for
    function tokenJS(uint256 tokenId)  public view returns (string memory) {
      return string.concat(
        'let blend=(100-', Strings.toString(blend[tokenId]),
        ')/100;let tokenHeightmapIndices=', ITerraformsDataHelper(terraformsDataHelper).heightmapIndicesString(tokenId),
        ';let tokenTerrainValues=', ITerraformsDataHelper(terraformsDataHelper).terrainValuesString(tokenId),
        ';let zoneColor=', ITerraformsDataHelper(terraformsDataHelper).zoneColorsString(tokenId),
        ';let chroma="', ITerraformsDataHelper(terraformsDataHelper).chromaString(tokenId),
        '";resource=', ITerraformsDataHelper(terraformsDataHelper).resourceString(tokenId),
        ';biome=', ITerraformsDataHelper(terraformsDataHelper).biomeString(tokenId),
        ';let k=1;switch(chroma){case"Flow":case"Plague":k=3;break;case"Pulse":k=2;break;case"Hyper":k=1}let PI=Math.PI;function mulberry32(e){return function(){var l=e+=1831565813;return l=Math.imul(l^l>>>15,1|l),(((l^=l+Math.imul(l^l>>>7,61|l))^l>>>14)>>>0)/4294967296}}let rand=mulberry32(resource),flowField=tokenTerrainValues.map(e=>e.map(e=>(Number(e)+0)/131072*2*PI));if("Plague"==chroma&&39!=biome)flowField=tokenTerrainValues.map(e=>e.map(e=>rand()*PI));else if(39==biome){for(let e=0;e<32;e++)for(let l=0;l<32;l++)if(2==tokenHeightmapIndices[l][e]||3==tokenHeightmapIndices[l][e]||4==tokenHeightmapIndices[l][e])switch(chroma){case"Flow":flowField[l][e]=0;break;case"Pulse":flowField[l][e]=.5*Math.floor((Number(tokenTerrainValues[l][e])+65536)/131072/.25)*PI;break;case"Hyper":flowField[l][e]=rand()*PI;break;case"Plague":flowField[l][e]=2*rand()*PI}else flowField[l][e]=(Number(tokenTerrainValues[l][e])+65536)/131072*2*PI;k=3}const canvas=document.getElementById("terraflows"),ctx=canvas.getContext("2d");canvas.width=418.14,canvas.height=600;let w=canvas.width,h=canvas.height;function drawFlow(e,l,t){rand()>blend?ctx.strokeStyle=zoneColor[tokenHeightmapIndices[Math.floor(l/h*tokenHeightmapIndices.length)][Math.floor(e/w*tokenHeightmapIndices[0].length)]]:ctx.strokeStyle=zoneColor[Math.floor(rand()*zoneColor.length)],ctx.beginPath(),ctx.moveTo(e,l),vx=0,vy=0;for(let o=0;o<t;o++)vx+=Math.cos(a=flowField[Math.floor(l/h*flowField.length)][Math.floor(e/w*flowField[0].length)]),vy+=Math.sin(a),(v=Math.sqrt(vx**2+vy**2))>=2&&(vx/=v/2,vy/=v/2),e+=vx,l+=vy,ctx.lineTo(e,l),e<0&&(e=w-1e-4,ctx.moveTo(e,l)),e>w&&(e=0,ctx.moveTo(e,l)),l<0&&(l=h-1e-4,ctx.moveTo(e,l)),l>h&&(l=0,ctx.moveTo(e,l));ctx.stroke()}ctx.fillStyle=zoneColor[zoneColor.length-1],ctx.fillRect(0,0,w,h);for(let i=0;i<Math.floor(resource/5**(k-1));i++)drawFlow(rand()*w,rand()*h,5**k);'
        );
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      string memory uri = string.concat(
        'data:application/json;base64,', Base64.encode(abi.encodePacked(
          string.concat(
            '{', 
                '"name": "Terraflow ', Strings.toString(tokenId),
                '", "description": "Flow field representation of the Terraforms onchain place (project is homage to Mathcastles)',
                '", "image": "', tokenSVG(tokenId, true),
                '", "animation_url": "', tokenHTML(tokenId, true),
                '", "attributes": [', 
                              '{"trait_type": "', 'BIOME', '","value":"', ITerraformsDataHelper(terraformsDataHelper).biomeString(tokenId), '"},',
                              '{"trait_type": "', 'CHROMA', '","value":"', ITerraformsDataHelper(terraformsDataHelper).chromaString(tokenId), '"},',
                              '{"trait_type": "', 'ZONE', '","value":"', ITerraformsDataHelper(terraformsDataHelper).zoneNameString(tokenId), '"},', 
                              '{"trait_type": "', 'RESOURCE', '","value": ', ITerraformsDataHelper(terraformsDataHelper).resourceString(tokenId), '},',  
                              '{"trait_type": "', 'BLEND', '","value": ', Strings.toString(blend[tokenId]), '}',  
            ']}'
          )
          ))
        );
      return uri;
    }
}