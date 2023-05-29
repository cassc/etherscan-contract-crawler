// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LingBeggar is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    address public vaultAddress;

    string public baseURI = "";
    string public hiddenMetadataURI = "";
    string public baseURIExtension = ".json";

    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant VAULT_SUPPLY = 50;
    uint256 public constant MAX_MINT_WHITELIST = 2;
    uint256 public MAX_MINT_PUBLIC = 1;

    bytes32 public merkleRoot;

    bool public isWhitelistMintActive = false;
    bool public isPublicMintActive = false;
    bool public revealed = false;

    mapping(address => uint256) public totalMinted;

    constructor(
        string memory _hiddenMetadataURI,
        string memory _initBaseURI,
        bytes32 _merkleRoot
    ) ERC721A("LingBeggar", "LINGBEGGAR") {
        vaultAddress = msg.sender;
        hiddenMetadataURI = _hiddenMetadataURI;
        baseURI = _initBaseURI;
        merkleRoot = _merkleRoot;
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        vaultAddress = _vaultAddress;
    }

    modifier callerIsUser() {
        // solhint-disable-next-line avoid-tx-origin
        require(tx.origin == msg.sender, "Contract Denied");
        _;
    }

    function publicMint(uint256 _quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(isPublicMintActive, "Public sale is not active");
        require(_quantity > 0, "Invalid quantity");
        require(
            totalMinted[msg.sender] + _quantity <= MAX_MINT_PUBLIC,
            "Max mint reached"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply reached");
        totalMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // Whitelist
    function whitelistMint(uint256 _quantity, bytes32[] calldata _proof)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(isWhitelistMintActive, "Whitelist mint is not active");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(_quantity > 0, "Invalid quantity");
        require(
            totalMinted[msg.sender] + _quantity <= MAX_MINT_WHITELIST,
            "Max mint reached"
        );
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply reached");
        totalMinted[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    // Metadata
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (!revealed) {
            return hiddenMetadataURI;
        }

        string memory currentBaseURI = _baseURI();
        return
            string(
                abi.encodePacked(
                    currentBaseURI,
                    _tokenId.toString(),
                    baseURIExtension
                )
            );
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setHiddenMetadataURI(string memory _newURI) public onlyOwner {
        hiddenMetadataURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseExtension(string memory _newBaseURIExtension)
        public
        onlyOwner
    {
        baseURIExtension = _newBaseURIExtension;
    }

    // Admin
    function toggleWhitelistMint() external onlyOwner {
        isWhitelistMintActive = !isWhitelistMintActive;
    }

    function togglePublicSale() external onlyOwner {
        isPublicMintActive = !isPublicMintActive;
    }

    function closeSale() external onlyOwner {
        isWhitelistMintActive = false;
        isPublicMintActive = false;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    // For marketing and airdrop etc.
    function airdrop(address[] memory _team, uint256[] memory _teamMint)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _team.length; i++) {
            require(
                totalSupply() + _teamMint[i] <= MAX_SUPPLY,
                "Max supply exceeded"
            );
            _safeMint(_team[i], _teamMint[i]);
        }
    }

    function setMaxMintPublic(uint256 _newMaxMints) external onlyOwner {
        MAX_MINT_PUBLIC = _newMaxMints;
    }

    function teamMint() external onlyOwner {
        require(
            totalSupply() + VAULT_SUPPLY <= MAX_SUPPLY,
            "Max supply reached"
        );
        _safeMint(vaultAddress, VAULT_SUPPLY);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(vaultAddress).transfer(balance);
    }

    function getLuckyUserAddress(uint256 _index)
        public
        view
        returns (address[] memory)
    {
        uint256 sum = totalSupply();
        address[] memory luckyUsers = new address[](20);
        uint256 j;
        for (uint256 i = _index; i < sum; i += 100) {
            luckyUsers[j] = ownerOf(_index);
            j++;
        }
        return luckyUsers;
    }

    function _sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "unable to send ETH");
    }
}