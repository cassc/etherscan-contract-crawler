// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ApeFiNFT is
    ERC721AQueryable,
    ERC2981,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    using SafeERC20 for IERC20;

    uint256 public constant PRESALE_PRICE_APEFI = 100000e18; // 100,000 APEFI
    uint256 public constant PRESALE_MAX_MINT = 500;
    uint256 public constant PRESALE_MAX_MINT_PER_ACCOUNT = 2;
    uint256 public constant WHITELIST_PRICE = 0.3e18; // 0.3 ETH
    uint256 public constant MINT_START_PRICE = 1e18; // 1 ETH
    uint256 public constant MINT_PRICE_DROP_INTERVAL = 30 minutes;
    uint256 public constant MINT_PRICE_DROP_DEGREE = 0.1e18; // 0.1 ETH
    uint256 public constant MIN_MINT_PRICE = 0.5e18; // 0.5 ETH
    uint256 public constant MAX_MINT_PER_ACCOUNT = 3;
    uint256 public constant MAX_MINT_PER_TX = 20;

    IERC20 public immutable apeFi;
    IERC721Enumerable public immutable bayc;
    IERC721Enumerable public immutable mayc;
    uint256 private immutable _maxSupply;

    string private _baseURIExtended;

    uint256 private _startTime;
    mapping(address => uint256) private _presaleMinted;

    bytes32 private _whitelistMerkleRoot;
    mapping(address => bool) private _whitelistMinted;
    mapping(uint256 => bool) private _baycUsed;
    mapping(uint256 => bool) private _maycUsed;

    mapping(address => uint256) private _publicMinted;

    event StartTimeSet(uint256 startTime);
    event WhitelistMerkleRootSet(bytes32 merkleRoot);

    constructor(
        address apeFi_,
        address bayc_,
        address mayc_,
        uint256 maxSupply_
    ) ERC721A("DeFiApes", "DEFIAPES") {
        apeFi = IERC20(apeFi_);
        bayc = IERC721Enumerable(bayc_);
        mayc = IERC721Enumerable(mayc_);
        _maxSupply = maxSupply_;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "contract cannot mint");
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Get max total supply.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Get the current block timestamp.
     */
    function getBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Get the NFT start time.
     */
    function getStartTime() public view returns (uint256) {
        return _startTime;
    }

    /**
     * @notice Get the account presale mint amount.
     * @param account The account
     */
    function getPresaleMinted(address account) public view returns (uint256) {
        return _presaleMinted[account];
    }

    /**
     * @notice Get the NFT whitelist mint start time.
     */
    function getWhitelistMintStartTime() public view returns (uint256) {
        return _startTime + 8 hours;
    }

    /**
     * @notice Get the whitelist merkle root.
     */
    function getWhitelistMerkleRoot() public view returns (bytes32) {
        return _whitelistMerkleRoot;
    }

    /**
     * @notice Return if the whitelist minted or not.
     * @param account The account
     */
    function isWhitelistMinted(address account) public view returns (bool) {
        return _whitelistMinted[account];
    }

    struct ApeUsed {
        uint256 tokenId;
        bool isUsed;
    }

    /**
     * @notice Return all the account's BAYC token IDs and its eligibility.
     * @param account The account
     */
    function getAccountEligibleBayc(
        address account
    ) public view returns (ApeUsed[] memory) {
        uint256 balance = bayc.balanceOf(account);
        ApeUsed[] memory apes = new ApeUsed[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = bayc.tokenOfOwnerByIndex(account, i);
            apes[i] = ApeUsed({tokenId: tokenId, isUsed: _baycUsed[tokenId]});
        }
        return apes;
    }

    /**
     * @notice Return all the account's MAYC token IDs and its eligibility.
     * @param account The account
     */
    function getAccountEligibleMayc(
        address account
    ) public view returns (ApeUsed[] memory) {
        uint256 balance = mayc.balanceOf(account);
        ApeUsed[] memory apes = new ApeUsed[](balance);
        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = mayc.tokenOfOwnerByIndex(account, i);
            apes[i] = ApeUsed({tokenId: tokenId, isUsed: _maycUsed[tokenId]});
        }
        return apes;
    }

    /**
     * @notice Get the NFT public mint start time.
     */
    function getPublicMintStartTime() public view returns (uint256) {
        return _startTime + 8 hours + 1 days;
    }

    /**
     * @notice Get the account public mint amount.
     * @param account The account
     */
    function getPublicMinted(address account) public view returns (uint256) {
        return _publicMinted[account];
    }

    /**
     * @notice Get the public mint price.
     */
    function getPublicMintPrice() public view returns (uint256) {
        uint256 timeElapsed = getBlockTimestamp() - getPublicMintStartTime();
        uint256 price = MINT_START_PRICE -
            (timeElapsed / MINT_PRICE_DROP_INTERVAL) *
            MINT_PRICE_DROP_DEGREE;
        if (price < MIN_MINT_PRICE) {
            price = MIN_MINT_PRICE;
        }
        return price;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Phase 1 - Presale NFT with APEFI.
     * @param quantity The amount
     */
    function presale(
        uint256 quantity
    ) external whenNotPaused nonReentrant onlyEOA {
        require(getStartTime() != 0, "start time not set");
        require(getBlockTimestamp() >= getStartTime(), "presale not started");
        require(
            getBlockTimestamp() < getWhitelistMintStartTime(),
            "presale closed"
        );
        require(
            totalSupply() + quantity <= PRESALE_MAX_MINT,
            "presale mintable amount exceeded"
        );

        if (getBlockTimestamp() < getStartTime() + 6 hours) {
            require(
                _presaleMinted[msg.sender] + quantity <=
                    PRESALE_MAX_MINT_PER_ACCOUNT,
                "max mint amount per account exceeded"
            );
        } else {
            require(
                quantity <= MAX_MINT_PER_TX,
                "max mint amount per tx exceeded"
            );
        }

        _presaleMinted[msg.sender] += quantity;

        _mint(msg.sender, quantity);

        uint256 amount = quantity * PRESALE_PRICE_APEFI;
        apeFi.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Phase 2 - Whitelist mint NFT.
     * @param merkleProof The merkle proof
     */
    function whitelistMint(
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused nonReentrant onlyEOA {
        require(getStartTime() != 0, "start time not set");
        require(
            getBlockTimestamp() >= getWhitelistMintStartTime(),
            "whitelist mint not started"
        );
        require(
            getBlockTimestamp() < getPublicMintStartTime(),
            "whitelist mint closed"
        );
        require(totalSupply() + 1 <= maxSupply(), "max supply exceeded");
        require(!_whitelistMinted[msg.sender], "already minted");
        require(
            MerkleProof.verify(
                merkleProof,
                _whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "merkle proof verification failed"
        );
        require(msg.value >= WHITELIST_PRICE, "not enough ether");

        _whitelistMinted[msg.sender] = true;

        // Whitelist can only mint 1 NFT.
        _mint(msg.sender, 1);
    }

    /**
     * @notice Phase 2 - Ape holders mint NFT.
     * @param baycTokenIds The BAYC token IDs
     * @param maycTokenIds The MAYC token IDs
     */
    function apesMint(
        uint256[] memory baycTokenIds,
        uint256[] memory maycTokenIds
    ) external payable whenNotPaused nonReentrant onlyEOA {
        require(getStartTime() != 0, "start time not set");
        require(
            getBlockTimestamp() >= getWhitelistMintStartTime(),
            "whitelist mint not started"
        );
        require(
            getBlockTimestamp() < getPublicMintStartTime(),
            "whitelist mint closed"
        );

        uint256 quantity = baycTokenIds.length + maycTokenIds.length;
        require(totalSupply() + quantity <= maxSupply(), "max supply exceeded");
        require(quantity <= MAX_MINT_PER_TX, "max mint amount per tx exceeded");
        require(msg.value >= WHITELIST_PRICE * quantity, "not enough ether");

        for (uint256 i = 0; i < baycTokenIds.length; ) {
            uint256 tokenId = baycTokenIds[i];

            require(bayc.ownerOf(tokenId) == msg.sender, "not the ape owner");
            require(!_baycUsed[tokenId], "ape was used");
            _baycUsed[tokenId] = true;

            unchecked {
                i++;
            }
        }

        for (uint256 i = 0; i < maycTokenIds.length; ) {
            uint256 tokenId = maycTokenIds[i];

            require(mayc.ownerOf(tokenId) == msg.sender, "not the ape owner");
            require(!_maycUsed[tokenId], "ape was used");
            _maycUsed[tokenId] = true;

            unchecked {
                i++;
            }
        }

        _mint(msg.sender, quantity);
    }

    /**
     * @notice Phase 3 - Public mint NFT.
     * @param quantity The amount
     */
    function publicMint(
        uint256 quantity
    ) external payable whenNotPaused nonReentrant onlyEOA {
        require(getStartTime() != 0, "start time not set");
        require(
            getBlockTimestamp() >= getPublicMintStartTime(),
            "public mint not started"
        );
        require(totalSupply() + quantity <= maxSupply(), "max supply exceeded");

        uint256 price = getPublicMintPrice();
        if (price != MIN_MINT_PRICE) {
            require(
                _publicMinted[msg.sender] + quantity <= MAX_MINT_PER_ACCOUNT,
                "max mint amount per account exceeded"
            );
        } else {
            require(
                quantity <= MAX_MINT_PER_TX,
                "max mint amount per tx exceeded"
            );
        }
        require(msg.value >= price * quantity, "not enough ether");

        _publicMinted[msg.sender] += quantity;

        _mint(msg.sender, quantity);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Admin sets the start time.
     * @param startTime The start time
     */
    function setStartTime(uint256 startTime) external onlyOwner {
        require(startTime > block.timestamp, "invalid start time");
        _startTime = startTime;

        emit StartTimeSet(startTime);
    }

    /**
     * @notice Admin sets whitelist merkle root.
     * @param merkleRoot The merkle root
     */
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _whitelistMerkleRoot = merkleRoot;

        emit WhitelistMerkleRootSet(merkleRoot);
    }

    /**
     * @notice Admin pauses minting.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Admin unpauses minting.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Admin sets the base URI.
     * @param baseURI The base URI
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        require(bytes(baseURI).length != 0, "empty base URI");

        _baseURIExtended = baseURI;
    }

    /**
     * @notice Admin withdraws APEFI and ether.
     */
    function withdraw() external onlyOwner {
        uint256 apeFiBal = apeFi.balanceOf(address(this));
        apeFi.safeTransfer(owner(), apeFiBal);

        uint256 ethBal = address(this).balance;
        (bool sent, ) = payable(owner()).call{value: ethBal}("");
        require(sent, "failed to send ether");
    }

    /**
     * @notice Admin sets the default royalty.
     * @param receiver The royalty receiver
     * @param feeNumerator The fee in basis points
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice Admin removes the default royalty.
     */
    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /**
     * @notice Admin sets the specific token royalty.
     * @param tokenId The token ID
     * @param receiver The royalty receiver
     * @param feeNumerator The fee in basis points
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Admin resets the royalty for the token ID back to the global default
     * @param tokenId The token ID
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}