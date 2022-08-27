//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Min.sol";

abstract contract ERC721Base is Ownable, ERC721Min {
    using Strings for uint256;

    string internal _contractURI;
    string internal _tokenBaseURI = ""; // metadata URI
    mapping(uint32 => string) public tokenURIs; // individual/unique metadata per token
    bool public useBaseURIOnly = true;

    error TransferOfTokenThatIsNotOwn();
    error InconsistentArrayLengths(uint array1, uint array2);
    error AddressIsZero();

    constructor(string memory name, string memory symbol)
        ERC721Min(name, symbol)
    {}

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

    // mint NFTs to a list of receivers
    function _airdrop(address[] calldata receivers, uint256[] calldata amounts)
        internal
        virtual
        onlyOwner
        consistentArrayLengths(receivers.length, amounts.length)
    {
        for (uint256 x; x < receivers.length; x++) {
            for (uint256 y; y < amounts[x]; y++) {
                _mint(receivers[x]);
            }
        }
    }

    // mint NFTs to single receiver
    function _batchMint(address receiver, uint256 amount)
        internal
    {
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

    function setTokenURI(uint32 tokenID, string calldata uri)
        external
        onlyOwner
    {
        tokenURIs[tokenID] = uri;
    }

    // returns specific tokenURI is one is assigned to the token
    // if not, then returns URI for NFT type using tokenBaseURI
    function tokenURI(uint256 tokenID)
        external
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenID)) revert NonexistentToken(tokenID);
        if (useBaseURIOnly) return _tokenBaseURI;
        if (bytes(tokenURIs[uint32(tokenID)]).length != 0)
            return tokenURIs[uint32(tokenID)];
        return
            string(
                abi.encodePacked(
                    _tokenBaseURI,
                    tokenID.toString()
                )
            );
    }

    function useBaseURI(bool value) external onlyOwner {
        useBaseURIOnly = value;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function isOwnerOf(address account, uint32[] calldata tokenIDs)
        public
        view
        returns (bool)
    {
        for (uint256 i; i < tokenIDs.length; i++) {
            if (_owners[tokenIDs[i]] != account) return false;
        }
        return true;
    }
}