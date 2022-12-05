// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Mondi is ERC721AQueryable, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    struct WhitelistData {
        uint256 presale;
        uint256 raffle;
    }

    uint256 public cost;
    uint256 public maxWhitelistSupply;
    uint256 public maxSupply;
    uint256 public maxWhitelistedPerWallet = 3;
    uint256 public maxRafflePerWallet=1;
    uint256 public maxMintAmountPerTx = 30;

    mapping(address => WhitelistData) private mintedWhitelistedPerAddress;

    bytes32 public merkleRoot;

    bool public whitelistMintEnabled = false;
    bool public raffleMintEnabled = false;

    bool public isSaleActive = false;
    bool public revealed = false;

    string private notRevealedUri;
    string private baseURI;
    
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
    }
    modifier mintRequire(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
        _;
    }
    function isWhitelisted(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    modifier whitelistRequire(uint256 _mintAmount, bytes32[] calldata _merkleProof){
        require(totalSupply() + _mintAmount <= maxWhitelistSupply, 'Max whitelist supply exceeded!');
        require(isWhitelisted(_merkleProof,keccak256(abi.encodePacked(_msgSender()))), 'Invalid proof!');
        require(mintedWhitelistedPerAddress[msg.sender].presale + _mintAmount <= maxWhitelistedPerWallet, "Limit per whitelisted wallet exceeded!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintRequire(_mintAmount) whitelistRequire(_mintAmount,_merkleProof){
        require(whitelistMintEnabled, 'The presale 1 sale is not active!');
        mintedWhitelistedPerAddress[msg.sender].presale += _mintAmount;
         _safeMint(msg.sender, _mintAmount);
    }

    function raffleMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintRequire(_mintAmount) whitelistRequire(_mintAmount,_merkleProof){
        require(raffleMintEnabled, 'The presale 2 is not active!');
        require(mintedWhitelistedPerAddress[msg.sender].raffle + _mintAmount <= maxRafflePerWallet, "maxRafflePerWallet exceeded!");
        mintedWhitelistedPerAddress[msg.sender].raffle += _mintAmount;
         _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) external payable mintRequire(_mintAmount){
        require(isSaleActive, 'Public Sale is not active!');
        _safeMint(msg.sender, _mintAmount);
    }

     function mintForAddress(uint256 _mintAmount, address _receiver) external onlyOwner {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
        require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
        _safeMint(_receiver, _mintAmount);
    }

    function flipWhitelistMintStatus() external onlyOwner {
        whitelistMintEnabled = !whitelistMintEnabled;
    }

    function flipRaffleMintStatus() external onlyOwner {
        raffleMintEnabled = !raffleMintEnabled;
    }

    function flipSaleStatus() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setMaxWhitelistSupply(uint256 _maxWhitelistSupply) external onlyOwner{
        maxWhitelistSupply = _maxWhitelistSupply;
    }

    function setMaxWhitelistedPerWallet(uint256 _maxWhitelistedPerWallet) external onlyOwner{
        maxWhitelistedPerWallet = _maxWhitelistedPerWallet;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }


    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setNotRevealedUri(string memory _notRevealedUri) external onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function setRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721A) returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentURI = _baseURI();
        require(bytes(currentURI).length > 0, "Base URI not yet set");
        return string(abi.encodePacked(currentURI, _tokenId.toString()));
    }

     /* Opensea Operator Filter Registry */
  // Requirement for royalties in OS
function setApprovalForAll(address operator, bool approved) public override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override (ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override (ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override (ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}