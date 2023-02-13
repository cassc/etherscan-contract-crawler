// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/DefaultOperatorFilterer.sol";

contract DoxxedDegensS2 is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer { 

    using Strings for uint256;

    mapping(address => uint256) public NClaimedPhase1;
    mapping(address => uint256) public NClaimedPhase2;
    mapping(address => uint256) public NClaimedPhase3;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_MINTS_WALLET_PHASE1 = 1;
    uint256 public constant MAX_MINTS_WALLET_PHASE2 = 3;
    uint256 public constant MAX_MINTS_WALLET_PHASE3 = 5;

    uint256 public constant PRICE_PHASE1 = 0 ether; 
    uint256 public constant PRICE_PHASE2 = 0.069 ether; 
    uint256 public constant PRICE_PHASE3 = 0.069 ether; 

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string private baseURI;
    uint256 public _minted = 0;

    bool public MintPhase1Active = false;
    bool public MintPhase2Active = false;
    bool public MintPhase3Active = false;

    address private PAYOUT_ADDRESS = 0x2CB56Fb45Fad6Fd114D59BAFF93CefdAF137816e;

    mapping(uint8 => bytes32) public roots;
    uint8 public constant DD_MINT_PASS_HOLDERS = 1;
    uint8 public constant CHILI_TRAVELS_HOLDERS = 2;

    IERC721 DVDA = IERC721(0xC084a29DD0C9436568435938B1C6c5af4F5C035f); 
    IERC721 GHN = IERC721(0xE6d48bF4ee912235398b96E16Db6F310c21e82CB);  
    IERC721 MGHN = IERC721(0x8BdfD304d22c9F02d542b59aa9b91236C21Dfd82);  
    IERC721 AHC = IERC721(0x9370045CE37F381500ac7D6802513bb89871e076); 


    constructor() ERC721A("Doxxed Degens: S2", "DoxxedDegensS2") {}

    function MintPhase1(uint256 amount, bytes32[] memory proof) public payable nonReentrant {
        require(MintPhase1Active, "MintPhase1 is not enabled");
        require(_minted + amount <= MAX_SUPPLY, "Exceed max supply");
        require(msg.value == amount * PRICE_PHASE1,"Invalid funds provided");
        require(isDDMintPassHolder(msg.sender, proof), "Not Holder of DD Mint Pass.");
        require(amount > 0 && amount <= MAX_MINTS_WALLET_PHASE1,"Must mint between the min and max.");
        require(NClaimedPhase1[msg.sender] + amount <= MAX_MINTS_WALLET_PHASE1,"Already minted Max");
        NClaimedPhase1[msg.sender] += amount;
        _minted +=amount;
        _safeMint(msg.sender, amount);

    }

    function MintPhase2(uint256 amount, bytes32[] memory proof) public payable nonReentrant {
        require(MintPhase2Active, "MintPhase2 is not enabled");
        require(_minted + amount <= MAX_SUPPLY, "Exceed max supply");
        require(isChiliTravelsHolder(msg.sender, proof) || isGHNHolder(msg.sender) || isAHCHolder(msg.sender) || isMGHNHolder(msg.sender) || isDVDAHolder(msg.sender), "Not Holder of Collections.");
        require(msg.value == amount * PRICE_PHASE2,"Invalid funds provided");
        require(amount > 0 && amount <= MAX_MINTS_WALLET_PHASE2,"Must mint between the min and max.");
        require(NClaimedPhase2[msg.sender] + amount <= MAX_MINTS_WALLET_PHASE2,"Already minted Max");
        NClaimedPhase2[msg.sender] += amount;
        _minted += amount;
        _safeMint(msg.sender, amount);
    }

    function MintPhase3(uint256 amount) public payable nonReentrant {
        require(MintPhase3Active, "MintPhase3 is not enabled");
        require(_minted + amount <= MAX_SUPPLY, "Exceed max supply");
        require(msg.value == amount * PRICE_PHASE3,"Invalid funds provided");
        require(amount > 0 && amount <= MAX_MINTS_WALLET_PHASE3,"Must mint between the min and max.");
        require(NClaimedPhase3[msg.sender] + amount <= MAX_MINTS_WALLET_PHASE3,"Already minted Max");
        NClaimedPhase3[msg.sender] += amount;
        _minted += amount;
        _safeMint(msg.sender, amount);
    }

    function TeamMint(uint256 amount) external onlyOwner {
        require(_minted + amount <= MAX_SUPPLY, "Max supply exceeded!");
            _minted += amount;
            _safeMint(msg.sender, amount);
        }

    function setMintPhase1Active(bool _state) public onlyOwner {
        MintPhase1Active = _state;
    }


    function setMintPhase2Active(bool _state) public onlyOwner {
        MintPhase2Active = _state;
    }

        function setMintPhase3Active(bool _state) public onlyOwner {
        MintPhase3Active = _state;
    }


    function isDVDAHolder(address _address) public view returns(bool){
        bool isOwner = false;
        if (DVDA.balanceOf(_address) > 0){
            isOwner = true;
        }
        return isOwner;
    }


    function isGHNHolder(address _address) public view returns(bool){
        bool isOwner = false;
        if (GHN.balanceOf(_address) > 0){
            isOwner = true;
        }
        return isOwner;
    }


    function isMGHNHolder(address _address) public view returns(bool){
        bool isOwner = false;
        if (MGHN.balanceOf(_address) > 0){
            isOwner = true;
        }
        return isOwner;
    }

    function isAHCHolder(address _address) public view returns(bool){
        bool isOwner = false;
        if (AHC.balanceOf(_address) > 0){
            isOwner = true;
        }
        return isOwner;
    }


    function isDDMintPassHolder(address _address, bytes32[] memory proof) public view returns(bool){
        bool isOwner = false;
        uint8 Type = DD_MINT_PASS_HOLDERS;
        bytes32 root = roots[Type];
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        isOwner = MerkleProof.verify(proof, root, leaf);
        return isOwner;
    }


    function isChiliTravelsHolder(address _address, bytes32[] memory proof) public view returns(bool){
        bool isOwner = false;
        uint8 Type = CHILI_TRAVELS_HOLDERS;
        bytes32 root = roots[Type];
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        isOwner = MerkleProof.verify(proof, root, leaf);
        return isOwner;
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }

    function setMerkleRoot(uint8 Type, bytes32 _root) external onlyOwner {
        require(
            Type == DD_MINT_PASS_HOLDERS || Type == CHILI_TRAVELS_HOLDERS, "Not a valid Type.");
            roots[Type] = _root;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = PAYOUT_ADDRESS.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }

   function withdrawMoneyToDeployer() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "WITHDRAW FAILED!");
    }

}