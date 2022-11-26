// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Randomize.sol";
import "./MintList.sol";

contract PerseaSimpleCollection is ERC721, ReentrancyGuard, Randomize(), Ownable {

    uint256 public price;
    uint256[] public  _listTokenIds;
    string  folderURI;
    address payable public receiver;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    /**

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor(string memory _folderURI, uint256 _price,uint256 _limit) ERC721("M909","M909") {
        receiver =  payable(msg.sender);
        setTotalSupply(_limit);
        folderURI =   _folderURI;
        price = _price;
    }


    /**
     * @dev Safely mints a token. Increments 'tokenId' by 1 and calls super._safeMint()
     *
    */

    function mint() public onlyOwner returns(uint256){
        uint256 newItemId = safeMint();
        return newItemId;
    }

    function setLimit(uint256 _limit) public onlyOwner {
        setTotalSupply(_limit);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setFolderURI(string memory _folderURI) public onlyOwner {
        folderURI = _folderURI;
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
        (bool sent, ) = receiver.call{ value :  msg.value }("");
        require(sent, "Persea : Failed to send Ether");
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

    function _baseURI() internal view virtual override returns(string memory) {
        return folderURI;
    }

    function totalLeft() public view returns(uint256) {
        return _listTokenIds.length;
    }

    function currentPrice() public view returns(uint256) {
        return price;
    }

    function setTotalSupply(uint256 newLimit) internal {
        delete _listTokenIds;
        for (uint256 index = 1; index <= newLimit; index++) {
            _listTokenIds.push(index);
        }
    }
}