//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC721MinUpgradeable.sol";

abstract contract ERC721BaseUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ERC721MinUpgradeable
{
    using StringsUpgradeable for uint256;

    string internal _contractURI;
    string internal _tokenBaseURI; // metadata URI
    mapping(uint32 => string) public tokenURIs; // individual/unique metadata per token

    error TransferOfTokenThatIsNotOwn();
    error InconsistentArrayLengths(uint array1, uint array2);
    error AddressIsZero();

    function __ERC721BaseUpgradeable_init(
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        __ERC721BaseUpgradeable_init_unchained(_name, _symbol);
    }

    function __ERC721BaseUpgradeable_init_unchained(
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        __ERC721MinUpgradeable_init(_name, _symbol);
        OwnableUpgradeable.__Ownable_init();
    }

    modifier consistentArrayLengths(uint arrayLength1, uint arrayLength2) {
        if (arrayLength1 != arrayLength2)
            revert InconsistentArrayLengths({
                array1: arrayLength1,
                array2: arrayLength2
            });
        _;
    }

    modifier notZeroAddress(address _address) {
        if (_address == address(0)) revert AddressIsZero();
        _;
    }

    modifier senderOwnsToken(uint32 id) {
        if (ownerOf(id) != _msgSender()) revert TransferOfTokenThatIsNotOwn();
        _;
    }

    modifier senderOwnsTokens(uint32[] calldata ids) {
        if (!isOwnerOf(_msgSender(), ids)) revert TransferOfTokenThatIsNotOwn();
        _;
    }

    // mint Nfts to a list of receivers, assigning an Nft type to each minted Nft
    function _airdrop(address[] calldata receivers) internal virtual onlyOwner {
        for (uint256 i; i < receivers.length; i++) {
            _mint(receivers[i]);
        }
    }

    // mint Nfts to single receiver
    function _batchMint(address receiver, uint256 amount) internal {
        for (uint256 i; i < amount; i++) {
            _mint(receiver);
        }
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _tokenBaseURI = uri;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
    }

    function setTokenURI(uint32 tokenId, string calldata uri)
        external
        onlyOwner
    {
        tokenURIs[tokenId] = uri;
    }

    // returns specific tokenURI is one is assigned to the token
    // if not, then returns URI for Nft type using tokenBaseURI
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonexistentToken(tokenId);
        if (bytes(tokenURIs[uint32(tokenId)]).length != 0)
            return tokenURIs[uint32(tokenId)];
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function isOwnerOf(address account, uint32[] calldata tokenIds)
        public
        view
        returns (bool)
    {
        for (uint256 i; i < tokenIds.length; i++) {
            if (_owners[tokenIds[i]] != account) return false;
        }
        return true;
    }
}