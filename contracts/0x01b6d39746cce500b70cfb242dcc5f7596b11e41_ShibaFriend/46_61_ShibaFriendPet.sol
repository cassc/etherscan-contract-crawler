//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

contract ShibaFriendPet is
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlUpgradeable
{
    struct ShibaDetail {
        bytes32 _id;
        uint64 tier;
        uint64 bacthId;
        uint64 minted_at;
    }
    uint64 public lockTime;
    mapping (uint256 => ShibaDetail) public ShibaDetails;
    string public tokenURIPrefix;
    string public tokenURISuffix;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    event MintBuy(address _recipient,bytes32 _shibaId ,uint64 _batchId ,uint64 _tier);
    function initialize() initializer public {
        __ERC721_init_unchained("SHIBANFT", "SHIBANFT");
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        lockTime = 90 days;
        tokenURIPrefix = "https://beta-api.shibafriend.io/pet/";
        tokenURISuffix = "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
       @dev Hook override for ERC721Enumerable
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override(ERC721EnumerableUpgradeable, ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, amount); // Call parent hook
    }

    function mintBuy(address _recipient, uint64 _tier ,uint64 _batchId)
        public
    {
        require(
            hasRole(MINTER_ROLE, msg.sender) ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ShibaFriendPet: Caller is not a minter"
        );

        bytes32 _shibaId;
        _shibaId = keccak256(abi.encodePacked(_batchId, _tier, block.timestamp, totalSupply()));
        ShibaDetail memory _shiba_detail = ShibaDetail(
                _shibaId,
                _tier,
                _batchId,
                uint64(block.timestamp)
        );
        ShibaDetails[uint(_shibaId)]= _shiba_detail;
         _mint(_recipient, uint(_shibaId));
        emit MintBuy(_recipient,_shibaId ,_batchId ,_tier);

    }

    function _transfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {

        require(block.timestamp > (ShibaDetails[tokenId].minted_at + lockTime) ,"SHFNFT: Still in lock time");
        super._transfer(from,to,tokenId);
    }
    function _burn(uint256 _tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        string memory _tokenURI = Strings.toHexString(_tokenId);
        return string(abi.encodePacked(tokenURIPrefix, _tokenURI, tokenURISuffix));
    }

    function setTokenURIAffixes(string memory _prefix, string memory _suffix)
        external
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        tokenURIPrefix = _prefix;
        tokenURISuffix = _suffix;
    }

    function getShibaDetail(uint256 _tokenId) public view returns (ShibaDetail memory) {
        return ShibaDetails[_tokenId];
    }
    function setLockTime(uint64 _lockTime)
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ShibaFriendPet: Caller is not an admin"
        );
        lockTime = _lockTime;
    }
}