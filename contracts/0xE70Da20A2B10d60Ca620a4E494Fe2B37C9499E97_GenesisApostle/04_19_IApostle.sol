// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ITRYPToken.sol";
import "./IERC721EnumerableNameable.sol";

contract IApostle is IERC721EnumerableNameable {
    
    enum APOSTLE_TYPE {
        NONE,
        VOYAGER,
        PSYCHONAUT,
        ANCIENT, 
        GODDESS
    }
    
    // Toggles
    bool public m_canValidate = false;
    bool public m_tokenGeneration = false;
    
    // Properties
    mapping (uint256 => APOSTLE_TYPE) private m_ApostleTypes;
    bytes32 private m_apostlesMerkle;  
    string private m_baseUri = "";
    
    // External
    ITRYPToken m_trypContract;
    
    constructor(string memory _name, string memory _symbol, string memory baseURI) IERC721EnumerableNameable (_name, _symbol) {
        m_baseUri = baseURI;
    }
    
    // OWNER ONLY
    
    function toggleValidation () external onlyOwner {
        m_canValidate = !m_canValidate;
    }

    function toggleTokenGeneration () external onlyOwner {
        m_tokenGeneration = !m_tokenGeneration;
    }

    function setTokenAddress (address _tokenAddress) public onlyOwner {
        m_trypContract = ITRYPToken (_tokenAddress);
    }
    
    function setApostleValidationMerkle (bytes32 _merkle) external onlyOwner {
        m_apostlesMerkle = _merkle;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        m_baseUri = _uri;
    }
    
    function setNamingPrice(uint256 _price) external onlyOwner {
		m_nameChangePrice = _price;
	}

    function setBioPrice(uint256 _price) external onlyOwner {
        m_bioChangePrice = _price;
    }
    
    // PUBLIC
   
    function changeName(uint256 _tokenId, string memory _newName) public override isTokenEnabled {
		m_trypContract.burn(msg.sender, m_nameChangePrice);
		super.changeName(_tokenId, _newName);
	}

    function changeBio(uint256 _tokenId, string memory _newBio) public override isTokenEnabled {
		m_trypContract.burn(msg.sender, m_bioChangePrice);
		super.changeBio(_tokenId, _newBio);
	}
    
    // VIEWS

    function validateApostle(uint _idx, uint _typeIdx, bytes32[] calldata _merkleProof) public isValidationActive {
        require(_exists(_idx), "Apostle does not exist.");
        require(ownerOf(_idx) == msg.sender, "You do not own this apostle.");
        require(m_ApostleTypes[_idx] == APOSTLE_TYPE(0), "Already validated.");

        // Verify merkle for apostle validation
        bytes32 nHash = keccak256(abi.encodePacked(_idx, _typeIdx));
        require(
            MerkleProof.verify(_merkleProof, m_apostlesMerkle, nHash),
            "Invalid merkle proof !"
        );
        
        m_ApostleTypes[_idx] = APOSTLE_TYPE(_typeIdx);
    }
    
    function getTypeForApostle (uint _idx) public view returns (APOSTLE_TYPE)  {
        return m_ApostleTypes[_idx];
    }
    
    // INTERNALS
    
    function _baseURI() internal view override returns (string memory) {
        return m_baseUri;
    }
    
    // EXTERNAL
    
    function getReward() external isTokenEnabled {
		m_trypContract.updateReward(msg.sender, address(0), 0);
		m_trypContract.claimReward(msg.sender);
	}
    
    // OVERRIDE
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (m_tokenGeneration) { m_trypContract.updateReward(from, to, tokenId); }
    }

    // MODIFIERS
	
    modifier isValidationActive() {
        require(m_canValidate, "Validation not open yet.");
        _;
    }

    modifier isTokenEnabled () {
        require(m_tokenGeneration, "Token generation not enabled.");
        _;
    }
    
}