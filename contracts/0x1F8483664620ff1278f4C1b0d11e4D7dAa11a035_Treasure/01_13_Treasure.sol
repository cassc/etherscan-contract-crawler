// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/***********************************************************/
/*     _____ __  ______                                    */
/*    |__  // / /_  __/_______  ____ ________  __________  */
/*     /_ </ /   / / / ___/ _ \/ __ `/ ___/ / / / ___/ _ \ */
/*   ___/ / /___/ / / /  /  __/ /_/ (__  ) /_/ / /  /  __/ */
/*  /____/_____/_/_/_/   \___/\__,_/____/\__,_/_/   \___/  */
/*           | |/_/                                        */
/*          _>  <                                          */
/*     ____/_/|_| _____ __            ___                  */
/*    / __ \_  __/ ___// /___  ______/ (_)___              */
/*   / / / / |/_/\__ \/ __/ / / / __  / / __ \             */
/*  / /_/ />  < ___/ / /_/ /_/ / /_/ / / /_/ /             */
/*  \____/_/|_|/____/\__/\__,_/\__,_/_/\____/              */
/*                                                         */
/***********************************************************/
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Treasure is ERC1155Supply, Ownable, ReentrancyGuard {
    string private contractMetadataURI;

    mapping(uint256 => bool) private _isMintable;
    mapping(uint256 => address) public burners;
    mapping(uint256 => uint256[]) public materials;
    mapping(uint256 => uint256[]) public materialsAmount;
    mapping(uint256 => string) public treasureURI;

    event MaterialBalance(uint256 typeId, uint256 amount);

    modifier treasureTypeExists(uint256 typeId) {
        require(bytes(treasureURI[typeId]).length != 0, "Treasure type not exists.");
        
        _;
    }

    constructor(string memory _contractURI) ERC1155("") {
        contractMetadataURI = _contractURI;
    }

    function airdrop(address to, uint256 typeId, uint256 amount) 
        external
        onlyOwner 
        treasureTypeExists(typeId) 
    {
        _mint(to, typeId, amount, "");
    }

    function airdropMultiAddress(address[] memory receivers, uint256 typeId, uint256 amount) 
        external 
        treasureTypeExists(typeId) 
        onlyOwner 
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], typeId, amount, "");
        }
    }

    function setMintRecipe(uint256 typeId, uint256[] memory materialIds, uint256[] memory amounts) 
        external 
        treasureTypeExists(typeId) 
        onlyOwner 
    {
        require(materialIds.length == amounts.length, "Formula: material and amount length mismatch");
        require(materialIds.length > 0, "Formula: no material");
        _isMintable[typeId] = true;
        materials[typeId] = materialIds;
        materialsAmount[typeId] = amounts;
    }

    function mintTreasureWithRecipe(uint256 typeId) 
        external 
        nonReentrant
        treasureTypeExists(typeId)
    {
        require(_isMintable[typeId], "Treasure type not mintable.");
        // check material owns
        for(uint256 i = 0; i < materials[typeId].length; i++) {
            emit MaterialBalance(materials[typeId][i], materialsAmount[typeId][i]);
            require(balanceOf(msg.sender, materials[typeId][i]) >= materialsAmount[typeId][i], "Not enough material.");
        }
        // burn material owns
        for(uint256 i = 0; i < materials[typeId].length; i++) {
            _burn(msg.sender, materials[typeId][i], materialsAmount[typeId][i]);
        }
        // mint treasure with formula
        _mint(msg.sender, typeId, 1, "");
    }

    function setTreasure(uint256 typeId, string memory _uri, address burnAddress) 
        external 
        onlyOwner 
    {
        treasureURI[typeId] = _uri;
        burners[typeId] = burnAddress;
    }
    
    function getTreasure(uint256 typeId) 
        public 
        view 
        onlyOwner 
        treasureTypeExists(typeId) 
        returns (string memory) 
    {
        return string(abi.encodePacked(typeId,',' ,treasureURI[typeId], ',', burners[typeId]));
    }

    function setBurner(uint256 typeId, address burnAddress) 
        external 
        treasureTypeExists(typeId) 
        onlyOwner 
    {
        burners[typeId] = burnAddress;
    }

    function setTreasureURI(uint256 typeId, string memory _uri) 
        external
        treasureTypeExists(typeId) 
        onlyOwner 
    {
        treasureURI[typeId] = _uri;
    }

    function burnForAddress(uint256 typeId, address burnTokenAddress, uint256 amount)
        external
        nonReentrant
        treasureTypeExists(typeId) 
    {
        require(msg.sender == burners[typeId], "Invalid burner address");
        _burn(burnTokenAddress, typeId, amount);
    }

    function setContractURI(string memory _uri) external onlyOwner {
        contractMetadataURI = _uri;
    }
    
    function contractURI() 
        public 
        view 
        returns (string memory)
    {
        return contractMetadataURI;
    }

    function uri(uint256 typeId)
        public
        view                
        override
        treasureTypeExists(typeId)
        returns (string memory)
    {
        return treasureURI[typeId];
    }
}