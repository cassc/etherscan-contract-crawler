// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

//   __  __ ______ _______       _  _______  ________          __
//  |  \/  |  ____|__   __|/\   | |/ /  __ \|  ____\ \        / /
//  | \  / | |__     | |  /  \  | ' /| |__) | |__   \ \  /\  / / 
//  | |\/| |  __|    | | / /\ \ |  < |  _  /|  __|   \ \/  \/ /  
//  | |  | | |____   | |/ ____ \| . \| | \ \| |____   \  /\  /   
//  |_|  |_|______|  |_/_/    \_\_|\_\_|  \_\______|   \/  \/    
                                                              
                                                              

contract Metakrew is ERC721Enumerable, ERC721Burnable, Ownable {
   string public baseURI;

   uint256 private totalMintedTokens = 0;

   //Max 9750 Metakrew
   uint256 public constant MAX_KREW = 9750;

    bytes32 public merkleRoot;

    bool public claimIsActive = false;
    bool public canSetProvenance = true;
    bool public canMint = true;
    
    //keccak256 hashed of ipfs hash
    string public PROVENANCE;

   // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    //List of addresses with remainder krew to claim
    mapping(address => uint256) public overflowedMintingAmount;

    //max claim per tx
    uint256 public mintCap;

    uint256 public deadline;

    constructor(uint256 _mintCap, uint256 _deadline) ERC721("Metakrew", "METAKREW") {
        mintCap = _mintCap;
        deadline = _deadline;
    }

      function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
  
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    //sets the max tx mint per block
    function setMintCap(uint cap) external onlyOwner {
        mintCap = cap;
    }

    function setDeadline(uint _deadline) external onlyOwner {
        deadline = _deadline;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function flipClaimState() external onlyOwner {
        require(canMint, "Cannot mint anymore");
        claimIsActive = !claimIsActive;
    }

    function setProvenance(string calldata _provenance) external onlyOwner {
        require(canSetProvenance == true, 'Provenance locked');
        PROVENANCE = _provenance;
    }

    function lockSetProvenance() external onlyOwner {
        canSetProvenance = false;
    }

    function lockMetakrewClaiming () external onlyOwner {
        canMint = false;
        claimIsActive = false;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }


    function claimKrew(uint256 amount, address _to) private {
        uint mintIndex = totalMintedTokens;
        uint newTotalMintedTokens = mintIndex + amount;
        require(newTotalMintedTokens <= MAX_KREW, "No Krew left to be claimed");

        totalMintedTokens = newTotalMintedTokens;

        while (mintIndex < newTotalMintedTokens) {
            mintIndex++;
            _mint(_to, mintIndex);
        }
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, uint256 maxAmount, uint256 amountToClaim, bytes32[] calldata merkleProof) external {
        require(claimIsActive, "Claim must be active to mint Krew");
        require(block.timestamp <= deadline, "The claiming time has passed.");
        require(amountToClaim != 0, "Must claim at least one");
        require(!isClaimed(index), 'Krew already claimed.');
        
        address account = msg.sender;

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, maxAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'Invalid proof.');

        // Mark it claimed
        _setClaimed(index);  

        uint  _amount = maxAmount;
        uint remainder;

        if(amountToClaim > mintCap){
        require(amountToClaim <= maxAmount, "Cannot claim more than you are eligible for");
           remainder = mintCap - amountToClaim;
           //Move address into the contract storage
           overflowedMintingAmount[account] = remainder;
           _amount = mintCap;
        } else if (amountToClaim < maxAmount) {
           remainder = maxAmount - amountToClaim;
           //Move address into the contract storage
           overflowedMintingAmount[account] = remainder;
           _amount = amountToClaim;
        }
        
        claimKrew(_amount, account);
    }

    function remainderClaim (uint256 amountToClaim) external {
        require(claimIsActive, "Claim must be active to mint Krew");
        require(block.timestamp <= deadline, "The claiming time has passed.");
        require(amountToClaim <= overflowedMintingAmount[msg.sender], 'Cannot claim more than you have left');
        require(amountToClaim > 0 && amountToClaim <= mintCap, 'Must mint at least 1 and less than or equal to max transaction');
        
        //deduct how many metakrew left for the address to mint
        overflowedMintingAmount[msg.sender] = overflowedMintingAmount[msg.sender] - amountToClaim;
      
        claimKrew(amountToClaim, msg.sender);
    }

    function devMintUnclaimed(uint mintAmount, address accountToMintTo) external onlyOwner {
        require(claimIsActive, 'Claim must be active to mint Krew');
        require(block.timestamp > deadline,'Claim window has not ended');
        
        claimKrew(mintAmount, accountToMintTo);
    }

}