// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**

      /$$$$$$   /$$$$$$  /$$      /$$
     /$$__  $$ /$$__  $$| $$$    /$$$
    |__/  \ $$| $$  \__/| $$$$  /$$$$
       /$$$$$/| $$ /$$$$| $$ $$/$$ $$
      |___  $$| $$|_  $$| $$  $$$| $$
     /$$  \ $$| $$  \ $$| $$\  $ | $$
    |  $$$$$$/|  $$$$$$/| $$ \/  | $$
    \______/  \______/ |__/     |__/


    ** Website
       https://3gm.dev/

    ** Twitter
       https://twitter.com/3gmdev

**/

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ERC721A {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract ArtForZombiesSpecials is ERC1155, Ownable {

    enum Stages { Closed, Whitelist, Public }

    ERC721A public brainsContract = ERC721A(0xcA0e2E59649423e7F912Ce39AeDa8cF25F2Bfa8c);
    string public baseURI = "";
    Stages public stage = Stages.Closed;
    mapping(uint256 => uint256) public mintAmount;
    mapping(uint256 => uint256) public supplyAmount;
    mapping(uint256 => bool) public brainTokenIdMinted;

    constructor() ERC1155("") {
        for (uint256 i = 1; i < 21; i++) {
            mintAmount[i] += 1;
            _mint(msg.sender, i, 1, "");
        }
    }

    function mint(uint256 _tokenId, uint256 _brainTokenId) external payable {
        require(stage == Stages.Whitelist || stage == Stages.Public, "Paused");
        require(supplyAmount[_tokenId] >= mintAmount[_tokenId] + 1, "Exceeds max supply");

        address _caller = _msgSender();
        require(tx.origin == _caller, "No contracts");
        require(_caller == brainsContract.ownerOf(_brainTokenId), "Not owner of this _brainTokenId");
        require(!brainTokenIdMinted[_brainTokenId], "_brainTokenId already use to mint");

        if(stage == Stages.Whitelist) {
            require(_tokenId >= 1 && _tokenId <= 5, "Can mint only range 1 to 5");
        }else if(stage == Stages.Public) {
            require(_tokenId >= 1 && _tokenId <= 20, "Can mint only range 1 to 20");
        }

        unchecked { 
            mintAmount[_tokenId] += 1; 
            brainTokenIdMinted[_brainTokenId] = true;
        }

        _mint(_caller, _tokenId, 1, "");
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }

    function setSupply(uint256[] memory ids, uint256[] memory supply) external onlyOwner {
        require(ids.length == supply.length, "Not same lenght");
        for (uint256 i; i < ids.length; i++) {
            supplyAmount[ids[i]] = supply[i];
        }
    }
    
    function setBrainsContract(ERC721A _brains) external onlyOwner {
        brainsContract = _brains;
    }

    function setStage(Stages _stage) external onlyOwner {
        stage = _stage;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "Failed to send");
    }
}