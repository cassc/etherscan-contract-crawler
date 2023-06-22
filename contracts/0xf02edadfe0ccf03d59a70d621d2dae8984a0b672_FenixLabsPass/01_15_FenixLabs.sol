// SPDX-License-Identifier: MIT

/*
                                          :=-                                             
                                        -====-                                            
                                      :=======-                                           
                                     -==========.                                         
                                    -============-                                        
                                   .===============-.                                     
                                   =++===============-.                                   
                                  .++++++++=============:.                                
                                  -+++++++++++++===========:                              
                                  -++++++++++++++++++========-.                           
                           .==    -++++++++++++=+++++++++++=====.                         
                          =+++.   -++++++++++++ .-++++++++++++++==.                       
                        .+**+++    ++++++++++++:    .:-=+++++++++++:                      
                       .*******+-  -++++++++++++:        :++++++++++-                     
                       +**********+=+*++++++**#-          :++++++++++:                    
                      -*********************##-            +++++++++++                    
                      +********************###             .=+++++++++:                   
                      *********************###.       :==-.  +++++++++=                   
                      +********************###=      =##****==++++++++=                   
                      -********************####      -##********++++++-                   
                       *#####**************####-      ##**************:                   
                       -##########*********####*      -#*************+                    
                        +##############****#%%%%       *##***********.                    
                         +#################%%%%%.      :####********:                     
                          =################%%%%%        :#%%%######:                      
                           :*############%%%%%%=          -*%%%%%+.                       
                             -##########%%%%%%=              .:.                          
                               -*%%%%%%%%%%#=.                                            
                                  :==+++=-.                                               


    Made with love by FenixLabs © 2022
    Credits:
        - ReZ
        - Wyse
        - Mario
        - KKL                                                                                                                                                                                     
*/

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FenixLabsPass is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    address public constant VAULT_WALLET =
        0x64b43Ba3Fa45D5fd16A87E6cCc07E14c505247aE;

    string public baseURI;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public constant FOUNDERS_SUPPLY = 10;

    Counters.Counter public totalSupply;

    // Founders
    uint256 public foundersAmountMinted;
    mapping(address => bool) public foundersClaimed;

    // AirDrop Ryzen Lifetime Holders
    mapping(address => bool) public ryzenLifetimeAirdrop;

    // Ryzen-Pre-Sale
    uint256 public ryzenUsersMintPrice = 0.25 ether;
    uint256 public ryzenPreSaleMintPerUser = 2;
    mapping(address => uint256) public ryzenUsersClaimed;
    bytes32 private ryzenUsersMerkleRoot;
    bool public isRyzenPreSaleLive;

    // Pre-Sale
    uint256 public preSalePrice = 0.30 ether;
    uint256 public preSaleMintPerUser = 1;
    mapping(address => uint256) public whitelistClaimed;
    bytes32 private whitelistMerkleRoot;
    bool public isPreSaleLive;

    // Public Sale
    uint256 public publicSaleAmountMinted;
    uint256 public constant PUBLIC_SALE_MINT_PRICE = 0.65 ether;
    uint256 public publicSaleStartTime;

    error DirectMintFromContractNotAllowed();
    error PreSaleInactive();
    error RyzenPreSaleInactive();
    error InsufficientETHSent();
    error ExceedsAllocatedForPreSale();
    error ExceedsAllocatedForRyzenPreSale();
    error NotOnWhitelist();
    error PublicSaleInactive();
    error ExceedsMaxSupply();
    error ExceedsAllocatedForFounders();
    error FounderAlreadyClaimed();
    error LifetimeAlreadyClaimed();
    error WithdrawalFailed();

    event Minted(uint256 remainingSupply);

    modifier callerIsUser() {
        if (tx.origin != msg.sender)
            revert DirectMintFromContractNotAllowed();
        _;
    }

    function getRemainingSupply() public view returns (uint256) {
        unchecked { return MAX_SUPPLY - totalSupply.current(); }
    }

    function isPublicSaleLive() public view returns (bool) {
        return
            publicSaleStartTime > 0 && block.timestamp >= publicSaleStartTime;
    }

    function ryzenPreSaleBuy(
        bytes32[] memory _merkleproof,
        uint256 mintQuantity
    ) external payable nonReentrant callerIsUser {
        if (!isRyzenPreSaleLive)
            revert RyzenPreSaleInactive();
        
        if (totalSupply.current() + 1 > MAX_SUPPLY)
            revert ExceedsMaxSupply();

        if (ryzenUsersClaimed[msg.sender] + mintQuantity > ryzenPreSaleMintPerUser)
            revert ExceedsAllocatedForRyzenPreSale();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleproof, ryzenUsersMerkleRoot, leaf))
            revert NotOnWhitelist();

        if (msg.value < ryzenUsersMintPrice * mintQuantity)
            revert InsufficientETHSent();

        unchecked {
            ryzenUsersClaimed[msg.sender] += mintQuantity;
        }

        for (uint256 i; i < mintQuantity;) {
            totalSupply.increment();
            _mint(msg.sender, totalSupply.current());
            unchecked { ++i; }
        }

        emit Minted(getRemainingSupply());
    }

    function preSaleBuy(
        bytes32[] memory _merkleproof,
        uint256 mintQuantity
    ) external payable nonReentrant callerIsUser {
        if (!isPreSaleLive)
            revert PreSaleInactive();
        
        if (totalSupply.current() + 1 > MAX_SUPPLY)
            revert ExceedsMaxSupply();

        if (whitelistClaimed[msg.sender] + mintQuantity > preSaleMintPerUser)
            revert ExceedsAllocatedForPreSale();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleproof, whitelistMerkleRoot, leaf))
            revert NotOnWhitelist();

        if (msg.value < preSalePrice * mintQuantity)
            revert InsufficientETHSent();

        unchecked {
            whitelistClaimed[msg.sender] += mintQuantity;
        }

        for (uint256 i; i < mintQuantity;) {
            totalSupply.increment();
            _mint(msg.sender, totalSupply.current());
            unchecked { ++i; }
        }

        emit Minted(getRemainingSupply());
    }

    function publicSaleBuy(uint256 mintQuantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        if (!isPublicSaleLive())
            revert PublicSaleInactive();

        if (totalSupply.current() + 1 > MAX_SUPPLY)
            revert ExceedsMaxSupply();

        if (msg.value < PUBLIC_SALE_MINT_PRICE * mintQuantity)
            revert InsufficientETHSent();

        unchecked {
            publicSaleAmountMinted += mintQuantity;
        }

        for (uint256 i; i < mintQuantity;) {
            totalSupply.increment();
            _mint(msg.sender, totalSupply.current());
            unchecked { ++i; }
        }

        emit Minted(getRemainingSupply());
    }

    function foundersMint(address founderAddress)
        external
        onlyOwner
        nonReentrant
    {
        if (foundersAmountMinted + 2 > FOUNDERS_SUPPLY)
            revert ExceedsAllocatedForFounders();

        if (foundersClaimed[founderAddress])
            revert FounderAlreadyClaimed();

        for (uint256 i; i < 2;) {
            totalSupply.increment();
            _mint(founderAddress, totalSupply.current());
            unchecked { ++i; }
        }

        unchecked { foundersAmountMinted += 2; }
        foundersClaimed[founderAddress] = true;

        emit Minted(getRemainingSupply());
    }

    function airdropLifetimeHolders(address[] memory lifetimeHolders)
        external
        onlyOwner
        nonReentrant
    {
        for (uint256 i = 0; i < lifetimeHolders.length;) {
            if (ryzenLifetimeAirdrop[lifetimeHolders[i]])
                revert LifetimeAlreadyClaimed();

            for (uint256 j; j < 2;) {
                totalSupply.increment();
                _mint(lifetimeHolders[i], totalSupply.current());
                unchecked { ++j; }
            }

            ryzenLifetimeAirdrop[lifetimeHolders[i]] = true;
            unchecked { ++i; }
        }

        emit Minted(getRemainingSupply());
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(VAULT_WALLET).call{
            value: address(this).balance
        }("");

        if (!success)
            revert WithdrawalFailed();
    }

    function toggleRyzenPreSaleStatus() external onlyOwner {
        isRyzenPreSaleLive = !isRyzenPreSaleLive;
    }

    function togglePreSaleStatus() external onlyOwner {
        isPreSaleLive = !isPreSaleLive;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setRyzenUsersMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        ryzenUsersMerkleRoot = _merkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }

    function setRyzenUsersMintPrice(uint256 _price) external onlyOwner {
        ryzenUsersMintPrice = _price;
    }

    function setPreSalePrice(uint256 _price) external onlyOwner {
        preSalePrice = _price;
    }

    function setPublicSaleStartTime(uint256 _startTime) external onlyOwner {
        publicSaleStartTime = _startTime;
    }
}