//    
//     _____            _                _       
//    |  ___|          | |              (_)      
//    | |__ _   _ _ __ | |__   ___  _ __ _  __ _ 
//    |  __| | | | '_ \| '_ \ / _ \| '__| |/ _` |
//    | |__| |_| | |_) | | | | (_) | |  | | (_| |
//    \____/\__,_| .__/|_| |_|\___/|_|  |_|\__,_|
//               | |                             
//               |_|                             
//    


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


error MintError(string message);
error SupplyError(string message);

contract Euphoria is ERC721A, Ownable, DefaultOperatorFilterer {

    address public constant EUPHORIA_VAULT = 0xcbaD40F263651bE54205CfAA461A32Bf64355711;

    enum MINT_TYPE{ PUBLIC, WL, OG }

    // ## variables
    
    // supply config
    uint256 public maxSupply = 4444;
    uint256 public teamSupply = 150;
    uint256 public usedTeamSupply = 0;
    
    // max mint per wallet config
    uint256 public maxMintForWhitelist = 2;
    uint256 public maxMintForOg = 2;
    uint256 public maxMintForPublic = 3; 
    
    // price config
    uint256 public publicSalePrice = 0.018 ether;
    uint256 public whitelistSalePrice = 0.015 ether;
    uint256 public ogSalePrice = 0.013 ether;

    // internal config
    uint256 public mintStage = 0; // 0 - closed || 1 - og + wl || 2 - public || 3 - paused
    bytes32 private $ogMerkleRoot;
    bytes32 private $wlMerkleRoot;


    // ## mappings for internal and external mint logic
    mapping(address => uint256) public ogMintCounts;
    mapping(address => uint256) public wlMintCounts;
    mapping(address => uint256) public publicMintCounts;


    // # metadata variables
    string public tokenBaseUrl = "ipfs://NOT-REVEALED";
    string public tokenUrlSuffix = ".json";


    constructor(bytes32 _ogMerkle, bytes32 _wlMerkle) ERC721A("Euphoria", "EHR") {
        $ogMerkleRoot = _ogMerkle;
        $wlMerkleRoot = _wlMerkle;
    }

    modifier priceCompliance(MINT_TYPE mintType, uint256 _quantity) {
        uint256 salePrice = publicSalePrice;
        if (mintType == MINT_TYPE.WL) {
            salePrice = whitelistSalePrice;
        } else if (mintType == MINT_TYPE.OG) {
            salePrice = ogSalePrice;
        }
        if (msg.value !=  _quantity * salePrice) {
            revert MintError("price_error");
        }
        _;
    }

    modifier supplyCompliance(uint256 _quantity) {
        if (totalSupply() + _quantity + (teamSupply - usedTeamSupply) > maxSupply) {
            revert MintError("not_enough_supply");
        }
        _;
    }

    // # mint functions

    // public mint
    function publicMint(uint256 _quantity)
    priceCompliance(MINT_TYPE.PUBLIC, _quantity) supplyCompliance(_quantity)
    public payable {
        if (tx.origin != msg.sender) {
            revert("MintError: Contract mints not allowed");
        }
        if (mintStage != 2) {
            revert("MintError: Mint not started");
        }
        if (publicMintCounts[msg.sender] + _quantity > maxMintForPublic) {
            revert("MintError: Exceed max mint");
        }
        publicMintCounts[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    // whitelist mint
    function whitelistMint(uint256 _quantity, bytes32[] memory _proof)
    priceCompliance(MINT_TYPE.WL, _quantity) supplyCompliance(_quantity)    
    public payable {
        if (mintStage != 1) {
            revert("MintError: Mint not started");
        }
        if (!_verifyWL(_proof, msg.sender)) {
            revert("MintError: Address not whitelisted");
        }
        if (wlMintCounts[msg.sender] + _quantity > maxMintForWhitelist) {
            revert("MintError: Exceed max mint");
        }
        wlMintCounts[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    // og mint
    function ogMint(uint256 _quantity, bytes32[] memory _proof)
    priceCompliance(MINT_TYPE.OG, _quantity) supplyCompliance(_quantity)   
    public payable {
        if (mintStage != 1) {
            revert("MintError: Mint not started");
        }
        if (!_verifyOG(_proof, msg.sender)) {
            revert("MintError: Address not whitelisted");
        }
        // check if address has not minted too much
        if (ogMintCounts[msg.sender] + _quantity > maxMintForOg) {
            revert("MintError: Exceed max mint");
        }
        ogMintCounts[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }


    // # management functions

    function teamMint(uint256 _quantity) public onlyOwner {
        // check if mint is possible
        if (usedTeamSupply + _quantity > teamSupply) {
            revert SupplyError("Not enough team supply left");
        }
        if (totalSupply() + _quantity > maxSupply) {
            revert SupplyError("Not enough supply left");
        }
        usedTeamSupply += _quantity;
        _mint(EUPHORIA_VAULT, _quantity);
    }

    function setOgMerkleRoot(bytes32 _root) public onlyOwner {
        $ogMerkleRoot = _root;
    }

    function setWlMerkleRoot(bytes32 _root) public onlyOwner {
        $wlMerkleRoot = _root;
    }

    function setMintStage(uint256 _stage) public onlyOwner {
        mintStage = _stage;
    }

    function setTokenBaseUrl(string memory _url) public onlyOwner {
        tokenBaseUrl = _url;
    }

    function setTokenUrlSuffix(string memory _suffix) public onlyOwner {
        tokenUrlSuffix = _suffix;
    }

    function setPublicSalePrice(uint256 _price) public onlyOwner {
        publicSalePrice = _price;
    }

    function setWhitelistSalePrice(uint256 _price) public onlyOwner {
        whitelistSalePrice = _price;
    }

    function setOgSalePrice(uint256 _price) public onlyOwner {
        ogSalePrice = _price;
    }

    function reduceSupply(uint256 _supply) public onlyOwner {
        // check given supply is possible
        if (_supply < totalSupply() + (teamSupply - usedTeamSupply)) {
            revert SupplyError("Too low");
        }
        if (_supply > maxSupply) {
            revert SupplyError("Cannot increase supply");
        }
        maxSupply = _supply;
    }

    function setTeamSupply(uint256 _supply) public onlyOwner {
        if (_supply < usedTeamSupply) {
            revert SupplyError("Team supply cannot be reduced below used team supply");
        }
        // check if given supply is possible
        if (maxSupply < totalSupply() + (_supply - usedTeamSupply)) {
            revert SupplyError("Too low");
        }
        teamSupply = _supply;
    }


    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(EUPHORIA_VAULT, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }


    // # internal functions

    function _verifyOG(
        bytes32[] memory proof,
        address addr
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));
        return MerkleProof.verify(proof, $ogMerkleRoot, leaf);
    }

    function _verifyWL(
        bytes32[] memory proof,
        address addr
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr))));
        return MerkleProof.verify(proof, $wlMerkleRoot, leaf);
    }


    // # Overrides

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory) {
        if (keccak256(bytes(tokenBaseUrl)) == keccak256(bytes("ipfs://NOT-REVEALED"))) {
            return "ipfs://QmcpoaifTkpHcqKNGjfjxuXRQrP9fa4466eVXN3MUfbQa3";
        }
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        return
        bytes(tokenBaseUrl).length != 0
            ? string(abi.encodePacked(tokenBaseUrl, Strings.toString(tokenId), tokenUrlSuffix))
            : "";
    }


    // operator overrides

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override payable onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        payable
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}