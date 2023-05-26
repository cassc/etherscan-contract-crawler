// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title A contract for ratDAO
/// @author Phillip
/// @notice NFT Minting
contract ratDAO is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeMath for uint8;
    uint16 private _tokenId;
    
    // Team wallet
    address [] teamWalletList = [
       0x0CC494215f952b7cD96378D803a0D3a6CAb282b0,         // Wallet 1 address
       0x214Fe0B10F0b2C4ea182F25DDdA95130C250C3e1,         // Wallet 2 address
       0xcC27e870C2ee553c60f51582433E80D1A4ed79da,         // Wallet 3 address
       0x1418a130132379b99f6E3871bef9507389b2972C,         // Wallet 4 address
       0x77fc746a68bFa56812b96f9686495efFF6F39364          // Wallet 5 address
    ];
    
    mapping (address => uint8) teamWalletPercent;
    
    // Mint Counter for Each Wallet
    mapping (address => uint8) addressFreeMintCountMap;      // Up to 2
    mapping (address => uint8) addressPreSaleCountMap;       // Up to 2
    mapping (address => uint8) addressPublicSaleCountMap;    // Up to 5
    
    // Minting Limitation
    uint16 public secretFreeMintLimit = 600;
    uint16 public normalFreeMintLimit = 400;
    uint16 public preSaleDiscountLimit = 2000;
    uint16 public preSaleNormalLimit = 1000;
    uint16 public totalLimit = 8888;
    
    /**
     * Mint Step flag
     * 0:   freeMint, 
     * 1:   preSale - discount, 
     * 2:   preSale - normal,
     * 3:   publicSale,
     * 4:   reveal,
     * 5:   paused
     */ 
    uint8 public mintStep = 0;

    // Merkle Tree Root
    bytes32 private merkleRoot;
    
    // Mint Price
    uint public mintPriceDiscount = 0.048 ether;
    uint public mintPrice = 0.06 ether;

    // BaseURI (real, placeholder)
    string private realBaseURI = "https://gateway.pinata.cloud/ipfs/QmWvVa8sUuRuTYLHNXPUVH7CmoDvXx7Ura8gVQBBn3zXcQ/";
    string private placeholderBaseURI  = "https://ratdao.mypinata.cloud/ipfs/QmabSngCR5cztRiSemNnjXcv9KPtWYuBZ1Rg4ciHKfV4GN/";

    uint8 private LIMIT5 = 5;
    uint8 private LIMIT2 = 2;

    constructor() ERC721("ratDAO", "RDAO") {
        teamWalletPercent[teamWalletList[0]] = 29;         // Wallet 1 percent
        teamWalletPercent[teamWalletList[1]] = 29;         // Wallet 2 percent
        teamWalletPercent[teamWalletList[2]] = 20;         // Wallet 3 percent
        teamWalletPercent[teamWalletList[3]] = 10;         // Wallet 4 percent
        teamWalletPercent[teamWalletList[4]] = 12;         // Wallet 5 percent
    }

    event Mint (address indexed _from, 
                uint8 _mintStep, 
                uint _tokenId, 
                uint _mintPrice,    
                uint8 _mintCount, 
                uint8 _freeMintCount, 
                uint8 _preSaleCount,
                uint8 _publicSaleCount);

    event Setting ( uint8 _mintStep,
                    uint256 _mintPrice,
                    uint256 _mintPriceDiscount,
                    uint16 _totalLimit,
                    uint8 _limit5,
                    uint8 _limit2);

    /**
     * Override _baseURI
     * mintStep:    0~3 - Unreveal
     *              4 - Reveal
     */
    function _baseURI() internal view override returns (string memory) {
        if (mintStep == 4)           // Reveal
            return realBaseURI;
        return placeholderBaseURI;
    }

    /**
     * Override tokenURI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json"));
    }

    /**
     * Address -> leaf for MerkleTree
     */
    function _leaf(address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    /**
     * Verify WhiteList using MerkleTree
     */
    function verifyWhitelist(bytes32 leaf, bytes32[] memory proof) private view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == merkleRoot;
    }

    /**
     * Secret Free Mint
     * mintStep:    0
     * mintCount:   Up to 2
     */
    function mintFreeSecret(uint8 _mintCount) external nonReentrant returns (uint256) {
        
        require(mintStep == 0 && _mintCount > 0 && _mintCount <= LIMIT2);
        require(msg.sender != address(0));
        require(addressFreeMintCountMap[msg.sender] + _mintCount <= LIMIT2);
        require(_mintCount <= secretFreeMintLimit);

        for (uint8 i = 0; i < _mintCount; i++) {
            _tokenId++;
            _safeMint(msg.sender, _tokenId);
        }
        
        addressFreeMintCountMap[msg.sender] += _mintCount;
        secretFreeMintLimit -= _mintCount;
        totalLimit -= _mintCount;

        emit Mint(msg.sender,
                    mintStep, 
                    _tokenId,
                    0,  // _mintPrice
                    _mintCount,
                    addressFreeMintCountMap[msg.sender],
                    addressPreSaleCountMap[msg.sender],
                    addressPublicSaleCountMap[msg.sender]);

        return _tokenId;
    }

    /**
     * Secret Free Mint
     * mintStep:    0
     * mintCount:   Up to 2
     */
    function mintFreeNormal(uint8 _mintCount, bytes32[] memory _proof) external nonReentrant returns (uint256) {
        
        require(mintStep == 0 && _mintCount > 0 && _mintCount <= LIMIT2);
        require(msg.sender != address(0));
        require(addressFreeMintCountMap[msg.sender] + _mintCount <= LIMIT2);
        require(_mintCount <= normalFreeMintLimit);
        require(verifyWhitelist(_leaf(msg.sender), _proof) == true);

        for (uint8 i = 0; i < _mintCount; i++) {
            _tokenId++;
            _safeMint(msg.sender, _tokenId);
        }

        addressFreeMintCountMap[msg.sender] += _mintCount;
        normalFreeMintLimit -= _mintCount;
        totalLimit -= _mintCount;

        emit Mint(msg.sender, 
                    mintStep, 
                    _tokenId,
                    0,  // _mintPrice
                    _mintCount,
                    addressFreeMintCountMap[msg.sender],
                    addressPreSaleCountMap[msg.sender],
                    addressPublicSaleCountMap[msg.sender]);

        return _tokenId;
    }

    /**
     * Presale with WhiteList
     * mintStep:    1: discount
     *              2: normal
     * mintCount:   Up to 2
     */
    function mintPresale(uint8 _mintCount, bytes32[] memory _proof) external payable nonReentrant returns (uint256) {
        
        require(_mintCount > 0 && _mintCount <= LIMIT2);
        require(msg.sender != address(0));
        require(addressPreSaleCountMap[msg.sender] + _mintCount <= LIMIT2);
        require((       // Presale 1
                    mintStep == 1 
                    && (_mintCount <= preSaleDiscountLimit)
                    && (msg.value == (mintPriceDiscount * _mintCount))
                ) || (  // Presale 2
                    mintStep == 2 
                    && (_mintCount <= preSaleNormalLimit)
                    && (msg.value == (mintPrice * _mintCount))
                ));
            
        require(verifyWhitelist(_leaf(msg.sender), _proof) == true);

        for (uint8 i = 0; i < _mintCount; i++) {
            _tokenId++;
            _safeMint(msg.sender, _tokenId);
        }
        
        addressPreSaleCountMap[msg.sender] += _mintCount;
        if (mintStep == 1) {
            preSaleDiscountLimit -= _mintCount;
        } else {
            preSaleNormalLimit -= _mintCount;
        }
        totalLimit -= _mintCount;

        emit Mint(msg.sender, 
                    mintStep, 
                    _tokenId,
                    mintPrice,
                    _mintCount,
                    addressFreeMintCountMap[msg.sender],
                    addressPreSaleCountMap[msg.sender],
                    addressPublicSaleCountMap[msg.sender]);
        
        return _tokenId;
    }

    /**
     * Public Sale
     * mintStep:    3
     * mintCount:   Up to 5
     */
    function mintPublic(uint8 _mintCount) external payable nonReentrant returns (uint256) {
        
        require(mintStep == 3 && _mintCount > 0 && _mintCount <= LIMIT5);
        require(msg.sender != address(0));
        require(msg.value == (mintPrice * _mintCount));
        require(addressPublicSaleCountMap[msg.sender] + _mintCount <= LIMIT5);
        require(_mintCount <= totalLimit);

        for (uint8 i = 0; i < _mintCount; i++) {
            _tokenId++;
            _safeMint(msg.sender, _tokenId);
        }
        
        addressPublicSaleCountMap[msg.sender] += _mintCount;
        totalLimit -= _mintCount;

        emit Mint(msg.sender, 
                    mintStep, 
                    _tokenId,
                    mintPrice,
                    _mintCount,
                    addressFreeMintCountMap[msg.sender],
                    addressPreSaleCountMap[msg.sender],
                    addressPublicSaleCountMap[msg.sender]);
        
        return _tokenId;
    }

    /**
     * Set status of mintStep
     * mintStep:    0 - freeMint, 
     *              1 - preSale 1: discount,
     *              2 - preSale 2: normal,
     *              3 - publicSale,
     *              4 - reveal,
     *              5 - paused
     */
    function setMintStep(uint8 _mintStep) external onlyOwner returns (uint8) {
        require(_mintStep >= 0 && _mintStep <= 5);
        mintStep = _mintStep;
        emit Setting(mintStep, mintPrice, mintPriceDiscount, totalLimit, LIMIT5, LIMIT2);
        return mintStep;
    }

    // Get Balance
    function getBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }
    
    // Withdraw
    function withdraw() external onlyOwner {
        require(address(this).balance != 0);
        
        uint256 balance = address(this).balance;

        for (uint8 i = 0; i < teamWalletList.length; i++) {
            payable(teamWalletList[i]).transfer(balance.div(100).mul(teamWalletPercent[teamWalletList[i]]));
        }
    }

    /// Set Methods
    function setRealBaseURI(string memory _realBaseURI) external onlyOwner returns (string memory) {
        realBaseURI = _realBaseURI;
        return realBaseURI;
    }

    function setPlaceholderBaseURI(string memory _placeholderBaseURI) external onlyOwner returns (string memory) {
        placeholderBaseURI = _placeholderBaseURI;
        return placeholderBaseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner returns (bytes32) {
        merkleRoot = _merkleRoot;
        return merkleRoot;
    }

    /**
     * Get TokenList by sender
     */
    function getTokenList(address account) external view returns (uint256[] memory) {
        require(msg.sender != address(0));
        require(account != address(0));

        address selectedAccount = msg.sender;
        if (owner() == msg.sender)
            selectedAccount = account;

        uint256 count = balanceOf(selectedAccount);
        uint256[] memory tokenIdList = new uint256[](count);

        if (count == 0)
            return tokenIdList;

        uint256 cnt = 0;
        for (uint256 i = 1; i < (_tokenId + 1); i++) {

            if (_exists(i) && (ownerOf(i) == selectedAccount)) {
                tokenIdList[cnt++] = i;
            }

            if (cnt == count)
                break;
        }

        return tokenIdList;
    }

    /**
     * Get Setting
     *  0 :     mintStep
     *  1 :     mintPrice
     *  2 :     mintPriceDiscount
     *  3 :     totalLimit
     *  4 :     LIMIT5
     *  5 :     LIMIT2
     */
    function getSetting() external view returns (uint256[] memory) {
        uint256[] memory setting = new uint256[](6);
        setting[0] = mintStep;
        setting[1] = mintPrice;
        setting[2] = mintPriceDiscount;
        setting[3] = totalLimit;
        setting[4] = LIMIT5;
        setting[5] = LIMIT2;
        return setting;
    }

    /**
     * Get Status by sender
     *  0 :     freeMintCount
     *  1 :     presaleCount
     *  2 :     publicSaleCount
     */
    function getAccountStatus(address account) external view returns (uint8[] memory) {
        require(msg.sender != address(0));
        require(account != address(0));

        address selectedAccount = msg.sender;
        if (owner() == msg.sender)
            selectedAccount = account;

        uint8[] memory status = new uint8[](3);

        if(balanceOf(selectedAccount) == 0)
            return status;
        
        status[0] = addressFreeMintCountMap[selectedAccount];
        status[1] = addressPreSaleCountMap[selectedAccount];
        status[2] = addressPublicSaleCountMap[selectedAccount];

        return status;
    }
}