// SPDX-License-Identifier: MIT

/*
██████╗░███████╗██╗░░░██╗░█████╗░███╗░░██╗██████╗░  ░█████╗░██╗░░░░░██████╗░██╗░░██╗░█████╗░
██╔══██╗██╔════╝╚██╗░██╔╝██╔══██╗████╗░██║██╔══██╗  ██╔══██╗██║░░░░░██╔══██╗██║░░██║██╔══██╗
██████╦╝█████╗░░░╚████╔╝░██║░░██║██╔██╗██║██║░░██║  ███████║██║░░░░░██████╔╝███████║███████║
██╔══██╗██╔══╝░░░░╚██╔╝░░██║░░██║██║╚████║██║░░██║  ██╔══██║██║░░░░░██╔═══╝░██╔══██║██╔══██║
██████╦╝███████╗░░░██║░░░╚█████╔╝██║░╚███║██████╔╝  ██║░░██║███████╗██║░░░░░██║░░██║██║░░██║
╚═════╝░╚══════╝░░░╚═╝░░░░╚════╝░╚═╝░░╚══╝╚═════╝░  ╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝
*/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ERC721A.sol";
import "./OSOperatorFilterer.sol";


contract BA is ERC721A, OSOperatorFilterer, Ownable  {

    enum Status {
        Closed,
        Whitelist,
        Waitlist
    }

    using Strings for uint256;
    string  public          collectionName = "Beyond Alpha Access Orb";
    string  public          description = "Tight-knit group of curated traders and investors looking to redefine **Alpha** by going Beyond the standards of Web3. \\n\\nOwnership of Beyond Alpha NFT grants you lifetime membership to a group of likeminded and ambitious individuals and any future release.";
    string  public          imageURI = "ipfs://QmapvrvtX7PN5DA7MYx1dqBwf4n5SztrEwDMn9BuURh6Ao";
    
    uint256 public constant hardMaxSupply = 500;
    uint256 public          maxSupply = 125;
    uint256 public          wlCost = 0.25 ether;
    uint256 public          waitCost = 0.28 ether;

    bytes32 public          whiteMerkleRoot;
    bytes32 public          waitMerleRoot;

    Status  public           status;

    mapping(address => bool) private alreadyMinted;

    constructor() ERC721A("Beyond Alpha", "BA"){
        status = Status.Closed;
    }

    modifier verifyMint(uint256 _price, Status _status){
        require(tx.origin == msg.sender, "Only true tx sender");
        require(status == _status, "The mint is paused!");
        require(alreadyMinted[msg.sender] == false, "already minted");
        require(totalSupply() + 1 <= maxSupply, "Max supply exceeded!");
        require(msg.value == _price, "invalid price");
        _;
    }

    //---------- Set start from 1 ----------
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //--------------------------------------------------------
    //-------------------- Mint Functions --------------------

    //---------- Whitelist Mint ----------
    function whitelistMint(bytes32[] calldata _merkleProof) public payable verifyMint(wlCost, Status.Whitelist) {

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, whiteMerkleRoot, leaf), "Invalid proof!");
    
        _safeMint(msg.sender, 1);
        alreadyMinted[msg.sender] = true; 
    }

    //----------- Waitlist Mint ----------
    function waitlistMint(bytes32[] calldata _merkleProof) public payable verifyMint(waitCost, Status.Waitlist) {
        
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, waitMerleRoot, leaf), "Invalid proof!");
    
        _safeMint(msg.sender, 1);
        alreadyMinted[msg.sender] = true; 
    }

    //------------- Dev Mint -------------
    function devMint(uint256 _count, address _address) external onlyOwner {
        require(totalSupply() + _count <= maxSupply, "Max supply exceeded!");
        _mint(_address, _count);
    } 

    //-------------------- Mint Functions --------------------
    //--------------------------------------------------------


    //--------------------------------------------------------
    //----------------------- Metadata -----------------------


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "', collectionName, ' #', tokenId.toString(), '",',
                '"description": "', description, '",',
                '"animation_url": "', imageURI, '/ba.mp4",',
                '"image": "', imageURI, '/ba.png"',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    //----------------------- Metadata -----------------------
    //--------------------------------------------------------


    //--------------------------------------------------------
    //------------------ Сontrol Functions -------------------


    //----------- Set Image URL -----------
    function setImageURI(string calldata _imageURI) external onlyOwner {
        imageURI = _imageURI;
    }

    //------------- Set Name --------------
    function setCollectionName(string calldata _collectionName) external onlyOwner {
        collectionName = _collectionName;
    }

    //----------- Set Description -----------
    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }

    //----------- Set Whitelist Merkle -----------
    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whiteMerkleRoot = _merkleRoot;
    }

    //----------- Set Waitlist Merkle -----------
    function setWaitlistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        waitMerleRoot = _merkleRoot;
    }

    //------ Toogle Mint Status -------
    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    //--------- Set Whitelist Mint Price -----------
    function setWLCost(uint256 _cost) public onlyOwner {
        wlCost = _cost;
    }

    //--------- Set Waitlist Mint Price -----------
    function setWaitCost(uint256 _cost) public onlyOwner {
        waitCost = _cost;
    }

    //------- Set Round Mint Cap ---------
    function setCap(uint256 amount) public onlyOwner {
        require(amount <= hardMaxSupply, "Maximum supply reached");
        require(totalSupply() <= amount, "the maximum supply cannot be less than count minted");
        maxSupply = amount;
        status = Status.Closed;
    }

    //------------------ Сontrol Functions -------------------
    //--------------------------------------------------------


    //--------------------------------------------------------
    //------------------ Punishment system -------------------

    function revoke(uint256 _id, address _from, address _to) external onlyOwner {
        _safeTransferFrom(_from, _to, _id, "");
    }

    //------------------ Punishment system -------------------
    //--------------------------------------------------------


    //--------------------------------------------------------
    //----------------------- Withdraw -----------------------

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
    
    //----------------------- Withdraw -----------------------
    //--------------------------------------------------------


    //--------------------------------------------------------
    //--------------- Restriction Modificators ----------------
    
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //--------------- Restriction Modificators ---------------
    //--------------------------------------------------------

}