//WalletTaggr V1 - A part of the 0xJOAT Ecosystem
//0xJOAT-HQ - https://www.0xJOAT.com
//WalletTaggr - https://www.WalletTaggr.com
//Learn more in the '0xJOAT's House' Discord server - Link available at 0xJOAT-HQ
//In loving memory of Arnie

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract WalletTaggr is ERC721, Ownable {
    uint256 public mintPrice; // Price to mint 1 WalletTag
    uint256 public promoPrice;// Promo price to mint 1 WalletTag
    uint256 public totalSupply; // Current total supply
    bytes32 public merkleRoot; // Encoded free claim list 
    bool public isMintActive; // Variable used to pause mint
    address payable public devWallet; // 0xJOAT's secure wallet (specifically for this contract)
    mapping(uint256 => string) public tokenIdToMessage; // Token message mapping (storage)
    mapping(uint256 => string) public tokenIdToType; // Token type mapping (storage)
    mapping(uint256 => bool) public canTransfer; // Token canTransfer mapping (storage)
    mapping(address => bool) public admins; // Admin for approving transfers mapping (storage)
    mapping(address => bool) public claimed; // Tracks whether the wallet has already claimed it's promo mint 

    constructor() payable ERC721("WalletTaggr", "WT") {
        mintPrice = 0.01 ether;
        promoPrice = 0.001 ether;
        totalSupply = 0; // This is only the initial value. The contract increases this every time a new WalletTag is minted
        merkleRoot = 0x5a0521dce0ec52432b1cdc67a8c36ce2b3ae5a83f63331767020c969b47429ff; //Pre-launch allowlist 
        isMintActive = false; //Ensures mints will not occur prior to launch
        devWallet = payable(0x3561dce6c215f655fb442E1eC9bF724c16b47309);
    }

    //Modifier to ensure mint functions cant be abused by external contracts
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
    //Mint pause function - Only to be triggered with the consent of the WalletTaggr community - most likely in the event of WalletTaggr V2.
    function setIsMintActive(bool isMintActive_) external onlyOwner {
        isMintActive = isMintActive_;
    }

    //Function to update the allowlist in order to run continuing collabs, promotions and competitions
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    //Regular mint function
    function mint(address destination_, string memory type_, string memory complaint_) external payable callerIsUser {
        require(isMintActive, "Minting not enabled!");
        require(msg.value == mintPrice, 'Wrong mint value!');
        uint256 newTokenId = totalSupply + 1;
        totalSupply++;
        tokenIdToMessage[newTokenId] = complaint_;  
        tokenIdToType[newTokenId] = type_;    
        _safeMint(destination_, newTokenId);
    }

    //Promo claim function - checks for presence in merkle tree before authorising reduced price
    function claim(address destination_, string memory type_, string memory complaint_, bytes32[] calldata _merkleProof) external payable callerIsUser {
        require(isMintActive, "Minting not enabled!");
        require(msg.value == promoPrice, "Wrong mint value!");
        require(claimed[msg.sender] == false , "You have already claimed!");
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, node), "Wallet not whitelisted");
        uint256 newTokenId = totalSupply + 1;
        totalSupply++;
        tokenIdToMessage[newTokenId] = complaint_;  
        tokenIdToType[newTokenId] = type_;
        _safeMint(destination_, newTokenId);        
        claimed[msg.sender] = true;      
    }

    //Function to build the NFT's image in accordance with metadata standards
    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), "Token doesn't exist, yet.");
        string[7] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.titles { color: white; font-family: sans-serif; font-size: 18px; }.message { color: white; font-family: sans-serif; font-size: 12px; }</style><rect x="0" y="0" width="100%" height="100%" fill="red"/><rect x="1%" y="1%" width="98%" height="98%" fill="black"/><foreignObject x="10" y="10" width="96%" height="8%"><div xmlns="http://www.w3.org/1999/xhtml" class="titles"><strong><u>WalletTag #';
        parts[1] = Strings.toString(tokenId_);
        parts[2] = '</u></strong></div></foreignObject><foreignObject x="10" y="30" width="96%" height="8%"><div xmlns="http://www.w3.org/1999/xhtml" class="titles"><u>Type - ';
        parts[3] = getType(tokenId_);
        parts[4] = '</u></div></foreignObject><foreignObject x="10" y="55" width="96%" height="80%"><div xmlns="http://www.w3.org/1999/xhtml" class="message">Message - ';
        parts[5] = getMessage(tokenId_);
        parts[6] = '</div></foreignObject></svg>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "WalletTag #', Strings.toString(tokenId_), '", "description": "WalletTaggr is a protocol for tagging ethereum wallet addresses with permanent messages. Users are encouraged to utilize the protocol in the manner that best pleases them, whether that is reporting scam addresses or joking with friends!", "image_data": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    
    //Checks the message stored on the WalletTag from the id
    function getMessage (uint256 tokenId_) public view returns (string memory) {
        string memory message = tokenIdToMessage[tokenId_];
        return message;
    }

    //Checks the type of WalletTag from the id
    function getType (uint256 tokenId_) public view returns (string memory) {
        string memory msgtype = tokenIdToType[tokenId_];
        return msgtype;
    }

    //Function to togle admin status (enables scaling once there are too many reviews to be handled by 0xJOAT alone)
    function setIsAdmin (address adminAddress, bool value_) external onlyOwner {
        admins[adminAddress] = value_;
    }

    //Function to reset claimed status (only if a wallet is eligible for it)
    function setClaimed (address address_, bool hasClaimed_) external onlyOwner {
        claimed[address_] = hasClaimed_;
    }

    //Set whether a token can be transferred (pending a review by 0xJOAT)
    function setCanTransfer (uint256 tokenId_, bool canTransfer_) external {
        require(admins[msg.sender] == true, "You do not have the authority to authorise this authorisation!");
        canTransfer[tokenId_] = canTransfer_;
    }

    //Check if token is eligible to be burned
    function getCanTransfer (uint256 tokenId_) public view returns (bool) {
        return canTransfer[tokenId_];
    }

    //Check if wallet has already claimed a promo mint
    function isClaimed (address walletId_) public view returns (bool) {
        return claimed[walletId_];
    }

    // 3x Transfer function overrides
    // Ensures any authorised disposals can only be burned
    function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(canTransfer[tokenId] == true,"Steady-on, you cant transfer this! More info: https://youtu.be/dQw4w9WgXcQ");
        to = 0x000000000000000000000000000000000000dEaD;
        _safeTransfer(from, to, tokenId, data);
    }
    function safeTransferFrom (address from, address to, uint256 tokenId) public virtual override {
        require(canTransfer[tokenId] == true,"Steady-on, you cant transfer this! More info: https://youtu.be/dQw4w9WgXcQ");
        to = 0x000000000000000000000000000000000000dEaD;
        _safeTransfer(from, to, tokenId,'');
    } 
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(canTransfer[tokenId] == true,"Steady-on, you cant transfer this! More info: https://youtu.be/dQw4w9WgXcQ");
        to = 0x000000000000000000000000000000000000dEaD;
        _safeTransfer(from, to, tokenId, '');
    }

    // Withdraw function to collect mint fees 
    function withdraw() external onlyOwner {
        (bool success, ) = devWallet.call{ value: address(this).balance }('');
        require(success, "Withdrawal failed!");
    }
}