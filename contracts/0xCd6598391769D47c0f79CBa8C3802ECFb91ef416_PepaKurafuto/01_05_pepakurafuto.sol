/*
       __          ___        __                            ___               __                     ___  ___         ___  ___   ___             
  .'|=|  |    .'|=|_.'   .'|=|  |    .'|=|`.     .'|   .'| |   | |`.     .'|=|  |   .'|=|`.     .'|=|_.' |   | |`.   `._|=|   |=|_.'   .'|=|`.   
.'  | |  |  .'  |  ___ .'  | |  |  .'  | |  `. .'  | .' .' |   | |  `. .'  | |  | .'  | |  `. .'  |  ___ |   | |  `.      |   |      .'  | |  `. 
|   |=|.'   |   |=|_.' |   |=|.'   |   |=|   | |   |=|.:   |   | |   | |   |=|.'  |   |=|   | |   |=|_.' |   | |   |      |   |      |   | |   | 
|   |       |   |  ___ |   |       |   | |   | |   |   |'. `.  | |   | |   |  |`. |   | |   | |   |      `.  | |   |      `.  |      `.  | |  .' 
|___|       |___|=|_.' |___|       |___| |___| |___|   |_|   `.|=|___| |___|  |_| |___| |___| |___|        `.|=|___|        `.|        `.|=|.'   
                                                                                                                                                 
*/



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import ".deps/github/chiru-labs/ERC721A/contracts/ERC721A.sol";



contract PepaKurafuto is ERC721A, Ownable {
    
    uint256 public pepaprice = 0.004 ether;
    uint256 public maxmint = 10;
    uint256 public maxsupply = 2222;
    address payable public payment;
    bool public mintstatus;
    string public baseTokenURI = "https://ipfs.io/ipfs/bafybeiaspwcxo53g7bv4e4y774wyko4nwm73htemmede4xgxaskeo5dxmu/" ;
    string public defaultTokenURI;

    constructor() ERC721A("PepaKurafuto", "PEPA") {

        payment = payable(msg.sender);
        _mint(msg.sender, 1); 
    }

    function pepa_mint(uint256 _quantity) external payable {
        require(mintstatus,"Sales Closed");
        require(_quantity + _numberMinted(msg.sender) <= 10, "Exceeded Max 10 per wallet");
        require(totalSupply() + _quantity <= maxsupply, "Exceeded Total Supply");
        require(msg.value >= _quantity*pepaprice, "Not Enough Ether");
        _mint(msg.sender, _quantity);
    }


  function pepa_burn(uint256 tokenId) external {
        require(ownerOf(tokenId) == (msg.sender), "You do not own this token");
        _burn(tokenId);  
  }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

   function getHoldTokenIdsByOwner(address _owner)
    private
    view
    returns (uint256[] memory)
    {
        uint256 index = 0;
        uint256 hasMinted = _totalMinted();
        uint256 tokenIdsLen = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLen);
        for (
            uint256 tokenId = 1;
            index < tokenIdsLen && tokenId <= hasMinted;
            tokenId++
        ) {
            if (_owner == ownerOf(tokenId)) {
                tokenIds[index] = tokenId;
                index++;
            }
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view virtual
    override
    returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
        : defaultTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setDefaultURI(string calldata _defaultURI) external onlyOwner {
        defaultTokenURI = _defaultURI;
    }

    function setpeparice(uint256 mintprice) external onlyOwner {
        pepaprice = mintprice;
    }

    function setmintstatus(bool status) external onlyOwner {
        mintstatus = status;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


}