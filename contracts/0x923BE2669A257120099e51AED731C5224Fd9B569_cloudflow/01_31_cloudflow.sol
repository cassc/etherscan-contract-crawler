// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC1155SupplyWithAll.sol";
import "@openzeppelin/[email protected]/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/[email protected]/access/OwnableUpgradeable.sol";
import "@openzeppelin/[email protected]/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/[email protected]/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";



contract cloudflow is ERC1155SupplyWithAll, Ownable {
    
    uint256 constant BoababTreeCloud = 1;
    uint256 constant cloudflowers = 2;
    uint256 constant whitelovecloudflower = 3;
    uint256 constant lightskydragon = 4;
    uint256 constant nightwalk = 5;
    uint256 constant cloudwavesinperfectmotion = 6;
    uint256 constant cloudrastanameslarry = 7;

    mapping (uint256 => string) private _uris;

    constructor() ERC1155("https://arweave.net/h9vAVGqYogUjhkFasK_BT2zTcjEgjKjjimeSXVht9QI/cloudflow.json")

    {

    _mint(msg.sender, BoababTreeCloud, 5000, "");
    _mint(msg.sender, cloudflowers,  5000, "");
    _mint(msg.sender, whitelovecloudflower, 5000, "");
    _mint(msg.sender, lightskydragon, 5000, "");
    _mint(msg.sender, nightwalk, 5000, "");
    _mint(msg.sender, cloudwavesinperfectmotion, 5000, "");
    _mint(msg.sender, cloudrastanameslarry, 5000, "");
     
    }

function contractURI() public pure returns (string memory) {
        return "https://arweave.net/h9vAVGqYogUjhkFasK_BT2zTcjEgjKjjimeSXVht9QI/cloudflow.json";
    }


function uri(uint256 _tokenId) override public pure returns (string memory){
        return           string(abi.encodePacked("https://arweave.net/h9vAVGqYogUjhkFasK_BT2zTcjEgjKjjimeSXVht9QI/cloudflow", Strings.toString(_tokenId),".json"));
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155SupplyWithAll)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}