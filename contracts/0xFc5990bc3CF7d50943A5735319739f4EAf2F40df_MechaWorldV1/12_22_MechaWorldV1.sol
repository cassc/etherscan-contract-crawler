// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import {IERC721AUpgradeable, ERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {ERC721ABurnableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import {OperatorFilterer} from "./utils/OperatorFilterer.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract MechaWorldV1 is
    ERC721AQueryableUpgradeable,
    ERC721ABurnableUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    bool public operatorFilteringEnabled;

    string public uriPrefix;
    string public uriSuffix;
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public totalFree;
    uint256 public maxFreePer;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountPerWallet;
    uint256 public totalFreeMinted;

    mapping(address => uint256) public _mintedFreeAmount;
    mapping(address => uint256) public _mintedAmount;
    mapping(address => uint256) public _refunded;

    bool public paused;
    bool public revealed;
    bool public refundOpened;

    uint256 public teamMinted;
    uint256 public maxTeamMint;

    uint256[50] __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _totalFree,
        uint256 _maxFreePer,
        uint256 _maxMintAmountPerTx,
        uint256 _maxMintAmountPerWallet,
        uint256 _maxTeamMint,
        string memory _hiddenMetadataUri,
        uint96 feeBasis
    ) public initializer initializerERC721A {
        __ERC721A_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        __ERC2981_init();

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        setCost(_cost);
        uriPrefix = "";
        uriSuffix = ".json";
        totalFreeMinted = 0;
        teamMinted = 0;
        paused = true;
        revealed = false;
        refundOpened = false;
        maxTeamMint = _maxTeamMint;
        maxSupply = _maxSupply;
        setTotalFree(_totalFree);
        setMaxFreePer(_maxFreePer);
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
        setHiddenMetadataUri(_hiddenMetadataUri);

        _setDefaultRoyalty(_msgSender(), feeBasis);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            _mintedAmount[msg.sender] + _mintAmount <= maxMintAmountPerWallet,
            "Max amount exceeded!"
        );
        require(
            totalSupply() + _mintAmount <=
                maxSupply - (maxTeamMint - teamMinted),
            "Max supply exceeded!"
        );
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract!");
        _;
    }

    function teamMint(
        uint256 _mintAmount
    ) public onlyOwner callerIsUser nonReentrant {
        require(
            _mintAmount > 0 && _mintAmount <= maxTeamMint,
            "Invalid mint amount!"
        );
        require(
            teamMinted + _mintAmount <= maxTeamMint,
            "Max amount exceeded!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        teamMinted += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(
        uint256 _mintAmount
    ) public payable callerIsUser mintCompliance(_mintAmount) {
        require(!paused, "The contract is paused!");

        if (totalFreeMinted >= totalFree) {
            require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        } else if (
            (totalFreeMinted + _mintAmount <= totalFree) &&
            (_mintAmount <= maxFreePer - _mintedFreeAmount[msg.sender])
        ) {
            require(msg.value >= 0, "Insufficient funds!");
            totalFreeMinted += _mintAmount;
            _mintedFreeAmount[msg.sender] += _mintAmount;
        } else if (
            (totalFreeMinted < totalFree) &&
            (totalFreeMinted + maxFreePer - _mintedFreeAmount[msg.sender] >=
                totalFree)
        ) {
            require(
                msg.value >=
                    (_mintAmount * cost) -
                        ((totalFree - totalFreeMinted) * cost),
                "Insufficient funds!"
            );
            totalFreeMinted += totalFree - totalFreeMinted;
            _mintedFreeAmount[msg.sender] += totalFree - totalFreeMinted;
        } else {
            require(
                msg.value >=
                    (_mintAmount * cost) -
                        ((maxFreePer - _mintedFreeAmount[msg.sender]) * cost),
                "Insufficient funds!"
            );
            totalFreeMinted += maxFreePer - _mintedFreeAmount[msg.sender];
            _mintedFreeAmount[msg.sender] = maxFreePer;
        }
        _mintedAmount[msg.sender] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) public mintCompliance(_mintAmount) onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _tokenId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        if (revealed == false) {
            currentBaseURI = hiddenMetadataUri;
        }

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

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setRefundOpened(bool _state) public onlyOwner {
        refundOpened = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setTotalFree(uint256 _totalFree) public onlyOwner {
        totalFree = _totalFree;
    }

    function setMaxFreePer(uint256 _maxFreePer) public onlyOwner {
        maxFreePer = _maxFreePer;
    }

    function setMaxMintAmountPerTx(
        uint256 _maxMintAmountPerTx
    ) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxMintAmountPerWallet(
        uint256 _maxMintAmountPerWallet
    ) public onlyOwner {
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
    }

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function refund() public callerIsUser nonReentrant {
        require(refundOpened, "Refunds not started!");
        uint256 refundNumber = _mintedAmount[msg.sender] -
            _mintedFreeAmount[msg.sender] -
            _refunded[msg.sender];
        require(refundNumber > 0 && cost > 0, "No refund items!");
        _refunded[msg.sender] += refundNumber;
        (bool success, ) = (msg.sender).call{value: refundNumber * cost}("");
        require(success, "Refund failed!");
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 sendAmount = address(this).balance;
        address n = payable(msg.sender);
        bool success;
        (success, ) = n.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful!");
    }

    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}