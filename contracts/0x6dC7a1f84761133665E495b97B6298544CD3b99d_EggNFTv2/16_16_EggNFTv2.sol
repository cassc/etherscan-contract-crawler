//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EggNFTv2 is ERC1155Supply, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    uint public constant EGG_NFT_V2_ID_OFFSET = 3000;
    mapping(uint => uint) public maxSupply;
    uint public onetimeLimit = 1;
    uint public walletLimit = 1;
    uint public curMintId;

    constructor() ERC1155("https://storageapi2.fleek.co/{id}") {
        baseURI = "https://storageapi2.fleek.co/";
        curMintId = 1;
        maxSupply[EGG_NFT_V2_ID_OFFSET + 1] = 100;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setMaxSupply(uint _id, uint _supply) external onlyOwner {
        require (totalSupply(EGG_NFT_V2_ID_OFFSET + _id) <= _supply, "!supply");
        maxSupply[_id] = _supply;
    }

    function setCurrentMint(uint _id) external onlyOwner {
        curMintId = _id;
    }

    function setOnetimeLimit(uint _limit) external onlyOwner {
        require (_limit > 0, "!limit");
        onetimeLimit = _limit;
    }

    function setWalletLimit(uint _limit) external onlyOwner {
        require (_limit > 0, "!limit");
        walletLimit = _limit;
    }

    function mint(uint _amount) external nonReentrant {
        require (_amount > 0 && _amount <= onetimeLimit, "!amount");
        require (balanceOf(msg.sender, EGG_NFT_V2_ID_OFFSET + curMintId) + _amount <= walletLimit, "exceeded mint");
        require (totalSupply(EGG_NFT_V2_ID_OFFSET + curMintId) + _amount <= maxSupply[curMintId], "exceeded supply");
        
        _mint(msg.sender, EGG_NFT_V2_ID_OFFSET + curMintId, _amount, "");
    }

    function uri(uint _id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
    }
}