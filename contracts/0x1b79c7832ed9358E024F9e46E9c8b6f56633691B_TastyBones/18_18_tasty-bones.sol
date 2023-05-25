// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//          .e$$$$e.
//        e$$$$$$$$$$e
//       $$$$$$$$$$$$$$
//      d$$$$$$$$$$$$$$b
//      $$$$$$$$$$$$$$$$
//     4$$$$$$$$$$$$$$$$F
//     4$$$$$$$$$$$$$$$$F
//      $$$" "$$$$" "$$$
//      $$F   4$$F   4$$
//      '$F   4$$F   4$"
//       $$   $$$$   $P
//       4$$$$$"^$$$$$%
//        $$$$F  4$$$$
//         "$$$ee$$$"
//         . *$$$$F4
//          $     .$
//          "$$$$$$"
//           ^$$$$
//             ""       

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./approving-bone.sol";
import "./ERC721A.sol";

contract TastyBones is Ownable, ERC721A, ReentrancyGuard {

    string public baseURI;
    uint256 public teamTBones = 50;
    uint256 public constant price = 0.069 ether;
    uint8 public maxFreeBoneMint = 1;
    uint8 public maxFreeMint = 2;
    uint8 public maxPresaleMint = 2;
    uint8 public maxRaffleMint = 1;
    uint8 public maxMintPerAccount = 2;
    uint256 public maxFreeMintSupply = 500;
    uint256 public maxPresaleSupply = 4000;
    uint256 public maxRaffleSupply = 500;
    uint256 public maxTastyBones = 5049;
    bool public isRaffleActive = false;
    bool public isPresaleActive = false;
    bool public isFreeActive = false;
    uint256 public mintedFreeMint = 0;
    uint256 public mintedPresale = 0;

    // free mint
    mapping (uint256 => bool) public mintedTBforFreeMintBone;
    mapping (address => uint256) public mintedTBforFreeMintAddress;

    // presale mint
    mapping (address => uint256) public mintedTBforPresale;

    // raffle mint
    mapping (address => bool) public mintedTBforRaffle;
    mapping(address => uint256) addressBlockBought;

    bytes32 private freeMintBoneMerkleRoot;
    bytes32 private freeMintListMerkleRoot;
    bytes32 private presaleMerkleRoot;
    bytes32 private raffleMerkleRoot;

    ApprovingBone public approvingBoneContract;

    constructor(
        address boneContractAddress, 
        bytes32 boneRoot,
        bytes32 freeRoot,
        bytes32 presaleRoot,
        bytes32 raffleRoot
        ) 
        ERC721A("Tasty Bones", "TASTYBONES", 50, 5049)  {
        freeMintBoneMerkleRoot = boneRoot;
        freeMintListMerkleRoot = freeRoot;
        presaleMerkleRoot = presaleRoot;
        raffleMerkleRoot = raffleRoot;
        approvingBoneContract = ApprovingBone(boneContractAddress);
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isFreeActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        } 

        if(mintType == 2) {
            require(isPresaleActive, "PRESALE_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 3) {
            require(isRaffleActive, "RAFFLE_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    /**
     * Free mint function
     */
    function mintFreeWithBone(
        uint256 boneTokenId, 
        bytes32[] calldata boneProof) external isSecured(1) {

        uint256 boneCount = approvingBoneContract.balanceOf(msg.sender);
        bool bonesOfOwner = findBonesOfOwner(msg.sender, boneTokenId, boneCount);

        require(mintedFreeMint + 1 <= maxFreeMintSupply, "EXCEEDS_FREE_MINT_SUPPLY" );
        require(mintedTBforFreeMintAddress[msg.sender] + 1 <= maxMintPerAccount,"ALREADY_MINTED_MAX_2");
        require(mintedTBforPresale[msg.sender] + 1 <= maxMintPerAccount, "EXCEEDS_MAX_PRESALE_MINT" );
        require(totalSupply() + 1 <= maxTastyBones, "EXCEEDS_MAX_SUPPLY" );
        require(MerkleProof.verify(boneProof, freeMintBoneMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "YOU_ARE_NOT_WHITELISTED_TO_MINT_FREE_WBONE");
        require(bonesOfOwner,"USER_DO_NOT_OWN_A_BONE");
        require(boneCount > 0, "NO_BONE_PASS");
        require(!mintedTBforFreeMintBone[boneTokenId], "BONE_ALREADY_USED_FOR_MINTING");

        mintedTBforFreeMintAddress[msg.sender] += 1;
        addressBlockBought[msg.sender] = block.timestamp;
        mintedTBforFreeMintBone[boneTokenId] = true;
        mintedFreeMint += 1;
        _safeMint(msg.sender, 1);
    }

    /**
     * Free mint function
     */
    function mintFreeWL(
        uint256 numberOfTokens,
        bytes32[] calldata freeMintProof,
        uint256 maxMint
        ) external isSecured(1) {
        require(mintedFreeMint + numberOfTokens <= maxFreeMintSupply, "EXCEEDS_FREE_MINT_SUPPLY" );
        require(mintedTBforFreeMintAddress[msg.sender] + numberOfTokens <= maxMint,"CANNOT_MINT_MORE_THAN_ALLOWED");
        require(mintedTBforFreeMintAddress[msg.sender] + numberOfTokens <= maxMintPerAccount,"ALREADY_MINTED_MAX_2");
        require(mintedTBforPresale[msg.sender] + numberOfTokens <= maxMintPerAccount, "EXCEEDS_MAX_PRESALE_MINT" );
        require(totalSupply() + numberOfTokens <= maxTastyBones, "EXCEEDS_MAX_SUPPLY" );
        require(MerkleProof.verify(freeMintProof, freeMintListMerkleRoot, keccak256(abi.encodePacked(msg.sender, maxMint))), "YOU_ARE_NOT_WHITELISTED_TO_MINT_FREE");

        mintedTBforFreeMintAddress[msg.sender] += numberOfTokens;
        addressBlockBought[msg.sender] = block.timestamp;
        mintedFreeMint += numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * Presale mint function
     */
    function mintPresale(uint256 numberOfTokens, bytes32[] calldata proof) external payable isSecured(2) {
        require(msg.value == price * numberOfTokens, "INSUFFICIENT_PAYMENT");
        require(mintedTBforFreeMintAddress[msg.sender] + numberOfTokens <= maxMintPerAccount, "NOT_ALLOWED_TO_MINT_MORE_THAN_2" );
        require(mintedTBforPresale[msg.sender] + numberOfTokens <= maxMintPerAccount, "EXCEEDS_MAX_PRESALE_MINT" );
        require(mintedPresale + numberOfTokens <= maxPresaleSupply, "EXCEEDS_MAX_PRESALE_SUPPLY" );
        require(totalSupply() + numberOfTokens <= maxTastyBones, "EXCEEDS_MAX_SUPPLY" );
        require(MerkleProof.verify(proof, presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_WHITELIST_PROOF");

        addressBlockBought[msg.sender] = block.timestamp;
        mintedTBforPresale[msg.sender] += numberOfTokens;
        mintedPresale += numberOfTokens;
        _safeMint( msg.sender, numberOfTokens);
    }

    /**
     * Raffle Mint Function
     */
    function mintRaffle(bytes32[] calldata proof) external payable isSecured(3) {
        require(msg.value == price * maxRaffleMint, "MAX_MINT_REACHED");
        require(totalSupply() + maxRaffleMint <= maxTastyBones, "EXCEEDS_MAX_SUPPLY" );
        require(!mintedTBforRaffle[msg.sender], "EXCEEDS_MAX_RAFFLE_MINT" );
        require(mintedTBforFreeMintAddress[msg.sender] < 1, "NOT_ALLOWED_TO_MINT_MORE_THAN_2" );
        require(mintedTBforPresale[msg.sender] < 1, "NOT_ALLOWED_TO_MINT_MORE_THAN_2" );
        require(MerkleProof.verify(proof, raffleMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_WHITELIST_PROOF");
        
        addressBlockBought[msg.sender] = block.timestamp;
        mintedTBforRaffle[msg.sender] = true;
        _safeMint(msg.sender, maxRaffleMint);
    }

    /**
     * Mint Tasty Bones for the Team
     */
    function mintTBForTeam(uint256 numberOfTokens) external onlyOwner {
        require(teamTBones > 0, "NFTS_FOR_THE_TEAM_HAS_BEEN_MINTED");
        require(numberOfTokens <= teamTBones, "EXCEEDS_MAX_MINT_FOR_TEAM");

        teamTBones -= numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    function findBonesOfOwner(address _owner, uint256 tokenId, uint256 tokenCount) internal view returns(bool) {
        for(uint256 i; i < tokenCount; i++){
            uint256 tokensId = approvingBoneContract.tokenOfOwnerByIndex(_owner, i);
            if(tokensId == tokenId) {
                return true;
            } 
        }

        return false;
    }

    /**
     * Returns Tasty Bones of the Caller
     */
    function tokenIdOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // SETTER FUNCTIONS

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setFreeBoneMerkleRoot(bytes32 freeMintRoot) external onlyOwner {
        freeMintBoneMerkleRoot = freeMintRoot;
    }

    function setFreeWlMerkleRoot(bytes32 freeWLMintRoot) external onlyOwner {
        freeMintListMerkleRoot = freeWLMintRoot;
    }

    function setPresaleMerkleRoot(bytes32 presaleRoot) external onlyOwner {
        presaleMerkleRoot = presaleRoot;
    }

    function setRaffleMerkleRoot(bytes32 raffleRoot) external onlyOwner {
        raffleMerkleRoot = raffleRoot;
    }

    function setMaxFreeBoneMint(uint8 _maxBoneMint) external onlyOwner {
        maxFreeBoneMint = _maxBoneMint;
    }

    function setMaxFreeMint(uint8 _maxFreeMint) external onlyOwner {
        maxFreeMint = _maxFreeMint;
    }

    function setMaxPresaleMint(uint8 _maxPresaleMint) external onlyOwner {
        maxPresaleMint = _maxPresaleMint;
    }

    function setMaxRaffleMint(uint8 _maxRaffleMint) external onlyOwner {
        maxRaffleMint = _maxRaffleMint;
    }

    function setMaxFreeMintSupply(uint256 _maxFreeMintSupply) external onlyOwner {
        maxFreeMintSupply = _maxFreeMintSupply;
    }

    function setMaxPresaleMintSupply(uint256 _maxPresaleMintSupply) external onlyOwner {
        maxPresaleSupply = _maxPresaleMintSupply;
    }

    function setMaxRaffleMintSupply(uint256 _maxRaffleMintSupply) external onlyOwner {
        maxRaffleSupply = _maxRaffleMintSupply;
    }


    // TOGGLES

    function toggleRaffleMintActive() external onlyOwner {
        isRaffleActive = !isRaffleActive;
    }

    function togglePresaleActive() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function toggleFreeMintActive() external onlyOwner {
        isFreeActive = !isFreeActive;
    }


    
    function approvingBoneContractAddress() external view returns (address) {
        return address(approvingBoneContract);
    }

    /**
     * Withdraw Ether
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }
}