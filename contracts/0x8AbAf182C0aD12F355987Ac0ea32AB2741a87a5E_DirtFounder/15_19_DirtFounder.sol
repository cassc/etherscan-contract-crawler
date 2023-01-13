pragma solidity ^0.8.4;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DirtFounder is 
    ERC721ABurnable, 
    OperatorFilterer,
    AccessControlEnumerable,
    ERC2981
{
    bool public operatorFilteringEnabled;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_PER_MINT = 2;
    uint256 public constant MAX_PER_ALLOWLIST = 2;
    uint256 public constant PRICE_PER_MINT = 0.503 ether;
    bytes32 public allowListMerkleRoot;

    bool public isAllowListActive = false;
    bool public isPublicActive = false;
    bool public isAirdropFinished = false;
    bool public reserved = false;

    string private _baseTokenURI;
    //allow list mapping: address -> amount eligible to int
    mapping(address => uint256) public allowList;
    
    bytes32 public constant FINANCIER_ROLE = keccak256("FINANCIER_ROLE");
   
    constructor() ERC721A("DirtFounder", "DF") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(FINANCIER_ROLE, msg.sender);

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721A, AccessControlEnumerable, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function mintFounder(uint256 quantity) external payable {
        require(isPublicActive, "Public not open");
        require(msg.value >= quantity * PRICE_PER_MINT, "Not enough ETH");
        require(quantity <= MAX_PER_MINT, "Exceed limit per mint");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough founders remaining"
        );
        _mint(msg.sender, quantity);
    }

    function mintFounderAllowList(uint256 quantity, bytes32[] calldata allowListProof_) external payable {
        require(isAllowListActive, "Allowlist not open");
        require(msg.value >= quantity * PRICE_PER_MINT, "Not enough ETH");
        require(quantity <= MAX_PER_MINT, "Exceed limit per mint");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough founders remaining"
        );
        require(verifyAddress(allowListProof_), "Invalid merkle proof");
        require(allowList[msg.sender] + quantity <= MAX_PER_ALLOWLIST, "Exceed allowlist mint");
        allowList[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

     function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "NFT does not exist"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /// @dev See {ERC721A-_startTokenId}.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Needed for opensea royalty control 
    function owner() public view virtual returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    function verifyAddress(bytes32[] calldata allowListProof_) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(allowListProof_, allowListMerkleRoot, leaf);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function airdropFounders(address[] calldata addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isAirdropFinished == false, "Airdrop closed");
        require(
            totalSupply() + addresses.length <= MAX_SUPPLY,
            "Not enough Founders remaining"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], 1);
        }
    }

    function setAirdropFinished() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isAirdropFinished = true;
    }

    function setPublicSaleActive(bool _isPublicSaleActive) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPublicActive = _isPublicSaleActive;
    }
    
    function setAllowListActive(bool _isAllowListActive) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isAllowListActive = _isAllowListActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseURI;
    }

    function withdrawEther() external onlyRole(FINANCIER_ROLE) {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMerkleRoot(bytes32 allowListMerkleRootHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowListMerkleRoot = allowListMerkleRootHash;
    }

    function reserveMint(uint256 quantity, address reserve_address) external onlyRole(DEFAULT_ADMIN_ROLE) {
      require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough Founders remaining"
      );
      require(
            quantity % 10 == 0,
            "can only mint a multiple of 10"
      );
      require(reserved == false, "Already reserved");
      uint256 numChunks = quantity / 10;
      // needed to mint in batches to keep gas low
      for (uint256 i = 0; i < numChunks; i++) {
          _mint(reserve_address, 10);
      }
      reserved = true;
    }

    /*//////////////////////////////////////////////////////////////
                        Opensea royalty enforcer FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function setApprovalForAll(address operator, bool approved)
        public
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}