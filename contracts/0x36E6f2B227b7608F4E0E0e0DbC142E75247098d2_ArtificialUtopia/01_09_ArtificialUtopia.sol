// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/*
       ,---.                  ,--.--------.              
     .--.'  \      .-.,.---. /==/,  -   , -\.--.-. .-.-. 
     \==\-/\ \    /==/  `   \\==\.-.  - ,-./==/ -|/=/  | 
     /==/-|_\ |  |==|-, .=., |`--`\==\- \  |==| ,||=| -| 
     \==\,   - \ |==|   '='  /     \==\_ \ |==|- | =/  | 
     /==/ -   ,| |==|- ,   .'      |==|- | |==|,  \/ - | 
    /==/-  /\ - \|==|_  . ,'.      |==|, | |==|-   ,   / 
    \==\ _.\=\.-'/==/  /\ ,  )     /==/ -/ /==/ , _  .'  
     `--`        `--`-`--`--'      `--`--` `--`..---'    
 
    Artificial Utopia All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtificialUtopia is ERC721A, Ownable, ReentrancyGuard {

    enum SALE_STAGE {
        CLOSED,
        CLAIM,
        PUBLIC
    }    

    uint16 constant public COLLECTION_SIZE = 1000;

    uint32 constant public CLAIM_START_TIME = 1669748400;
    uint32 constant public PUBLIC_SALE_START_TIME = 1670353200;

    bytes8 constant private _hashSalt = 0x95f67dae39ec0c42;
    address constant private _signerAddress = 0xa32DA85E11BE36De76C3D7901C102A9Ba4f98DBD;

     address[4] private _payoutWallets = [
        0xAb8da4a15424E0A51B31317f3A69f76f1c4033c1,
        0xEA469f5F95Ec73a9DCF37C729BCBd7dB5d4D1bC9,
        0x7e3F983911eB2740Ba7F685907B68A0044bA9cFF,
        0x9BB75389c8D1d6fDA48c6f8c1daE6Fd3F4bd5DEb
    ];

    // Used nonces for minting signatures    
    mapping(uint64 => bool) private _usedNonces;

    constructor() ERC721A("Artificial Utopia", "ARTU") {}

    // Claim tokens for free based on a backend whitelist
    function claimMint(bytes32 hash, bytes memory signature, uint256 quantity, uint64 maxTokens, uint64 nonce)
        external
    {
        SALE_STAGE saleStage = getSaleStage();
        require(saleStage == SALE_STAGE.CLAIM, "SPF holders claim stage has not begun yet");

        require(totalSupply() + quantity <= COLLECTION_SIZE, "Reached max supply");
        require(numberMinted(msg.sender) + quantity <= maxTokens, "Exceeding claiming limit for this account");

        require(_operationHash(msg.sender, quantity, maxTokens, nonce) == hash, "Hash comparison failed");
        require(_isTrustedSigner(hash, signature), "Direct minting is disallowed");
        require(!_usedNonces[nonce], "Hash is already used");
        
        _usedNonces[nonce] = true;
        _safeMint(msg.sender, quantity);
    }

    // Mint tokens during the sales
    function saleMint(bytes32 hash, bytes memory signature, uint64 nonce, uint256 quantity)
        external
    {
        SALE_STAGE saleStage = getSaleStage();
        require(saleStage == SALE_STAGE.PUBLIC, "Sales have not begun yet");

        require(totalSupply() + quantity <= COLLECTION_SIZE, "Reached max supply");
        require(quantity <= 10, "Can't mint more then 10 tokens per transaction");

        require(_operationHash(msg.sender, quantity, COLLECTION_SIZE, nonce) == hash, "Hash comparison failed");
        require(_isTrustedSigner(hash, signature), "Direct minting is disallowed");
        require(!_usedNonces[nonce], "Hash is already used");

        _usedNonces[nonce] = true;
        _safeMint(msg.sender, quantity);
    }

    // Generate hash of current mint operation
    function _operationHash(address buyer, uint256 quantity, uint64 maxTokens, uint64 nonce) internal view returns (bytes32) {        
         SALE_STAGE saleStage = getSaleStage();

        if(saleStage == SALE_STAGE.CLOSED)
            revert("Sales have not begun yet");

        return keccak256(abi.encodePacked(
            _hashSalt,
            buyer,
            uint64(block.chainid),
            uint64(saleStage),
            uint64(maxTokens),
            uint64(quantity),
            uint64(nonce)
        ));
    } 

    // Test whether a message was signed by a trusted address
    function _isTrustedSigner(bytes32 hash, bytes memory signature) internal pure returns(bool) {
        return _signerAddress == ECDSA.recover(hash, signature);
    }

    // Withdraw money in equal ammounts to a list of addresses
    function withdrawMoney() external onlyOwner nonReentrant {
        require(address(this).balance > 0, "No funds on the contract");

        uint payoutWalletsCount = _payoutWallets.length;
        uint paymentPerWallet = address(this).balance / payoutWalletsCount;

        for (uint i = 0; i < payoutWalletsCount; i++) {
            payable(_payoutWallets[i]).transfer(paymentPerWallet);
        }
    }

    // Number of tokens minted by an address
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Get current sale stage
    function getSaleStage() public view returns (SALE_STAGE) {
        if(block.timestamp >= PUBLIC_SALE_START_TIME)
            return SALE_STAGE.PUBLIC;
        
        if(block.timestamp >= CLAIM_START_TIME)
            return SALE_STAGE.CLAIM;
        
        return SALE_STAGE.CLOSED;
    }

    // URI with contract metadata for opensea
    function contractURI() public pure returns (string memory) {
        return "ipfs://bafkreihrl6esjddaqoh5nuela6mw75vuukp2txa6lmt7mldohetdwvrd2a";
    }

    // Starting index for the token IDs
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Token metadata folder/root URI
    string private _baseTokenURI = "ipfs://bafybeifq7euaj3aapmxpl6q7e5huxw6u6qe5qsnolhbdgnopvsewp5nvyq/";

    // Get base token URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Set base token URI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Recieve any amount of ether
    receive() external payable {}
}