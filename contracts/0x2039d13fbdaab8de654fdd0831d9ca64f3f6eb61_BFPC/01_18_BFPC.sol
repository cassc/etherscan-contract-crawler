// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract BFContract {
    function walletOfOwner(address _owner) public view virtual returns(uint256[] memory);
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract BFPC is ERC721A, ERC2981, Ownable, ReentrancyGuard {

    // attributes
    string private baseURI;
    address public operator;

    mapping(address => uint256) public mintedPerAddress;

    bool public claimableActive = true; 
    
    address public botsContractAdd; 
    mapping(uint256 => bool) public nftClaimed;
    
    // constants
    uint256 immutable public MAX_NUM;
    uint256 constant public MAX_MINT_PER_BLOCK = 150;

    // modifiers
    modifier whenClaimableActive() {
        require(claimableActive, "Claimable state is not active");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender , "Only operator can call this method");
        _;
    }

    // events
    event ClaimableStateChanged(bool indexed claimableActive);
    event TokenMinted(uint256 supply);

    constructor(string memory name, string memory symbol,
        address addresses,
        uint256 amount,        
        address royalty_,
        uint96 royaltyFee_,
        string memory tokenBaseURI_
    ) ERC721A(name, symbol){
        botsContractAdd = addresses;
        MAX_NUM = amount;
        operator = msg.sender;
        baseURI = tokenBaseURI_;
        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) external onlyOperator {
        baseURI = uri;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Methods
    function flipClaimableState() external onlyOperator {
        claimableActive = !claimableActive;
        emit ClaimableStateChanged(claimableActive);
    }

    function checkNftClaimed(address _owner) public view returns( bool[] memory,uint256[] memory) {
        BFContract botsContract = BFContract(botsContractAdd);
        uint256[] memory tokensId = botsContract.walletOfOwner(_owner);

        bool[] memory list = new bool[](tokensId.length);
        uint256[] memory id = new uint256[](tokensId.length);
        for(uint256 i; i < list.length; ++i){
           list[i] = nftClaimed[tokensId[i]];
           id[i] = tokensId[i];
        }
        return (list,id);
    }


    function nftOwnerClaim(uint256[] calldata tokenIds) external whenClaimableActive {
        require(tokenIds.length > 0, "Should claim at least one land");
        require(tokenIds.length <= MAX_MINT_PER_BLOCK, "Input length should be <= MAX_MINT_PER_BLOCK");
        require(totalSupply() + tokenIds.length <= MAX_NUM, "Exceeds maximum supply" );

        claimNFT(tokenIds);
    }

    function claimNFT(uint256[] calldata tokenIds) private {
        for(uint256 i; i < tokenIds.length; ++i){
            uint256 tokenId = tokenIds[i];
            require(!nftClaimed[tokenId], "NFT already claimed");
            require(ERC721(botsContractAdd).ownerOf(tokenId) == msg.sender, "Must own all of the defined by tokenIds");
            
            claimNFTByTokenId(tokenId);    
        }
        claimNFT(tokenIds.length);
    }

    function claimNFTByTokenId(uint256 tokenId) private {
        nftClaimed[tokenId] = true;
    }

    function claimNFT(uint256 amount) private{
        _safeMint(msg.sender, amount);
        emit TokenMinted(totalSupply());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}