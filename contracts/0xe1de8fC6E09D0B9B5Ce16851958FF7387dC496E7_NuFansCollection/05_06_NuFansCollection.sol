//SPDX-License-Identifier: Unlicense
//Creator: Cipherr

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NuFansCollection is ERC721A, Ownable {

    string internal baseURI;
    string private placeholderUri;

    uint256 public publicMintPrice;
    uint256 public whitelistMintPrice;
    uint256 public totalMinted; 
    uint256 public maxSupply;
    uint256 public maxMintAmount; // keeps track of remaining NFTs to be minted

    bool public isPublicMintEnabled;
    bool public isWhitelistMintEnabled;
    bool public isRevealed;
    bool private teamMinted;

    uint256 public publicMintLimit;
    uint256 public whitelistMintLimit;

    bytes32 private merkleRoot; // Root for whitelist addresses

    address private NU_DAO_WALLET;
    address private TEAM_WALLET;


    constructor() payable ERC721A("Nu Fans Collection", "NUFANS") {
        publicMintPrice = 0.09 ether;
        whitelistMintPrice = 0.045 ether;
        totalMinted = 0;
        maxSupply = 5000;
        maxMintAmount = maxSupply - totalMinted;
        publicMintLimit = 1;
        whitelistMintLimit = 5;
        placeholderUri = "ipfs://QmYe6p4A3U5K9r9SPHx76vU3AtSpso8vQhiR99YgykTfxn/placeholder.json";
        baseURI = "ipfs://QmeXgGnYAwBvc6EjGm4jpaHdCUU3vjgE1LomdeRP6ZF3qc/";
    }

    // Modifiers

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Nufoundary Fans :: Cannot be called by a contract");
        _;
    }


    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    mapping(address => uint256) public publicMinted;

    // public mint function
    function publicMint(uint256 _mintAmount) external payable callerIsUser {
        require(isPublicMintEnabled, "Public minting not enabled");
        require(_mintAmount > 0, "mint amount must be greater than 0");
        require(_mintAmount <= maxMintAmount,"You cannot mint more than available supply");
        require(totalMinted + _mintAmount <= maxSupply, "Mint Unavailable: amount greater than max supply");
        require(publicMinted[msg.sender] + _mintAmount <= publicMintLimit, "You cannot mint more than the Public mint limit");
        require(msg.value >= (publicMintPrice * _mintAmount), "Payment is below the Price");

        if (msg.sender != owner()) {
            //general public
            require(
                msg.value == publicMintPrice * _mintAmount,
                "Not enough ether to mint"
            );
        }

        publicMinted[msg.sender] = publicMinted[msg.sender] + _mintAmount;
        maxMintAmount = maxMintAmount - _mintAmount;
        totalMinted = totalMinted + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    mapping(address => uint256) public whitelistMinted;

    // Whitelist mint function
    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) external payable callerIsUser {
        require(isWhitelistMintEnabled, "Whitelist mint not yet enabled");
        require(_mintAmount > 0, "mint amount must be greater than 0");
        require(_mintAmount <= maxMintAmount,"You cannot mint more than available supply");
        require(totalMinted + _mintAmount <= maxSupply, "Mint Unavailable: amount greater than max supply");
        require(whitelistMinted[msg.sender] + _mintAmount <= whitelistMintLimit, "You cannot mint more than the Whitelist mint limit");
        require(msg.value >= (whitelistMintPrice * _mintAmount), "Payment is below the Price");
         // Generate a leaf node from the caller of this function
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        // Check for an invalid proof (if sender is in allowlist)
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You are not on the whitelist");


        whitelistMinted[msg.sender] = whitelistMinted[msg.sender] + _mintAmount;
        maxMintAmount = maxMintAmount - _mintAmount;
        totalMinted = totalMinted + _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    // Team Mint
    function teamMint() external onlyOwner{
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(TEAM_WALLET, 500);

        totalMinted = totalMinted + 500;
        maxMintAmount = maxMintAmount - 500;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(_exists(_tokenId), "making URI query for nonexistent token");

        if(isRevealed == true){
            return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(_tokenId), ".json")) : "";
            // bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : "";
        }else{
            return placeholderUri;
        }
    }

    //only owner functions

    // set or change public mint price
    function setPublicMintPrice(uint256 _newMintPrice) public onlyOwner {
        publicMintPrice = _newMintPrice;
    }

    // set or change whitelist mint price
    function setWhitelistMintPrice(uint256 _newMintPrice) public onlyOwner {
        whitelistMintPrice = _newMintPrice;
    }

    // set or change base URI
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // set or change placeholder URI
    function setPlaceHolderUri(string memory _newBaseURI) external onlyOwner {
        placeholderUri = _newBaseURI;
    }

    // set public mint status
    function setPublicMint() external onlyOwner {
        isPublicMintEnabled = !isPublicMintEnabled;
    }

    // set whitelist mint status
    function setWhitelistMint() external onlyOwner {
        isWhitelistMintEnabled = !isWhitelistMintEnabled;
    }

    // change reveal status
    function setReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    // change limit of public mint
    function setPublicMintLimit(uint256 _limit) external onlyOwner {
        publicMintLimit = _limit;
    }

    // change limit of whitelist mint
    function setWhitelistMintLimit(uint256 _limit) external onlyOwner {
        whitelistMintLimit = _limit;
    }

    // set or change merkle root
    function setMerkleRoot(bytes32 _root) external onlyOwner{
        merkleRoot = _root;
    }

    // set NU_DAO Wallet address
    function setDaoWallet(address _wallet) external onlyOwner{
        NU_DAO_WALLET = _wallet;
    }

    // set Team wallet address
    function setTeamWallet(address _wallet) external onlyOwner{
        TEAM_WALLET = _wallet;
    }

    // function to withdraw all
    function manualWithdraw(address _walletAdrress) external onlyOwner{
        payable(_walletAdrress).transfer(address(this).balance);
    }

    function withdraw() external onlyOwner {
        // Nu DAO's cut
        uint256 nuDaoCut = address(this).balance * 10/100;
        // Teams Cut
        uint256 teamCut = address(this).balance * 90/100;

        payable(NU_DAO_WALLET).transfer(nuDaoCut);
        payable(TEAM_WALLET).transfer(teamCut);
    }

    
}