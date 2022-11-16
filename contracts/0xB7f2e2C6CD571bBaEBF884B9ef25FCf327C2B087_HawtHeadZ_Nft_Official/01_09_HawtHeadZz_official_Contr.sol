//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract HawtHeadZ_Nft_Official  is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;

	uint256 public maxSupply = 4444;
    uint256 public wlSupply = 1000;
    uint256 public wlMinted = 0;
	uint256 public maxperTxn = 5;

    uint256 public cost = 0.005 ether;

    bool public isPreMint = true;
    bool public isRevealed = false;
	bool public pause = true;

    string private baseURL = "";
    string public hiddenMetadataUrl = "ipfs://QmfLwkjyDeamDmEDqcFG1ywpHG2q7Dd1kMSXXNXCX3T2yU/unrevealed.json";

    bytes32 public merkleRoot;

	constructor(
        string memory _baseMetadataUrl,
		bytes32 _merkleRoot
	)
	ERC721A("HawtHeadZz Official", "HHZNFT") {
        setBaseUri(_baseMetadataUrl);
		merkleRoot = _merkleRoot;
    }

	function _baseURI() internal view override returns (string memory) {
		return baseURL;
	}

    function setBaseUri(string memory _baseURL) public onlyOwner {
	    baseURL = _baseURL;
	}

    function sethiddenMetadataUrl(string memory _hiddenMetadataUrl) public onlyOwner {
	    hiddenMetadataUrl = _hiddenMetadataUrl;
	}

    function reveal(bool _state) external onlyOwner {
	    isRevealed = _state;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
    	return 1;
  	}

    function presaleSwitch(bool _state) external onlyOwner {
	    isPreMint = _state;
	}

    function PreMint(uint256 mintAmount, bytes32[] calldata _merkleProof) external payable premintChecks(_merkleProof, mintAmount){
		_safeMint(msg.sender, mintAmount);
        wlMinted+=mintAmount;
    }

    modifier premintChecks(bytes32[] calldata _merkleProof, uint256 mintAmount){
		require(!pause, "The contract is paused");
        require(isPreMint, "Pre mint not start");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You're not whitelisted!");
        require(wlMinted + mintAmount <= wlSupply,"Exceeds whitelist supply");
		require(mintAmount <= maxperTxn, "max per txn exceeded");
        _;
    }

	function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
	}

    function setWlSupply(uint256 newWlSupply) external onlyOwner {
		wlSupply = newWlSupply;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory)
	{
        require(_exists(tokenId), "That token doesn't exist");
        if(isRevealed == false) {
            return hiddenMetadataUrl;
        }
        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : "";
	}

	function publicMint(uint256 mintAmount) external payable {
		require(!pause, "The contract is paused");
		require(!isPreMint, "Public mint not start");
        require(_totalMinted() + mintAmount <= maxSupply,"Exceeds max supply");
        require(msg.value >= cost * mintAmount, "insufficient funds");
		require(mintAmount <= maxperTxn, "max per txn exceeded");
		_safeMint(msg.sender, mintAmount);
	}

	function setCost(uint256 _newCost) public onlyOwner{
		cost = _newCost;
	}

	function setMaxPerTxn(uint _newMax) public onlyOwner{
		maxperTxn = _newMax;
	}

	function setPause(bool _state) public onlyOwner{
		pause = _state;
	}

    function airDrop(address to, uint256 mintAmount) external onlyOwner {
		require(
			_totalMinted() + mintAmount <= maxSupply,
			"Exceeds max supply"
		);
		_safeMint(to, mintAmount);
	}

    function setMerkleRoot(bytes32 _newMerkle) public onlyOwner{
        merkleRoot = _newMerkle;
    }

	function withdraw() external onlyOwner {
		(bool dev, ) = payable(0xfc16449c03250f0580C7a330A9389044F350B6Bb).call{
            value: (address(this).balance * 5) / 100
        }("");
		require(dev);
		(bool success, ) = payable(owner()).call{
            value: address(this).balance
        }("");
        require(success);
	}
}