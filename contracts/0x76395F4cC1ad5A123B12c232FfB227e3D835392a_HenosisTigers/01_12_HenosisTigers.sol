// #     # ####### #     # #######  #####  ###  #####     ####### ###  #####  ####### ######   #####  
// #     # #       ##    # #     # #     #  #  #     #       #     #  #     # #       #     # #     # 
// #     # #       # #   # #     # #        #  #             #     #  #       #       #     # #       
// ####### #####   #  #  # #     #  #####   #   #####        #     #  #  #### #####   ######   #####  
// #     # #       #   # # #     #       #  #        #       #     #  #     # #       #   #         # 
// #     # #       #    ## #     # #     #  #  #     #       #     #  #     # #       #    #  #     # 
// #     # ####### #     # #######  #####  ###  #####        #    ###  #####  ####### #     #  #####  

// SPDX-License-Identifier: MIT
// @author fripon.eth

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./DefaultOperatorFilterer.sol";

contract HenosisTigers is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

    using Strings for uint;

    enum Step {
        Paused,
        Allowlist,
        Public
    }

    Step public state = Step.Paused;

    // Mint parameters

    uint256 public cost = 0.042 ether;
    uint256 public maxSupply = 5000;
    uint256 public publicSupply = 800;
    uint256 public allowlistSupply = 4000;    
    uint256 public teamSupply = 200;
    uint256 public maxPerWalletAllowlist = 2;
    uint256 public maxPerWalletPublic = 5;
    uint256 public maxPerTx = 5;
    
    // URIs

    string public uriPrefix = "";
    string public hiddenMetadataUri = "ipfs://QmXViKZ5cDHtJmTGvNcryucQ7Fs82oDvVbr7CpuRMTy3kX/";
    
    bytes32 public allowlistMerkleRoot = 0xd737f8386896d8f79ad338107287b917ba44b93e17e6eed3ed400b1fee0fc408;

    mapping(address => uint256) public publicMinted;
    mapping(address => uint256) public allowlistMinted;

    constructor() ERC721A("HenosisTigers", "HenosisTigers") {}

    // OVERRIDES
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // MODIFIERS
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxPerTx,
            "Invalid mint amount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded"
        );
        _;
    }

    // MINTING FUNCTIONS
    
    function mintAllowList(
        uint256 amount,
        bytes32[] calldata proof
    ) public payable mintCompliance(amount) {
        require(state == Step.Allowlist, "Allowlist mint is not live");
        require(msg.value >= cost * amount, "Insufficient funds");
        require(totalSupply() + amount <= allowlistSupply, "Allowlist supply sold out!");
        require(allowlistMinted[msg.sender] + amount <= maxPerWalletAllowlist, "Can't mint that many");
        require(_verify(msg.sender, proof), "Invalid proof");

        allowlistMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function publicMint(uint256 amount) public payable mintCompliance(amount) {
        require(state == Step.Public, "Public mint is disabled");
        require(publicMinted[msg.sender] + amount <= maxPerWalletPublic, "Can't mint that many");
        require(msg.value == cost * amount, "Insufficient funds");

        _safeMint(msg.sender, amount);
    }

    function mintForAddress(uint256 amount, address _receiver)
        public
        onlyOwner
    {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _safeMint(_receiver, amount);
    }


    // MERKLE TREE

    function _verify(address _addr, bytes32[] calldata _proof)
      internal
      view
      returns (bool _isValid)
    {
      bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_addr))));
      _isValid = MerkleProof.verify(_proof, allowlistMerkleRoot, leaf);
    }

    // GETTERS


    function numberMinted(address _minter) public view returns (uint256) {
        return _numberMinted(_minter);
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
                : string(
                    abi.encodePacked(
                        hiddenMetadataUri,
                        _tokenId.toString(),
                        ".json"
                    )
                );
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

    // SETTERS
    function setState(Step _state) public onlyOwner {
        state = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setPublicSupply(uint256 _publicSupply) external onlyOwner {
        require(
            _publicSupply <= maxSupply,
            "Public supply can't be higher than max supply"
        );
        publicSupply = _publicSupply;
    }

    function setTeamSupply(uint256 _teamSupply) external onlyOwner {
        require(
            _teamSupply <= maxSupply,
            "Team supply can't be higher than max supply"
        );
        teamSupply = _teamSupply;
    }

    function setAllowlistSupply(uint256 _allowlistSupply) external onlyOwner {
        require(
            _allowlistSupply <= maxSupply,
            "Allowlist supply can't be higher than max supply"
        );
        allowlistSupply = _allowlistSupply;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Max supply cannot be increased");
        maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTx(uint256 _maxPerTx)
        public
        onlyOwner
    {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerWalletPublic(uint256 _maxPerWalletPublic)
        public
        onlyOwner
    {
        maxPerWalletPublic = _maxPerWalletPublic;
    }

    function setMaxPerWalletAllowlist(uint256 _maxPerWalletAllowlist)
        public
        onlyOwner
    {
        maxPerWalletAllowlist = _maxPerWalletAllowlist;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot)
        external
        onlyOwner
    {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    // WITHDRAW
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

        // Operator Filter

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}