//SPDX-License-Identifier: Unlicense
/**
    Baushaus: https://www.baushaus.xyz/
 */
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BaseERC721.sol";
import "./Merkle.sol";

contract Bedlam is Ownable, ReentrancyGuard, BaseERC721, Merkle {          
    bool public isPhaseSaleActive;
    mapping(address => uint256) internal whitelistCount;
    bool public isWhitelistActive;
    mapping(address => uint256) public totalClaimed;
    mapping(uint256 => bool) submitted;

    event Submission(uint256[]ids, uint16[] values, address sender);
    event Claimed(string[] ids, uint256 startingIndex, address sender);
    event PhaseOneActive(bool live);
    event WhitelistActive(bool live);

    constructor(bytes32 _whitelistRoot, bytes32 _phaseoneRoot, uint256 _supply, uint256 _max)
        Merkle(
            _whitelistRoot,
            _phaseoneRoot
        )
        BaseERC721(
            _supply, 
            _max,
            0.07 ether,
            "https://ipfs.io/ipfs/QmeHzogTxMk27xDARdPJfQMqNF1xyUt4oECNSrCQfpwCH8/",
            "Bedlam",
            "BED"         
        ) {}

    /**
        @dev phase one tokens are ERC1155 
        take a snapshot of existing holders and identify totalAllocated for each address
        using events and offchain db cross reference submission with correct rarity
     */
    function claim(string[] calldata ids, uint256 totalAllocated, bytes32[] calldata proof) external nonReentrant {
        uint256 current = totalSupply();
        require(totalClaimed[msg.sender] + ids.length <= totalAllocated, "cannot exceed");     
        require(isPhaseSaleActive, "Not Live");
        require(_phaseOneVerify(_phaseOneLeaf(msg.sender, totalAllocated), proof), "Invalid"); 
        require(current + ids.length <= supply, "Sold out");
        for(uint256 i; i < ids.length; i++) {
            _safeMint(msg.sender, current + i);            
        }
        totalClaimed[msg.sender] += ids.length;
        emit Claimed(ids, current, msg.sender);
    }

    function whitelistMint(uint256 count, uint256 tokenId, bytes32[] calldata proof) external payable nonReentrant {               
        require(isWhitelistActive, "Not Live");
        require(_whitelistVerify(_whitelistLeaf(msg.sender, tokenId), proof), "Invalid"); 
        require(whitelistCount[msg.sender] + count <= max, "Max Mint");
        _callMint(count);
        whitelistCount[msg.sender] += count;
    }

    /**
        @dev Users submits SOPs to the contract for their NFT.
        Users who submit none are given randomised values from their existing
        metadata SOPS. Any bad actors who submit SOP's they do not own cross
        referenced in the metadata will be randomised as well.
        
        SOPS need to be submitted in batches, the events are concatted to 
        check their existing SOPs to validate their decision.
     */
    function submitSymbol(uint256[] memory ids, uint16[] memory values) external nonReentrant {
        require(ids.length * 5 == values.length, "Invalid submission");
        for(uint256 i; i < ids.length; i++) {
            require(ownerOf(ids[i]) == msg.sender, "Not owner");
            require(!submitted[ids[i]], "Cannot resubmit");
            submitted[ids[i]] = true;
        }
        emit Submission(ids, values, msg.sender);
    }

    function isSubmitted(uint256 id) public view returns (bool) {
        return submitted[id];
    }

    function togglePhaseOne() external onlyOwner {
        isPhaseSaleActive = !isPhaseSaleActive;
        emit PhaseOneActive(isPhaseSaleActive);
    }

    function viewClaimed(address account) external view returns (uint256) {
        return totalClaimed[account];
    }

    function toggleWhitelist() external onlyOwner {
        isWhitelistActive = !isWhitelistActive;
        emit WhitelistActive(isWhitelistActive);
    }
}