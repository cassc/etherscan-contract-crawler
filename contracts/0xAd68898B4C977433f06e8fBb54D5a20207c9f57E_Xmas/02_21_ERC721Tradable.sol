// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
//import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
//import "openzeppelin-solidity/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./Base64.sol";
import "./strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    //using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;

    event Created(uint256 tokenId, address receiver, uint256 amount, uint256 NGO_id);

    struct Card {
        address creator;
        string  message;
        uint256 donated;
        uint256 NGO_id;
        uint256 icon_id;
        uint256 bg_color;
        uint256 icon_color_1;
        uint256 icon_color_2;
        uint256 icon_color_3;
        uint256 icon_color_4;
    }

    mapping(uint256 => Card) private cards_list;


    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * @dev Mints a card to an address with a tokenURI.
     * @param _to address of the future owner of the card
     */
    function mintTo(
        address _to, 
        string  memory _message, 
        uint256 _amount, 
        uint256 _NGO_id, 
        uint256 _icon_id, 
        uint256 _bg_color, 
        uint256 _icon_color_1,
        uint256 _icon_color_2,
        uint256 _icon_color_3,
        uint256 _icon_color_4

    ) internal returns(uint256 _token_id) {
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
        //string memory dona = Strings.toString(_amount/10**14);
        cards_list[_currentTokenId] = Card(msg.sender, _message, _amount, _NGO_id, _icon_id, _bg_color, _icon_color_1, _icon_color_2, _icon_color_3, _icon_color_4);
        emit Created(newTokenId, _to, _amount, _NGO_id);
        return newTokenId;
    }

    // Views
    function read_card(uint256 card_id) public view returns(string memory) {
        return cards_list[card_id].message;
    }

    function get_card(uint256 card_id) public view returns(Card memory) {
        return cards_list[card_id];
    }

    function _getNextTokenId() private view returns (uint256) { return _currentTokenId + 1; }
    function _incrementTokenId() private { _currentTokenId++; }

    function baseTokenURI() virtual public pure returns (string memory);

    function tokenURI(uint256 _tokenId) override public view virtual returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}