// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import {ERC721} from "../lib/solady/src/tokens/ERC721.sol";
import {LibString} from "../lib/solady/src/utils/LibString.sol";
import {OwnableRoles} from "../lib/solady/src/auth/OwnableRoles.sol";
import {MerkleProofLib} from "../lib/solady/src/utils/MerkleProofLib.sol";

contract TheFoolz is ERC721, OwnableRoles {

    string private _name;
    string private _symbol;
    string private _baseURI;
    uint256 private _totalSupply;

    uint256 public MAX_SUPPLY = 777;
    uint256 public MINT_CAP = 259;
    uint256 public WL_PHASE1_START = 1687453200;
    uint256 public WL_PHASE1_END = 1687455000; 
    uint256 public WL_PHASE2_END = 1687471200; 
    uint256 public PUBLIC_START = 1687471205; 
    uint256 public PUBLIC_END = 1687557600;

    uint256 public WL_PHASE1_PRICE = 0.01 ether;
    uint256 public WL_PHASE2_PRICE = 0.01 ether;
    uint256 public PUBLIC_PRICE = 0.015 ether;

    uint256 public constant WL_PHASE1_LIMIT = 4;
    uint256 public constant WL_PHASE2_LIMIT = 3;
    uint256 public constant PUBLIC_LIMIT = 2;

    mapping(address => uint256) public whitelistPurchases;
    mapping(address => uint256) public whitelist2Purchases;
    mapping(address => uint256) public publicPurchases;

    bytes32 public whitelistRootPhase1;
    bytes32 public whitelistRootPhase2;

    struct UpdateStruct {
        uint256 WL_PHASE1_START;
        uint256 WL_PHASE1_END;
        uint256 WL_PHASE2_END;
        uint256 PUBLIC_START;
        uint256 PUBLIC_END;
        uint256 WL_PHASE1_PRICE;
        uint256 WL_PHASE2_PRICE;
        uint256 PUBLIC_PRICE;
        uint256 MINT_CAP;
        bytes32 whitelistRootPhase1;
        bytes32 whitelistRootPhase2;
    }


    constructor() {
        _name = "THE FOOLZ";
        _symbol = "DFZ";
        super._initializeOwner(msg.sender);
    }


    function price(uint256 amount)public view returns (uint256) {
        if (block.timestamp <= WL_PHASE1_END) {
            return amount * WL_PHASE1_PRICE;
        } else if (block.timestamp <= WL_PHASE2_END) {
            return amount * WL_PHASE2_PRICE;
        } else {
            return amount * PUBLIC_PRICE;
        }
    }

    function _mint(address to, uint256 id) internal override {
        super._mint(to, id);
    }
    
    function teamMint(uint256 amount) public onlyOwner {
        require(_totalSupply + amount <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, _totalSupply + 1);
            _totalSupply += 1;
        }
    }

    function setBaseURI(string memory baseURI_) public onlyOwnerOrRoles(_ROLE_0) {
        _baseURI = baseURI_;
    }

    function mint(uint256 amount, bytes32[] calldata proof) public payable {
        require(block.timestamp >= WL_PHASE1_START, "Minting has not started yet");
        require(block.timestamp <= PUBLIC_END, "Minting has ended");
        require(_totalSupply + amount <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");
        require(_totalSupply + amount <= MINT_CAP, "Exceeds MINT_CAP");
        require(msg.value >= price(amount), "Ether value sent is not correct");

        bytes32 node = keccak256(abi.encodePacked(uint256(uint160(msg.sender))));

        if (block.timestamp <= WL_PHASE1_END) {
            require(MerkleProofLib.verify(proof, whitelistRootPhase1, node), "Invalid proof for phase 1");
            require(whitelistPurchases[msg.sender] + amount <= WL_PHASE1_LIMIT, "Exceeds whitelist phase 1 limit");
            whitelistPurchases[msg.sender] += amount;
        } else if (block.timestamp <= WL_PHASE2_END) {
            require(MerkleProofLib.verify(proof, whitelistRootPhase2, node), "Invalid proof for phase 2");
            require(whitelist2Purchases[msg.sender] + amount <= WL_PHASE2_LIMIT, "Exceeds whitelist phase 2 limit");
            whitelist2Purchases[msg.sender] += amount;
        } else {
            require(block.timestamp >= PUBLIC_START, "Public minting has not started yet");
            require(publicPurchases[msg.sender] + amount <= PUBLIC_LIMIT, "Exceeds public limit");
            publicPurchases[msg.sender] += amount;
        }

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, _totalSupply + 1);
            _totalSupply += 1;
        }
    }

    function update(UpdateStruct memory params) public onlyOwnerOrRoles(_ROLE_0) {
        WL_PHASE1_START = params.WL_PHASE1_START != 0 ? params.WL_PHASE1_START : WL_PHASE1_START;
        WL_PHASE1_END = params.WL_PHASE1_END != 0 ? params.WL_PHASE1_END : WL_PHASE1_END;
        WL_PHASE2_END = params.WL_PHASE2_END != 0 ? params.WL_PHASE2_END : WL_PHASE2_END;
        PUBLIC_START = params.PUBLIC_START != 0 ? params.PUBLIC_START : PUBLIC_START;
        PUBLIC_END = params.PUBLIC_END != 0 ? params.PUBLIC_END : PUBLIC_END;
        WL_PHASE1_PRICE = params.WL_PHASE1_PRICE != 0 ? params.WL_PHASE1_PRICE : WL_PHASE1_PRICE;
        WL_PHASE2_PRICE = params.WL_PHASE2_PRICE != 0 ? params.WL_PHASE2_PRICE : WL_PHASE2_PRICE;
        PUBLIC_PRICE = params.PUBLIC_PRICE != 0 ? params.PUBLIC_PRICE : PUBLIC_PRICE;
        MINT_CAP = params.MINT_CAP != 0 && params.MINT_CAP <= MAX_SUPPLY ? params.MINT_CAP : MINT_CAP;
        whitelistRootPhase1 = params.whitelistRootPhase1 != 0 ? params.whitelistRootPhase1 : whitelistRootPhase1;
        whitelistRootPhase2 = params.whitelistRootPhase2 != 0 ? params.whitelistRootPhase2 : whitelistRootPhase2;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI, LibString.toString(tokenId)));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

}