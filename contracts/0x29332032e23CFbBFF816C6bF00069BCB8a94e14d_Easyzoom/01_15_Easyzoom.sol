// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {IERC721A, ERC721A} from "erc721a/contracts/ERC721A.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC2981, ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/OperatorFilterer.sol"; 


// Supply Error
error ExceedsMaxSupply();
// Sale Errors
error SaleNotActive();
error Unauthorized();
// Limit Errors
error TxnLimitReached();
error MintLimitReached();
// Utility Errors
error TimeCannotBeZero();
// Withdrawl Errors
error ETHTransferFailDev();
error ETHTransferFailOwner();
// General Errors
error AddressCannotBeZero();
error CallerIsAContract();
error IncorrectETHSent();

contract Easyzoom is
    ERC721AQueryable,
    Ownable,
    OperatorFilterer,
    ERC2981,
    ReentrancyGuard
{
    bytes32 private _MerkleRoot;
    
    uint256 public constant MINT_LIMIT_PER_ADDRESS = 1;
    uint256 public MAX_SUPPLY = 888;

    bool public operatorFilteringEnabled;
    bool public whitelistMintState = false;
    string private _baseTokenURI;
    mapping(address => uint256) public userMinted;

    event UpdateBaseURI(string baseURI);
    event UpdateWhitelistMintStatus(bool _whitelistMintState);
    event UpdateMerkleRoot(bytes32 merkleRoot);

    constructor(    
    string memory _tokenName,
    string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Set default royalty to 10% (denominator out of  10000).
        _setDefaultRoyalty(msg.sender, 1000);
    }

    //===============================================================
    //                        Modifiers
    //===============================================================

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsAContract();
        _;
    }


    //===============================================================
    //                    Supply control
    //===============================================================

    function burnSupply(uint256 maxSupplyNew) external onlyOwner {
        require(maxSupplyNew > 0, "new max supply should > 0");
        require(maxSupplyNew < MAX_SUPPLY, "can only reduce max supply");
        require(
            maxSupplyNew >= totalSupply(),
            "cannot burn more than current supply"
        );
        MAX_SUPPLY = maxSupplyNew;
    }

    //===============================================================
    //                    Minting Functions
    //===============================================================

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 quantity)
        external
        payable
        callerIsUser
        nonReentrant
    {
        if (!whitelistMintState) revert SaleNotActive();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(_merkleProof, _MerkleRoot, leaf))
            revert Unauthorized();

        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();

        if (_getAux(msg.sender) != 0) revert TxnLimitReached();

        if (userMinted[msg.sender] + quantity > MINT_LIMIT_PER_ADDRESS)
            revert MintLimitReached();

        userMinted[msg.sender] += quantity;
        _setAux(msg.sender, 1);
        _mint(msg.sender, quantity);
    }

    function devMint(address _to, uint256 quantity) external payable onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY) revert ExceedsMaxSupply();
        _mint(_to, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //===============================================================
    //                      Setter Functions
    //===============================================================

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
        emit UpdateBaseURI(baseURI);
    }


    function setWhitelistMintStateStatus(bool _whitelistMintState) external onlyOwner {
        whitelistMintState = _whitelistMintState;
        emit UpdateWhitelistMintStatus(_whitelistMintState);
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _MerkleRoot = merkleRoot;
        emit UpdateMerkleRoot(merkleRoot);
    }

    //===============================================================
    //                  ETH Withdrawl
    //===============================================================

  function withdraw() public onlyOwner nonReentrant {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }
    //===============================================================
    //                    Operator Filtering
    //===============================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) external onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    //===============================================================
    //                  ERC2981 Implementation
    //===============================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    //===============================================================
    //                   SupportsInterface
    //===============================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
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

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}