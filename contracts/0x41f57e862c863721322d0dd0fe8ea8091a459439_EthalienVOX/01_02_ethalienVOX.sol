// SPDX-License-Identifier: MIT
//
// Ethalien VOX
/*
 *    _.--'""'--._
 *   / _        _ \
 *  / / o\    / o\ \
 *  \ \___\  /___/ /
 *   \__        __/
 *      \  ''  /
 *       \\__//
 *        '..'
 *
 *
 * @Danny_One
 * 
 */

import "./ERC721_efficient.sol";


pragma solidity ^0.8.0;


contract EthalienVOX is ERC721Enumerable, Ownable, nonReentrant {

	uint256 public vxPrice = 55000000000000000;		// 0.055 ETH
	
    uint256 public immutable MAX_SUPPLY = 10000;	// 10k supply
    uint256 public immutable MAX_TEAMRESERVE = 100;	// total team reserves allowed
	
	bool public saleActive = false;
	
	uint256 public maxSaleMint = 10;
	
	string public VOXprovenance;
	
	uint256 public teamMints = 0;
	
	bytes32 public MerkleRoot;
	
    address public proxyRegistryAddress;
	
	struct AddressInfo {
		uint256 ownerPresaleMints;
		bool projectProxy;
	}
	
	mapping(address => AddressInfo) public addressInfo;
		
	constructor() ERC721("Ethalien VOX", "VALIEN") {}

	
	// PUBLIC FUNCTIONS
	
	function mint(uint256 _mintAmount) public payable reentryLock {
		require(saleActive, "public sale is not active");
		require(msg.sender == tx.origin, "no proxy transactions allowed");
		
		uint256 supply = totalSupply();
		require(_mintAmount < maxSaleMint + 1, "max mint amount per session exceeded");
		require(supply + _mintAmount < MAX_SUPPLY + 1, "max NFT limit exceeded");
	
		require(msg.value >= _mintAmount * vxPrice, "not enough ETH sent");

		for (uint256 i=0; i < _mintAmount; i++) {
		  _safeMint(msg.sender, supply + i);
		}
	}
  
  
	function mintPresale(bytes32[] memory _proof, bytes1 _maxAmountKey, uint256 _mintAmount) public payable reentryLock {
		require(MerkleRoot > 0x00, "claim period not started!");
		
		uint256 supply = totalSupply();
		require(supply + _mintAmount < MAX_SUPPLY + 1, "max collection limit exceeded");
		
		require(MerkleProof.verify(_proof, MerkleRoot, keccak256(abi.encodePacked(msg.sender, _maxAmountKey))), "unauthorized proof-key combo for sender");

		require(addressInfo[msg.sender].ownerPresaleMints + _mintAmount < uint8(_maxAmountKey) + 1, "max free NFT claims exceeded");
		require(msg.value >= _mintAmount * vxPrice, "not enough ETH sent");
		
		addressInfo[msg.sender].ownerPresaleMints += _mintAmount;
		
		for (uint256 i=0; i < _mintAmount; i++) {
		  _safeMint(msg.sender, supply + i);
		}
	}
	
	function checkProofWithKey(bytes32[] memory proof, bytes memory key) public view returns(bool) {
        return MerkleProof.verify(proof, MerkleRoot, keccak256(abi.encodePacked(msg.sender, key)));
    }
	
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        MarketplaceProxyRegistry proxyRegistry = MarketplaceProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || addressInfo[operator].projectProxy) return true;
        return super.isApprovedForAll(_owner, operator);
    }


	// ONLY OWNER FUNCTIONS

	function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setMerkleRoot(bytes32 _MerkleRoot) public onlyOwner {
        MerkleRoot = _MerkleRoot;
    }
	
    function flipSaleState() public onlyOwner {
        saleActive = !saleActive;
    }

	function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
		proxyRegistryAddress = _proxyRegistryAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
		(bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        vxPrice = _newPrice;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        VOXprovenance = _provenance;
    }
	
	// reserve function for team mints (giveaways & payments)
    function teamMint(address _to, uint256 _reserveAmount) public onlyOwner {
        require(_reserveAmount > 0 && _reserveAmount + teamMints < MAX_TEAMRESERVE + 1, "Not enough reserve left for team");
		uint256 supply = totalSupply();
		teamMints = teamMints + _reserveAmount;
		
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i );
        }
    }

}

contract OwnableDelegateProxy { }
contract MarketplaceProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}