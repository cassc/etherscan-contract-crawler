// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Orb360 is ERC1155, ERC1155Supply, AccessControl, ERC2981 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TYPE_ADMIN_ROLE = keccak256("TYPE_ADMIN_ROLE");

    string public name = "Orb360";
    string public symbol = "0RB360";

    struct TokenSetting {
        bool exists;
        uint256 maxSupply;
        bool purchasable;
        uint256 price;
        string uri;
    }
    mapping(uint256 => TokenSetting) tokenIdToSettings;
    address private _mintFeeRecipient = 0xd980cA4273Af75Cd95DC4e4C74E09aF4ec08cE15;

    modifier tokenSettingExists(uint256 _id) {
        require(tokenIdToSettings[_id].exists, "Orb360: This token does not exist");
        _;
    }

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(TYPE_ADMIN_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function addTokenType(uint256 _maxSupply, bool _purchasable, uint256 _price, string memory _uri)
        public 
        onlyRole(TYPE_ADMIN_ROLE)
    {
        _tokenIdCounter.increment();

        tokenIdToSettings[_tokenIdCounter.current()] = TokenSetting(
            true,
            _maxSupply,
            _purchasable,
            _price,
            _uri
        );
    }

    function setTokenRoyalty(uint256 _tokenId, address _recipient, uint256 _percent) 
        public
        onlyRole(TYPE_ADMIN_ROLE)
    {
        require(_percent <= 10, "Orb360: Max royalty is 10%");
        require(_recipient != address(0), "Orb360: Recipient is zero address");

        _setTokenRoyalty(_tokenId, _recipient, uint96(_percent*100));
    }

    function purchase(address _to, uint256 _id, uint256 _amount)
        public 
        payable
        tokenSettingExists(_id)
    {
        require(tokenIdToSettings[_id].purchasable, "Orb360: Token not purchasable");
        require(msg.value == tokenIdToSettings[_id].price * _amount, "Orb360: Invalid amount sent");
        mint(_to, _id, _amount, "sad");
        payable(_mintFeeRecipient).transfer(tokenIdToSettings[_id].price * _amount);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        internal
        tokenSettingExists(id)
    {
        require(totalSupply(id) + amount <= tokenIdToSettings[id].maxSupply, "Orb360: Max supply exceeded");
        _mint(account, id, amount, data);
    }

    function airdrop(uint256 _tokenId, address[] memory _recipients, uint256[] memory _amounts) 
        public
        onlyRole(MINTER_ROLE)
        tokenSettingExists(_tokenId)
    {
        require(_recipients.length == _amounts.length, "Orb360: Invalid mapping of amounts to recipients");

        for(uint256 i = 0; i < _recipients.length; i++) {
            mint(_recipients[i], _tokenId, _amounts[i], "");
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) 
    {
        return tokenIdToSettings[tokenId].uri;
    }

    function setTokenUri(uint _tokenId, string memory _uri) 
        public
        onlyRole(TYPE_ADMIN_ROLE)
        tokenSettingExists(_tokenId)
    {
        tokenIdToSettings[_tokenId].uri = _uri;
    }

    function setMintFeeRecipient(address recipient)
    public
    onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _mintFeeRecipient = recipient;
    }

    function getTokenSettings(uint256 _tokenId) public view returns (TokenSetting memory) {
        return tokenIdToSettings[_tokenId];
    }

    function withdraw(uint amount, address payable ethReceiver) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool) 
    {
        require(amount <= address(this).balance,"Invalid amount requested");
        ethReceiver.transfer(amount);
        return true;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}