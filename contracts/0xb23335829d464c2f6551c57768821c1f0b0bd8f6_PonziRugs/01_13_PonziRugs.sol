// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";
import "./PonziRugsGenerator.sol";
contract PonziRugs is ERC721, Ownable{  
    // On Tupac's Soul
    uint256 public  MAX_SUPPLY          = 1250;
    uint256 public  GET_RUGGED_IN_ETHER = 0.06 ether;
    uint256 public  RUG_GIVEAWAY        = 16;
    uint256 public  totalSupply;
    uint256 RUG_RANDOM_SEED = 0;
    
    bool public hasRuggeningStarted = false;

    mapping(string => bool) isMinted;
    mapping(uint256 => uint256[]) idToCombination;

    constructor() ERC721("PonziRugs", "RUG") {}

    function toggleRuggening() public onlyOwner 
    {
        hasRuggeningStarted = !hasRuggeningStarted;
    }

    function devRug(uint rugs) public onlyOwner 
    {
        require(totalSupply + rugs <= RUG_GIVEAWAY, "Exceeded giveaway limit");
        rugPull(rugs);
    }

    function getRugged(uint256 rugs) public payable
    {
        require(hasRuggeningStarted,                        "The ruggening has not started");
        require(rugs > 0 && rugs <= 2,                      "You can only get rugged twice per transaction");   
        require(GET_RUGGED_IN_ETHER * rugs == msg.value,    "Ether Amount invalid to get rugged do: getRuggedInEther * rugs");
        rugPull(rugs);
    }
    
    function rugPull(uint256 rugPulls) internal 
    {
        require(totalSupply + rugPulls < MAX_SUPPLY);
        require(!PonziRugsGenerator.isTryingToRug(msg.sender));

        for (uint256 i; i < rugPulls; i++)
        {
            idToCombination[totalSupply] = craftRug(totalSupply);
            _mint(msg.sender, totalSupply);
            totalSupply++;
        }
    }

    function craftRug(uint256 tokenId) internal returns (uint256[] memory colorCombination)
    {
        uint256[] memory colors = new uint256[](5);
        colors[0] = random(tokenId) % 1000;
        for (uint8 i = 1; i < 5; i++)
        {
            RUG_RANDOM_SEED++;
            colors[i] = random(tokenId) % 21;
        }
        string memory combination = string(abi.encodePacked(colors[0], colors[1], colors[2], colors[3], colors[4]));
        if(isMinted[combination]) craftRug(tokenId + 1);
        isMinted[combination] = true;
        return colors;
    }

    function random(uint256 seed) internal view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed, RUG_RANDOM_SEED)));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) 
    {
        require(tokenId >= 0 && tokenId <= totalSupply, "Invalid token ID");
        PonziRugsGenerator.PonziRugsStruct memory rug;
        string memory svg;
        (rug, svg) = PonziRugsGenerator.getRugForSeed(idToCombination[tokenId]);
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Ponzi Rugs #', Utils.uint2str(tokenId),
            '", "description": "Ever been rugged before? Good, Now you can do it on chain! No IPFS, no API, all images and metadata exist on the blockchain.",',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)),'",', rug.metadata,'}'
        ))));    
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    function withdrawAll() public payable onlyOwner 
    {
        require(payable(msg.sender).send(address(this).balance));
    }
}