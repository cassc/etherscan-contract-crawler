// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/strings.sol';
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract PetPals is ERC721AQueryable, ReentrancyGuard, Ownable, Pausable {
    using Strings for uint256;

    event stageChanged(uint256 stage);
    event airDropped(uint256 count, address recipient);
    
    uint256 private constant WhiteListMintPrice = .07 ether;
    uint256 private constant WhiteListMintMax = 2;
	uint256 private constant PublicMintPrice = .077 ether;
    uint256 private constant PublicMintMax = 3;
	
	uint256 public maxSupply = 10000;
	uint256 public airdropSupply = 150;
    uint256 public airdropCount = 0;
    uint256 public publicCount = 0;
    uint256 public whiteListCount = 0;
	uint256 public currentStage = 0;

    string private realBaseURI;
	address private dustAddress = 0xA0355DFCE8c5dFbBfF68d9Dce7B21E9E50729194;

    bytes32 private merkleRootWhiteList = 0x0000000000000000000000000000000000000000000000000000000000000000;
	
	mapping(address => uint256) private whiteListClaims;
	mapping(address => uint256) private publicClaims;

    uint256[] private withdrawPercentage = [1500, 6000, 1000, 1500];

    address[] private withdrawRecipients = [0xe9f834F353c0F7a847aE0Ed0aC46e8cad6747F8f,
        0xA0355DFCE8c5dFbBfF68d9Dce7B21E9E50729194,
        0x550C960A848DA40Cf9cB08833C380F63828410b9,
		0xf19Ae62764A2466EE3f28d3424A417f8dB6CB5E1];

    constructor() ERC721A("PetPals", "PPALS"){
    }

    modifier airdropRequirement(uint256 _count) {
        require(airdropCount + _count <= airdropSupply, "Airdrop supply exceeded.");
        require((totalSupply() + _count) <= maxSupply, "Airdrop count exceeds total supply.");
        _;
    }
    
    modifier mintRequirement(uint _amount,
        uint256 _mintPrice, 
        uint256 _mintCount,
        uint256 _maxMint) {
        require(_mintCount > 0 && _mintCount <= _maxMint, "Invalid number of token.");
        require((totalSupply() + _mintCount - airdropCount) <= _mintSupply(), "Exceeding the number of tokens supply.");
        require((_mintCount * _mintPrice) == _amount, "Invalid amount received.");
        _;
    }

	receive() external payable {
    }
	
    function airdropMultiple(address[] memory _recipients) external 
        onlyOwner
		nonReentrant		
        airdropRequirement(_recipients.length) {
        
        for (uint256 i = 0; i < _recipients.length; i++) {
			_safeMint(_recipients[i], 1);
			emit airDropped(1, _recipients[i]);
		}
		
		airdropCount += _recipients.length;
	}
	
	function airdrop(uint256 _count, address _recipient) public
        nonReentrant 
        onlyOwner 
        airdropRequirement(_count) {

        airdropCount += _count;
        _safeMint(_recipient, _count);

        emit airDropped(_count, _recipient);
	}
	
    function mintWhiteList(uint256 _count, bytes32[] calldata _merkleProof) external 
        payable
        nonReentrant
        whenNotPaused
        mintRequirement(msg.value,
            WhiteListMintPrice,
            _count,
            WhiteListMintMax) {
        require(currentStage > 0 && currentStage < 3, "Whitelist mint is not active.");
        require(whiteListClaims[msg.sender] + _count <= WhiteListMintMax, "Exceeding number of tokens allowed for this address.");

		bytes32 proof = keccak256(abi.encodePacked(msg.sender));
		
		require(MerkleProof.verify(_merkleProof, merkleRootWhiteList, proof), "Not authorized for Whitelist mint.");
		
        whiteListClaims[msg.sender] += _count;
        whiteListCount += _count;
		
		_safeMint(msg.sender, _count);
	}

    function mintPublic(uint256 _count) external 
        payable
        nonReentrant
        whenNotPaused
        mintRequirement(msg.value,
            PublicMintPrice,
            _count,
            PublicMintMax) {
        require(currentStage == 2, "Public mint is not active.");
        require(publicClaims[msg.sender] + _count <= PublicMintMax, "Exceeding number of tokens allowed for this address.");

        publicClaims[msg.sender] += _count;
        publicCount += _count;
		
		_safeMint(msg.sender, _count);
	}

    function whiteListCountForAddress(address _addr) external view returns(uint256) {
        uint256 count = whiteListClaims[_addr];

        return count;
    }
	
	function publicCountForAddress(address _addr) external view returns(uint256) {
        uint256 count = publicClaims[_addr];

        return count;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 0;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        realBaseURI = _newBaseURI;
    }
	
	function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(totalSupply() <= _newMaxSupply, "The total supply is greater than the new max supply.");
        require(_newMaxSupply >= publicCount + whiteListCount + airdropSupply, "The new max supply must be greater than or equal to the sum of the supplies.");
		maxSupply = _newMaxSupply;
	}

    function setAirdropSupply(uint256 _newSupply) external onlyOwner {
		require(airdropCount <= _newSupply, "The airdrop count is greater than the new airdrop supply.");
        require(maxSupply >= publicCount + whiteListCount + _newSupply, "The maxSupply will be to low for the new airdrop supply.");
        airdropSupply = _newSupply;
	}

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        require(balance > 0, "No fund to withdraw.");

		for (uint256 i = 0; i < withdrawRecipients.length; i++) {
			_withdraw(withdrawRecipients[i], ((balance * withdrawPercentage[i]) / 10000));
		}
        
        balance = address(this).balance;

        if (balance > 0){
            _withdraw(dustAddress, balance);
        }
    }

    function setMerkleRootWhiteList(bytes32 _newRoot) external onlyOwner {
		merkleRootWhiteList = _newRoot;
	}

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721A, IERC721A) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
		require(_exists(_tokenId), "URI query for nonexistent token.");
		
        if (currentStage == 4) {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), ".json")) : '';
        } else {
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, "unreveal.json")) : '';
        }
	}

    function setStage(uint256 _newStage) external onlyOwner {
		require(_newStage != currentStage, "Already at this stage.");
		require(_newStage >= 0 && _newStage <= 4, "Invalid stage.");
        currentStage = _newStage;
    }
	
	function addressHasWL(address _addr, bytes32[] calldata _merkleProof) external view returns(bool){
		bytes32 proof = keccak256(abi.encodePacked(_addr));
		
		return MerkleProof.verify(_merkleProof, merkleRootWhiteList, proof);
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return realBaseURI;
    }

    function _withdraw(address _recipient, uint256 _amount) private {
        require(_recipient != address(0), "Recipient wallet is invalid.");
        require(payable(_recipient).send(_amount), "Error sending fund.");
    }

    function _mintSupply() private view returns(uint256){
        return maxSupply - airdropSupply;
    }
}