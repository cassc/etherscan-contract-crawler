// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

abstract contract AuroraCapsules {
    function tokensOfOwner(address addr) public virtual view returns(uint256[] memory);
    function ownerOf(uint256 tokenId) public virtual view returns(address addr);
}

abstract contract SuperSpaceDefenders {
    function ownerOf(uint256 tokenId) public virtual view returns(address addr);
}

contract ProjectLucifer is ERC721Enumerable, Ownable {  
    using Address for address;

    AuroraCapsules private ac;
    SuperSpaceDefenders private ssd;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 6666;

    // Dynamic limit of tokens that can ever exist in cas to cut supply
    uint256 public publicSaleLimit = 1111;

    //counter for public supply
    uint256 private publicSaleCounter = 0;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    // Allowlist merkleTree root
    bytes32 public whitelistRoot;

    // Starting and stopping sale and presale
    bool public active = true;
    bool public whiteListSaleActive = false;
    bool public claimActive = false;

    // Prices
    // uint256 public whiteListPrice = 0.025 ether;
    // uint256 public publicPrice = 0.05 ether;
    uint256 public whiteListPrice = 0.0 ether;
    uint256 public publicPrice = 0.0 ether;


    // Team addresses for withdrawals
    address public a1;
    address public a2;
    address public a3;
    address public a4;
    address public a5;
    address public a6;

    mapping (address => uint256) public whitelistMinted;

    mapping (uint256 => bool) public isAcTokenIdMinted;
    mapping (uint256 => bool) public isSsdTokenIdMinted;

    constructor (string memory newBaseURI, address acAddress, address ssdAddress) ERC721 ("Project Lucifer", "PL") {
        setBaseURI(newBaseURI);

        // Deploy with Aurora Capsules contract address
        ac = AuroraCapsules(acAddress);
        ssd = SuperSpaceDefenders(ssdAddress);
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

    function claimTokens(uint256[] calldata _ownedACTokens, uint256[] calldata _ownedSSDTokens) public {
        require( claimActive,                                                                        "Sale isn't active" );

        uint256[] memory tokensIds = new uint256[]( _ownedACTokens.length + _ownedSSDTokens.length);
        uint256 count = 0;

        // Validation AC
        if(_ownedACTokens.length > 0) {
            for (uint256 i = 0; i < _ownedACTokens.length; i++) {
                require(ac.ownerOf(_ownedACTokens[i]) == msg.sender,                            "Require to be token holder");
                require(isAcTokenIdMinted[_ownedACTokens[i]] == false,                            "AC Token alredy minted");
                tokensIds[count] = 4445 + _ownedACTokens[i];
                count = count + 1;
            }
        }

        // Validation SD
        if(_ownedSSDTokens.length > 0) {
            for (uint256 i = 0; i < _ownedSSDTokens.length; i++) {
                require(ssd.ownerOf(_ownedSSDTokens[i]) == msg.sender,                            "Require to be token holder");
                require(isSsdTokenIdMinted[_ownedSSDTokens[i]] == false,                            "SSD Token alredy minted");
                tokensIds[count] = _ownedSSDTokens[i];
                count = count + 1;
            }
        }

        for (uint256 i = 0; i < tokensIds.length; i++) {
            if(tokensIds[i] > 4444) {
                isAcTokenIdMinted[tokensIds[i] - 4445] = true;
            } else {
                isSsdTokenIdMinted[tokensIds[i]] = true;
            }

            _safeMint( msg.sender, tokensIds[i] );
        }

    }

    function mintToken(uint256 _amount, bytes32[] calldata _merkleProof) public payable {
        require( active,                                                                        "Sale isn't active" );
        require( _amount > 0 &&  _amount < 26,                                                   "Can only mint between 1 and 25 tokens at once" );

        uint256 totalPrice = 0 ether;
        uint256 whiteListMintAmount = 0;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bool isWhiteListed = MerkleProof.verify(_merkleProof, whitelistRoot, leaf);

        if(whiteListSaleActive && isWhiteListed) {
            whiteListMintAmount = 5 - whitelistMinted[msg.sender];
        }

        if(_amount <= whiteListMintAmount) {
            totalPrice = (_amount * whiteListPrice);
        } else {
            totalPrice = (whiteListMintAmount * whiteListPrice) + ((_amount - whiteListMintAmount) * publicPrice);
        }

        require( msg.value == totalPrice,                                                       "Wrong amount of ETH sent" );
        require( publicSaleCounter + _amount <= publicSaleLimit,                               "Can't mint more than max supply" );

        for (uint256 i = 0; i < _amount; i++) {
            if(whiteListSaleActive && isWhiteListed && whitelistMinted[msg.sender] < 5) {
                whitelistMinted[msg.sender] = whitelistMinted[msg.sender] + 1;
            }

            publicSaleCounter = publicSaleCounter + 1;
            _safeMint( msg.sender, 5555 + publicSaleCounter );
            
        }
    }

    // Admin minting function for the team, collabs, customs and giveaways
    function mintOwner(uint256 _amount) public onlyOwner {
        require( publicSaleCounter + _amount <= publicSaleLimit,                                                "Can't mint more than max supply" );

        for (uint256 i = 0; i < _amount; i++) {
            publicSaleCounter = publicSaleCounter + 1;
            _safeMint( msg.sender, 5555 + publicSaleCounter );
        }
    }


    // airdrop by owner function 
    function airDropOwner(uint256[] memory _amounts, address[] memory _a) public onlyOwner {
        uint256 count = publicSaleCounter;
        for (uint256 i = 0; i < _amounts.length; i++) {
            count = count + _amounts[i];
        }

        require( count <= publicSaleLimit,                                         "Can't mint more than max supply" );

        for (uint256 i = 0; i < _a.length; i++) {
            for (uint256 k = 0; k < _amounts[i]; k++) {
                publicSaleCounter = publicSaleCounter + 1;
                _safeMint( _a[i], 5555 + publicSaleCounter );
            }
        }
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Set new MerkleTree Root 
    function setWhiteListRoot(bytes32 newRoot) public onlyOwner {
        whitelistRoot = newRoot;
    }

    function getPublicSaleCounter() public view returns(uint256) {
        return publicSaleCounter;
    }

    // Start and stop public sale
    function setActive(bool val) public onlyOwner {
        active = val;
    }
    function setWhiteListSaleActive(bool val) public onlyOwner {
        whiteListSaleActive = val;
    }

    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }
    
    // Set a different public price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        publicPrice = newPrice;
    }

    function setWhiteListPrice(uint256 newPrice) public onlyOwner {
        whiteListPrice = newPrice;
    }

    // Set different supply limit, just in case we need to cut supply
    function setPublicSaleLimit(uint256 limit) public onlyOwner {
        publicSaleLimit = limit;
    }

    function getAcTokensOfOwner(address addr) public view returns(uint256[] memory) {
        return ac.tokensOfOwner(addr);
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