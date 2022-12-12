// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0 || ^0.8.1;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../loyalties/Loyalty.sol";

contract ERC1155Openzeppelin is ERC1155, Ownable, Loyalty {
    string public name = "BULLZ Collection";
    string public symbol = "BULLZ";    
    string public baseUri = "https://prod-eth-api.bullz.com/api/nfts/item/";
    
    ILoyalty private loyalty;

    constructor(string memory _name, string memory _symbol)
        ERC1155("https://prod-eth-api.bullz.com/api/nfts/item/")
    {
        if (bytes(_name).length != 0) {
            name = _name;
        }
        if (bytes(_symbol).length != 0) {
            symbol = _symbol;
        }
    }

    function awardItem(
        uint256 newItemId,
        uint256 amount,
        bytes memory data,
        uint256 loyaltyPercent,
        uint256 resaleStatus
    ) public returns (uint256) {
        _mint(_msgSender(), newItemId, amount, data);
        addLoyalty(newItemId, _msgSender(), loyaltyPercent, resaleStatus);
        return newItemId;
    }

    function setURI(string memory newUri)
        public
        onlyOwner
        returns (string memory)
    {
        _setURI(newUri);
        baseUri = newUri;

        return newUri;
    }

    function uri(uint256 _tokenid)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenid), ".json")
            );
    }
}