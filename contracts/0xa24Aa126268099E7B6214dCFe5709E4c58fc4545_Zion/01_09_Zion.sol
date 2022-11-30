// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Zion is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum ContractMintState {
        PAUSED,
        WHITELIST,
        PUBLIC
    }

    ContractMintState public state = ContractMintState.PAUSED;

    string public uriPrefix = "";
    string public hiddenMetadataUri = "ipfs://QmRtoGVkaRgk4NNy2DP672EV9hKNDiV2GEEFmjJSpwBHmq";

    uint256 public whitelistEarlyCost = 0.0045 ether;
    uint256 public whiteListCost = 0.009 ether;
    uint256 public publicCost = 0.009 ether;

    uint256 public maxPerWalletPublic = 3;
    uint256 public maxMintAmountPerTx = 3;

    uint256 public maxSupply = 5555;

    bytes32 public whitelistMerkleRoot = 0xf855bcc24595ef2b6ec13caefeed5f9fa968c0cb758ba204497f101ee7897a22;

    mapping(address => uint256) public publicMinted;

    mapping(address => uint256) public whitelistMinted;

    constructor() ERC721A("Zion", "ZION") {}

    // OVERRIDES
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // MERKLE TREE
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function _leaf(address account, uint256 allowance) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(account, allowance))));
    }

    // MINTING FUNCTIONS
    function publicMint(uint256 amount) public payable {
        require(state == ContractMintState.PUBLIC, "Public mint is disabled");
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        require(amount > 0 && amount <= maxMintAmountPerTx, "Invalid mint amount");
        require(publicMinted[msg.sender] + amount <= maxPerWalletPublic);
        require(msg.value == publicCost * amount, "Insufficient funds");

        publicMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

    function mintAllowList(uint256 amount, uint256 allowance, bytes32[] calldata proof) public payable {
        require(state == ContractMintState.WHITELIST, "Allowlist mint is disabled");
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");

        if (totalSupply() > 555)
            require(msg.value >= whiteListCost * amount, "Insufficient funds");
        else
            require(msg.value >= whitelistEarlyCost * amount, "Insufficient funds");

        require(whitelistMinted[msg.sender] + amount <= allowance, "Can't mint that many");
        require(_verify(_leaf(msg.sender, allowance), proof), "Invalid proof");

        whitelistMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintForAddress(uint256 amount, address _receiver) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _safeMint(_receiver, amount);
    }

    // GETTERS

    function numberMinted(address _minter) public view returns (uint256) {
        return _numberMinted(_minter);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json")) : hiddenMetadataUri;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);
        uint256 ownerTokenIdx = 0;
        for (uint256 tokenIdx = _startTokenId(); tokenIdx <= totalSupply(); tokenIdx++) {
            if (ownerOf(tokenIdx) == _owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                ownerTokenIdx++;
            }
        }
        return ownerTokens;
    }

    // SETTERS
    function setState(ContractMintState _state) public onlyOwner {
        state = _state;
    }

    function setCosts(uint256 _whiteListCost, uint256 _whitelistEarlyCost, uint256 _publicCost) public onlyOwner {
        whiteListCost = _whiteListCost;
        whitelistEarlyCost = _whitelistEarlyCost;
        publicCost = _publicCost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Cannot increase the supply");
        maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxPerWalletPublic(uint256 _maxPerWalletPublic) public onlyOwner {
        maxPerWalletPublic = _maxPerWalletPublic;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    // WITHDRAW
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        bool success = true;
        (success,) = payable(0x1883d6E106499ab641503D436610A9AE3C20fa62).call {value : contractBalance}("");
        require(success, "Transfer failed");
    }
}