// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
@author smashice.eth
@checkout dtech.vision and hupfmedia.de
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░▒▓▒▓░░▒█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░▓▒▓▒█▒▓▒█░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░▒▓░▓▒▓▒▓░▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░▒▓░▓▒▓▒▓░▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░▓░▓▒▓▒▒▓▓▒▓░▓███████████████░░░▓█████████████▒░░▓█████████████▓░░██░░░░░░░░░░░░█▓░░░
░░░░░░▓░▒░▒░▒██▒▓░░░░░░░░▓█░░░░░░░░░██░░░░░░░░░░░░░░░▒█▒░░░░░░░░░░░░░░░██░░░░░░░░░░░░█▓░░░
░░░░░▒▓████████▒▓░░░░░░░░▓█░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒█▒░░░░░░░░░░░░░░░██▒▒▒▒▒▒▒▒▒▒▒▒█▓░░░
░░░░▒██▒▒▓▒▒▒██▒▓░░░░░░░░▓█░░░░░░░░░██▓▓▓▓▓▓▓▓▓▓▓▓▓░░▒█▒░░░░░░░░░░░░░░░██▓▓▓▓▓▓▓▓▓▓▓▓█▓░░░
░░░▒▒██▒▓░▒▓░██▒▒░░░░░░░░▓█░░░░░░░░░██░░░░░░░░░░░░░░░▒█▒░░░░░░░░░░░░░░░██░░░░░░░░░░░░█▓░░░
░░░▒▒▓█████████▒░░░░░░░░░▓█░░░░░░░░░▒█▓▓▓▓▓▓▓▓▓▓▓▓▓░░░██▓▓▓▓▓▓▓▓▓▓▓▓▒░░██░░░░░░░░░░░░█▓░░░
░░░▒▓░▒░▒░▒░▒░▒░░░░░░░░░░▒▒░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒░░░░░░░░░░░░▒░░░░
░░░▒▓░▓░▓▒▓▒▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░▒░▓░▓▒▓▒▓░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░▓░▓▒▓░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░▓▒▓░░░▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░▒▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
*/

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721-templates/chirulabsERC721A.sol";

contract SmackmanCoin is chirulabsERC721A { 
    using SafeMath for uint256;
    using Strings for uint;
    /**
     * @param name The NFT collection name
     * @param symbol The NFT collection symbol
     * @param receiver The wallet address to recieve the royalties
     * @param feeNumerator Numerator of royalty % where Denominator default is 10000
     */
    constructor (
        string memory name, 
        string memory symbol,
        address receiver,
        uint96 feeNumerator
        ) 
    chirulabsERC721A(name, symbol, receiver, feeNumerator)
    {
        fundReciever = receiver;
        _safeMint(0x7Fdd26B919b651054f475E2c995720808B4cB6D7, 8); //
        _safeMint(0x989c17E16e937dC2dc139644c116D799A7148acE, 8); //coude.eth
        _safeMint(0xa52997Ab60C0fB10fE136981B3d4d26d8E863430, 8); //frankflux.eth
        _safeMint(0x51938E058a23cAe9aD8EC4bA538C55888C4C7656, 8); //alicedee.eth
        _safeMint(0x25981260Dd48274Abb39d48eD3cd96384522c217, 8); //rarart.eth
        _safeMint(0x64d808D23047760BAda636FACf2b48FD9942aeb3, 8); //drpflux.eth
        _safeMint(0x745Eb80612B49B22e4244aB06eaE0b37Efb39907, 8); //
        _safeMint(0xBee3FF8dA5bfa477af63D93D1C607830A1828c4A, 8); //Michael Emperiom
        _safeMint(0xDa4e937243c746d7Cfe7179FB20d6c194EE1550c, 100); //Treasury
    }

    address internal fundReciever;
    string public baseURI = "ar://fIlS8rS9ZwkTP_IILzqHCl4bcFGneGtZRy9gK2e75CE/";
    string public provenanceHash = "ae964744fac8df70b4967ea2544b558d6913b3c5e3473704d12388cca8611c28";

    uint256 constant public MAX_SUPPLY = 1111; 
    uint256 public upsellsLeft = 350;
    uint256 public mintPrice = 0.07 ether; 
    uint256 public offset = 0;
    bytes32 public claim1RootHash;
    bytes32 public claim2RootHash;
    bool public mintActive = false;
    bool public preSaleActive = false;

    mapping(address => uint256) preSale1Book;
    mapping(address => uint256) preSale2Book;

    /**
     * Allows owner to send aribitrary amounts of tokens to arbitrary adresses
     * Used to get offchain PreSale buyers their tokens
     * @param recipient Array of addresses of which recipient[i] will recieve amount [i]
     * @param amount Array of integers of which amount[i] will be airdropped to recipient[i]
     */
    function airdrop(
        address[] memory recipient,
        uint256[] memory amount
    )
    public onlyOwner
    {
        for(uint i = 0; i < recipient.length; ++i)
        {
            require(totalSupply().add(amount[i]) <= MAX_SUPPLY, "705 no more token available");
            _safeMint(recipient[i], amount[i]);
        }
    }

    /**
     * If mint is active, set it to not active.
     * If mint is not active, set it to active.
     */
    function flipMintState() 
    public onlyOwner
    {
        mintActive = !mintActive;
    }

    /**
     * If PreSale is active, set it to not active.
     * If PreSale is not active, set it to active.
     */
    function flipPreSaleState() 
    public onlyOwner
    {
        preSaleActive = !preSaleActive;
    }

    /**
     * Allows you to buy tokens
     * @param amount_ amount of tokens to get
     * @param toAddress_ reciever of the token(s)
     */
    function mint(
        uint256 amount_,
        address toAddress_
    ) 
    public payable 
    {
        require(mintActive, "702 Feature disabled/not active"); 
        require(totalSupply().add(amount_) <= MAX_SUPPLY, "705 no more token available"); 
        require(mintPrice.mul(amount_) <= msg.value, "703 Not enough currency sent"); 

        _safeMint(toAddress_, amount_); 
    }

    function randomizeOffset() public {
        require(offset == 0, "Offset was set already");
        require(!preSaleActive && !mintActive, "minting needs to be done");
        offset = block.difficulty % MAX_SUPPLY;
    }

    /**
     * Set MerkleTree Root for Claim of 1
     * @param claim1RootHash_ Roothash for the Merkle Tree
     */
    function setPreSale1Root(
        bytes32 claim1RootHash_
    ) 
    public onlyOwner 
    {
        claim1RootHash = claim1RootHash_;
    }

    /**
     * Set MerkleTree Root for Claim of 2
     * @param claim2RootHash_ Roothash for the Merkle Tree
     */
    function setPreSale2Root(
        bytes32 claim2RootHash_
    ) 
    public onlyOwner 
    {
        claim2RootHash = claim2RootHash_;
    }

    /**
     * Presale Tokens to only addresses within the merkle tree
     * @dev using merkle tree for proof of being approved for the presale
     */
    function preSale1Token(
        uint amount_,
        bytes32[] calldata proof_
    ) 
    public payable 
    {
        require(preSaleActive, "702 Feature disabled/not active");
        require(amount_ <= 3, "MAX 3");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof_, claim1RootHash, leaf), "Invalid Proof");
        preSale1Book[msg.sender] = preSale1Book[msg.sender].add(1);
        require(preSale1Book[msg.sender] <= 1, "Already claimed");

        if(amount_ > 1) // one is free
            upsellsLeft = upsellsLeft - (amount_ - 1);
            require(upsellsLeft > 0, "no more +1/+2 available");
            require(msg.value >= mintPrice * (amount_ - 1), "703 Not enough currency sent");
              
        _safeMint(msg.sender, amount_);
    }

    /**
     * Presale Tokens to only addresses within the merkle tree
     * @dev using merkle tree for proof of being approved for the presale
     */
    function preSale2Token(
        uint amount_,
        bytes32[] calldata proof_
    ) 
    public payable 
    {
        require(preSaleActive, "702 Feature disabled/not active");
        require(amount_ <= 4, "MAX 4");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof_, claim2RootHash, leaf), "Invalid Proof");

        uint256 currentClaim = preSale2Book[msg.sender]; //get already claimed tokens
        if(amount_ == 1)
            preSale2Book[msg.sender] = preSale2Book[msg.sender].add(1);
        else
            preSale2Book[msg.sender] = preSale2Book[msg.sender].add(2);
        require(preSale2Book[msg.sender] <= 2, "MAX 2 PER WALLET");

        if(amount_ > 2 && currentClaim == 0)
        {
            // no tokens claimed so has 2 free claims
            upsellsLeft = upsellsLeft - (amount_ - 2);
            require(upsellsLeft > 0, "no more +1/+2 available");
            require(msg.value >= mintPrice * (amount_ - 2), "703 Not enough currency sent");
        }
        else
        {
            // 1 token already claimed so only 1 free left
            upsellsLeft = upsellsLeft - (amount_ - 1);
            require(upsellsLeft > 0, "no more +1/+2 available");
            require(msg.value >= mintPrice * (amount_ - 1), "703 Not enough currency sent");
        }
              
        _safeMint(msg.sender, amount_);
    }

    /**
     * Allows owner to withdraw all ETH
     */
    function withdraw()
    public onlyOwner 
    {
        uint256 balance = address(this).balance;
        uint256 checkBal = 0;
        require(balance >= 1000, "Balance too small to safely withdraw!");
        //splitting balance into predefined percentages
        uint256 bal1 = balance.mul(50).div(1000);
        checkBal += bal1;
        uint256 bal2 = balance.mul(50).div(1000);
        checkBal += bal2;
        uint256 bal3 = balance.mul(50).div(1000);
        checkBal += bal3;
        uint256 bal4 = balance.mul(50).div(1000);
        checkBal += bal4;
        uint256 bal5 = balance.mul(100).div(1000);
        checkBal += bal5;
        uint256 bal6 = balance.mul(50).div(1000);
        checkBal += bal6;
        uint256 bal7 = balance.mul(50).div(1000);
        checkBal += bal7;
        uint256 bal8 = balance.mul(100).div(1000);
        checkBal += bal8;
        uint256 bal9 = balance.mul(500).div(1000);
        checkBal += bal9;
        require(checkBal <= balance, "Math Error, balances don't add up.");
        
        //transfer Ether
        payable(0x7Fdd26B919b651054f475E2c995720808B4cB6D7).transfer(bal1);
        payable(0x989c17E16e937dC2dc139644c116D799A7148acE).transfer(bal2);
        payable(0xa52997Ab60C0fB10fE136981B3d4d26d8E863430).transfer(bal3);
        payable(0x51938E058a23cAe9aD8EC4bA538C55888C4C7656).transfer(bal4);
        payable(0x25981260Dd48274Abb39d48eD3cd96384522c217).transfer(bal5);
        payable(0x64d808D23047760BAda636FACf2b48FD9942aeb3).transfer(bal6);
        payable(0x745Eb80612B49B22e4244aB06eaE0b37Efb39907).transfer(bal7);
        payable(0xBee3FF8dA5bfa477af63D93D1C607830A1828c4A).transfer(bal8);
        payable(0xDa4e937243c746d7Cfe7179FB20d6c194EE1550c).transfer(bal9);
    }

    /**
     * Allows owner to set reciever of withdrawl
     * @param reciever who to recieve the balance of the contract
     */
    function setReciever(address reciever)
    public onlyOwner
    {
        fundReciever = reciever;
    }

    /**
     * Allows owner to set baseURI for all tokens
     * @param newBaseURI_ new baseURI to be used in tokenURI generation
     */
    function setBaseURI(
        string calldata newBaseURI_
    ) external onlyOwner 
    {
        baseURI = newBaseURI_;
    }

    /**
     * Allows owner to set a new mintPrice
     * @param mintPrice_ new mintPrice to be used
     */
    function setMintPrice(
        uint256 mintPrice_
    ) public onlyOwner
    {
        mintPrice = mintPrice_;
    }

    /**
     * Allows owner to set new EIP2981 Royalty share and/or reciever for the whole collection
     * @param reciever_ new royalty reciever to be used
     * @param feeNumerator_ new royalty share in basis points to be used e.g. 100 = 1%
     */
    function setRoyalty(
        address reciever_,
        uint96 feeNumerator_
    ) public onlyOwner
    {
        _setDefaultRoyalty(reciever_, feeNumerator_);
    }

    /**
     * Returns the URI (Link) to the given tokenId
     * @param tokenId_ tokenId of which to get the URI
     */
    function tokenURI(
        uint tokenId_
    ) public override view
    returns (string memory)
    {
        require(_exists(tokenId_), "704 Query for nonexistent token");
        uint256 metadataID = (tokenId_ + offset) % MAX_SUPPLY;

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, metadataID.toString(), '.json')) : "https://dtech.vision";
    }

}