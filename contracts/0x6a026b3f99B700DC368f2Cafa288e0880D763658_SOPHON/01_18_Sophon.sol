// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.7;
import "./openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import  "./openzeppelin/access/Ownable.sol";
import "./ChainlinkIndexStorage.sol";
import {MerkleProof} from "./openzeppelin/cryptography/MerkleProof.sol";

interface IChainlink {
    function returnSpecificIdFromShuffledMapping(uint256, uint256) external returns(uint256);
}


contract SOPHON is ERC721Enumerable, Ownable {

    bytes32 public whitelistRoot;
    uint256 private mappingSpecifier;
    string private baseURI;
    
    uint256 public reincarnationReserve;
    uint256 public maxMintPerWallet;
    uint256 public maxSupply;
    uint256 public mintStart;
    bool public mintIsAcvtive;

    bool honorWhitelist = true;
    

    mapping(address => uint256) private _mintsPerWallet;
    mapping(address => bool) private _blaclistedWallets;

    address public ChainlinkVrfAddress;
    IChainlink ChainlinkVRF;
    

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxMintPerWallet,
        uint256 _maxSupply,
        uint256 _mintStart,
        uint256 _reincarnationReserve,
        bytes32 _whitelistRoot,
        address _VrfAddress
    ) ERC721(name, symbol) {
        ChainlinkVrfAddress = _VrfAddress;
        ChainlinkVRF = IChainlink(ChainlinkVrfAddress);
        maxMintPerWallet = _maxMintPerWallet;
        maxSupply = _maxSupply;
        mintStart = _mintStart;
        reincarnationReserve = _reincarnationReserve;
        whitelistRoot = _whitelistRoot;
        mintIsAcvtive = false;
        }


    function setWhitelistRoot(bytes32 newWhitelistRoot) external onlyOwner {
        whitelistRoot = newWhitelistRoot;
    }

    function mint(bytes32[] calldata whitelistProof) external {
        require(_blaclistedWallets[msg.sender] == false, "You are blacklisted.");
        require(mintIsAcvtive, "Minting isn't active yet.");
        require(mintStart < block.timestamp, "Mint timestamp hasn't been met yet.");
        require(_mintsPerWallet[msg.sender] < maxMintPerWallet, "You've already minted NFTs");

        uint256 amount =  maxMintPerWallet - _mintsPerWallet[msg.sender];
        require(totalSupply() + amount < maxSupply - reincarnationReserve, "Public mint has been over.");
        require(msg.sender == tx.origin, "Minter is not original sender.");


        // If needed, honor the global whitelist
        if (honorWhitelist) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            bool verified = MerkleProof.verify(whitelistProof, whitelistRoot, leaf);
            require(verified, "Your wallet is not whitelisted.");
        }
        
        _mintsPerWallet[msg.sender] = maxMintPerWallet;
        for (uint256 i = 0; i<amount; i++){
            if(totalSupply()%1111 == 0 && totalSupply() != 0){
                mappingSpecifier = mappingSpecifier +1;
            }
            uint256 mintIndex = ChainlinkVRF.returnSpecificIdFromShuffledMapping(mappingSpecifier, totalSupply()%1111);
            _safeMint(msg.sender, mintIndex);
        } 
    }

    function airdropMint(uint256 totalAirdropAmount) external onlyOwner {
            require(totalSupply() + totalAirdropAmount < maxSupply, "MaxSupply is reached.");
            for (uint256 i = 0; i < totalAirdropAmount; ++i){
                if(totalSupply()%1111 == 0 && totalSupply() != 0){
                    mappingSpecifier = mappingSpecifier +1;
                }
                uint256 mintIndex = ChainlinkVRF.returnSpecificIdFromShuffledMapping(mappingSpecifier, totalSupply()%1111);
                _safeMint(owner(), mintIndex);
                
            }
        }


    function addBlacklistedWallets(address[] calldata addresses) public onlyOwner{
        for (uint256 i = 0; i < addresses.length; ++i){
            _blaclistedWallets[addresses[i]] = true;
        }
    }

    function updateChainlinkVrfAddress(address _ChainlinkVrfAddress) public onlyOwner{
        ChainlinkVrfAddress = _ChainlinkVrfAddress;
    }

    function update_maxMintPerWallet(uint256 newLimit) public onlyOwner{
        maxMintPerWallet = newLimit;
    }
    function flipHonorWhitelist() public onlyOwner {
        honorWhitelist = !honorWhitelist;
    }

    function flipMintState() public onlyOwner {
        mintIsAcvtive = !mintIsAcvtive;
    }

    function updateMintStart(uint256 _timeStamp) public onlyOwner{
        mintStart = _timeStamp;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}