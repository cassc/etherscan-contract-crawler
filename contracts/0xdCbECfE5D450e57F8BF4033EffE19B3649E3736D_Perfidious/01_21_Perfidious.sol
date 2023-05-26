// SPDX-License-Identifier: MIT

/*
   ▄███████▄    ▄████████    ▄████████    ▄████████  ▄█  ████████▄   ▄█   ▄██████▄  ███    █▄     ▄████████ 
  ███    ███   ███    ███   ███    ███   ███    ███ ███  ███   ▀███ ███  ███    ███ ███    ███   ███    ███ 
  ███    ███   ███    █▀    ███    ███   ███    █▀  ███▌ ███    ███ ███▌ ███    ███ ███    ███   ███    █▀  
  ███    ███  ▄███▄▄▄      ▄███▄▄▄▄██▀  ▄███▄▄▄     ███▌ ███    ███ ███▌ ███    ███ ███    ███   ███        
▀█████████▀  ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ▀▀███▀▀▀     ███▌ ███    ███ ███▌ ███    ███ ███    ███ ▀███████████ 
  ███          ███    █▄  ▀███████████   ███        ███  ███    ███ ███  ███    ███ ███    ███          ███ 
  ███          ███    ███   ███    ███   ███        ███  ███   ▄███ ███  ███    ███ ███    ███    ▄█    ███ 
 ▄████▀        ██████████   ███    ███   ███        █▀   ████████▀  █▀    ▀██████▀  ████████▀   ▄████████▀  
                            ███    ███                                                                      
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";

contract Perfidious is ERC721Enumerable, Ownable, AccessControl, PaymentSplitter, ReentrancyGuard {

    uint constant public MAX_SUPPLY = 1800;
    string public baseURI = "";
    string public contractURI = "";
    bytes32 public presaleListMerkleRoot;
    bytes32 public chaosListMerkleRoot;
    uint constant public presaleListQuantity = 2;
    uint constant public chaosListQuantity = 1;
    uint constant public publicQuantity = 1;
    mapping(address => bool) public mintTracker;
    
    State public saleState = State.OFF;
    enum State { OFF, PRESALE, PUBLIC, FROZEN }

    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");

    address[] private addressList = [
        0xfD28d97Dde0c26a7ED2Db99C63e7714b71309a59,
        0xBc3B2d37c5B32686b0804a7d6A317E15173d10A7,
        0x909957dcc1B114Fe262F4779e6aeD4d034D96B0f
    ];
    
    uint[] private shareList = [
        80,
        10,
        10
    ];

    constructor() 
        ERC721("Perfidious", "Perfidious") 
        PaymentSplitter(addressList, shareList) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SUPPORT_ROLE, msg.sender);
    }

    function mint() payable external nonReentrant {
        require(saleState == State.PUBLIC, "Sale is not active");
        require(!mintTracker[msg.sender], "Exceeds wallet limit");
        mintTracker[msg.sender] = true;
        _mintTokens(msg.sender, publicQuantity);
    }

    function presaleMint(bytes32[] memory proof) payable external nonReentrant {
        require(saleState == State.PRESALE, "Sale is not active");
        require(MerkleProof.verify(proof, presaleListMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not on the presale list");
        require(!mintTracker[msg.sender], "Exceeds wallet limit");
        mintTracker[msg.sender] = true;
        _mintTokens(msg.sender, presaleListQuantity);
    }

    function chaosMint(bytes32[] memory proof) payable external nonReentrant {
        require(saleState == State.PRESALE, "Sale is not active");
        require(MerkleProof.verify(proof, chaosListMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "You are not on the chaos list");
        require(!mintTracker[msg.sender], "Exceeds wallet limit");
        mintTracker[msg.sender] = true;
        _mintTokens(msg.sender, chaosListQuantity);
    }

    function perfidiousMint(address addr, uint quantity) external onlyRole(SUPPORT_ROLE) {
        _mintTokens(addr, quantity);
    }

    function _mintTokens(address to, uint256 count) internal {
        uint256 totalSupply = _owners.length;
        require(totalSupply + count <= MAX_SUPPLY, "Exceeds max supply");
        require(saleState != State.FROZEN, "Collection is frozen");
        require(tx.origin == msg.sender, "No contracts");
          for(uint i; i < count; i++) { 
            _mint(to, totalSupply + i);
        }
    }

    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyRole(SUPPORT_ROLE) {
        contractURI = _contractURI;
    }

    function clearMintTracker(address addr) external onlyRole(SUPPORT_ROLE) {
        mintTracker[addr] = false;
    }

    function setPresaleMerkleRoot(bytes32 presaleRoot) external onlyRole(SUPPORT_ROLE)  {
        presaleListMerkleRoot = presaleRoot;
    }

    function setChaosMerkleRoot(bytes32 chaosRoot) external onlyRole(SUPPORT_ROLE) {
        chaosListMerkleRoot = chaosRoot;
    }

    function disableMint() external onlyRole(SUPPORT_ROLE) {
        require(saleState != State.FROZEN, "Collection is frozen");
        saleState = State.OFF;
    } 
    
    function enablePublicMint() external onlyRole(SUPPORT_ROLE) {
        require(saleState != State.FROZEN, "Collection is frozen");
        saleState = State.PUBLIC;
    }

    function enablePresaleMint() external onlyRole(SUPPORT_ROLE) {
        require(saleState != State.FROZEN, "Collection is frozen");
        saleState = State.PRESALE;
    }

    function freezeSupply() external onlyRole(SUPPORT_ROLE) {
        saleState = State.FROZEN;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}