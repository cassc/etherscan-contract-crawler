/**                                                                                                                                                                           
   d888888o.       ,o888888o.     8 888888888o.            .8.                    `8.`8888.      ,8'           b.             8 8 8888888888   8 8888     ,88'  ,o888888o.     
 .`8888:' `88.  . 8888     `88.   8 8888    `88.          .888.                    `8.`8888.    ,8'            888o.          8 8 8888         8 8888    ,88'. 8888     `88.   
 8.`8888.   Y8 ,8 8888       `8b  8 8888     `88         :88888.                    `8.`8888.  ,8'             Y88888o.       8 8 8888         8 8888   ,88',8 8888       `8b  
 `8.`8888.     88 8888        `8b 8 8888     ,88        . `88888.                    `8.`8888.,8'              .`Y888888o.    8 8 8888         8 8888  ,88' 88 8888        `8b 
  `8.`8888.    88 8888         88 8 8888.   ,88'       .8. `88888.                    `8.`88888'               8o. `Y888888o. 8 8 888888888888 8 8888 ,88'  88 8888         88 
   `8.`8888.   88 8888         88 8 888888888P'       .8`8. `88888.                   .88.`8888.               8`Y8o. `Y88888o8 8 8888         8 8888 88'   88 8888         88 
    `8.`8888.  88 8888        ,8P 8 8888`8b          .8' `8. `88888.                 .8'`8.`8888.              8   `Y8o. `Y8888 8 8888         8 888888<    88 8888        ,8P 
8b   `8.`8888. `8 8888       ,8P  8 8888 `8b.       .8'   `8. `88888.               .8'  `8.`8888.             8      `Y8o. `Y8 8 8888         8 8888 `Y8.  `8 8888       ,8P  
`8b.  ;8.`8888  ` 8888     ,88'   8 8888   `8b.    .888888888. `88888.             .8'    `8.`8888.            8         `Y8o.` 8 8888         8 8888   `Y8. ` 8888     ,88'   
 `Y8888P ,88P'     `8888888P'     8 8888     `88. .8'       `8. `88888.           .8'      `8.`8888.           8            `Yo 8 888888888888 8 8888     `Y8.  `8888888P'     
                                                       
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";
import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";


contract SoraxNeko is ERC721A, Ownable, DefaultOperatorFilterer {
    string public baseTokenURI;
    string public defaultTokenURI;
    uint256 public NekoPrice = 0.0018 ether;
    uint256 public maxSupply = 1204;
    uint256 public maxFree = 200;
    uint256 public maxFreePerWallet = 1;
    address payable public payMen;
    bool public MintStatus;

    constructor() ERC721A("Sora x Neko", "SxN") {
        payMen = payable(msg.sender);
        _mint(msg.sender, 4); 
    }

    function MintNeko(uint256 _quantity) external payable {
        require(MintStatus,"Sales Closed");
        require(_quantity + _numberMinted(msg.sender) <= 11, "Exceeded Max 11 per wallet");
        require(totalSupply() + _quantity <= maxSupply, "Exceeded Total Supply");
        require(msg.value >= _quantity*NekoPrice, "Not Enough Ether");
        _mint(msg.sender, _quantity);
    }


    function FreeNeko() external{
        uint256 amount = 1;
        require(MintStatus,"Sales Closed");
        require(totalSupply() + amount <= maxFree, "Opps, no more free");
        require(amount + _numberMinted(msg.sender) <= maxFreePerWallet, "Opps, too late");

        _mint(msg.sender, amount);
    }

  function BurnNeko(uint256 tokenId) external {
        require(ownerOf(tokenId) == (msg.sender), "You do not own this token");
        _burn(tokenId);  
  }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

   function getHoldTokenIdsByOwner(address _owner)
    public
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
    view
    virtual
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

    function setNekoPrice(uint256 mintprice) external onlyOwner {
        NekoPrice = mintprice;
    }

    function setMintStatus(bool status) external onlyOwner {
        MintStatus = status;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

}