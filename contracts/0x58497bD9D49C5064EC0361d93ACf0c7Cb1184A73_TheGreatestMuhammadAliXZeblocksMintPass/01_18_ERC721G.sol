// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/[email protected]/utils/structs/EnumerableSet.sol";
import "@openzeppelin/[email protected]/security/ReentrancyGuard.sol";
import "@openzeppelin/[email protected]/utils/Address.sol";
import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";


contract TheGreatestMuhammadAliXZeblocksMintPass is ERC721, ERC721Burnable, AccessControl, ReentrancyGuard  {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address payable;
    uint256 public MAX_SUPPLY = 2000;
    uint256 public MAX_MINT_PER_TX = 10;
    mapping(address => uint256) public claimedTokens;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    bytes32 public merkleRootPhase1;
    bytes32 public merkleRootPhase2;
    uint256 public AmountPhase1Cap = 1000;
    uint256 public AmountPhase2Cap = 1000;
    uint256 public Phase1Minted;
    uint256 public Phase2Minted;
    mapping(address => uint256) public whitelistedQuantitiesPhase1;
    mapping(address => uint256) public whitelistedQuantitiesPhase2;
    mapping(address => bool) public usersClaimedPhase1Before;
    mapping(address => bool) public usersClaimedPhase2Before;
    EnumerableSet.AddressSet private claimedPhase1;
    EnumerableSet.AddressSet private claimedPhase2;
    bool public phase1Enabled;
    bool public phase2Enabled;
    bool public openMintingEnabled;
    string private _currentBaseURI = "https://fleek.muhammadalinft.io/7d0c8100-40cb-45ac-b78d-7f9e3775762f-bucket/ali/data.json";
    uint256 public claimPrice;
    uint256 public openMintPrice;
    uint256 public claimPriceToken;
    uint256 public openMintPriceToken;
    address payable public PaymentAddress;
    IERC20 public paymentToken;


    constructor() ERC721("The Greatest: Muhammad Ali x Zeblocks Mint Pass", "MAXZE"){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        phase1Enabled = false;
        phase2Enabled = false;
        openMintingEnabled = false;
        claimPrice = 0.2 ether;
        openMintPrice = 0.2 ether;
        claimPriceToken = 9000000 ether;
        openMintPriceToken = 9000000 ether;
        PaymentAddress = payable(msg.sender); 
    }

    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function totalMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }


    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _currentBaseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? baseURI : "";
    }
    
    function setMaxSupply(uint256 supply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_SUPPLY=supply;
    }

    function setMaxMintPerTx(uint256 maxTx) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MAX_MINT_PER_TX=maxTx;
    }

    function setMerkleRoots(bytes32 _merkleRootPhase1, bytes32 _merkleRootPhase2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRootPhase1 = _merkleRootPhase1;
        merkleRootPhase2 = _merkleRootPhase2;
    }

    function setMerkleRootPhase1(bytes32 _merkleRootPhase1) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRootPhase1 = _merkleRootPhase1;
    }

    function setMerkleRootPhase2( bytes32 _merkleRootPhase2) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRootPhase2 = _merkleRootPhase2;
    }

    function togglePhase(uint8 phase, bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (phase == 1) {
            phase1Enabled = enabled;
        } else if (phase == 2) {
            phase2Enabled = enabled;
        } else {
            revert("Invalid phase");
        }
    }

    function toggleOpenMinting(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        openMintingEnabled = enabled;
    }

    function setClaimPrice(uint256 _claimPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimPrice = _claimPrice;
    }

    function setPaymentTokenAddress(address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentToken = IERC20(tokenAddress);
    }
    
    function setTokenPrices(uint256 _claimPriceToken, uint256 _openMintPriceToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        claimPriceToken = _claimPriceToken;
        openMintPriceToken = _openMintPriceToken;
    }

    function setOpenMintPrice(uint256 _openMintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        openMintPrice  = _openMintPrice;
    }

    function setPaymentAddress(address payable _paymentAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        PaymentAddress = _paymentAddress;
    }

    function setAmountPhase1(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        AmountPhase1Cap = amount;
    }

     function setAmountPhase2(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        AmountPhase2Cap = amount;
    }

    function setWhitelistedQuantityPhase1(address user, uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistedQuantitiesPhase1[user] = quantity;
    }

    function setWhitelistedQuantityPhase2(address user, uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistedQuantitiesPhase2[user] = quantity;
    }

    function claim(uint256 numTokens, uint256 allowance1, uint256 allowance2, bytes32[] calldata merkleProofPhase1, bytes32[] calldata merkleProofPhase2, bool payWithToken) external payable nonReentrant {
        require(phase1Enabled || phase2Enabled, "Both claim phases are disabled");
        require(numTokens > 0 && numTokens <= MAX_MINT_PER_TX, "Invalid number of tokens to mint");

        uint256 totalPayment;

        if (payWithToken) {
            totalPayment = claimPriceToken * numTokens;
            require(paymentToken.balanceOf(msg.sender) >= totalPayment, "Insufficient token payment");
            paymentToken.transferFrom(msg.sender, PaymentAddress, totalPayment);
        } else {
            totalPayment = claimPrice * numTokens;
            require(msg.value >= totalPayment, "Insufficient ETH payment");
            PaymentAddress.sendValue(msg.value);
        }

        uint256 allowedTotal = 0;

        if (phase1Enabled) { 
            if (!claimedPhase1.contains(msg.sender) && merkleProofPhase1.length > 0) {
                bool validPhase1Proof = MerkleProof.verify(merkleProofPhase1, merkleRootPhase1, keccak256(bytes.concat(keccak256(abi.encode(msg.sender, allowance1)))));
         
                require(validPhase1Proof, "Invalid proof or quantity for phase 1");
                claimedPhase1.add(msg.sender);
                whitelistedQuantitiesPhase1[msg.sender] += allowance1;
                allowedTotal += allowance1;
                usersClaimedPhase1Before[msg.sender]=true;
            } else {
                allowedTotal += whitelistedQuantitiesPhase1[msg.sender];
            }
        }

        if (phase2Enabled) {
            if (!claimedPhase2.contains(msg.sender) && merkleProofPhase2.length > 0) {
                bool validPhase2Proof = MerkleProof.verify(merkleProofPhase2, merkleRootPhase2, keccak256(bytes.concat(keccak256(abi.encode(msg.sender, allowance2)))));
                require(validPhase2Proof, "Invalid proof or quantity for phase 2");
                claimedPhase2.add(msg.sender);
                whitelistedQuantitiesPhase2[msg.sender] += allowance2;
                allowedTotal += allowance2;
                usersClaimedPhase2Before[msg.sender]=true;
            } else {
                allowedTotal += whitelistedQuantitiesPhase2[msg.sender];
            }
        }

        require(numTokens <= allowedTotal, "Claim limit exceeded");

        for (uint256 i = 0; i < numTokens; i++) {
            if (phase1Enabled) {
                if (whitelistedQuantitiesPhase1[msg.sender] > 0) {
                  require(_tokenIdCounter.current() < MAX_SUPPLY, "Max Supply Limit");
                  require(Phase1Minted < AmountPhase1Cap, "Max Supply Limit");
                  Phase1Minted++;
          
                    uint256 tokenId = _tokenIdCounter.current();
                    _tokenIdCounter.increment();
                    _safeMint(msg.sender, tokenId);
                    whitelistedQuantitiesPhase1[msg.sender]--;
                    continue;
                }
            }
            if (phase2Enabled) {
                if (whitelistedQuantitiesPhase2[msg.sender] > 0) {
                    require(_tokenIdCounter.current() < MAX_SUPPLY, "Max Supply Limit");
                    require(Phase2Minted < AmountPhase2Cap, "Max Supply Limit");
                    Phase2Minted++;
                    uint256 tokenId = _tokenIdCounter.current();
                    _tokenIdCounter.increment();
                    _safeMint(msg.sender, tokenId);
                    whitelistedQuantitiesPhase2[msg.sender]--;
                    continue;
                }
            }
        }
    }

    function openMint(uint256 numTokens, bool payWithToken) external payable nonReentrant {
        require(openMintingEnabled, "Open minting is not enabled");

        uint256 totalPayment;

        if (payWithToken) {
            totalPayment = openMintPriceToken * numTokens;
            require(paymentToken.balanceOf(msg.sender) >= totalPayment, "Insufficient token payment");
            paymentToken.transferFrom(msg.sender, PaymentAddress, totalPayment);
        } else {
            totalPayment = openMintPrice * numTokens;
            require(msg.value >= totalPayment, "Insufficient ETH payment");
            PaymentAddress.sendValue(msg.value);
        }

        require(_tokenIdCounter.current() + numTokens <= MAX_SUPPLY, "Mint limit exceeded");
        require(numTokens > 0 && numTokens <= MAX_MINT_PER_TX, "Invalid number of tokens to mint");

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public virtual override 
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function batchBurn(uint256[] memory tokenIds) public virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            burn(tokenIds[i]);
        }
    }
}