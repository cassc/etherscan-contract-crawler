// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "hardhat/console.sol";

contract NUSICAliveCollectivePass is ERC721A, Pausable, Ownable, DefaultOperatorFilterer, ERC2981, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant RESERVE_MAX = 50;
    uint256 public constant PUBLIC_MAX = 950;
    uint256 public constant MINT_PER_ADDR = 99; // Mint per Address

    string public defaultURI = "https://bafkreidtb4eljut3mnuje67gdl65ml2qyp26hut6y4skuwccqhd4qhugku.ipfs.nftstorage.link/";
    string private baseURI;
    string private baseContractURI = "https://bafkreidikrxvxlwhk7mmvzhxgwi77xjjulgwocagdq6dat776afnwcljnu.ipfs.nftstorage.link/";

    bool public saleLive = true;

    uint256 public price = 0.25 ether;
    address public manager = 0x05C6b4369C5c1E25c2bc8C54b669c0b0C02D8b9a;
    address public treasuryAddress = 0x644a57c612Bf365cFF591Ba0535c7B5c0F6E175c;

    address public crossmintAddress;
    uint256 public publicTokenMinted;
    uint256 public reserveTokenMinted;

    mapping(uint256 => string) private _tokenURIs;

    event Minted(address indexed to, uint256 tokenQuantity, uint256 amount, string _type);
    
    modifier onlyOwnerOrManager() {
        require((owner() == msg.sender) || (manager == msg.sender), "Caller needs to be Owner or Manager");
        _;
    }

    modifier mintPerAddressNotExceed(uint256 tokenQuantity) {
		require(balanceOf(msg.sender) + tokenQuantity <= MINT_PER_ADDR, 'Exceed Per Address limit');
		_;
	}

    constructor(string memory _name, string memory _symbol) ERC721A(_name, _symbol) {
        //manager = msg.sender;
        //treasuryAddress = msg.sender;
        crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233; // ETH Mainnet
        //crossmintAddress = 0xDa30ee0788276c093e686780C25f6C9431027234; // Mumbai
        _setDefaultRoyalty(owner(), 500);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _baseuri) public onlyOwnerOrManager {
		baseURI = _baseuri;
	}

    function setDefaultRI(string calldata _defaultURI) public onlyOwnerOrManager {
		defaultURI = _defaultURI;
	}

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) public {
		require(ownerOf(_tokenId) == msg.sender,"Caller is not owner of token");
        _tokenURIs[_tokenId] = _tokenURI;
	}

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    function setContractURI(string memory _contractURI) public onlyOwnerOrManager {
        baseContractURI = _contractURI;
    }

    function toggleSaleLive() public onlyOwnerOrManager {
        saleLive = !saleLive;
    }

    function setPrice(uint256 newPrice) public onlyOwnerOrManager {
        require(newPrice > 0, "Price can not be zero");
        price = newPrice;
    }

    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }

    function setTreasuryAddress(address _treasuryAddress) public onlyOwnerOrManager {
        treasuryAddress = _treasuryAddress;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exists");
        string memory _tokenURI = _tokenURIs[tokenId];
        return bytes(_tokenURI).length > 0 ? _tokenURI : defaultURI;
    }

    function mint(uint256 tokenQuantity) public payable mintPerAddressNotExceed(tokenQuantity) whenNotPaused nonReentrant{
        require(saleLive, "Sale Not Active"); // Sale should be active
        require(publicTokenMinted + tokenQuantity <= PUBLIC_MAX, "Minting would exceed max public supply"); // Total Minted should not exceed Max public Supply
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "Minting would exceed max supply"); // Total Minted should not exceed Max Supply
        require((price * tokenQuantity) == msg.value, "Incorrect Funds Sent" ); // Amount sent should be equal to price to quantity being minted
        
        _safeMint(msg.sender, tokenQuantity);
        publicTokenMinted+=tokenQuantity;
        emit Minted(msg.sender, tokenQuantity, msg.value, "CryptoNative");
    }

    function crossMint(address _to, uint256 tokenQuantity) public payable mintPerAddressNotExceed(tokenQuantity) whenNotPaused nonReentrant {
        require(msg.sender == crossmintAddress,"This function is for Crossmint only.");
        // polygon mainnet = 0x12A80DAEaf8E7D646c4adfc4B107A2f1414E2002
        // polygon mumbai  = 0xDa30ee0788276c093e686780C25f6C9431027234  

        require(saleLive, "Sale Not Active"); // Sale should be active
        require(publicTokenMinted + tokenQuantity <= PUBLIC_MAX, "Minting would exceed max public supply"); // Total Minted should not exceed Max public Supply
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "Minting would exceed max supply"); // Total Minted should not exceed Max Supply
        require((price * tokenQuantity) == msg.value, "Incorrect Funds Sent" ); // Amount sent should be equal to price to quantity being minted

        _safeMint(_to, tokenQuantity);
        publicTokenMinted+=tokenQuantity;
        emit Minted(_to, tokenQuantity, msg.value, "CrossMint");
    }

    function withdraw() public onlyOwner nonReentrant{
        require(treasuryAddress != address(0),"Fund Owner is NULL");
        (bool sent1, ) = treasuryAddress.call{value: address(this).balance}("");
        require(sent1, "Failed to withdraw");
    }

    function airdrop(address[] memory _userList, uint256[] memory _tokenQuantity) public onlyOwnerOrManager nonReentrant {
        require(_userList.length == _tokenQuantity.length, "List mismatch");
        for (uint256 index = 0; index < _userList.length; index++) {
            require(_userList[index] != address(0), "Null Address Provided");
            require(reserveTokenMinted + _tokenQuantity[index] <= RESERVE_MAX, "Minting would exceed AirDrop Quota");
            _safeMint(_userList[index], _tokenQuantity[index]);
            reserveTokenMinted+= _tokenQuantity[index];
            emit Minted(_userList[index], _tokenQuantity[index], 0, "AirDrop");
        }
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

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwnerOrManager nonReentrant{
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function pause() public onlyOwnerOrManager nonReentrant {
        _pause();
    }

    function unpause() public onlyOwnerOrManager nonReentrant {
        _unpause();
    }

    // Operator Filtering
    function setApprovalForAll(address operator, bool approved) 
        public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to,uint256 tokenId) 
        public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) 
        public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}