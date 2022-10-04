// SPDX-License-Identifier: MIT

/*

   __ _     __   ______  _____ ______ _     _ _______ ______ _      _     _ ______  
  / _| |   (_ \ |  ___ \(_____/ _____| |   | (_______/ _____| |    | |   | (____  \ 
 / / | |  _  \ \| |   | |  _ | /  ___| |__ | |_     | /     | |    | |   | |____)  )
( (  | | / )  ) | |   | | | || | (___|  __)| | |    | |     | |    | |   | |  __  ( 
 \ \_| |< ( _/ /| |   | |_| || \____/| |   | | |____| \_____| |____| |___| | |__)  )
  \__|_| \_(__/ |_|   |_(_____\_____/|_|   |_|\______\______|_______\______|______/ 
                                                                                    
Dev Team: @RabTai @anonsophi
*/
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract kNIGHTCLUB is ERC721, Ownable, ERC2981Upgradeable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private supply;

    uint8 public maxMintPerTx = 2;
    uint16 public constant maxSupply = 5500;
    uint256 public mintCost = 0.08 ether;
    bool public mintPaused = true;
    bool public publicMint = false;
    address public treasuryAddress;

    string public contractURI;

    //Calculated using Markle, make sure to use the rigth Root
    bytes32 public merkleRoot;
    string public baseURI;
    mapping(address => bool) public whitelistClaimed;

    constructor() ERC721("(k)NIGHCLUB", "KNC") {
        mint(500);
    }

    //** Read Functions **

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    //** Write Functions **

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _mintAmount) public payable {
        require(supply.current() + _mintAmount <= maxSupply,"Max supply already reached");
        require(!mintPaused, "Minting is paused");
        require(!publicMint, "Public mint is live");
        require(!whitelistClaimed[msg.sender], "Whitelist already claimed");
        //Check if Merkle root has been already added
        require (merkleRoot!="", "Merkle Root hasn't been added yet");
        require(_mintAmount > 0, "Need more than 0");
        require(_mintAmount <= maxMintPerTx, "Can't mint more than a limit");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Not in whitelist");
        require(msg.value >= mintCost * _mintAmount, "Not enough ETH");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply.increment();
            _safeMint(msg.sender, supply.current());
        }
        whitelistClaimed[msg.sender] = true;
    }

    function crossMint(address _to, uint256 _mintAmount) public payable {
        require(supply.current() + _mintAmount <= maxSupply,"Max supply already reached");
        require(!mintPaused, "Minting is paused");
        require(_mintAmount <= maxMintPerTx, "Can't mint more than a limit");
        require(_mintAmount > 0, "Need more than 0");
        require(msg.value >= mintCost * _mintAmount,"Not enough ETH");
        //Crossmint address
        require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,"This function is for Crossmint only.");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply.increment();
            _safeMint(_to, supply.current());
        }
  }

    function mint(uint256 _mintAmount) public payable {
            require(supply.current() + _mintAmount <= maxSupply,"Max supply already reached");
        if (msg.sender != owner()) {
                require(!mintPaused, "Minting is paused");
                require(publicMint, "Public mint is not live yet");
                require(_mintAmount <= maxMintPerTx, "Can't mint more than a limit");
                require(msg.value >= mintCost * _mintAmount,"Not enough ETH");
            }
            require(_mintAmount > 0, "Need more than 0");
            for (uint256 i = 1; i <= _mintAmount; i++) {
                supply.increment();
                _safeMint(msg.sender, supply.current());
            }
        }

    
    //** Only owner **

    function withdraw() public onlyOwner {
        require (treasuryAddress!=address(0), "Treasury address hasn't been added yet");
        (bool success, ) = payable(treasuryAddress).call{
         value: address(this).balance
        }("");
        require(success);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
       merkleRoot = _root;
    }

    function setCost(uint256 _newMintCost) public onlyOwner {
        mintCost = _newMintCost;
    }

    function setMaxMint(uint8 _maxMint) public onlyOwner {
        maxMintPerTx=_maxMint;
    }

     function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setTreasury(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    //For marketplaces that do not support 9821
    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function pauseMint(bool _trueFalse) public onlyOwner {
        mintPaused = _trueFalse;
    }

     function enablePublicMint() public onlyOwner {
        publicMint = true;
        maxMintPerTx=10;
    }

    //** Supporting fucntions *

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}