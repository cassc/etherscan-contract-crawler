// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721A, ERC721A, ERC721AQueryable} from "erc721a/extensions/ERC721AQueryable.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import {ERC2981} from "openzeppelin-contracts/token/common/ERC2981.sol";

contract BoredGaryYachtClub is ERC721AQueryable, Ownable, OperatorFilterer, ERC2981 {
    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant AIRDROP_SUPPLY = 2469;
    uint256 public constant PUBLIC_SUPPLY = MAX_SUPPLY - AIRDROP_SUPPLY;

    uint256 public constant MAX_MINT = 5;
    uint256 public constant PRICE = 0.0045 ether;

    uint64 public _teamMinted;
    bool public _started;
    string public _uri = "https://boredgaryyachtclub.com/metadata/";

    constructor() ERC721A("BoredGaryYachtClub", "BGYC") {
        _initializeOwner(tx.origin);
        _registerForOperatorFiltering();
        setFee(msg.sender, 750);
    }

    function mint(uint256 amount, bool hasExtraFreeMint, uint8 v, bytes32 r, bytes32 s) external payable {
        if (!_started) revert NotStarted();

        uint256 availableTokens = PUBLIC_SUPPLY - (totalSupply() - _teamMinted);
        if (amount > availableTokens) revert ExceedMaxSupply();

        uint256 userMinted = _numberMinted(msg.sender);
        if (userMinted + amount > MAX_MINT) revert ExceedMaxMint();

        uint256 maximumFreeMints = 1;
        if (hasExtraFreeMint) {
            bytes32 digest = keccak256(abi.encodePacked(msg.sender));
            digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));
            if (ecrecover(digest, v, r, s) != owner()) revert InvalidSignature();
            maximumFreeMints = 2;
        }

        uint256 paidMints = amount;

        if (userMinted < maximumFreeMints) {
            uint256 availableFreeMints = maximumFreeMints - userMinted;
            if (amount > availableFreeMints) {
                paidMints -= availableFreeMints;
            } else {
                paidMints = 0;
            }
        }

        if (paidMints * PRICE > msg.value) revert InsufficientFunds();

        _mint(msg.sender, amount);
    }

    function _uiStatus(address account)
        public
        view
        returns (
            bool started,
            uint256 userMinted,
            uint256 maxSupply,
            uint256 maxMintPerAccount,
            uint256 publicSupply,
            uint256 publicMinted,
            uint256 price
        )
    {
        started = _started;
        userMinted = _numberMinted(account);
        maxSupply = MAX_SUPPLY;
        maxMintPerAccount = MAX_MINT;
        publicSupply = PUBLIC_SUPPLY;
        publicMinted = totalSupply() - _teamMinted;
        price = PRICE;
    }

    /// ======== Admin ========

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _uri = baseURI;
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length);
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            totalAmount += amounts[i];
            _mint(recipients[i], amounts[i]);
        }

        if (totalAmount + _teamMinted > AIRDROP_SUPPLY) revert ExceedMaxSupply();
        _teamMinted += uint64(totalAmount);
    }

    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(payable(msg.sender), address(this).balance);
    }

    function setFee(address feeRecipient, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(feeRecipient, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A, IERC721A)
        returns (bool)
    {
        return ERC2981.supportsInterface(interfaceId) || ERC721A.supportsInterface(interfaceId);
    }

    /// ======== OperatorFilter ========

    function repeatRegistration() public {
        _registerForOperatorFiltering();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// ======== Error ========
    error NotStarted();
    error ExceedMaxMint();
    error ExceedMaxSupply();
    error InvalidSignature();
    error InsufficientFunds();
}