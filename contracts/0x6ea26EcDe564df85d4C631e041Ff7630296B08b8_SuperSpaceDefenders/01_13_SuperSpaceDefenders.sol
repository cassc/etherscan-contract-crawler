// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

abstract contract AuroraCapsules {
    function tokensOfOwner(address addr) public virtual view returns(uint256[] memory);
    function ownerOf(uint256 tokenId) public virtual view returns(address addr);
}

contract SuperSpaceDefenders is ERC721A, Ownable {  
    using Address for address;

    AuroraCapsules private ac;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 8888;

    // Dynamic limit of tokens that can ever exist in cas to cut supply
    uint256 public dynamicSupplyLimit = 8888;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    // Allowlist merkleTree root
    bytes32 public whitelistRoot;

    // Starting and stopping sale and presale
    bool public active = false;
    bool public presaleActive = false;

    // Start and stop allowlist sale windows
    bool public firstAllowSaleActive = true;
    bool public secondAllowSaleActive = false;

    // Prices
    uint256 public holderPrice = 0.03 ether;
    uint256 public allowListPrice = 0.05 ether;
    uint256 public publicPrice = 0.07 ether;

    // Allowlist limits
    uint256 public allowMintCount = 0;
    uint256 public maxAllowListLimit = 4444;
    uint256 public firstAllowSaleLimit = 2;
    uint256 public secondAllowSaleLimit = 5;

    uint256 public holderSaleLimit = 4;


    // Team addresses for withdrawals
    address public a1;
    address public a2;
    address public a3;
    address public a4;
    address public a5;
    address public a6;

    // List of addresses that have minted a number of tokens for presale
    mapping (address => uint256) public firstMintedList;
    mapping (address => uint256) public secondMintedList;

    mapping (uint256 => uint256) public acTokenIdToAmounMinted;

    constructor (string memory newBaseURI, address acAddress) ERC721A ("Super Space Defenders", "SSD") {
        setBaseURI(newBaseURI);

        // Deploy with Aurora Capsules contract address
        ac = AuroraCapsules(acAddress);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Set token start ID to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

    function getAcTokensOfOwner(address addr) public view returns(uint256[] memory) {
        return ac.tokensOfOwner(addr);
    }

    function mintPresale(uint256 _amount, bytes32[] calldata _merkleProof, uint256[] calldata _ownedACTokens) public payable {
        require( presaleActive,                                                                 "Presale isn't active" );
        require( _amount > 0,                                                                   "Can't mint 0 amount" );

        // Validation
        uint256 supply = totalSupply(); 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isWhiteListed = MerkleProof.verify(_merkleProof, whitelistRoot, leaf);

        // Set mint amount
        uint256 holderMintLimit = 0;
        uint256 allowLimit = 0;

        if(_ownedACTokens.length > 0) {
            for (uint256 i = 0; i < _ownedACTokens.length; i++) {
                require(ac.ownerOf(_ownedACTokens[i]) == msg.sender,                            "Require to be token holder");

                uint256 acTokenLimit = holderSaleLimit - acTokenIdToAmounMinted[_ownedACTokens[i]]; 
                holderMintLimit = holderMintLimit + acTokenLimit;
            }
        }

        if(isWhiteListed) {
            if (secondAllowSaleActive) {
                allowLimit = secondAllowSaleLimit  - secondMintedList[msg.sender];
            } else if (firstAllowSaleActive) {
                allowLimit = firstAllowSaleLimit  - firstMintedList[msg.sender];
            }
        }

        require( holderMintLimit + allowLimit >= _amount,                                       "Can't mint more than reserved" );


        // Price calc and allow max limit check
        uint256 totalPrice = 0 ether;

        if(_amount <= holderMintLimit) {
            totalPrice = _amount * holderPrice;
        } else {
            uint256 allowCount = _amount - holderMintLimit;

            require( allowCount <= allowLimit,                                              "Can't mint more than allowed for current phase" );
            require( allowMintCount + allowCount <= maxAllowListLimit,                      "Can't mint more than max limit in presale" );

            totalPrice = (holderMintLimit * holderPrice) + (allowCount * allowListPrice);
        }

        // price check
        require( msg.value == totalPrice,                                                       "Wrong amount of ETH sent" );
        require( supply + _amount <= dynamicSupplyLimit,                                        "Can't mint more than max supply" );


        // set contract data
        for (uint256 i = 1; i <= _amount; i++) {
            if(i <= holderMintLimit) {
                for (uint256 k = 0; k < _ownedACTokens.length; k++) {
                    if(acTokenIdToAmounMinted[_ownedACTokens[k]] < holderSaleLimit) {
                        acTokenIdToAmounMinted[_ownedACTokens[k]] = acTokenIdToAmounMinted[_ownedACTokens[k]] + 1;
                        break;
                    }
                }
            } else {
                allowMintCount = allowMintCount + 1;

                if (secondAllowSaleActive) {
                    secondMintedList[msg.sender] = secondMintedList[msg.sender] + 1;
                } else if (firstAllowSaleActive) {
                    firstMintedList[msg.sender] = firstMintedList[msg.sender] + 1;
                }
            }
        }

        //mint
        _safeMint( msg.sender, _amount );
    }

    function mintToken(uint256 _amount) public payable {
        require( active,                                                                        "Sale isn't active" );
        require( _amount > 0 &&  _amount < 6,                                                   "Can only mint between 1 and 5 tokens at once" );

        uint256 supply = totalSupply();
        uint256 totalPrice = 0 ether;

        totalPrice = _amount * publicPrice;

        require( supply + _amount <= dynamicSupplyLimit,                                        "Can't mint more than max supply" );
        require( msg.value == totalPrice,                                                       "Wrong amount of ETH sent" );
        
        _safeMint( msg.sender, _amount );
    }

    // Admin minting function for the team, collabs, customs and giveaways
    function mintOwner(uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();

        require( supply + _amount <= MAX_SUPPLY,                                                "Can't mint more than max supply" );
        _safeMint( msg.sender, _amount );
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Set new MerkleTree Root 
    function setWhiteListRoot(bytes32 newRoot) public onlyOwner {
        whitelistRoot = newRoot;
    }

    // Start and stop public sale
    function setActive(bool val) public onlyOwner {
        active = val;
    }

    // Start and stop presale / allowList sale
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }


    // ALLOWLIST SALES
    // Start and stop first allowList sale window
    function setFirstAllowSaleActive(bool val) public onlyOwner {
        firstAllowSaleActive = val;
    }

    // Start and stop second allowList sale window
    function setSecondAllowSaleActive(bool val) public onlyOwner {
        secondAllowSaleActive = val;
    }


    // EDIT PRICES
    // Set a different holder price in case ETH changes drastically
    function setHolderPrice(uint256 newPrice) public onlyOwner {
        holderPrice = newPrice;
    }

    // Set a different allowList price in case ETH changes drastically
    function setAllowListPrice(uint256 newPrice) public onlyOwner {
        allowListPrice = newPrice;
    }
    
    // Set a different public price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }


    // EDIT LIMITS
    // Set different max allowList limit, just in case
    function setMaxAllowLimit(uint256 limit) public onlyOwner {
        maxAllowListLimit = limit;
    }

    // Set different first allowList limit, just in case
    function setFirstAllowSaleLimit(uint256 limit) public onlyOwner {
        firstAllowSaleLimit = limit;
    }

    // Set different second allowList limit, just in case
    function setSecondAllowSaleLimit(uint256 limit) public onlyOwner {
        secondAllowSaleLimit = limit;
    }

    // Set different supply limit, just in case we need to cut supply
    function setDynamicSupplyLimit(uint256 limit) public onlyOwner {
        dynamicSupplyLimit = limit;
    }

    // Set different holder limit, just in case
    function setHolderSaleLimit(uint256 limit) public onlyOwner {
        holderSaleLimit = limit;
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