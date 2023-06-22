// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract SKAPES is Ownable, ERC721A, ReentrancyGuard {
    bytes32 private _ogMerkleRoot;
    uint256 private _collectionSize;
    bool private _isMintActive = false;
    bool private _isRevealed = false;
    string private _tokenURIPrefix;
    string private _tokenURISuffix;
    address private _vaultAddress;
    address private _ownerAddress1;
    address private _ownerAddress2;
    address private _ownerAddress3;
    uint256 private _ogMintCost = 40000000000000000; // .04 Eth
    uint256 private _publicMintCost = 40000000000000000; // .04 Eth

    enum MintStateOptions{OG, Public}
    MintStateOptions _mintState = MintStateOptions.OG;

    constructor(
        uint256 collectionSize,
        address vaultAddress,
        address ownerAddress1,
        address ownerAddress2,
        address ownerAddress3
        ) ERC721A("SKAPES", "SKAPES") {
            _collectionSize = collectionSize;
            _vaultAddress = vaultAddress;
            _ownerAddress1 = ownerAddress1;
            _ownerAddress2 = ownerAddress2;
            _ownerAddress3 = ownerAddress3;
    }

    mapping (address => uint) _ogOwnerTransactionCount;

    function toBytes32(address addr) pure internal returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function setIsMintActive(bool isMintActive) public onlyOwner {
        _isMintActive = isMintActive;
    }

    function getIsMintActive() public view returns (bool) {
        return _isMintActive;
    }

    function setIsRevealed(bool isRevealed) public onlyOwner {
        _isRevealed = isRevealed;
    }

    function getIsRevealed() public view returns (bool) {
        return _isRevealed;
    }

    function setMintState(MintStateOptions newMintState) public onlyOwner {
        _mintState = newMintState;
    }

    function getMintState() public view returns (MintStateOptions) {
        return _mintState;
    }

    function getTokenURIPrefix() internal view virtual returns (string memory) {
        return _tokenURIPrefix;
    }

    function setTokenURIPrefix(string calldata newURIPrefix) external onlyOwner {
        _tokenURIPrefix = newURIPrefix;
    }

     function getTokenURISuffix() internal view virtual returns (string memory) {
        return _tokenURISuffix;
    }

    function setTokenURISuffix(string calldata newURISuffix) external onlyOwner {
        _tokenURISuffix = newURISuffix;
    }

    function setOGMintCost(uint256 newCost) public onlyOwner() 
    {
        _ogMintCost = newCost;
    }

    function setPublicMintCost(uint256 newCost) public onlyOwner() 
    {
        _publicMintCost = newCost;
    }

    function setOGMerkleRoot(bytes32 ogMerkleRoot) external onlyOwner {
        _ogMerkleRoot = ogMerkleRoot;
    }

    function isUserOG(bytes32[] calldata ogMerkleProof) public view returns (bool) {
        return MerkleProof.verify(ogMerkleProof, _ogMerkleRoot, toBytes32(msg.sender));
    }

    function didUserMintOG() public view returns (bool) {
        return _ogOwnerTransactionCount[msg.sender] == 1;
    }

    function ownerMint(uint256 quantity) external payable {
        require(quantity > 0);
        require(
            totalSupply() + quantity <= _collectionSize,
            "sold out"
        );
        require(msg.sender == _vaultAddress || msg.sender == _ownerAddress1|| msg.sender == _ownerAddress2|| msg.sender == _ownerAddress3, "You're not an owner. Let's not try that again.");

        _safeMint(msg.sender, quantity);
    }

    function OGMint(uint256 quantity, bytes32[] calldata ogMerkleProof) external payable nonReentrant {
        require(isUserOG(ogMerkleProof) == true, "You are not an OG");
        require(_isMintActive, "Mint is not available at this time");
        require(_mintState == MintStateOptions.OG, "OG mint is not available at this time");
        require(_ogOwnerTransactionCount[msg.sender] < 1, "Each address may only perform one transaction in this phase of the mint");
        require(quantity > 0);
        require(quantity <= 2, "You cannot mint more than 2 SKAPES at this stage in the mint");
        require(
            totalSupply() + quantity <= _collectionSize,
            "sold out"
        );
        require(msg.value >= SafeMath.mul(_ogMintCost, quantity), "Not enough funds");
        
        _safeMint(msg.sender, quantity);

        _ogOwnerTransactionCount[msg.sender] += 1;
    }

    function PublicMint(uint256 quantity) external payable nonReentrant {
        require(_isMintActive, "Mint is not available at this time");
        require(_mintState == MintStateOptions.Public, "Public mint is not available at this time");
        require(quantity > 0);
        require(quantity <= 2, "You cannot mint more than 2 SKAPES in a single transaction");
        require(
            totalSupply() + quantity <= _collectionSize,
            "sold out"
        );
        require(msg.value >= SafeMath.mul(_publicMintCost, quantity), "Not enough funds");

        _safeMint(msg.sender, quantity);
    }

    function withdraw() external onlyOwner nonReentrant {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_tokenURIPrefix).length == 0) {
            return "";
        }

        string memory tokenIdString = Strings.toString(tokenId);

        if (!_isRevealed) {
            return string(abi.encodePacked(_tokenURIPrefix));
        } else {
            return string(abi.encodePacked(_tokenURIPrefix, tokenIdString, _tokenURISuffix));
        }
    }
}