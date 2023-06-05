// @@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@(((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@(((((((((((((((((((((((((((///////((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@(((((((((((((((((((((((((((///////((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@(((((((@@@((((((((((((((((((((((((///(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@(((((((@@@@@@((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@(((((((@@@@@@((((((((((((((((((((((((((((((((((@@@@@@(((((((((((((((((@@@
// @@@@@@@(((((((@@@@@@((((((((((((((((((((((((((((((((((@@@@@@(((((((((((((((((@@@
// @@@@@@@(((@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((%%%%%%%%%%%%%%%%
// @@@@@@@@@@@@@@@@@(((((((((((((%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@
// @@@@@@@@@@@@@@((((((((((%%%%%%%%%%################%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@
// @@@@@@@@@@@@@@((((((((((%%%%%%%%%%################%%%%%%%%%%%%%%%%%%%%@@@@@@@@@@
// @@@@@@@(((((((%%%%%%*******##############################***%%%%%%%@@@@@@@@@@@@@
// @@@@(((%%%%%%%%%%%%%%%%%###       ,,,##########       ,,,###@@@@@@@@@@@@@@@@@@@@
// ((((%%%%%%%%%%%%%%%%#######,,,       ##########,,,       ###@@@@@@@@@@@@@@@@@@@@
// ((((%%%%%%%%%%%%%%%%#######,,,       ##########,,,       ###@@@@@@@@@@@@@@@@@@@@
// %%%%%%%%%%%%%%%%%%%%****###,,,,,,,   ##########,,,,,,,   ###@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@%%%*******##############################@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@**********#############%%%%%%%#######******@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@**********#############%%%%%%%#######******@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@*******************************************@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@*******************************************@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@***********************************************@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@***********************************************@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@********************************************@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@%%%%****************************************@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@%%%%###*************************************@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@%%%%###*************************************@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@%%%%##########**************************@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@%%%%##########%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  
//
// Forgotten Punks
// 1000 Wizard Punks NFTs inspired by Forgotten Runes Wizard's Cult and CryptoPunks
// 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { MerkleProof } from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';


contract ForgottenPunks is 
    ERC721,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard
{
    string private _baseTokenURI;
    bytes32 public merkleRoot;

    bool public mintEnabled = false;
    uint256 public mintPrice = (1 ether/100);
    uint256 public constant maxMint = 5;

    uint256 public claimsAllowedPerAddress = 1;
    mapping(address => uint) public claimed;
    
    uint256 public constant MAX_SUPPLY = 1000;


    constructor(string memory initialBaseURI, bytes32 initialMerkleRoot) 
        ERC721('ForgottenPunks', 'ForgottenPunks') 
    {  
        setBaseURI(initialBaseURI);
        setMerkleRoot(initialMerkleRoot);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function setMintEnabled(bool _newMintEnabled) public onlyOwner {
        mintEnabled = _newMintEnabled;
    }

    function setMintPrice(uint256 _newMintPrice) public onlyOwner {
        mintPrice = _newMintPrice;
    }

    function setClaimsAllowedPerAddress(uint256 _newClaimsAllowedPerAddress) public onlyOwner {
        claimsAllowedPerAddress = _newClaimsAllowedPerAddress;
    }

    function ownerMint(address to, uint256 numberOfTokens) public nonReentrant onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply");
         
        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, totalSupply());
        }
    }
    
    function mint(uint256 numberOfTokens) public nonReentrant payable {
        require(mintEnabled, "Mint is not enabled");
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(numberOfTokens <= maxMint, "Max mint per transaction exceeded");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply");        
        require(msg.value == (mintPrice * numberOfTokens), "Ether value sent is incorrect");
         
        for(uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function canClaim(address claimer, bytes32[] calldata merkleProof) public view returns (bool) {        
        return 
            claimed[claimer] < claimsAllowedPerAddress && 
            MerkleProof.verify(
                merkleProof, 
                merkleRoot, 
                keccak256(abi.encodePacked(claimer))
            );
    }

    function claim(bytes32[] calldata merkleProof) public nonReentrant {
        require(mintEnabled, "Mint is not enabled");
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(canClaim(msg.sender, merkleProof), "Not eligible for claim");
        
        _safeMint(msg.sender, totalSupply());
        claimed[msg.sender] += 1;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}