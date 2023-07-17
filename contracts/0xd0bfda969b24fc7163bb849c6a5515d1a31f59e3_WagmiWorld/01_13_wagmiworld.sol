// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "erc721a/contracts/ERC721A.sol";

contract WagmiWorld is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;

    event stageChanged(uint256 stage);
    event airDropped(uint256 count, address recipient);

    uint256 private constant PrivateMintPrice = .065 ether;
    uint256 private constant PrivateMintWagmiListMax = 1;
	uint256 private constant PrivateMintWagmiListPlusMax = 2;
	uint256 private constant PrivateMintAdditional = 4;
	uint256 private constant PublicMintPrice = .095 ether;
    uint256 private constant PublicMintMax = 4;
	
	uint256 private _maxSupply;
	uint256 private _privateMintSupply;
	uint256 private _airdropSupply;
	uint256 private _currentStage = 0;
	uint256 private _currentPrivateCount = 0;
    uint256 private _currentAirdropCount = 0;

    string private _realBaseURI;
	address private _dustAddress = 0x2783838bf14dD069f58B862A22311A2730D90f12;
	
	mapping(address => uint256) private _privateClaims;
	mapping(address => uint256) private _publicClaims;

    bytes32 private _merkleRootWagmiList = 0x0000000000000000000000000000000000000000000000000000000000000000;
	bytes32 private _merkleRootWagmiListPlus = 0x0000000000000000000000000000000000000000000000000000000000000000;
      
    uint256[] private _fundRecipientsPercentage = [4350, 1500, 1500, 800, 800, 500, 300, 200, 50];

    address[] private _fundRecipients = [
	0xd7C15eD7FC348CD1BCFe27B12E0581645e82FD00,
	0x1d120cc622aF4A6559bF013B8A264841B2C54076,
	0x491252D2D7FbF62fE8360F80eAFccdF6edfa9090,
	0x2861806A3F3a3E0567E87D99f12959E8b78b0119,
	0xa3c0F074647607611bE7706F48aDDbB09a1620b8,
	0x2783838bf14dD069f58B862A22311A2730D90f12,
	0x550C960A848DA40Cf9cB08833C380F63828410b9,
	0x784A1F2f56B452109AFA5bdA11aa0f096a0E976D,
    0xAd00A816d592Ae3eBa1399c9C5293A8798928355];

    constructor(uint256 maxSupply, uint256 airdropSupply, uint256 privateMintSupply)  ERC721A("WAGMI WORLD", "WGMI"){
		_maxSupply = maxSupply;
		_airdropSupply = airdropSupply;
		_privateMintSupply = privateMintSupply;
    }

	receive() external payable {
    }
	
	fallback() external payable{
	}
	
    function airdropMultiple(address[] memory recipients) external onlyOwner() {
		require((_currentAirdropCount + recipients.length) <= _airdropSupply, "Exceeding airdrop supply.");
		
        for (uint256 i = 0; i < recipients.length; i++) {
			airdrop(1, recipients[i]);
		}
	}
	
	function airdrop(uint256 count, address recipient) public onlyOwner() {
		require((_currentAirdropCount + count) <= _airdropSupply, "Exceeding airdrop supply count.");
		
        _safeMint(recipient, count);
        _currentAirdropCount += count;

        emit airDropped(count, recipient);
	}

    function mintPrivateStage(uint256 count, bytes32[] calldata merkleProof) external payable nonReentrant {
		require(_currentStage == 1 || _currentStage == 2, "Private sale is not active.");
		
		bytes32 proof = keccak256(abi.encodePacked(msg.sender));
		
		uint256 mintCount = 0;
		
		if(MerkleProof.verify(merkleProof, _merkleRootWagmiList, proof)){
			if(_currentStage == 1){
				mintCount = PrivateMintWagmiListMax;
			}
			else{
				mintCount = PrivateMintWagmiListMax + PrivateMintAdditional;
			}
		}
		else if(MerkleProof.verify(merkleProof, _merkleRootWagmiListPlus, proof)){
			if(_currentStage == 1){
				mintCount = PrivateMintWagmiListPlusMax;
			}
			else{
				mintCount = PrivateMintWagmiListPlusMax + PrivateMintAdditional;
			}
		}
		
		require(mintCount > 0, "Not authorized for private mint.");
		require(count > 0 && count <= mintCount, "Exceeding number of tokens allowed.");
		require(_privateClaims[msg.sender] + count <= mintCount, "Exceeding number of tokens allowed for this address.");
		require((_currentPrivateCount + count) <= _privateMintSupply, "Out of supply.");
		require(msg.value == (PrivateMintPrice * count), "Invalid amount received.");
		
		_safeMint(msg.sender, count);

        _privateClaims[msg.sender] += count;
        _currentPrivateCount += count;
	}
	
    function mintPublic(uint256 count) external payable nonReentrant {
		require(_currentStage == 3, "Public sale is not active.");
		require((totalSupply() - _currentAirdropCount + count) <= (_maxSupply - _airdropSupply), "Out of supply.");
		require(count > 0 && count <= PublicMintMax, "Exceeding number of tokens allowed.");
		require(_publicClaims[msg.sender] + count <= PublicMintMax, "Exceeding number of tokens allowed for this address.");
		require(msg.value == (PublicMintPrice * count), "Invalid amount received.");
		
        _safeMint(msg.sender, count);
		_publicClaims[msg.sender] += count;
	}

	function getAirdropCount() external view returns(uint256){
        return _currentAirdropCount;
    }

	function getStage() external view returns(uint256){
        return _currentStage;
    }

	function setStage(uint256 newStage) external onlyOwner() {
		require(newStage != _currentStage, "Already to that mint stage.");
        require(newStage >= 0 && newStage <= 4, "Invalid stage.");
		
        _currentStage = newStage;

        emit stageChanged(_currentStage);
	}

    function setBaseURI(string memory newBaseURI) external onlyOwner() {
        _realBaseURI = newBaseURI;
    }
	
	function setMaxSupply(uint256 newMaxSupply, uint256 newPrivateMintSupply) external onlyOwner() {
		_maxSupply = newMaxSupply;
		_privateMintSupply = newPrivateMintSupply;
	}

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        require(balance > 0, "No fund to withdraw.");

		for (uint256 i = 0; i < _fundRecipients.length; i++) {
			_withdraw(_fundRecipients[i], ((balance * _fundRecipientsPercentage[i]) / 10000));
		}
        
        balance = address(this).balance;

        if (balance > 0){
            _withdraw(_dustAddress, balance);
        }
    }

    function setMerkleRootWagmiList(bytes32 newRoot) external onlyOwner() {
		_merkleRootWagmiList = newRoot;
	}
	
	function setMerkleRootWagmiListPlus(bytes32 newRoot) external onlyOwner() {
		_merkleRootWagmiListPlus = newRoot;
	}

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return _realBaseURI;
    }

    function _withdraw(address recipient, uint256 amount) private {
        require(payable(recipient).send(amount), "Error sending fund.");
    }
}