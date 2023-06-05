// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "erc721a/contracts/ERC721A.sol";

contract cybonixnft is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    event stageChanged(uint256 stage);
    event airDropped(uint256 count, address recipient);

    uint256 private constant OGMintPrice = .08 ether;
    uint256 private constant PrivateMintWLMaxTx = 2;
	uint256 private constant PrivateMintOGMaxTx = 3;
    uint256 private constant PrivateMintWLMaxWallet = 2;
	uint256 private constant PrivateMintOGMaxWallet = 3;
    uint256 private constant PublicMintMaxTx = 2;
	
	uint256 private _mintPrice = .085 ether;
	uint256 private _currentPrivateCount = 0;
	uint256 private _maxSupplyCount;    
    uint256 private _currentStage = 0;
    uint256 private _airdropSupplyCount;
    uint256 private _currentAirdropCount = 0;

	address private _remainderAddress = 0x544aD958465B87757d0B28C899dF836A6Ac497EB;
    
	mapping(address => uint256) private _claims;
    
    string private _realBaseURI;

    bytes32 private _merkleRootWL = 0x0000000000000000000000000000000000000000000000000000000000000000;
	bytes32 private _merkleRootOG = 0x0000000000000000000000000000000000000000000000000000000000000000;
      
    uint256[] private _mintingRecipientsPercentage = [1250, 1250, 575, 250, 3500, 1575, 700, 50, 100, 250, 200, 100, 100, 100];

    address[] private _recipients = [
	0xB55248a92CF4c67A485abe60539D3c56b1Fba3e7,
	0xDb73bC05acba19A79F3dc9A24c6A498eF48e2857,
	0x06fD15f24D3CA62B53fFc8b13b75fa19B045d788,
	0xf902BA03ffe34E497b7f24aC135037a5c876d037,
	0x72c7F42e8bD452F288aE4c7Ce44c725c29dceE49,
	0x491252D2D7FbF62fE8360F80eAFccdF6edfa9090,
	0x46ac300f16DF3732c98c87825fa0b2E0196a686F,
	0xe5E56b430576ad527b8C324eb374544BECd2D89A,
    0x6e4EA253fCdFc1E6862Da77e55e1C79b5e6865EF,
	0x550C960A848DA40Cf9cB08833C380F63828410b9,
	0x28B3cAD1d80014684fFb1B7A4F56c6894c474D9D,
	0x79C7F92C0b6b6770581d96898EE1858Ce1007726,
	0x616621F46e27F824dB7A25e815717f661b3B8638,
	0xafBD28f83c21674796Cb6eDE9aBed53de4aFbcC4];

    modifier ensureUser() {
		require(msg.sender == tx.origin, "Not authorized.");
		_;
	}

    constructor(uint256 maxSupplyCount, uint256 airdropSupplyCount)  ERC721A("Cybonix NFT", "CBNX"){
		_maxSupplyCount = maxSupplyCount;
		_airdropSupplyCount = airdropSupplyCount;
    }

	receive() external payable {
    }
	
	fallback() external payable{
	}
	
    function airdropMultipleRecipients(address[] memory recipients) external onlyOwner() {
		require((_currentAirdropCount + recipients.length) <= _airdropSupplyCount, "Exceeding airdrop supply count.");
		
        for (uint256 i = 0; i < recipients.length; i++) {
			airdrop(1, recipients[i]);
		}
	}

    function mintPrivate(uint256 count, bytes32[] calldata merkleProof) external payable ensureUser nonReentrant {
		require(_currentStage == 1 || _currentStage == 2, "Private sale is not active.");
		
		uint256 mintPrice;
		uint256 maxTx;
		uint256 maxWallet;
		
		bytes32 proof = keccak256(abi.encodePacked(msg.sender));
		
		if(_currentStage == 1){
			require(MerkleProof.verify(merkleProof, _merkleRootOG, proof), "Not authorized for OG private mint.");
			require(count > 0 && count <= PrivateMintOGMaxTx, "Exceeding number of tokens allowed for a transaction.");
			require(_claims[msg.sender] + count <= PrivateMintOGMaxWallet, "Exceeding number of tokens allowed for this address.");
			
			mintPrice = OGMintPrice;
		}
		else if(_currentStage == 2){
			bool canMint = false;
			
			if(MerkleProof.verify(merkleProof, _merkleRootOG, proof)){
				mintPrice = OGMintPrice;
				maxTx = PrivateMintOGMaxTx;
				maxWallet = PrivateMintOGMaxWallet;
				canMint = true;
			} else if(MerkleProof.verify(merkleProof, _merkleRootWL, proof)){
				mintPrice = _mintPrice;
				maxTx = PrivateMintWLMaxTx;
				maxWallet = PrivateMintWLMaxWallet;
				canMint = true;
			}
		
			require(canMint, "Not authorized for WL private mint.");
			require(count > 0 && count <= maxTx, "Exceeding number of tokens allowed for a transaction.");
			require(_claims[msg.sender] + count <= maxWallet, "Exceeding number of tokens allowed for this address.");
		}
		
		require((_currentPrivateCount + count) <= (_maxSupplyCount - _airdropSupplyCount), "Out of supply.");
		
		require(msg.value == (mintPrice * count), "Invalid amount received.");
		
		_safeMint(msg.sender, count);

        _claims[msg.sender] += count;
        _currentPrivateCount += count;
	}

    function mintPublic(uint256 count) external payable ensureUser nonReentrant {
		require(_currentStage == 3, "Public sale is not active.");
		require((totalSupply() - _currentAirdropCount + count) <= (_maxSupplyCount - _airdropSupplyCount), "Out of supply.");
		require(count > 0 && count <= PublicMintMaxTx, "Exceeding number of tokens allowed for a transaction.");
		require(msg.value == (_mintPrice * count), "Invalid amount received.");
		
        _safeMint(msg.sender, count);
	}

	function getStage() external view returns(uint256){
        return _currentStage;
    }

	function getMintPrice() external view returns(uint256){
        return _mintPrice;
    }

	function setMintPrice(uint256 price) external onlyOwner() {
        _mintPrice = price;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner() {
        _realBaseURI = newBaseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;

        require(balance > 0, "No fund to withdraw.");

		for (uint256 i = 0; i < _recipients.length; i++) {
			_withdraw(_recipients[i], ((balance * _mintingRecipientsPercentage[i]) / 10000));
		}
        
        balance = address(this).balance;

        if (balance > 0){
            _withdraw(_remainderAddress, balance);
        }
    }

    function airdrop(uint256 count, address recipient) public onlyOwner() {
		require((_currentAirdropCount + count) <= _airdropSupplyCount, "Exceeding airdrop supply count.");
		
        _safeMint(recipient, count);
        _currentAirdropCount += count;

        emit airDropped(count, recipient);
	}

    function setMerkleRootWL(bytes32 newRoot) external onlyOwner() {
		_merkleRootWL = newRoot;
	}
	
	function setMerkleRootOG(bytes32 newRoot) external onlyOwner() {
		_merkleRootOG = newRoot;
	}

    function setStage(uint256 newStage) external onlyOwner() {
		require(newStage != _currentStage, "Already to that mint stage.");
        require(newStage >= 0 && newStage <= 4, "Invalid stage.");
		
        _currentStage = newStage;

        emit stageChanged(_currentStage);
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