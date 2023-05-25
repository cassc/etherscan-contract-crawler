pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./abstract/Whitelist.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ZeeMasks is ERC721, ERC721Enumerable, Ownable, Whitelist {
    /// @notice Emitted when the merkle root has been set.
    event MerkleRootSet(bytes32 merkleRoot);

    bool public mintIsActive = false;
    string private _baseURIextended;
    bytes32 internal _whitelistMerkleRoot;
    uint256 private publiclyMinted = 0;

    uint256 private fireClass = 0;
    uint256 private waterClass = 0;
    uint256 private grassClass = 0;

    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MAX_PUBLIC_MINT = 3000;

    mapping(address => bool) private minters;

    constructor() ERC721("Mask of ZEE", "MoZ") {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) external onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setMintState(bool newState) external onlyOwner {
        mintIsActive = newState;
    }

    function canMint(address account) external view returns(bool) {
        return minters[account] == false;
    }

    function mint(bytes32[] memory whitelistProof) external {
        uint256 ts = totalSupply();
        require(minters[msg.sender] == false, "Only single item can be minted per wallet");
        require(mintIsActive, "Minting not yet activated");
        require(ts < MAX_SUPPLY, "Mint would exceed max tokens");
        require(publiclyMinted < MAX_PUBLIC_MINT, "All tokens minted");
        require(_isValidMerkleProof(msg.sender, whitelistProof), "Wallet not whitelisted");

        minters[msg.sender] = true;
        _safeMint(msg.sender, ts);
        publiclyMinted++;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @inheritdoc IWhitelist
    function setWhitelistMerkleRoot(bytes32 merkleRoot)
    external
    override
    onlyOwner
    {
        _whitelistMerkleRoot = merkleRoot;

        emit MerkleRootSet(merkleRoot);
    }

    /// @inheritdoc IWhitelist
    function getWhitelistMerkleRoot() external view override returns (bytes32) {
        return _getWhitelistMerkleRoot();
    }

    /// @inheritdoc Whitelist
    function _getWhitelistMerkleRoot() internal view override returns (bytes32) {
        return _whitelistMerkleRoot;
    }

    /// @inheritdoc IWhitelist
    function isUserWhitelisted(address account, bytes32[] memory whitelistProof)
    external
    view
    override
    returns (bool)
    {
        return _isValidMerkleProof(account, whitelistProof);
    }

    function publiclyMintedTokens() external view returns (uint256)
    {
        return publiclyMinted;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }
}