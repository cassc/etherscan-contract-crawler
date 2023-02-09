// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { ERC721A } from "erc721a/ERC721A.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { OperatorFilterer } from "closedsea/OperatorFilterer.sol";
import { ERC2981 } from "openzeppelin/token/common/ERC2981.sol";
import { ECDSA } from "openzeppelin/utils/cryptography/ECDSA.sol";

contract ProjectDNE is ERC721A, Ownable, ERC2981, OperatorFilterer {
    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrWithdrawFailed();
    error ErrInvalidMaxSupply();
    error ErrIncorrectValue();
    error ErrMintNotOpen();
    error ErrExceedsMaxPerWallet();
    error ErrInvalidSignature();
    error ErrExceedsMaxSupply();
    error ErrMintZero();
    error ErrNotWhitelisted();
    error ErrNotAllowlisted();

    /* -------------------------------------------------------------------------- */
    /*                                    logs                                    */
    /* -------------------------------------------------------------------------- */
    event LogMint(address indexed sender, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    // signer
    address private _signer;

    // operator filterer
    bool public operatorFilteringEnabled;

    // supply & price
    uint256 public maxSupply = 1666;
    uint256 public mintPrice = 0.022 ether;
    uint256 public maxPerWallet = 1;

    // tokenURI
    string private _unrevealedURI;
    string public baseURI;

    // mint state
    enum MintState { Closed, WL, AllowList, Public }
    MintState public mintState; 

    // counter
    mapping(address => uint256) public mintCounter;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    constructor(address signer_) ERC721A("Project DNE", "DNE") {
        // initial states
        _signer = signer_;

        // operator filterer
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // erc2981 royalty - 5%
        _setDefaultRoyalty(0x58e57e5c14554AF774D52516b402bD5697D9cCc8, 500);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function mint(uint256 amount_, bool isWL_, bool isAllowList_, bytes calldata signature_) external payable {
        // checks
        if (amount_ == 0) { revert ErrMintZero(); }
        if (msg.value != amount_ * mintPrice) { revert ErrIncorrectValue(); }
        if (mintCounter[msg.sender] + amount_ > maxPerWallet) { revert ErrExceedsMaxPerWallet(); }
        if (totalSupply() + amount_ > maxSupply) { revert ErrExceedsMaxSupply(); }
        if (mintState == MintState.Closed) { revert ErrMintNotOpen(); }
        if (mintState == MintState.WL && !isWL_) { revert ErrNotWhitelisted(); }
        if (mintState == MintState.AllowList && !isWL_ && !isAllowList_) { revert ErrNotAllowlisted(); }

        // check signature
        bytes32 hash = keccak256(abi.encodePacked(
            msg.sender,
            amount_,
            isWL_,
            isAllowList_
        ));
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
        if (ECDSA.recover(ethHash, signature_) != _signer) revert ErrInvalidSignature();

        // update states
        mintCounter[msg.sender] += amount_;

        // mint
        _mint(msg.sender, amount_);

        // emit
        emit LogMint(msg.sender, amount_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   owners                                   */
    /* -------------------------------------------------------------------------- */
    // addresses
    function setSigner(address signer_) external onlyOwner {
        _signer = signer_;
    }

    // supply
    function reduceSupply(uint256 maxSupply_) external onlyOwner {
        if (maxSupply_ >= maxSupply) { revert ErrInvalidMaxSupply(); }
        maxSupply = maxSupply_;
    }

    // price
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    // maxPerWallet
    function setMaxPerWallet(uint256 maxPerWallet_) external onlyOwner {
        maxPerWallet = maxPerWallet_;
    }

    // mint state
    function setMintState(MintState mintState_) external onlyOwner {
        mintState = mintState_;
    }

    // tokenURI
    function setUnrevealedURI(string calldata unrevealedURI_) external onlyOwner {
        _unrevealedURI = unrevealedURI_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    // operator filterer
    function setOperatorFilteringEnabled(bool value_) external onlyOwner {
        operatorFilteringEnabled = value_;
    }

    // erc2981
    function setDefaultRoyalty(address receiver_, uint96 feeNumerator_) external onlyOwner {
        _setDefaultRoyalty(receiver_, feeNumerator_);
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        address _wallet1 = 0x58e57e5c14554AF774D52516b402bD5697D9cCc8;
        uint _payable1 = balance * 46 / 100;
        payable(_wallet1).transfer(_payable1);

        address _wallet2 = 0x41a420856b3828462eA555c736cAa93Ccf022391;
        uint _payable2 = balance * 46 / 100;
        payable(_wallet2).transfer(_payable2);

        address _wallet3 = 0xe5101e7a40C4f2c2802155b952F9E70E13abcC9b;
        uint _payable3 = balance * 3 / 100;
        payable(_wallet3).transfer(_payable3);

        address _wallet4 = 0x58c7B809AEb890132cD41fF730cbF6AB1f995ad7;
        uint _payable4 = balance * 5 / 100;
        payable(_wallet4).transfer(_payable4);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   erc721a                                  */
    /* -------------------------------------------------------------------------- */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(baseURI).length == 0) {
            return _unrevealedURI;
        } else {
            return super.tokenURI(tokenId);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              erc165 overrides                              */
    /* -------------------------------------------------------------------------- */
    function supportsInterface(bytes4 interfaceId) 
        public view virtual override (ERC721A, ERC2981)
        returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /* -------------------------------------------------------------------------- */
    /*                         operator filterer overrides                        */
    /* -------------------------------------------------------------------------- */
    function setApprovalForAll(address operator, bool approved) 
        public override(ERC721A) 
        onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
        public payable override(ERC721A)
        onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public payable override (ERC721A)
        onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public payable override (ERC721A)
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable override (ERC721A) 
        onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}