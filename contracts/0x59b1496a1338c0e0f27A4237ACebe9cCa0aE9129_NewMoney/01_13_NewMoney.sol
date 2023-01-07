// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat/console.sol";
import "./ERC721.sol";

contract NewMoney is ERC721, Pausable, Ownable {
    uint8 public constant MAX_SUPPLY = 100;

    string private baseURI;

    address private _signer;
    mapping(uint256 => bool) private _usedNonces;
    mapping(uint256 => bool) private _boughtTokens;
    mapping(uint256 => string) private _tokenURIs;

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    event PrivateExchangeTransfer(address indexed from, address indexed to, uint256 tokenID);

    constructor(string memory uri, address _owner) ERC721("New Money", "NM$") {
        _signer = owner();
        
        baseURI = uri;

        // Mint all the tokens
        super._setBalances(_owner, 300);
        for (uint8 i = 0; i < MAX_SUPPLY; i++) {
            super._setOwners(i, _owner);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function setSigner(address signer)
        external
        onlyOwner
    {
        _signer = signer;
    }

    function updateBaseURI(string memory uri)
        external
        onlyOwner
    {
        baseURI = uri;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // transfer token ownership and set a new tokenURI
    function transfer(address to, uint256 tokenId, uint256 nonce, Signature memory signature)
        external
        whenNotPaused
    {
        // ensure nonce hasn't been used before
        require(!_usedNonces[nonce], "Nonce already used.");
        
        require(
            _isVerifiedSignature(_createTransferMessageDigest(ownerOf(tokenId), to, tokenId, nonce), signature), 
            "Signature is not valid."
        );

        require(!isBoughtOffPrivateExchange(tokenId), "Bought tokens can't be traded on the private exchange.");

        // prevent token from being transferred to itself
        require(to != ownerOf(tokenId), "Cannot transfer to yourself.");

        // add nonce to used nonces
        _usedNonces[nonce] = true;

        emit PrivateExchangeTransfer(ownerOf(tokenId), to, tokenId);

        _safeTransfer(ownerOf(tokenId), to, tokenId, "");
        
    }

    function buyOffPrivateExchange(uint256 tokenId, Signature memory signature)
        external
        payable
        whenNotPaused
    {
        require(
            _isVerifiedSignature(_createBuyMessageDigest(msg.sender, tokenId, msg.value), signature), 
            "Signature is not valid."
        );

        require(ownerOf(tokenId) == msg.sender, "Only token owners can buy off private exchange.");

        _boughtTokens[tokenId] = true;
    }

    function isBoughtOffPrivateExchange(uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _boughtTokens[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory) 
    {
        // if the token is bought off private exchange, return the URI
        if (_boughtTokens[tokenId]) {
            return _tokenURIs[tokenId];
        }
        return super.tokenURI(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(isBoughtOffPrivateExchange(tokenId), "Token must be bought off private exchange to transfer.");
        
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(isBoughtOffPrivateExchange(tokenId), "Token must be bought off private exchange to transfer.");
        
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override
    {
        require(isBoughtOffPrivateExchange(tokenId), "Token must be bought off private exchange to approve.");
        
        super.approve(to, tokenId);
    }

    function withdrawFunds()
        external
        onlyOwner
        whenNotPaused
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Override _baseURI
    function _baseURI()
        internal
        view
        override(ERC721) returns (string memory)
    {
        return baseURI;
    }
    
    /// @dev check that the coupon sent was signed by the coupon signer
    function _isVerifiedSignature(bytes32 digest, Signature memory signature)
        internal
        view
        returns (bool)
    {
        address signer = ecrecover(digest, signature.v, signature.r, signature.s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer == _signer;
    }

    function _createTransferMessageDigest(address _from, address _to, uint _tokenId, uint _nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_from, _to, _tokenId, _nonce))
            )
        );
    }

    function _createBuyMessageDigest(address _owner, uint _tokenId, uint _price)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(_owner, _tokenId, _price))
            )
        );
    }
}