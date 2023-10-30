//
//
//
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  ██████  ███████ ████████ ██████  ███████ ███████ ██      ██████  ██████   //
// ██       ██         ██    ██   ██ ██      ██      ██           ██      ██  //
// ██   ███ █████      ██    ██████  █████   █████   ██       █████   █████   //
// ██    ██ ██         ██    ██   ██ ██      ██      ██           ██      ██  //
//  ██████  ███████    ██    ██   ██ ███████ ███████ ███████ ██████  ██████   //
//                                                                            //                                                                      
////////////////////////////////////////////////////////////////////////////////
//
//
//

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract JIGGIESbyGETREEL33Minter is Ownable {

    address public jIGGIESbyGETREEL33Address = 0x476Ae7237d50E01C84d8f04E7C8021909600A898;

    bytes32 public genesisClaimRoot = 0x232450d8a4fb5d9e42138c429c6be5b0a6154662cb284556acb6c8b6f26c9545;
    bytes32 public genesisMintRoot = 0x232450d8a4fb5d9e42138c429c6be5b0a6154662cb284556acb6c8b6f26c9545;

    uint256 public genesisHolderPrice = 0.45 ether;
    uint256 public publicPrice = 0.57 ether;

    bool public isGenesisMintClaimEnabled = true;
    bool public isPublicMintEnabled = false;

    mapping(address => uint256) public claimedNFTs;
    mapping(address => uint256) public mintedNFTs;

    uint256 public maxSupply = 2000;

    using Counters for Counters.Counter;
    Counters.Counter private _idTracker;

    function setclaimRoot(bytes32 newroot) public onlyOwner {genesisClaimRoot = newroot;}
    function setMintRoot(bytes32 newroot) public onlyOwner {genesisMintRoot = newroot;}

    function setConfig(uint256 _genesisHolderPrice, 
    uint256 _publicPrice, 
    bool _isGenesisMintClaimEnabled, 
    bool _isPublicMintEnabled, 
    bytes32 _claimRoot, 
    bytes32 _mintRoot, 
    uint256 _maxSupply)
        public
        onlyOwner
    {
        genesisHolderPrice = _genesisHolderPrice;
        publicPrice = _publicPrice;
        
        isGenesisMintClaimEnabled = _isGenesisMintClaimEnabled;
        isPublicMintEnabled = _isPublicMintEnabled;

        genesisClaimRoot = _claimRoot;
        genesisMintRoot = _mintRoot;

        maxSupply = _maxSupply;
    }

    function getAvailableSupply() public view returns (uint256) {
        return 1 + maxSupply - _idTracker.current();
    }

    function setSupply(uint256 _maxSupply)
        public
        onlyOwner
    {
        maxSupply = _maxSupply;
    }

    function setIsGenesisMintClaimEnabled(bool isEnabled) public onlyOwner {
        isGenesisMintClaimEnabled = isEnabled;
    }

    function setIsPublicMintEnabled(bool isEnabled) public onlyOwner {
        isPublicMintEnabled = isEnabled;
    }

    function getPublicPrice() public view returns (uint256) {
        return publicPrice;
    }

    function setPublicPrice(uint256 _price)
        public
        onlyOwner
    {
        publicPrice = _price;
    }

    function getGenesisHolderPrice() public view returns (uint256) {
        return genesisHolderPrice;
    }

    function setGenesisHolderPrice(uint256 _price)
        public
        onlyOwner
    {
        genesisHolderPrice = _price;
    }

    function setJIGGIESbyGETREEL33Address(address _address)  public onlyOwner {
        jIGGIESbyGETREEL33Address = _address;
    }

    function airdrop(
        address[] memory to,
        uint256[] memory id,        
        uint256[] memory amount
    ) onlyOwner public {
        require(to.length == id.length && to.length == amount.length, "Length mismatch");
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(jIGGIESbyGETREEL33Address);
        for (uint256 i = 0; i < to.length; i++)
            token.mint(to[i], id[i], amount[i], "");
    }


    function claimGenesisHolder(uint256 amount, uint256 balance, bytes32[] calldata proof) public {
        require(isGenesisMintClaimEnabled, "Mint not enabled");
        require(_idTracker.current() <= maxSupply, "Not enough supply");
        require(MerkleProof.verify(proof, genesisClaimRoot, keccak256(abi.encodePacked(msg.sender, balance))), "Invalid merkle proof");
        require(amount > 0, "Amount must be greater than 0");
        require(claimedNFTs[msg.sender] + amount <= balance * 3, "Wallet already claimed");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(jIGGIESbyGETREEL33Address);
        
        for(uint256 i = 0; i < amount; i++){
            token.mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }
        
        claimedNFTs[msg.sender] += amount; 
    }

    function mintGenesisHolder(uint256 amount, uint256 balance, bytes32[] calldata proof) public payable {
        require(isGenesisMintClaimEnabled, "Mint not enabled");
        require(_idTracker.current() <= maxSupply, "Not enough supply");
        require(MerkleProof.verify(proof, genesisMintRoot, keccak256(abi.encodePacked(msg.sender, balance))), "Invalid merkle proof");
        require(msg.value >= genesisHolderPrice * amount, "Not enough eth");
        require(amount > 0, "Amount must be greater than 0");
        require(mintedNFTs[msg.sender] + amount <= balance * 7, "Wallet already minted");
        
        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(jIGGIESbyGETREEL33Address);
        
        for(uint256 i = 0; i < amount; i++){
            token.mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }
        mintedNFTs[msg.sender] += amount;
    }

    function mintPublic(uint256 amount) public payable {
        require(isPublicMintEnabled, "Mint not enabled");
        require(_idTracker.current() <= maxSupply, "Not enough supply");
        require(msg.value >= publicPrice * amount, "Not enough eth");
        require(amount > 0, "Amount must be greater than 0");

        ERC1155PresetMinterPauser token = ERC1155PresetMinterPauser(jIGGIESbyGETREEL33Address);

        for(uint256 i = 0; i < amount; i++){
            token.mint(msg.sender, _idTracker.current(), 1, "");
            _idTracker.increment();
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}