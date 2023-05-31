// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract AuroraCapsules is ERC721A, Ownable {  
    using Address for address;

    // Starting and stopping sale and presale
    bool public active = false;
    bool public presaleActive = false;
    bool public earlySaleOver = false;

    // Price of each token
    uint256 public price = 0.1 ether;

    // dynamic presale limit
    uint256 public dynamicPreSaleLimit = 1;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 1111;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    bytes32 public whitelistRoot;

    bytes32 public earlyWhitelistRoot;

    // Team addresses for withdrawals
    address public a1;
    address public a2;
    address public a3;
    address public a4;
    address public a5;
    address public a6;

    // List of addresses that have minted a number of tokens for presale
    mapping (address => uint256) public presaleMinted;

    constructor (string memory newBaseURI) ERC721A ("Aurora Capsules", "AC") {
        setBaseURI(newBaseURI);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(addr);

        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 currentMatch = 0;

        if(tokenCount > 0) {
            for(uint256 i; i < supply; i++){
                address tokenOwnerAdd = ownerOf(i);
                if(tokenOwnerAdd == addr) {
                    tokensId[currentMatch] = i;
                    currentMatch = currentMatch + 1;
                }
            }
        }
        
        return tokensId;
    }

    // Exclusive presale minting
    function mintPresale(uint256 _amount, bytes32[] calldata _merkleProof, bytes32[] calldata _earlyMerkleProof) public payable {
        require( presaleActive,                  "Presale isn't active" );
        require( _amount > 0,                    "Can't mint zero amount" );

        uint256 supply = totalSupply();
        uint256 reservedAmt = 0;
        uint256 alreadyMinted = presaleMinted[msg.sender];

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        bool isWhiteListed = MerkleProof.verify(_merkleProof, whitelistRoot, leaf);
        bool isEarlyWhiteListed = MerkleProof.verify(_earlyMerkleProof, earlyWhitelistRoot, leaf);

        if(isEarlyWhiteListed || isWhiteListed) {
            if(alreadyMinted > dynamicPreSaleLimit) {
                alreadyMinted = dynamicPreSaleLimit;
            }

            // 1111 acts as a no limit key here
            if(dynamicPreSaleLimit == 1111) {
                reservedAmt = MAX_SUPPLY - supply;
            } else {
                reservedAmt = dynamicPreSaleLimit - alreadyMinted;
            }
        }

        if (earlySaleOver == isEarlyWhiteListed) {
            reservedAmt = 0;
        }
        
        require( reservedAmt > 0,                "No tokens reserved for your address" );
        require( _amount <= reservedAmt,         "Can't mint more than reserved" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );

        presaleMinted[msg.sender] = presaleMinted[msg.sender] + _amount;

        _safeMint( msg.sender, _amount );
    }

    // Standard mint function
    function mintToken(uint256 _amount) public payable {
        require( active,                         "Sale isn't active" );

        uint256 supply = totalSupply();
        uint256 reservedAmt = 0;
        uint256 alreadyMinted = presaleMinted[msg.sender];

        if(alreadyMinted > dynamicPreSaleLimit) {
            alreadyMinted = dynamicPreSaleLimit;
        }

        // 1111 acts as a no limit key here
        if(dynamicPreSaleLimit == 1111) {
            reservedAmt = MAX_SUPPLY - supply;
        } else {
            reservedAmt = dynamicPreSaleLimit - alreadyMinted;
        }

        require( _amount > 0 && _amount <= reservedAmt,     "Can only mint between 1 and 5 tokens at once" );
        require( supply + _amount <= MAX_SUPPLY,            "Can't mint more than max supply" );
        require( msg.value == price * _amount,              "Wrong amount of ETH sent" );

        _safeMint( msg.sender, _amount );
    }

    // Admin minting function for the team, collabs, customs and giveaways
    function mintOwner(uint256 _amount) public onlyOwner {
        // Limited to a publicly set amount
        uint256 supply = totalSupply();
        require( supply + _amount <= MAX_SUPPLY,    "Can't mint more than max supply" );

        _safeMint( msg.sender, _amount );
    }

    // Edit presale spots
    function editPresaleMinted(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            presaleMinted[_a[i]] = _amount[i];
        }
    }

    // Start and stop presale
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Start and stop sale
    function setActive(bool val) public onlyOwner {
        active = val;
    }

    // Set if early sale over
    function setEarlySaleOver(bool val) public onlyOwner {
        earlySaleOver = val;
    }

    // Set different presale limit, just in case
    function setDynamicPreSaleLimit(uint256 limit) public onlyOwner {
        dynamicPreSaleLimit = limit;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Set new MerkleTree Root 
    function setWhiteListRoot(bytes32 newRoot) public onlyOwner {
        whitelistRoot = newRoot;
    }

    // Set new early MerkleTree Root 
    function setEarlyWhiteListRoot(bytes32 newRoot) public onlyOwner {
        earlyWhitelistRoot = newRoot;
    }

    // Set team addresses
    function setAddresses(address[] memory _a) public onlyOwner {
        a1 = _a[0];
        a2 = _a[1];
        a3 = _a[2];
        a4 = _a[3];
        a5 = _a[4];
        a6 = _a[5];
    }

    // Withdraw funds from contract for the team
    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        require(payable(a1).send((percent * 26) + (percent / 2))); // 26.5% for MACO
        require(payable(a2).send(percent * 25)); // 25% for Community Wallet
        require(payable(a3).send(percent * 20)); // 20% for NFT Forge
        require(payable(a4).send(percent * 11)); // 11% for Vanglog
        require(payable(a5).send(percent * 10)); // 10% for Knox
        require(payable(a6).send((percent * 7) + (percent / 2))); // 7.5% for Junshi
    }
}