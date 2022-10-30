// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin/token/ERC721/ERC721.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Counters.sol";
import "openzeppelin/utils/Strings.sol";
import "openzeppelin/token/ERC721/extensions/ERC721Royalty.sol";
import "forge-std/console2.sol";


contract InvestmentNFT is ERC721, ERC721Royalty, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    event PairUpgrade(uint256 token1, uint256 token2);

    // Needed for minting
    Counters.Counter private _tokenIdCounter;
    uint256 public immutable maxSupply;

    /// Base URL for the token metadata, eg. "ipfs://something/"
    string public baseUrl;
    // Extension of the metadata file.
    // You can set this to ".json" to have tokenURI() construct an url with
    // ".json" at the end.
    string internal metadataFileExt = ".json";
    /// If true - metadata can't be updated anymore.
    bool public metadataUrlLocked = false;

    /// Pass an ID to check if given token ID has been upgraded.
    mapping (uint256 => bool) public isUpgraded;
    /// A list of blocked NFT operators - operators may be blocked for violating
    /// trust like not respecting royalties. If you wonder what operator is - OpenSea,
    /// Rarible, Foundation are examples of operators. Only operators may be blocked,
    /// this does not block any user from transferring or selling their NFTs.
    mapping (address => bool) public isOperatorBlocked;
    
    constructor(string memory _baseUrl, uint256 _maxSupply, uint256[] memory upgraded) ERC721("The INFT", "INFT") {
        baseUrl = _baseUrl;
        maxSupply = _maxSupply;
        for (uint256 i = 0; i < upgraded.length; i++) {
            isUpgraded[upgraded[i]] = true;
        }
    }

    function safeMint(address to) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= maxSupply, "Max supply reached");
        _safeMint(to, tokenId);
        return tokenId;
    }

    function safeBatchMint(address[] memory to) public onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            safeMint(to[i]);
        }
    }

    /// Number of NFTs which already have been minted.
    function numberMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// Changes the base URL for the token metadata.
    function setMetadataUrl(string memory _baseUrl) public onlyOwner {
        require(!metadataUrlLocked, "Base URL is locked");
        require(bytes(_baseUrl).length > 0, "Base URL cannot be empty");
        baseUrl = _baseUrl;
    }

    /// Blocks the ability to change the metadata base URL in the future.
    /// Only contract owner can do this.
    function lockMetadataUrl() public onlyOwner {
        metadataUrlLocked = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory mod = isUpgraded[tokenId] ? "-upgraded" : "";

        return string(abi.encodePacked(baseUrl, tokenId.toString(), mod, metadataFileExt));
    }
    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // check if token needs upgrading!
        if (!isUpgraded[tokenId] && to != address(0) && to != owner()) {
            uint256 pairedId = getPairedToken(tokenId);
            // if both paired token and the token we are about to transfer are owned by
            // the same address - we upgrade both tokens

            if(_exists(pairedId) && ownerOf(pairedId) == to) {
                isUpgraded[tokenId] = true;
                isUpgraded[pairedId] = true;
                emit PairUpgrade(tokenId, pairedId);
            }
        }
    }

    // based on tokenId returns it's paired token's ID
    function getPairedToken(uint256 tokenId) public pure returns (uint256) {
        assert(tokenId > 0);
        return tokenId % 2 == 0 ? tokenId - 1 : tokenId + 1;
    }

    /// Changes the royalties of the NFTs.
    /// @param receiver address of a wallet which should receive the royalties
    /// @param feeNumerator royalty percentage, denumerator is 10000 so 1000 = 10%, 100 = 1%, 300 = 3% etc.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Operator blocking
    function blockOperators(address[] memory operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            address op = operators[i];
            require(op != address(0), "Operator cannot be zero address");
            require(op != owner(), "Owner cannot be blocked");
            isOperatorBlocked[op] = true;
        }
    }

    function unblockOperators(address[] memory operators) external onlyOwner {
        for (uint256 i = 0; i < operators.length; i++) {
            isOperatorBlocked[operators[i]] = false;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Check if not a blocked operator. This will only block dishonest operators
        // (imagine OpenSea one day deciding they won't respect royalties anymore)
        if (from != to && isOperatorBlocked[_msgSender()]) {
            revert("Operator is blocked");
        }
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if(approved == true && isOperatorBlocked[operator]) {
            revert("Operator is blocked");
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address to, uint256 tokenId) public override {
        if(isOperatorBlocked[to]) {
            revert("Operator is blocked");
        }
        super.approve(to, tokenId);
    }

    // overrides needed by solidity

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}