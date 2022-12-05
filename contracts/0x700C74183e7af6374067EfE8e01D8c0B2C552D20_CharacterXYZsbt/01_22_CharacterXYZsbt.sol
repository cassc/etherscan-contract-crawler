// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract CharacterXYZsbt is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    address public fundsReciever;
    uint256 public SBTfee;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    function initialize(uint256 _SBTfee, address _fundsReciever)
        public
        initializer
    {
        __ERC721_init("CharacterXYZsbt", "CharacterXYZsbt");
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);

        SBTfee = _SBTfee;
        fundsReciever = _fundsReciever;
    }

    //----- PUBLIC FUNCTIONS -----//

    function safeMint(address to) public payable {
        require(msg.value == SBTfee, "Value sent not equal to SBT Fee");

        AddressUpgradeable.sendValue(payable(fundsReciever), msg.value);

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    //----- ADMINISTRATIVE FUNCTIONS -----//

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function freeMint(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function setSBTfee(uint256 _value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        SBTfee = _value;
    }

    function setFundsReciever(address _fundsReciever)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        fundsReciever = _fundsReciever;
    }

    function setTokenUri(uint256 tokenId, string calldata uri)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        _setTokenURI(tokenId, uri);
    }

    //----- Read FUNCTIONS -----//
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function tokensMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    //----- Internal and UUPS FUNCTIONS -----//

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
        require(from == address(0) || to == address(0), "Cannot Transfer SBT");
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}