// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IEssence.sol";

contract Draco is ERC721A, Ownable {
    using Address for address;
    using Strings for uint256;
    
    string public baseURI;
    bytes32 public merkleRoot;

    address public essence;

    uint256 public constant EMISSION_RATE = uint256(10 * 1e18) / 86400;

    uint256 public maxDraco = 4444;
    uint256 public price = 0.055 ether;

    uint256 public constant TEAM_SUPPLY = 15;
    uint256 public constant MAX_FREE = 2;
    uint256 public constant MAX_WHITELIST = 3;
    uint256 public constant MAX_PUBLIC = 5;
    uint256 public freeMintCount = 18;

    string public constant BASE_EXTENSION = ".json";

    bool public presaleActive = false;
    bool public saleActive = false;
    bool public teamClaimed = false;

    mapping (address => uint256) public freeWhitelist;
    mapping (address => uint256) public presaleWhitelist;
    mapping (uint256 => uint256) public claimTime;

    constructor() ERC721A("Dracoverse", "DRACO", 20) { 
    }

    function adminMint() public onlyOwner {
        require(totalSupply() + TEAM_SUPPLY <= maxDraco,     "");
        require(!teamClaimed,                                "");

        teamClaimed = true;

        _safeMint(msg.sender, TEAM_SUPPLY);
    }

    function freeMint() public {
        uint256 reserved = freeWhitelist[msg.sender];
        require(presaleActive || saleActive, "");
        
        freeMintCount -= reserved;
        freeWhitelist[msg.sender] = 0;

        _safeMint(msg.sender, reserved);
    }
    
    function presaleMint(uint256 _numberOfMints, bytes32[] calldata _merkleProof) public payable {
        uint256 total = presaleWhitelist[msg.sender] + _numberOfMints;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),             "");
        require(presaleActive,                                                  "");
        require(total <= MAX_WHITELIST,                                         "");
        require(totalSupply() + _numberOfMints + freeMintCount <= maxDraco,     "");
        require(price * _numberOfMints == msg.value,                            "");
        
        presaleWhitelist[msg.sender] = total;
        
        _safeMint(msg.sender, _numberOfMints);
    }
    
    function mint(uint256 _numberOfMints) public payable {
        require(saleActive,                                                     "");
        require(_numberOfMints > 0 && _numberOfMints <= MAX_PUBLIC,             "");
        require(totalSupply() + _numberOfMints + freeMintCount <= maxDraco,     "");
        require(price * _numberOfMints == msg.value,                            "");
        
        _safeMint(msg.sender, _numberOfMints);
    }

    function setEssence(address _essence) public onlyOwner {
        essence = _essence;
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        presaleActive = false;
        saleActive = !saleActive;
    }

    function setFreeList(address[] calldata _addresses, uint256[] calldata _counts) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++){
            freeWhitelist[_addresses[i]] = _counts[i];
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _safeMint(address _to, uint256 _quantity) internal {
        uint256 total = totalSupply();
        for(uint256 i = 0; i < _quantity; i++){
            claimTime[total + i] = block.timestamp;
        }
        _safeMint(_to, _quantity, "");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _id) public view virtual override returns (string memory) {
        require(_exists(_id), "");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _id.toString(), BASE_EXTENSION))
            : "";
    }

    function setMaxDraco(uint256 _count) public onlyOwner {
        maxDraco = _count;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setFreeMintCount(uint256 _count) public onlyOwner {
        freeMintCount = _count;
    }

    function claim(uint256[] calldata tokenIds) public {
        require(tx.origin == msg.sender, "?");
        uint256 total = 0;
        for(uint256 i; i < tokenIds.length; i++){
            require(ownerOf(tokenIds[i]) == msg.sender, "");
            total += (block.timestamp - claimTime[tokenIds[i]]) * EMISSION_RATE;
            claimTime[tokenIds[i]] = block.timestamp;
        }
        IEssence(essence).mintToken(msg.sender, total);
    }    

    function walletOfOwner(address _owner) external view returns (uint256[] memory tokenIds, uint256 rewards) {
        uint256 tokenCount = balanceOf(_owner);
        uint256 total = 0;

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            total += (block.timestamp - claimTime[tokensId[i]]) * EMISSION_RATE;
        }

        return (tokensId, total);
    }

    function withdraw(address _address) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_address).transfer(balance);
    } 

    function whitelistCount(bytes32[] calldata _merkleProof, address _address) external view returns(uint256 count) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        if(MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            return MAX_WHITELIST - presaleWhitelist[_address];
        } else {
            return 0;
        }
    }
}