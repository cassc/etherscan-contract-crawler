//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HausPets is ERC721URIStorage, ERC721Burnable, Pausable, Ownable {
    bytes32 public _merkleRoot;
    string  public baseURI;
    IERC20 public _gotterdammerung;

    mapping(address => uint256) public baseQuantityMinted;
    mapping(address => uint256) public midQuantityMinted;
    mapping(address => uint256) public rareQuantityMinted;
    mapping(address => uint256) public tokenQuantityMinted;

    uint256 public rareCounter = 0;
    uint256 public midCounter = 390;
    uint256 public baseCounter = 3112;
    uint256 public tokenCounter = 7777;

    constructor(string memory ipfsBaseUri, bytes32 merkleRoot, address gotterdammerung) ERC721 ("hauspets", "PETS") {
        baseURI = ipfsBaseUri;
        _merkleRoot = merkleRoot;
        _gotterdammerung = IERC20(gotterdammerung);

        pause();
    }

    function adoptPets(uint256 baseQuantity, uint256 midQuantity, uint256 rareQuantity, 
                  uint256 allowedBaseQuantity, uint256 allowedMidQuantity, uint256 allowedRareQuantity, bytes32[] calldata proof) public whenNotPaused {
        require(baseQuantity + midQuantity + rareQuantity <= 10, "Max 10 per txn");
        require(canMintQuantity(msg.sender, allowedBaseQuantity, allowedMidQuantity, allowedRareQuantity, proof), "Failed quantity proof check");
        
        if (baseQuantity > 0) {
            require(baseQuantity + baseQuantityMinted[msg.sender] <= allowedBaseQuantity, "Exceeds allowed v0.03 quantity");
            baseQuantityMinted[msg.sender] = baseQuantityMinted[msg.sender] + baseQuantity;
            
            for(uint256 i = 0; i < baseQuantity; i++) {
                _safeMint(msg.sender, baseCounter);
                _setTokenURI(baseCounter, Strings.toString(baseCounter));
                baseCounter++;
            }
        }

        if (midQuantity > 0) {
            require(midQuantity + midQuantityMinted[msg.sender] <= allowedMidQuantity, "Exceeds allowed v0.02 quantity");
            midQuantityMinted[msg.sender] = midQuantityMinted[msg.sender] + midQuantity;
            
            for(uint256 i = 0; i < midQuantity; i++) {
                _safeMint(msg.sender, midCounter);
                _setTokenURI(midCounter, Strings.toString(midCounter));
                midCounter++;
            }
        }

        if (rareQuantity > 0) {
            require(rareQuantity + rareQuantityMinted[msg.sender] <= allowedRareQuantity, "Exceeds allowed v0.01 quantity");
            rareQuantityMinted[msg.sender] = rareQuantityMinted[msg.sender] + rareQuantity;
            
            for(uint256 i = 0; i < rareQuantity; i++) {
                _safeMint(msg.sender, rareCounter);
                _setTokenURI(rareCounter, Strings.toString(rareCounter));
                rareCounter++;
            }
        }
        
    }

    function adoptTokenPet(uint256 quantity) public whenNotPaused {
        require(quantity + tokenCounter < 8027, "No supply remaining");
        require(quantity + tokenQuantityMinted[msg.sender] <= 2, "Exceeds allowed quantity");
        uint256 allowance = _gotterdammerung.allowance(msg.sender, address(this));
        require(allowance >= quantity * 25000 * 10**uint(18), "Exceeds approved token allowance");

        tokenQuantityMinted[msg.sender] = tokenQuantityMinted[msg.sender] + quantity;
        _gotterdammerung.transferFrom(msg.sender, address(0xd61F1c85df608701e3cd8CB245DBa925430e8854), quantity * 25000 * 10**uint(18));

        for(uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, tokenCounter);
            _setTokenURI(tokenCounter, Strings.toString(tokenCounter));
            tokenCounter++;
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function canMintQuantity(address account, uint256 allowedBase, uint256 allowedMid, uint256 allowedRare, bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, _merkleRoot, generateQuantityMerkleLeaf(account, allowedBase, allowedMid, allowedRare));
    }

    function generateQuantityMerkleLeaf(address account, uint256 allowedBaseQuantity, uint256 allowedMidQuantity, uint256 allowedRareQuantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allowedBaseQuantity, allowedMidQuantity, allowedRareQuantity));
    }

}