// SPDX-License-Identifier: MIT

/*
       ,----,.       ,----,.       ,----,.       ,----,. 
     ,'   ,' |     ,'   ,' |     ,'   ,' |     ,'   ,' | 
   ,'   .'   |   ,'   .'   |   ,'   .'   |   ,'   .'   | 
 ,----.'    .' ,----.'    .' ,----.'    .' ,----.'    .' 
 |    |   .'   |    |   .'   |    |   .'   |    |   .'   
 :    :  |--,  :    :  |--,  :    :  |--,  :    :  |--,  
 :    |  ;.' \ :    |  ;.' \ :    |  ;.' \ :    |  ;.' \ 
 |    |      | |    |      | |    |      | |    |      | 
 `----'.'\   ; `----'.'\   ; `----'.'\   ; `----'.'\   ; 
   __  \  .  |   __  \  .  |   __  \  .  |   __  \  .  | 
 /   /\/  /  : /   /\/  /  : /   /\/  /  : /   /\/  /  : 
/ ,,/  ',-   ./ ,,/  ',-   ./ ,,/  ',-   ./ ,,/  ',-   . 
\ ''\       ; \ ''\       ; \ ''\       ; \ ''\       ;  
 \   \    .'   \   \    .'   \   \    .'   \   \    .'   
  `--`-,-'      `--`-,-'      `--`-,-'      `--`-,-'     
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HunterOrrell5555 is ERC721Enumerable, Ownable, ReentrancyGuard {

    event MintGenerativeArt(
        address indexed _to,
        uint256 indexed _tokenId,
        bytes32 _seed
    );

    bytes32 merkleRoot;
    string public PROVENANCE;
    bool public isSaleActive;
    string private _baseURIextended;

    bool public isAllowListActive;
    uint public constant MAX_SUPPLY = 555;
    uint public constant RESERVE_SUPPLY = 31;
    uint public constant MAX_ALLOWLIST_MINT = 1;
    uint public constant MAX_PUBLIC_MINT = 1;
    uint public constant PRICE_PER_TOKEN = 0.1 ether;

    mapping(address => uint) private _allowListNumMinted;

    constructor() ERC721("5555HunterOrrell", "5555") {
    }

    function setAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function onAllowList(address claimer, bytes32[] memory proof) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function numAvailableToMint(address claimer, bytes32[] memory proof) public view returns (uint) {
        if (onAllowList(claimer, proof)) {
            return MAX_ALLOWLIST_MINT - _allowListNumMinted[claimer];
        } else {
            return 0;
        }
    }

    function _internalMint(address to, uint tokenId) internal {
        bytes32 seed = keccak256(abi.encodePacked(tokenId, to, block.number, block.difficulty));
        emit MintGenerativeArt(to, tokenId, seed);
        _safeMint(to, tokenId);
    }

    function mintAllowList(uint numberOfTokens, bytes32[] memory merkleProof) external payable nonReentrant {
        uint ts = totalSupply();
        require(isAllowListActive, "Allow list is not active");
        require(onAllowList(msg.sender, merkleProof), "Not on allow list");
        require(numberOfTokens <= MAX_ALLOWLIST_MINT - _allowListNumMinted[msg.sender], "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _allowListNumMinted[msg.sender] += numberOfTokens;
        for (uint i = 0; i < numberOfTokens; i++) {
            _internalMint(msg.sender, ts + i);
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) external onlyOwner {
        PROVENANCE = provenance;
    }

    function reserve() external onlyOwner {
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < RESERVE_SUPPLY; i++) {
            _internalMint(msg.sender, supply + i);
        }
    }

    function setSaleActive(bool newState) external onlyOwner {
        isSaleActive = newState;
    }

    function mint(uint numberOfTokens) external payable nonReentrant {
        uint ts = totalSupply();
        require(isSaleActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfTokens; i++) {
            _internalMint(msg.sender, ts + i);
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}