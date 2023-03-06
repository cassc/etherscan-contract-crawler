// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract Noby is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum ContractMintState {
        PAUSED,
        PUBLIC,
        ALLOWLIST,
        WHITELIST
    }

    uint256 public maxSupply = 780;
    uint256 public publicSupply = 780;

    string public uriPrefix = "";
    // // 
    string public hiddenMetadataUri =
        "ipfs://QmTQdPZ6p9vc7firTN44kX9psndz5EZPoupWVjT3sPCtWw";

    uint256 public publicCost = 0.1 ether;
    uint256 public allowlistCost = 0.1 ether;
    uint256 public whitelistCost = 0 ether;

    constructor(
        bytes32 wlRoot,
        ContractMintState mintState,
        string memory _uri
    ) ERC721A("Noby's Nft", "NOBY") {
        setWhitelistMerkleRoot(wlRoot);
        setAllowlistMerkleRoot(wlRoot);
        setState(mintState);
        setUriPrefix(_uri);
    }

    function setPublicCost(uint256 _cost) public onlyOwner {
        publicCost = _cost;
    }

    function setAllowlistCost(uint256 _cost) public onlyOwner {
        allowlistCost = _cost;
    }

    function setWhitelistCost(uint256 _cost) public onlyOwner {
        whitelistCost = _cost;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : hiddenMetadataUri;
    }

    modifier mintCompliance(uint256 _mintAmount, uint256 _limit) {
        require(
            _mintAmount > 0 && _mintAmount <= _limit,
            "Invalid mint amount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded"
        );
        _;
    }

    uint256 public publicMintLimit = 3;

    function setPublicMintLimit(uint256 _limit) public onlyOwner {
        publicMintLimit = _limit;
    }

    mapping(address => uint256) public publicMinted;

    function publicMint(uint256 amount)
        public
        payable
        mintCompliance(amount, publicMintLimit)
    {
        require(
            publicMinted[msg.sender] + amount <= publicMintLimit,
            "Can't mint that many"
        );
        require(state == ContractMintState.PUBLIC, "Public mint is disabled");
        require(totalSupply() + amount <= publicSupply, "Can't mint that many");
        require(msg.value >= publicCost * amount, "Insufficient funds");
        publicMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    // allowlistMintLimit - section
    uint256 public allowlistMintLimit = 3;

    function setAllowlistMintLimit(uint256 _limit) public onlyOwner {
        allowlistMintLimit = _limit;
    }

    bytes32 private _allowlistMerkleRoot;

    function allowlistMerkleRoot() public view onlyOwner returns (bytes32) {
        return _allowlistMerkleRoot;
    }

    function setAllowlistMerkleRoot(bytes32 _root) public onlyOwner {
        _allowlistMerkleRoot = _root;
    }

    mapping(address => uint256) public allowlistMinted;

    uint256 public whitelistMintLimit = 3;

    function setWhitelistMintLimit(uint256 _limit) public onlyOwner {
        whitelistMintLimit = _limit;
    }

    bytes32 private _whitelistMerkleRoot;

    function whitelistMerkleRoot() public view onlyOwner returns (bytes32) {
        return _whitelistMerkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 _root) public onlyOwner {
        _whitelistMerkleRoot = _root;
    }

    mapping(address => uint256) public whitelistMinted;

    function mintForAddress(uint256 amount, address _reciver) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _safeMint(_reciver, amount);
    }

    function numberMinted(address _mint) public view returns (uint256) {
        return _numberMinted(_mint);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);
        uint256 ownerTokenIdx = 0;
        for (
            uint256 tokenIdx = _startTokenId();
            tokenIdx <= totalSupply();
            tokenIdx++
        ) {
            if (ownerOf(tokenIdx) == _owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                ownerTokenIdx++;
            }
        }
        return ownerTokens;
    }

    ContractMintState public state = ContractMintState.PAUSED;

    function setState(ContractMintState _state) public onlyOwner {
        state = _state;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function _leaf(address account, uint256 allowance)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, allowance));
    }

    function _verify(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 root
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function whitelistMerkleMint(
        uint256 amount,
        uint256 numToken,
        bytes32[] memory proof
    ) public payable {
        require(
            state == ContractMintState.WHITELIST,
            "whitelist mint disabled"
        );
        require(
            whitelistMinted[msg.sender] + amount <= whitelistMintLimit,
            "can't mint that many"
        );
        require(msg.sender != address(0), "address error");
        bytes32 leaf = _leaf(msg.sender, numToken);
        bytes32 _root = whitelistMerkleRoot();
        require(_verify(leaf, proof, _root), "Verification failed");

        whitelistMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

}