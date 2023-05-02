// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ITWMTSource {
    function getStakerTokens(
        address staker
    )
        external
        view
        returns (uint256[] memory, uint256[] memory, uint256[] memory);
}

interface ITWM {
    function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory);

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract WatchParts is
    ERC721ABurnable,
    ERC721AQueryable,
    OperatorFilterer,
    ERC2981,
    ReentrancyGuard,
    Ownable
{
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";

    // Max number of NFTs
    uint256 public constant MAX_SUPPLY = 11110;
    uint256 public _publicPrice;
    uint256 public _guestPriceForHolder;
    uint256 public reserveMaxLimit;

    // The watchmaker contract
    ITWM public TWM;
    ITWMTSource public STAKING;

    // Stores the number of minted tokens by user
    mapping(address => uint256) public _mintedByAddress;

    bytes32 public whitelistMerkleRoot;

    /// @notice Operator filter toggle switch
    bool private operatorFilteringEnabled;

    event TokensMinted(address indexed mintedBy, uint256 indexed tokensNumber);

    constructor(
        string memory _name,
        string memory _symbol,
        address _twm,
        address _staking,
        string memory _initBaseURI
    ) ERC721A(_name, _symbol) {
        TWM = ITWM(_twm);
        STAKING = ITWMTSource(_staking);
        setBaseURI(_initBaseURI);
        reserveMaxLimit = 50;
        _publicPrice = 0.01 ether;
        _guestPriceForHolder = 0.008 ether;

        // Setup filter registry
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        // Setup royalties to 9.5% (default denominator is 10000)
        _setDefaultRoyalty(_msgSender(), 950);
    }

    function publicMint(
        uint256 tokensToMint,
        bytes32[] calldata merkleProof
    ) public payable nonReentrant {
        require(msg.sender == tx.origin, "Can't mint through another contract");

        require(
            totalSupply() + tokensToMint <= MAX_SUPPLY,
            "Mint exceeds total supply"
        );

        if (
            isV1Holder(_msgSender()) || isWhitelist(_msgSender(), merkleProof)
        ) {
            require(
                _guestPriceForHolder * tokensToMint <= msg.value,
                "Sent incorrect ETH value for guest"
            );
        } else {
            require(
                _publicPrice * tokensToMint <= msg.value,
                "Sent incorrect ETH value for public"
            );
        }

        _safeMint(_msgSender(), tokensToMint);

        _mintedByAddress[_msgSender()] += tokensToMint;

        emit TokensMinted(_msgSender(), tokensToMint);
    }

    function isV1Holder(address _addr) public view returns (bool) {
        uint256[] memory twmNFTs = TWM.walletOfOwner(_addr);

        (uint256[] memory stakedFirst, , ) = STAKING.getStakerTokens(_addr);

        uint256 totalOwnedTWMs = twmNFTs.length + stakedFirst.length;

        if (totalOwnedTWMs > 0) {
            return true;
        }

        return false;
    }

    function isWhitelist(
        address _addr,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                merkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(_addr))
            );
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner nonReentrant {
        whitelistMerkleRoot = _merkleRoot;
    }

    function reserveNFTs(address devAddr) public onlyOwner nonReentrant {
        require(
            totalSupply() + reserveMaxLimit <= MAX_SUPPLY,
            "Mint exceeds total supply"
        );

        _safeMint(devAddr, reserveMaxLimit);

        _mintedByAddress[devAddr] += reserveMaxLimit;

        emit TokensMinted(devAddr, reserveMaxLimit);
    }

    function updatePublicPrice(uint256 _newPrice) public onlyOwner {
        _publicPrice = _newPrice;
    }

    function updatePublicPriceForHolder(uint256 _newPrice) public onlyOwner {
        _guestPriceForHolder = _newPrice;
    }

    function updateReserveMaxLimit(uint256 _newMaxLimit) public onlyOwner {
        reserveMaxLimit = _newMaxLimit;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev sets the base uri for {_baseURI}
     */
    function setBaseURI(string memory baseURI_) public onlyOwner nonReentrant {
        baseURI = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI_ = _baseURI();
        return
            bytes(baseURI_).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI_,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    ///////////////////
    // operator filter
    ///////////////////

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}