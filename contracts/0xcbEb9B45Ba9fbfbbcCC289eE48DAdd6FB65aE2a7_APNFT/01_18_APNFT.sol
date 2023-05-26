// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";
import "./operator-filter-registry/IOperatorFilterRegistry.sol";

///@author Charles
///@dev For our collection "ALPHA PRESTIGE"(https://ap.fusionist.io/)
contract APNFT is ERC721, ERC2981, Ownable, DefaultOperatorFilterer {
    error IncorrectProof();
    error AllNFTsMinted();
    error AlreadyMintedByThisAddress();
    error CannotSetZeroAddress();

    using Address for address;
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 500;
    address public treasuryAddress;
    bytes32 public merkleRoot;

    mapping (address => bool) public minters;

    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    constructor(
        address defaultTreasury,
        string memory defaultBaseURI
    ) ERC721("ALPHA PRESTIGE", "AP")
      {
        setTreasuryAddress(payable(defaultTreasury));
        setBaseURI(defaultBaseURI);
        setRoyaltyInfo(500);
      }

//EXTERNAL ---------

    function mint(bytes32[] calldata proof) external payable {
        address account = msg.sender;
        uint256 totalSupply_ = _tokenIdCounter.current();
        if(totalSupply_  >= MAX_SUPPLY ) revert AllNFTsMinted();        
        if(_verify(_leaf(account), proof) == false) revert IncorrectProof();
        if(minters[account] == true) revert AlreadyMintedByThisAddress();
        minters[account] = true;
        
        _tokenIdCounter.increment();
        uint256 tokenId;
        unchecked {
            tokenId = totalSupply_ + 1;//tokenID starts from 1            
        }
        _safeMint(account, tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }  

    function withdraw() external onlyOwner {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    function setMerkleRoot(bytes32 merkleroot_) external onlyOwner {
        merkleRoot = merkleroot_;
    }    

    function changeOperatorFiltererRegister(IOperatorFilterRegistry newRegistry ) 
    external
    onlyOwner
    {
        operatorFilterRegistry = newRegistry;
    }

    ///@dev Don't panic. It is only used at the end of Claim process if some whitelisted NFTs are not claimed in time, then we can choose to dig them all out to avoid waste.
    ///@dev Worst case, we call it early in the Claim process on purpose. But we have nothing to gain by doing that -- although we have a lot of NFTs, it hurts the reputation of the whole project.
    function claimAllExpiredNFTsToOfficial() external onlyOwner{
        address account = msg.sender;
        uint256 totalSupply_ = _tokenIdCounter.current();
        uint256 leftNFTCount = MAX_SUPPLY- totalSupply_;
        for (uint i = 0; i < leftNFTCount; i++) {
            _tokenIdCounter.increment();//simple, but not gas efficient :(
            uint256 tokenId = _tokenIdCounter.current();  
            _safeMint(account, tokenId);
        }
    }

//PUBLIC ---------    


    function setTreasuryAddress(address payable newAddress) public onlyOwner {
        if (newAddress == address(0)) revert CannotSetZeroAddress();
        treasuryAddress = newAddress;
    }

    function setRoyaltyInfo(uint96 newRoyaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

//INTERNAL --------

    function setBaseURI(string memory newBaseURI) internal onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _verify(bytes32 leaf, bytes32[] calldata  proof) internal view returns (bool)
    {
        return MerkleProof.verifyCalldata(proof, merkleRoot, leaf);
    }

    function _leaf(address account) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }
}