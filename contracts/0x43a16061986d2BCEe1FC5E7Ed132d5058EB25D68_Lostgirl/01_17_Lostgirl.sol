// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Imports
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721EnumerableNameable.sol";
import "./LOSTToken.sol";
import "./LostboyNFT.sol";

contract Lostgirl is ERC721EnumerableNameable {
 
    // Constants
    uint256 private constant MAX_LOSTGIRLS = 10000;
    
    // Public
    bool public claimingEnabled = false;
    bool public tokenEnabled = false;
    mapping(address => uint256) public claims;

    // Private
    bytes32 private snapshotMerkle = "";
    string private baseURI = "";
    
    // External
    LostboyNFT public lostboyNFT;
    LOSTToken public lostToken;

    constructor(string memory _name, string memory _symbol, string memory _uri, address lostboyAddress) 
        ERC721EnumerableNameable (_name, _symbol) {
        baseURI = _uri;
        lostboyNFT = LostboyNFT(lostboyAddress);
    }
    
    // Owner
    
    function toggleClaim () public onlyOwner {
        claimingEnabled = !claimingEnabled;
    }

    function toggleToken () public onlyOwner { 
        tokenEnabled = !tokenEnabled;
    }

    function setSnapshotRoot (bytes32 _merkle) public onlyOwner {
        snapshotMerkle = _merkle;
    }

    function updateLOSTAddress (address _newAddress) public onlyOwner {
        lostToken = LOSTToken (_newAddress);
    }

    function updateNameChangePrice(uint256 _price) public onlyOwner {
		nameChangePrice = _price;
	}

    function updateBioChangePrice(uint256 _price) public onlyOwner {
        bioChangePrice = _price;
    }

    function setBaseURI (string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function ownerCollect (uint256 _numLostgirls) public onlyOwner {
        for (uint256 i = 0; i < _numLostgirls; i++) {
            uint256 currentIdx = totalSupply ();
            if (currentIdx < MAX_LOSTGIRLS) {
                _safeMint (msg.sender, currentIdx);
            }
        }
    }
    
    // Public
    
    function claim (uint256 _numLostgirls, 
    uint256 _merkleIndex, uint256 _maxAmount, bytes32[] calldata _merkleProof) public {
        require (claimingEnabled, "Claiming not open yet.");          
        require (totalSupply () + _numLostgirls <= MAX_LOSTGIRLS, "Exceeding supply limit.");  

        bytes32 dataHash = keccak256(abi.encodePacked(_merkleIndex, msg.sender, _maxAmount));
        require(
            MerkleProof.verify(_merkleProof, snapshotMerkle, dataHash),
            "Invalid merkle proof !"
        );
        require (claims[msg.sender] + _numLostgirls <= _maxAmount, "More than eligible for.");
        require (claims[msg.sender] + _numLostgirls <= lostboyNFT.balanceOf(msg.sender), "Not enough lostboys in wallet.");  

        for (uint256 i = 0; i < _numLostgirls; i++) {
            uint256 currentIdx = totalSupply ();
            if (currentIdx < MAX_LOSTGIRLS) {
                _safeMint (msg.sender, currentIdx);
            }
        }

        claims[msg.sender] = claims[msg.sender] + _numLostgirls;
    }

    // Nameable

    function changeName(uint256 _tokenId, string memory _newName) public override {
        require(tokenEnabled, "Token not available yet.");
		lostToken.burn(msg.sender, nameChangePrice);
		super.changeName(_tokenId, _newName);
	}

    function changeBio(uint256 _tokenId, string memory _newBio) public override {
        require(tokenEnabled, "Token not available yet.");
		lostToken.burn(msg.sender, bioChangePrice);
		super.changeBio(_tokenId, _newBio);
	}

    // Override

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
            
}