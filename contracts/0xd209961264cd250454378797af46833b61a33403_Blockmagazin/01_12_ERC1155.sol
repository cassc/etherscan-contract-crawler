// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// https://blockmagazin.de/
contract Blockmagazin is ERC1155, Ownable, Pausable {

    // Edition struct
    struct Edition {
        uint256 tokenId;
        string name;
        uint256 maxSupply;
        uint256 count;
        address[] partnerAddresses;
        uint256 price;
        bool mintEnabled;
    }

    // Mapping from token ID to edition
    mapping(uint256 => Edition) public editions;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    // Token uri
    string private baseUri;

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
    }

    /**
    * @dev withdraw eth from contract
    *
    * - `_recipient` recipient address.
    */
    function withdraw(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }

    /**
    * @dev return token uri
    *
    * - `_tokenId` edition tokeId.
    */
    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(
                baseUri,
                Strings.toString(_tokenId),
                ".json"));
    }

    /**
    * @dev add new edition
    *
    * - `_tokenId` edition tokeId.
    * - `_editionName` edition name.
    * - `_maxSupply` max token supply.
    * - `_partnerAddresses` partnerAddresses.
    * - `_price` edition price.
    * - `_mintEnabled` mint enabled.
    */
    function addEdition(uint256 _tokenId, string memory _editionName, uint256 _maxSupply, address[] memory _partnerAddresses, uint256 _price, bool _mintEnabled) public onlyOwner {
        require(_tokenId > 0, "Invalid token id provided.");
        require(editions[_tokenId].tokenId == 0, "Edition with tokenId already created.");
        editions[_tokenId] = Edition(_tokenId, _editionName, _maxSupply, 0, _partnerAddresses, _price, _mintEnabled);
    }

    /**
     * @dev change edition price
     *
     * - `_tokenId` edition tokeId.
     * - `_price` new edition price.
     */
    function setEditionPrice(uint256 _tokenId, uint256 _price) public onlyOwner {
        require(editions[_tokenId].tokenId != 0, "Edition not found.");
        editions[_tokenId].price = _price;
    }

    /**
     * @dev change edition mintable
    *
    * - `_tokenId` edition tokeId.
    * - `_mintEnabled` new flag.
    */
    function setEditionMintEnabled(uint256 _tokenId, bool _mintEnabled) public onlyOwner {
        require(editions[_tokenId].tokenId != 0, "Edition not found.");
        editions[_tokenId].mintEnabled = _mintEnabled;
    }

    /**
     * @dev add address to edition partnerAddresses
     *
     * - `_tokenId` edition tokeId.
     * - `_addresses` addresses to add.
     */
    function addToEditionPartnerAddresses(uint256 _tokenId, address[] calldata _addresses) public onlyOwner {
        require(editions[_tokenId].tokenId != 0, "Edition not found.");
        for (uint256 i = 0; i < _addresses.length; i++) {
            editions[_tokenId].partnerAddresses.push(_addresses[i]);
        }
    }

    /**
     * @dev See {ERC1155._setURI}
     *
     * - `_uri` new token uri.
     */
    function updatedUri(string memory _uri) public onlyOwner {
        _setURI(_uri);
        baseUri = _uri;
    }

    /**
     * @dev mint token
     *
     * - `_tokenId` edition tokeId.
     */
    function mint(uint256 _tokenId) public payable {
        require(editions[_tokenId].tokenId != 0, "Edition not found.");
        require(editions[_tokenId].count < editions[_tokenId].maxSupply, "Max token supply reached.");
        require(editions[_tokenId].mintEnabled, "Token mint is not enabled.");
        require(editions[_tokenId].price <= msg.value, "The sent value is not enough.");

        editions[_tokenId].count++;
        _mint(msg.sender, editions[_tokenId].tokenId, 1, "");
    }

    /**
    * @dev mint token for partner addresses
    *
    * - `_tokenId` edition tokeId.
    */
    function mintForPartnerAddress(uint256 _tokenId) public {
        require(editions[_tokenId].tokenId != 0, "Edition not found.");
        require(editions[_tokenId].count < editions[_tokenId].maxSupply, "Max token supply reached.");
        require(editions[_tokenId].mintEnabled, "Token mint is not enabled.");
        require(checkPartnerAddress(editions[_tokenId].tokenId, msg.sender), "Sender is not a listed partner.");
        editions[_tokenId].count++;
        _mint(msg.sender, editions[_tokenId].tokenId, 1, "");
    }

    /**
     * @dev check if edition partnerAddresses contains address
     * remove address from edition partnerAddresses
     *
     * - `_tokenId` edition tokeId.
     * - `_sender` msg.sender`.
     */
    function checkPartnerAddress(uint256 _tokenId, address _sender) internal returns (bool) {
        bool listed = false;
        for (uint256 i = 0; i < editions[_tokenId].partnerAddresses.length; i++) {
            if (_sender == editions[_tokenId].partnerAddresses[i]) {
                listed = true;
                for (uint256 j = i; j < editions[_tokenId].partnerAddresses.length - 1; j++) {
                    editions[_tokenId].partnerAddresses[j] = editions[_tokenId].partnerAddresses[j + 1];
                }
                editions[_tokenId].partnerAddresses.pop();
            }
        }
        return listed;
    }

    /**
    *
    * @dev
    * get edition struct by tokenId
    * - `_tokenId` edition tokeId.
    */
    function getEditionByTokenId(uint256 _tokenId) public view returns (Edition memory _edition) {
        return editions[_tokenId];
    }
}