// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BigEyeNFT is ERC721, ERC2981, ContextMixin, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _burntTokenIds;
    address proxyRegistryAddress;
    string public baseTokenURI;
    string public contractURI;
    uint8 constant private totalTokenClass = 25;
    mapping(address=>mapping(uint8=>bool)) public isClassWhitelisted;
    mapping(address=>mapping(uint8=>bool)) public isClassMinted;
    mapping(uint256=>uint8) public classForTokenId;
    mapping(uint8=>uint256) public mintFee;

    event Whitelisted(address minter, uint8 class, bool whitelist);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        string memory _baseTokenURI,
        string memory _contractURI,
        uint96 _royaltyFee
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _setDefaultRoyalty(msg.sender, _royaltyFee);
        _initializeEIP712(_name);
        baseTokenURI = _baseTokenURI;
        contractURI=_contractURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFee) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }
    
    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function updateMintFee(uint8 _class, uint256 _mintFee) external onlyOwner {
        require(_class<totalTokenClass && _class>=0, "class range is 0 ~ 24");
        mintFee[_class] = _mintFee;
    }

    function whitelistForMint(address _minter, uint8 _class, bool _whitelist) external onlyOwner {
        require(_class<totalTokenClass && _class>=0, "class range is 0 ~ 24");
        require(_whitelist!=isClassWhitelisted[_minter][_class], "Whitelist status is the same");
        require(!isClassMinted[_minter][_class], "Already minted");
        isClassWhitelisted[_minter][_class] = _whitelist;
        emit Whitelisted(_minter, _class, _whitelist);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current()-_burntTokenIds.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
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

    function supportsInterface(bytes4 interfaceId)
        public view virtual override(ERC721, ERC2981)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        delete classForTokenId[tokenId];
        _burntTokenIds.increment();
        _resetTokenRoyalty(tokenId);
    }

    function burn(uint256 tokenId)
        external {
        require(ERC721.ownerOf(tokenId) == _msgSender(), "Only owner can burn");
        _burn(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(_tokenId);
        string memory _tokenURI = Strings.toString(classForTokenId[_tokenId]);
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(_tokenId);
    }

    function mintNFT(address recipient, uint8 _class)
        public payable
        returns (uint256) {
        require(_class >= 0 && _class < totalTokenClass, "class range is 0 ~ 24");
        require(isClassWhitelisted[_msgSender()][_class], "Not whitelisted");
        require(!isClassMinted[_msgSender()][_class], "Already minted");
        require(msg.value == mintFee[_class], "Transaction value did not equal the mint price");        
        uint256 newItemId = _tokenIds.current();
        classForTokenId[newItemId] = _class;
        _safeMint(recipient, newItemId);
        isClassMinted[_msgSender()][_class]=true;
        _tokenIds.increment();
        return newItemId;
    }

    function withdrawPayments(address payable payee) public onlyOwner {
        (bool success, ) = payee.call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}