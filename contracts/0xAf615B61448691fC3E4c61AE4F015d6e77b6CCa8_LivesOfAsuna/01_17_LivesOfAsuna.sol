// Author: Eric Gao (@itsoksami, https://github.com/Ericxgao)

pragma solidity 0.8.10;

import "./BaseFixedPriceAuctionERC721A.sol";

contract LivesOfAsuna is BaseFixedPriceAuctionERC721A {
    mapping(uint256 => bool) private _usedNonces;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) private _variableWhitelistAmounts;

    string public tokenURIPrefix = "Lives of Asuna Token URI Verification:";
    string public mintWhitelistWithAmountPrefix = "Lives of Asuna Whitelist Verification:";

    constructor(
        address[] memory payees, 
        uint256[] memory shares,
        string memory name,
        string memory symbol,
        uint256 _whitelistMaxMint, 
        uint256 _publicListMaxMint,
        uint256 _nonReservedMax,
        uint256 _reservedMax,
        uint256 _price
    )
        BaseFixedPriceAuctionERC721A(payees, shares, name, symbol, _whitelistMaxMint, _publicListMaxMint, _nonReservedMax, _reservedMax, _price)
    {
    }

    function _hashSetTokenURI(string memory _prefix, address _address, string memory _tokenURI, uint256 _nonce) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_prefix, _address, _tokenURI, _nonce));
    }

    function _hashRegisterForWhitelistWithAmount(string memory _prefix, address _address, uint256 amount) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_prefix, _address, amount));
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI, uint256 nonce, bytes32 hash, bytes calldata signature) 
        external
    {       
        require(_verify(hash, signature), "Signature invalid.");
        require(_hashSetTokenURI(tokenURIPrefix, msg.sender, _tokenURI, nonce) == hash, "Hash invalid.");
        require(!_usedNonces[nonce], "Nonce already used.");
        require(ownerOf(tokenId) == msg.sender, "You do not own this token.");

        _usedNonces[nonce] = true;
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');

        string memory directTokenURI = _tokenURIs[tokenId];

        if (bytes(directTokenURI).length > 0) {
            return directTokenURI;
        }

        return super.tokenURI(tokenId);
    }

    function registerAndMintForWhitelist(bytes32 hash, bytes calldata signature, uint256 numberOfTokens, uint256 customLimit) external payable {
        require(_verify(hash, signature), "Signature invalid.");
        require(_hashRegisterForWhitelistWithAmount(mintWhitelistWithAmountPrefix, msg.sender, customLimit) == hash, "Hash invalid.");
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= customLimit, 'You cannot mint this many.');
        require(_whitelistClaimed[msg.sender] + numberOfTokens <= whitelistMaxMint, 'You cannot mint this many.');

        _whitelistClaimed[msg.sender] += numberOfTokens;
        _nonReservedMintHelper(numberOfTokens);
    }
}