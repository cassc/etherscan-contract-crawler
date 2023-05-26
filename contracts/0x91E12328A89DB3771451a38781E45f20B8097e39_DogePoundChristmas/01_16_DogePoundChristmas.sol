// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Burnable.sol';

/**
 * @title DogePound Christmas contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract DogePoundChristmas is ERC721Burnable {
    using SafeMath for uint256;

    uint256 public mintPrice;
    uint256 public maxMintAmountPerTX;
    uint256 public MAX_DPC_SUPPLY;
    uint256 public currentMintCount;
    uint256 public whitelistCount;
    uint256 public claimCount;

    bool public mintLimit = true;
    bool public isSale;

    mapping (address => uint256) public whitelistClaim;
    address private wallet = 0x74893b849076135FceC3Baf0FF571640f6c1e038;
    address private admin = 0xBbfEaEaEe7D61F4be4074e2053D194C52c45Aa28;

    string public constant CONTRACT_NAME = "Dogepound Christmas Contract";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(address user,uint256 count,uint256 maxCount)");

    constructor() ERC721("DogePound Christmas", "DogePound Christmas") {
        MAX_DPC_SUPPLY = 10000;
        mintPrice = 0.04 ether;
        maxMintAmountPerTX = 30;
        whitelistCount = 8303;
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Set mint price for a DogePound Christmas.
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * Set maximum count to mint per one tx.
     */
    function setMaxToMintPerTX(uint256 _maxMintAmountPerTX) external onlyOwner {
        maxMintAmountPerTX = _maxMintAmountPerTX;
    }

    /*
    * Set base URI
    */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Set sale status
    */
    function setSaleStatus(bool _isSale) external onlyOwner {
        isSale = _isSale;
    }

    /*
    * Set mintLimit flag
    */
    function setMintLimit(bool _mintLimit) external onlyOwner {
        mintLimit = _mintLimit;
    }

    /*
    * Set whitelist count
    */
    function setWhitelistCount(uint256 _whitelistCount) external onlyOwner {
        whitelistCount = _whitelistCount;
    }

    /**
     * Reserve DogePound Christmas by owner
     */
    function reserveDPC(address to, uint256 count)
        external
        onlyOwner
    {
        require(to != address(0), "Invalid address to reserve.");
        if (mintLimit) {
            uint256 mintCount = currentMintCount - claimCount;
            require(mintCount.add(count) <= MAX_DPC_SUPPLY.sub(whitelistCount), "Exceeds mintable count." );
        }
        require(currentMintCount.add(count) <= MAX_DPC_SUPPLY, "Reserve would exceed max supply");
        
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(count);
    }

    /**
    * Mint DogePound Christmas
    */
    function mintDPC(uint256 count)
        external
        payable
    {
        require(isSale, "Sale must be active to mint");
        if (mintLimit) {
            uint256 mintCount = currentMintCount - claimCount;
            require(mintCount.add(count) <= MAX_DPC_SUPPLY.sub(whitelistCount), "Exceeds mintable count." );
        }
        require(count <= maxMintAmountPerTX, "Invalid amount to mint per tx");
        require(currentMintCount.add(count) <= MAX_DPC_SUPPLY, "Purchase would exceed max supply");
        require(mintPrice.mul(count) <= msg.value, "Ether value sent is not correct");
        
        for(uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(count);
    }

    /**
    * Claim for whitelist user
    */
    function claimDPC(uint256 count, uint256 maxCount, uint8 v, bytes32 r, bytes32 s) external {
        require(isSale, "Sale must be active to mint");
        require(tx.origin == msg.sender, "Only EOA");
        require(currentMintCount.add(count) <= MAX_DPC_SUPPLY, "Exceed max supply");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, msg.sender, count, maxCount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        require(whitelistClaim[msg.sender].add(count) <= maxCount, "Exceed max claimable count");

        for(uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, currentMintCount + i);
        }

        currentMintCount = currentMintCount.add(count);
        claimCount = claimCount.add(count);
        whitelistClaim[msg.sender] = whitelistClaim[msg.sender].add(count);
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function withdraw() external onlyOwner {
        payable(wallet).transfer(address(this).balance);
    }
}