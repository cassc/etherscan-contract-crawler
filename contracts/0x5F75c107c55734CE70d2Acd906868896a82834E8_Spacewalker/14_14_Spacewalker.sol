// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @author Space Knight Club 
 * @title Spacewalker - NFT that grants access to the Space Knight Club and eligibility to become a Knight 
 */
contract Spacewalker is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    
    uint256 public constant MAX_SUPPLY = 10000;
    string public PROVENANCE_HASH = "";
    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    uint256 private _saleTime = 1630522800; // Date and time GMT: Wednesday 1 September 2021 19:00:00 (https://www.epochconverter.com/)
    uint256 private _price = 8 * 10**16; // This is currently .08 eth

    string private _baseTokenURI;
    
    // Time one need to hold the token to be eligible to become a Knight 
    mapping(uint => uint) public tokenToTrialLockPeriod; 
    // Date at which the token is unlocked to be eligible to become a Knight
    mapping(uint => uint) public tokenToUnlockedTrial; 
    
    constructor() ERC721("Spacewalker", "SW") {}
    
    /**
     * @dev Override hook for transfer functions to reset the locking period of the NFT bought
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        // Reset locking period
        tokenToUnlockedTrial[tokenId] = block.timestamp + tokenToTrialLockPeriod[tokenId];
    }
    
    /**
     * @notice tells if an address is eligible to become a Knight. To be eligible, the address needs to have a Spacewalker NFT that was hold for longer than the NFT locking period
     * @param candidate - address to check eligibility 
     * @return true if the address has at least one NFT that was hold for longer than its locking period
     */
    function eligibleToStandTrial(address candidate) public view returns (bool) {
        uint256[] memory tokensOfCandidate = walletOfOwner(candidate);
        uint256 tokenCount = balanceOf(candidate);
        
        // for each NFT of the candidate, check if it was hold for longer than its locking period 
        for (uint256 i; i < tokenCount; i++) {
            if (block.timestamp > tokenToUnlockedTrial[tokensOfCandidate[i]]) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @notice Save 250 NFT for the team - for promotional purposes
     */
    function reserveNFT(uint256 count) public onlyOwner {
        uint256 totalSupply = totalSupply();
        // make sure we can only mint the first 250
        require(totalSupply + count < 251, "Beyond max limit"); 
        for (uint256 index; index < count; index++) {
            _safeMint(owner(), totalSupply + index);
            tokenToTrialLockPeriod[totalSupply + index] = 30 days;
            tokenToUnlockedTrial[totalSupply + index] = block.timestamp + 30 days;
        }
    }

    function setSaleTime(uint256 time) public onlyOwner {
        _saleTime = time;
    }

    function getSaleTime() public view returns (uint256) {
        return _saleTime;
    }

    function isSaleOpen() public view returns (bool) {
        return block.timestamp >= _saleTime;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice mint method 
     * @param _count number of token to be minted 
     * @dev 20 tokens max 
     * @dev the first NFT to be minted have a shoter locking period to become eligible to become a Knight. This is to reward early adopters. 
     */
    function mint(uint256 _count) public payable {
        uint256 totSupply = totalSupply();
        require(
            totSupply + _count <= MAX_SUPPLY,
            "A transaction of this size would surpass the token limit."
        );
        require(
            totSupply < MAX_SUPPLY,
            "All tokens have already been minted."
        );
        require(_count < 21, "Exceeds the max token per transaction limit.");
        require(
            msg.value >= _price * _count,
            "The value submitted with this transaction is too low."
        );
        require(
            block.timestamp >= _saleTime,
            "Spacewalker sale is not currently open."
        );
        
        for (uint256 i; i < _count; i++) {
            uint256 newId = totSupply + i;
            // Reward early buyers with shorter lock period to become eligible to become Knight
            if (newId < 251) {
                tokenToTrialLockPeriod[newId] = 30 days;
            }
            else if (newId < 500) {
                tokenToTrialLockPeriod[newId] = 90 days;
            }
            else if (newId < 2000) {
                tokenToTrialLockPeriod[newId] = 120 days;
            }
            else if (newId < 4000) {
                tokenToTrialLockPeriod[newId] = 180 days;
            }
            else if (newId < 7000) {
                tokenToTrialLockPeriod[newId] = 240 days;
            }
            else if (newId < 10000) {
                tokenToTrialLockPeriod[newId] = 300 days;
            }
            _safeMint(msg.sender, newId);
        }
        // If we haven't set the starting index and this is the last saleable token 
        if ((startingIndexBlock == 0) && (totalSupply() == MAX_SUPPLY)) {
            startingIndexBlock = block.number;
        } 
    }
    
    /**
     * @notice list of the tokens ID owned by a specific address 
     */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    
    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE_HASH = _provenanceHash;
    }
    
    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() external {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint256(blockhash(startingIndexBlock)) % MAX_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % MAX_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndexBlock = block.number;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}