// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract CornyChon is ERC721A, Ownable, ReentrancyGuard {
	using Address for address;
	using Strings for uint256;

	uint64 public _maxSupply = 6969;
    string public metadataIpfsCid;
    mapping(address => uint256) public mintRecord;

	constructor() ERC721A("CornyChon", "CyC") {
	}


    function setMetadataIpfsCid(string calldata _metadataIpfsCid) external onlyOwner {
        metadataIpfsCid = _metadataIpfsCid;
    }

    function mint(uint256 quantity) external payable nonReentrant {
        require(msg.sender == tx.origin, "Claim from wallet only");
        require(mintRecord[msg.sender] + quantity <= 5, "Exceeds the maximum number of coins that an individual can mint");
        require(totalSupply() + quantity <= _maxSupply, "Maximum supply exceeded");
        mintRecord[msg.sender] = mintRecord[msg.sender] + quantity;
        _safeMint(msg.sender, quantity);
    }

	function withdraw() public onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
    

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked("ipfs://", metadataIpfsCid, "/", tokenId.toString(), ".json"));
        
    }
}