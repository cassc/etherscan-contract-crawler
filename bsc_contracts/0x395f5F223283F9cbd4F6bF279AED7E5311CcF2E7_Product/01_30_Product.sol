// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./ERC721Votes.sol";
import "./ProductFactory.sol";


/**
 * @title Product
 * Product - a contract for my non-fungible product.
 */
contract Product is ERC721Tradable,ERC721Votes {

    ProductFactory private productFactory;
    mapping(address=>uint256[]) private firstOwnerTokens;
    mapping(uint256=>address) private tokenFirstOwner;
    mapping(uint256 => string) private _baseTokenURIs;
    string private _currentBaseTokenURI;

    constructor()
    ERC721Tradable("GSMC", "GSMC")
    {
        _currentBaseTokenURI = baseTokenURI();
        _setupRole(DEFAULT_ADMIN_ROLE,msg.sender);
    }

    function baseTokenURI() override public pure returns (string memory){
        return "ipfs://bafybeieoqjvnvnskct3gjejnv2q77li3g6xqzz2dkp2rlgluymxb7c2nii/";
    }

    function currentBaseTokenURI() public view returns (string memory){
        return _currentBaseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked(_baseTokenURIs[_tokenId], Strings.toString(_tokenId)));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(balanceOf(to) < productFactory.maxMintQuantity(),"Receiver has reached maximum quantity allowed");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        require(balanceOf(to) < productFactory.maxMintQuantity(),"Receiver has reached maximum quantity allowed");
        _safeTransfer(from, to, tokenId, data);
    }

    function updateFactory (ProductFactory _productFactory) onlyOwner  public {
        productFactory = _productFactory;
        _setupRole(DEFAULT_ADMIN_ROLE,address(_productFactory));
    }

    function updateCurrentBaseTokenURI (string memory _baseTokenURI) onlyOwner  public {
        _currentBaseTokenURI = _baseTokenURI;
    }

    function listOwnerTokens(address owner) public view returns ( uint256[] memory){
        uint256[] memory ownerTokens;
        uint ownerBalance = balanceOf(owner);
        for(uint i=0; i<ownerBalance ;i++){
            ownerTokens[i] = tokenOfOwnerByIndex(owner,i);
        }
        return ownerTokens;
    }

    function listAllTokens() public view returns (uint256[] memory){
        return _allTokens;
    }

    function _safeMint(address to, uint256 tokenId) internal virtual override {
        _safeMint(to, tokenId, "");
        firstOwnerTokens[to].push(tokenId);
        tokenFirstOwner[tokenId] = to;
        _baseTokenURIs[tokenId] = _currentBaseTokenURI;
    }

    function firstOwnerOfToken(uint256 tokenId) public view returns (address) {
        return tokenFirstOwner[tokenId];
    }

    function firstOwnerTokensOf(address owner) public view returns (uint256[] memory){
        return firstOwnerTokens[owner];
    }
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        _transferVotingUnits(from, to, 1);
        super._afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Returns the balance of `account`.
     */
    function _getVotingUnits(address account) internal view virtual override returns (uint256) {
        return balanceOf(account);
    }

    /**
 * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
 * @dev Returns the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

}