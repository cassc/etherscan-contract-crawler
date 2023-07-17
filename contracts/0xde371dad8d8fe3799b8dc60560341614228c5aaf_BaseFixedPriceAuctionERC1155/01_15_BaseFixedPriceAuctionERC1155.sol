// SPDX-License-Identifier: MIT
// Author: Eric Gao (@itsoksami, https://github.com/Ericxgao)

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseFixedPriceAuctionERC1155 is ERC1155, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    struct TokenInfo {
        uint256 tokenId;
        uint256 whitelistMaxMint;
        uint256 publicListMaxMint;
        uint256 nonReservedMax;
        uint256 reservedMax;
        uint256 price;
    }

    string public prefix = "Capsule Whitelist Verification:";
    string private baseTokenURI = '';

    mapping(uint256 => mapping(address => uint256)) public _whitelistClaimed;
    mapping(uint256 => mapping(address => uint256)) public _publicListClaimed;

    mapping(uint256 => TokenInfo) private tokenInfos;
    
    mapping(uint256 => uint256) public nonReservedMinted;
    mapping(uint256 => uint256) public reservedMinted;
    mapping(uint256 => uint256) public max;
    mapping(uint256 => uint256) private mintedAmounts;

    PaymentSplitter private _splitter;

    constructor(
        address[] memory payees, 
        uint256[] memory shares,
        string memory _uri,
        TokenInfo[] memory _tokenInfos
    )
        ERC1155(_uri)
    {
        setTokenInfo(_tokenInfos);
        _splitter = new PaymentSplitter(payees, shares);
    }

    function setTokenInfo(TokenInfo[] memory _tokenInfos) public onlyOwner {
        uint256 len = _tokenInfos.length;
        TokenInfo memory tmpInfo;
        uint256 _tokenId;
        for (uint256 i = 0; i < len; i ++) {
            tmpInfo = _tokenInfos[i];
            _tokenId = tmpInfo.tokenId;
            tokenInfos[_tokenId] = tmpInfo;
            max[_tokenId] = tmpInfo.nonReservedMax + tmpInfo.reservedMax;
        }
    }

    function getTokenInfo(uint256 _tokenId) external view returns (TokenInfo memory) {
        return tokenInfos[_tokenId];
    }

    function totalSupply(uint256 _tokenId) public view returns (uint256) {
        return mintedAmounts[_tokenId];
    }

    function setPrice(uint256 _tokenId, uint256 _price) public onlyOwner {
        tokenInfos[_tokenId].price = _price;
    }

    function release(address payable account) external {
        _splitter.release(account);
    }

    function _hash(address _address) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(prefix, _address));
    }

    function _verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return (_recover(hash, signature) == owner());
    }

    function _recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        return hash.recover(signature);
    }

    function setPrefix(string memory _prefix) public onlyOwner {
        prefix = _prefix;
    }

    function setWhitelistMaxMint(uint256 _tokenId, uint256 _whitelistMaxMint) external onlyOwner {
        tokenInfos[_tokenId].whitelistMaxMint = _whitelistMaxMint;
    }

    function setPublicListMaxMint(uint256 _tokenId, uint256 _publicListMaxMint) external onlyOwner {
        tokenInfos[_tokenId].publicListMaxMint = _publicListMaxMint;
    }

    function mintCapsule(uint256 tokenId, uint256 numberOfTokens) external payable {
        require(_publicListClaimed[tokenId][msg.sender] + numberOfTokens <= tokenInfos[tokenId].publicListMaxMint, 'You cannot mint this many.');

        _publicListClaimed[tokenId][msg.sender] += numberOfTokens;
        _nonReservedMintHelper(tokenId, numberOfTokens);
    }
    
    function mintCapsuleWhitelist(bytes32 hash, bytes memory signature, uint256 tokenId, uint256 numberOfTokens) external payable {
        require(_verify(hash, signature), "This hash's signature is invalid.");
        require(_hash(msg.sender) == hash, "The address hash does not match the signed hash.");
        require(_whitelistClaimed[tokenId][msg.sender] + numberOfTokens <= tokenInfos[tokenId].whitelistMaxMint, 'You cannot mint this many.');

        _whitelistClaimed[tokenId][msg.sender] += numberOfTokens;
        _nonReservedMintHelper(tokenId, numberOfTokens);
    }

    function _nonReservedMintHelper(uint256 tokenId, uint256 numberOfTokens) internal {
        require(numberOfTokens * tokenInfos[tokenId].price == msg.value, "Invalid amount.");
        require(mintedAmounts[tokenId] + numberOfTokens <= max[tokenId], "Sold out.");

        mintedAmounts[tokenId] += numberOfTokens;
        _mint(msg.sender, tokenId, numberOfTokens, "");
    }

    function splitPayments() public payable onlyOwner {
        (bool success, ) = payable(_splitter).call{value: address(this).balance}(
        ""
        );
        require(success);
    }

    function mintReservedCapsule(uint256 tokenId) external onlyOwner {
        require(mintedAmounts[tokenId] == 0, 'Reserves already taken.');
        require(tokenInfos[tokenId].reservedMax != 0, 'reserved not set');
        _mint(msg.sender, tokenId, tokenInfos[tokenId].reservedMax, "");
        mintedAmounts[tokenId] = tokenInfos[tokenId].reservedMax;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString()));
    }
}