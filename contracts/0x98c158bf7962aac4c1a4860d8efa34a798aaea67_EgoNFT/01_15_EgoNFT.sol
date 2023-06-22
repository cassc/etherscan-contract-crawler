// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error Soulbound();
error AlreadyClaimed();
error NotClaimed();
error NotAuthorized();
error NotStart();
error NotEOA();

contract EgoNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    /* === Variables === */
    string private _baseURL;
    bool private _claimActive;
    Counters.Counter private _tokenIds;

    address private operatorAddress;

    mapping(uint256 => string) private _tokenURIs;

    /* === Modifiers === */
    modifier whenClaimActive() {
        if (!_claimActive) {
            revert NotStart();
        }
        _;
    }

    modifier EOAOnly() {
        if (tx.origin != msg.sender) {
            revert NotEOA();
        }
        _;
    }

    /* === Events === */
    event ClaimStart(bool indexed claimStarted);

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /* === Functions === */

    /** 
        @dev mint EGO nft for free
    */
    function claim() external whenClaimActive EOAOnly {
        if (balanceOf(msg.sender) > 0) {
            revert AlreadyClaimed();
        }
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        super._safeMint(msg.sender, id);
    }

    /**
     @dev switch for claim
    */
    function toggleClaimActive() external onlyOwner {
        _claimActive = !_claimActive;
        emit ClaimStart(_claimActive);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        _baseURL = uri;
    }

    function setOperator(address operator) external onlyOwner {
        operatorAddress = operator;
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external {
        if (_msgSender() != operatorAddress) {
            revert NotAuthorized();
        }

        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = uri;
    }

    /* === View functions === */
    function queryTokenByAddress(address tokenOwner)
        external
        view
        returns (uint256, string memory)
    {
        if (balanceOf(tokenOwner) == 0) {
            return (0, "");
        }
        uint256 tokenId = tokenOfOwnerByIndex(tokenOwner, 0);
        return (tokenId, tokenURI(tokenId));
    }

    /* === Soulbound Token === */

    /**
     * @notice SOULBOUND: Block transfers.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        if(from != address(0) && to != address(0)) {
            revert Soulbound();
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice SOULBOUND: Block approvals.
     */
    function setApprovalForAll(address operator, bool _approved)
        public
        virtual
        override(ERC721, IERC721)
    {
        revert Soulbound();
    }

    /**
     * @notice SOULBOUND: Block approvals.
     */
    function approve(address to, uint256 tokenId)
        public
        virtual
        override(ERC721, IERC721)
    {
        revert Soulbound();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is token URI for this specific token, use it.
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // return base URI + token ID
        return super.tokenURI(tokenId);
    }

    /* === emergency Withdraw === */

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function emergencyWithdrawERC20(IERC20 token) external onlyOwner {
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "Transfer failed"
        );
    }
}