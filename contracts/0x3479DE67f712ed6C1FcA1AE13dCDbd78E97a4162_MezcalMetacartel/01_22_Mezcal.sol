// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MezcalMetacartel is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct AddressNumberPair {
        address address_;
        uint number_;
    }

    CountersUpgradeable.Counter private supplyCounter;

    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

    uint256 public constant MAX_SUPPLY = 102;
    address[MAX_SUPPLY] private numberMap;
    string private customBaseURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, string memory customBaseURI_) public initializer {
        __ERC721_init("MetacartelMezcal", "MVMEZCAL");
        __ERC721URIStorage_init();
        __Ownable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        customBaseURI = customBaseURI_;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(WHITELISTER_ROLE, _owner);
    }

    /** MINTING **/
    function mint(uint256 id) public {
        require(numberMap[id - 1] == msg.sender);
        require(id >= 1 && id <= 102);
        require(totalSupply() + 1 <= MAX_SUPPLY, "Exceeds max supply");
        _mint(msg.sender, id - 1);
        supplyCounter.increment();
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    /** API **/

    function addToWhitelist(
        address address_,
        uint256 token_
    ) public onlyRole(WHITELISTER_ROLE) {
        require(token_ >= 1 && token_ <= 102);
        require(numberMap[token_ - 1] == address(0));
        numberMap[token_ - 1] = address_;
    }

    function editFromWhitelist(
        address address_,
        uint256 token_
    ) public onlyRole(WHITELISTER_ROLE) {
        require(token_ >= 1 && token_ <= 102);
        require(numberMap[token_ - 1] != address(0));
        require(numberMap[token_ - 1] != address_);
        require(_ownerOf(token_ - 1) != numberMap[token_ - 1]);
        numberMap[token_ - 1] = address_;
    }

    function removeFromWhitelist(
        uint256 token_
    ) public onlyRole(WHITELISTER_ROLE) {
        require(token_ >= 1 && token_ <= 102);
        require(_ownerOf(token_ - 1) != numberMap[token_ - 1]);
        numberMap[token_ - 1] = address(0);
    }

    function getNumbers(address _address) public view returns (uint[] memory) {
        uint[] memory numberList = new uint[](102);
        uint index = 0;
        for (uint i = 0; i < 102; i++) {
            if (numberMap[i] == _address) {
                numberList[index] = i + 1;
                index++;
            }
        }
        return numberList;
    }

    function getAddressNumberList()
        public
        view
        onlyRole(WHITELISTER_ROLE)
        returns (AddressNumberPair[] memory)
    {
        AddressNumberPair[] memory list = new AddressNumberPair[](102);
        uint index = 0;
        for (uint i = 0; i < 102; i++) {
            if (numberMap[i] != address(0)) {
                list[index] = AddressNumberPair({
                    address_: numberMap[i],
                    number_: i
                });
                index++;
            }
        }
        return list;
    }

    /** URI HANDLING **/

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    // overwrites

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function setTokenURI(
        uint256 _token,
        string memory _url
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._setTokenURI(_token, _url);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        supplyCounter.decrement();
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}