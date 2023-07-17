// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";

error CallerIsAContract();

interface IRhStaking {
  function isHardStaked(address from, uint256 tokenId) external view returns(bool);
  function isUserHardStakedAny(address from) external view returns(bool);
}

contract RetroHunters is ERC721A, Pausable, Ownable, DefaultOperatorFilterer, ERC2981, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxSupply = 7777;
    uint256 public constant TIER_ONE_MAX = 1000;
    uint256 public constant TIER_TWO_MAX = 6377;
    uint256 public constant RESERVE_MAX = 400;
    uint256 public constant MINT_PER_ADDR = 2;

    string public defaultURI = "ipfs://xxx";
    string private baseURI = "https://rh-metadata.s3.us-west-1.amazonaws.com/json/";

    uint256 public tierOneSaleMinted;
    uint256 public tierTwoSaleMinted;
    uint256 public reserveTokenMinted;
    uint256 public publicSaleMinted;
    uint256 public totalMinted;

    bool public tierOneSaleLive = false;
    bool public tierTwoSaleLive = false;
    bool public publicSaleLive = false;

    uint256 public tierOneSalePrice = 0.03 ether;
    uint256 public tierTwoSalePrice = 0.033 ether;
    uint256 public publicSalePrice = 0.033 ether;
    address manager;

    bytes32 private tierOneSaleMerkleRoot;
    bytes32 private tierTwoSaleMerkleRoot;

    mapping(address => uint256) public whitelistPurchases;
    mapping(address => uint256) public publicPurchases;
 
    address stakingContract;
    address multisigWallet;

    mapping(address => address[]) public approvedOperatorList;

    event TierOneSaleMinted(address indexed to, uint256 tokenQuantity, uint256 amount);
    event TierTwoSaleMinted(address indexed to, uint256 tokenQuantity, uint256 amount);
    event PublicSaleMinted(address indexed to, uint256 tokenQuantity, uint256 amount);
    event ReserveTokenMinted(address indexed to, uint256 tokenQuantity);

    constructor(string memory _name, string memory _symbol, bytes32 _tierOneSaleMerkleRoot, bytes32 _tierTwoSaleMerkleRoot) ERC721A(_name, _symbol) {
        manager = msg.sender;
        tierOneSaleMerkleRoot = _tierOneSaleMerkleRoot;
        tierTwoSaleMerkleRoot = _tierTwoSaleMerkleRoot;
        _setDefaultRoyalty(owner(), 500);
    }

    function setupStakingContract(address _stakingContract) public onlyOwner {
        stakingContract = _stakingContract;
    }

    function setMerkleRoot(bytes32 _tierOneSaleMerkleRoot, bytes32 _tierTwoSaleMerkleRoot) public onlyOwner {
        tierOneSaleMerkleRoot = _tierOneSaleMerkleRoot;
        tierTwoSaleMerkleRoot = _tierTwoSaleMerkleRoot;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _baseuri) public onlyOwner {
		baseURI = _baseuri;
	}

    function setDefaultRI(string calldata _defaultURI) public onlyOwner {
		defaultURI = _defaultURI;
	}

    function toggleTierOneSaleLive() public onlyOwner {
        tierOneSaleLive = !tierOneSaleLive;
    }

    function toggleTierTwoSaleLive() public onlyOwner {
        tierTwoSaleLive = !tierTwoSaleLive;
    }

    function togglePublicSaleLive() public onlyOwner {
        publicSaleLive = !publicSaleLive;
    }

    function setTierOneSalePrice(uint256 newPrice) public onlyOwner {
        require(newPrice > 0, "Price can not be zero");
        tierOneSalePrice = newPrice;
    }
    function setTierTwoSalePrice(uint256 newPrice) public onlyOwner {
        require(newPrice > 0, "Price can not be zero");
        tierTwoSalePrice = newPrice;
    }
    function setPublicSalePrice(uint256 newPrice) public onlyOwner {
        require(newPrice > 0, "Price can not be zero");
        publicSalePrice = newPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    function setMultisigWallet(address _multisigWallet) public onlyOwner {
        multisigWallet = _multisigWallet;
    }

    function getStakingContract() public view onlyOwner returns(address) {
        return stakingContract;
    }

    function getMultisigWallet() public view onlyOwner returns(address) {
        return multisigWallet;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    modifier whitelistMintLimitNotExceed(uint256 tokenQuantity) {
		require(whitelistPurchases[msg.sender] + tokenQuantity <= MINT_PER_ADDR, 'Exceed Per Address limit for Whitelist');
		_;
	}

    modifier publicMintLimitNotExceed(uint256 tokenQuantity) {
		require(publicPurchases[msg.sender] + tokenQuantity <= MINT_PER_ADDR, 'Exceed Per Address limit for Public');
		_;
	}

    modifier callerIsUser() {
        require(tx.origin == msg.sender || msg.sender == multisigWallet,"Caller must be User or Multisig Wallet");
        _;
    }

    modifier stakingContractExists() {
        require(stakingContract != address(0), "Staking Contract Missing");
        _;
    }

    modifier notHardStaked(address _from, uint256 _tokenId) {
        require(stakingContract != address(0), "Staking Contract Missing");
        require(!IRhStaking(stakingContract).isHardStaked(_from, _tokenId), "NFT is Hard Staked");
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NFT does not exists");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : defaultURI;
    }

    function tierOneSaleMint(uint256 tokenQuantity, bytes32[] calldata merkleProof) public payable whitelistMintLimitNotExceed(tokenQuantity) callerIsUser nonReentrant{
        require(tierOneSaleLive, "Tier One Sale Is Not Live");
        require((tierOneSaleMinted + tokenQuantity) <= TIER_ONE_MAX, "Tier One is Sold Out");
        require(totalSupply() + tokenQuantity <= maxSupply, "Minting would exceed max supply");
        require((tierOneSalePrice * tokenQuantity) == msg.value, "Incorrect Funds Sent" );

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, tierOneSaleMerkleRoot, node), 'Invalid Proof');

        _safeMint(msg.sender, tokenQuantity);
        whitelistPurchases[msg.sender]+= tokenQuantity;
        tierOneSaleMinted+=tokenQuantity;
        totalMinted+=tokenQuantity;

        emit TierOneSaleMinted(msg.sender, tokenQuantity, msg.value);
    }

    function tierTwoSaleMint(uint256 tokenQuantity, bytes32[] calldata merkleProof) public payable whitelistMintLimitNotExceed(tokenQuantity) callerIsUser nonReentrant{
        require(tierTwoSaleLive, "Tier Two Sale Is Not Live");
        require((tierTwoSaleMinted + tokenQuantity) <= TIER_TWO_MAX, "Tier Two is Sold Out");
        require(totalSupply() + tokenQuantity <= maxSupply, "Minting would exceed max supply");
        require((tierTwoSalePrice * tokenQuantity) == msg.value, "Incorrect Funds Sent" );
        
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, tierTwoSaleMerkleRoot, node), 'Invalid Proof');

        _safeMint(msg.sender, tokenQuantity);
        whitelistPurchases[msg.sender]+= tokenQuantity;
        tierTwoSaleMinted+=tokenQuantity;
        totalMinted+=tokenQuantity;

        emit TierTwoSaleMinted(msg.sender, tokenQuantity, msg.value);
    }

    function reserveMint(address _to) public onlyOwner callerIsUser nonReentrant{
        require(reserveTokenMinted < RESERVE_MAX, "Reserve tokens already minted");
        require(totalSupply() + RESERVE_MAX <= maxSupply, "Minting would exceed max supply");

        _safeMint(_to, RESERVE_MAX);
        totalMinted+=RESERVE_MAX;
        reserveTokenMinted = RESERVE_MAX;

        emit ReserveTokenMinted(_to, RESERVE_MAX);
    }

    function publicSaleMint(uint256 tokenQuantity) public payable publicMintLimitNotExceed(tokenQuantity) callerIsUser nonReentrant{
        require(publicSaleLive, "Public Sale Is Not Live");
        require((tierOneSaleMinted + tierTwoSaleMinted + publicSaleMinted + tokenQuantity) <= (maxSupply - RESERVE_MAX), "Public Sale Is Sold Out");
        require(totalSupply() + tokenQuantity <= maxSupply, "Public Sale Is Sold Out");
        require((publicSalePrice * tokenQuantity) == msg.value, "Incorrect Funds Sent");
        
        _safeMint(msg.sender, tokenQuantity);
        publicPurchases[msg.sender]+= tokenQuantity;
        publicSaleMinted+=tokenQuantity;
        totalMinted+=tokenQuantity;

        emit PublicSaleMinted(msg.sender, tokenQuantity, msg.value);
    }

    function withdraw() public onlyOwner nonReentrant{
        require(owner() != address(0),"Fund Owner is NULL");
        (bool sent1, ) = owner().call{value: address(this).balance}("");
        require(sent1, "Failed to withdraw");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner nonReentrant{
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 _totalSupply = _nextTokenId();
        uint256 arrayIndex = 0;
        for (uint256 i=1; i < _totalSupply; i++) {
            if(_owner == ownerOf(i)) {
                tokenIds[arrayIndex++] = i;
                if(arrayIndex >= ownerTokenCount) {
                    break;
                }
            }   
        }
        return tokenIds;
    }

    // Operator Filtering
    function setApprovalForAll(address operator, bool approved) 
        public override onlyAllowedOperatorApproval(operator) stakingContractExists {
        if(operator != address(0) && approved) {
            require(!IRhStaking(stakingContract).isUserHardStakedAny(msg.sender), "Some or All NFTS are Hard Staked");
        }
        manageOperator(operator, approved);
        super.setApprovalForAll(operator, approved);
    }

    function manageOperator(address operator, bool approved) internal {
        if(operator != address(0) && approved) {
            require(!isApprovedForAll(msg.sender, operator), "Operator is already approved");
            approvedOperatorList[msg.sender].push(operator);
        }
        else if(operator != address(0) && !approved){
            uint256 _operatorListLength = approvedOperatorList[msg.sender].length;
            for (uint256 j = 0; j < _operatorListLength; j++) {
                if(approvedOperatorList[msg.sender][j] == operator) {
                    approvedOperatorList[msg.sender][j] = approvedOperatorList[msg.sender][_operatorListLength - 1];
                    approvedOperatorList[msg.sender].pop();
                    break;
                }
            }
        }
    }

    function isApprovedForAllAnyMarket(address owner) public view returns (uint256){
        return approvedOperatorList[owner].length;
    }

    function approve(address operator, uint256 tokenId) 
        public payable override onlyAllowedOperatorApproval(operator) stakingContractExists {
        if(operator != address(0)) {
            require(!IRhStaking(stakingContract).isHardStaked(msg.sender, tokenId), "NFT is Hard Staked");
        }
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to,uint256 tokenId) 
        public payable override onlyAllowedOperator(from) notHardStaked(from, tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public payable override onlyAllowedOperator(from) notHardStaked(from, tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) 
        public payable override onlyAllowedOperator(from) notHardStaked(from, tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}