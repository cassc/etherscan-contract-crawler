// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Randomize.sol";
import "./MintList.sol";

contract  ProteinaLabCollection is ERC721, ReentrancyGuard, Randomize() {

    uint256 public price;
    uint256[] public  _listTokenIds;
    string  folderURI;

    address payable public receiver;
    address payable public receiver2;
    address  public owner;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor(string memory _folderURI, uint256 _price) ERC721("PL","PL") {
        receiver =  payable(address(0x719641651A6702C5983c9930688DD6e4A4088903)); // 72
        receiver2 = payable(address(0x81E1701e393f28D64C1085399f7D845bf32a73A0)); // 18
        price = _price;
        owner = msg.sender;
        // setPrice(10000000000000000000);
        folderURI =   _folderURI;
        _listTokenIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30];
    }


    /**
     * @dev Safely mints a token. Increments 'tokenId' by 1 and calls super._safeMint()
     *
     */

    function mint() public returns(uint256){
        require(msg.sender == receiver,"You not are the owner");
        uint256 newItemId = safeMint();
        return newItemId;
    }

    function safeMint() internal returns(uint256){
        uint256 newItemId = getCurreentId();
        _mint(msg.sender, newItemId);
        return newItemId;
    }

    function payableMint(uint256 quantity) public nonReentrant payable returns (uint256) {
        require(price > 0, "Persea: The admin doesnt have a price for this collection");
        require(msg.value >= price, "Persea: Balance not enough");
        require(quantity == 1, "Persea: Quantity not equal");
        (bool sent, ) = receiver.call{ value :  ((msg.value * 7200) / 10000) }("");
        require(sent, "Persea : Failed to send Ether");
        (bool sent2, ) = receiver2.call{ value :  ((msg.value * 1800) / 10000) }("");
        require(sent2, "Persea : Failed to send Ether");
        uint256 newItemId = safeMint();
        return newItemId;
    }

    function getCurreentId() internal  returns (uint256){
        uint256 newItemId = 0;
        require(totalLeft() > 0, "Persea: Not found ids in the list");
        if (totalLeft() > 1) {
            uint256 random = randomBetween(totalLeft(),1);
            newItemId = _listTokenIds[random];
            _listTokenIds[random] =  _listTokenIds[totalLeft() - 1];
            _listTokenIds.pop();
        } else {
            newItemId = _listTokenIds[0];
            _listTokenIds.pop();
        }
        require(newItemId > 0, "Not found token id");
        return newItemId;
    }

    function setFolderURI(string memory _folderURI) public {
        require(msg.sender == owner,"You not are the owner");
        folderURI = _folderURI;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        //string memory baseURI = _baseURI();
        return folderURI;
    }

    function totalLeft() public view returns(uint256) {
        return _listTokenIds.length;
    }

    function setPrice(uint256 newPrice) public {
        require(msg.sender == owner,"You not are the owner");
        price = newPrice;
    }

    function currentPrice() public view returns(uint256) {
        return price;
    }
}