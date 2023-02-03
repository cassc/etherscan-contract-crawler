// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/* ---------
    Structs
   --------- */

struct TokenConfig {
    bool mintPaused;
    uint32 startTime;
    uint32 endTime;
    uint256 tokenPrice;
    uint256 maxAllowance;
    string uri;
}

/* ----------
    Contract
   ---------- */

contract KillaChronicles is
    ERC1155(""),
    ERC2981,
    DefaultOperatorFilterer,
    Ownable
{
    /// @dev Mint configurations per token
    mapping(uint256 => TokenConfig) public configurations;

    /// @dev Keeps track of how many where minted per token, including airdrops
    mapping(uint256 => uint256) public mintedPerToken;

    /// @dev Keeps track of how many a wallet has minted per token, excluding airdrops
    mapping(uint256 => mapping(address => uint256)) public mintedPerWallet;

    /// @dev Authorities are used for adding utility
    mapping(address => bool) public authorities;

    /// @dev The collector address is where the funds get sent to after calling Collect()
    
    address public collector;
    /* --------
        Errors
       -------- */

    error MintNotStarted();
    error MintEnded();
    error MintPaused();
    error MintAlreadyStarted();
    error ArrayLengthMismatch();
    error NotEnoughEth();
    error ExceededAllowance();
    error NotAllowed();

    /* -------------
        Constructor
       ------------- */

    constructor() {
        _setDefaultRoyalty(msg.sender, 500);
    }

    /* ---------
        Minting
       --------- */

    /// @notice Mint a variable amount of a given token
    function mint(uint256 tokenId, uint256 qty) external payable {
        TokenConfig memory config = configurations[tokenId];

        if (config.mintPaused) revert MintPaused();
        if (block.timestamp < config.startTime || config.startTime == 0)
            revert MintNotStarted();
        if (block.timestamp > config.endTime) revert MintEnded();
        if (msg.value != config.tokenPrice * qty) revert NotEnoughEth();

        mintedPerWallet[tokenId][msg.sender] += qty;

        if (mintedPerWallet[tokenId][msg.sender] > config.maxAllowance)
            revert ExceededAllowance();

        mintedPerToken[tokenId] += qty;

        _mint(msg.sender, tokenId, qty, "");
    }

    /* ---------
        Utility
       --------- */

    modifier onlyAuthority() {
        if (!authorities[msg.sender]) revert NotAllowed();
        _;
    }

    /// @dev Mint a token, called by authority contract
    /// @dev Can't mint tokens with an endTime
    function mint(
        uint256 tokenId,
        address recipient,
        uint256 qty
    ) external onlyAuthority {
        TokenConfig memory config = configurations[tokenId];
        if (config.endTime > 0) revert NotAllowed();

        _mint(recipient, tokenId, qty, "");
    }

    /// @dev Burn tokens, called by authority contract
    function burn(
        uint256 tokenId,
        address owner,
        uint256 qty
    ) external onlyAuthority {
        _burn(owner, tokenId, qty);
    }

    /* -------
        Admin
       ------- */

    /// @notice Airdrop tokens
    /// @dev Can't be called after mint ended for that token
    function airdrop(
        uint256 tokenId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        TokenConfig memory config = configurations[tokenId];
        if (config.endTime > 0 && block.timestamp > config.endTime)
            revert MintEnded();
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenId, amounts[i], "");
            mintedPerToken[tokenId] += amounts[i];
        }
    }

    /// @notice Configure mint parameteres for a given token
    /// @dev Can't be called after mint ended for that token
    function setupMint(
        uint256 tokenId,
        uint32 startTime,
        uint32 hours_,
        uint256 price,
        uint256 allowance,
        string calldata _uri
    ) external onlyOwner {
        TokenConfig storage config = configurations[tokenId];
        if (
            configurations[tokenId].endTime != 0 &&
            block.timestamp > configurations[tokenId].endTime
        ) revert MintEnded();

        config.startTime = startTime;
        config.endTime = startTime + hours_ * 3600;
        config.tokenPrice = price;
        config.maxAllowance = allowance;
        config.uri = _uri;
    }

    /// @notice Sets the mint price for a given token
    function setTokenPrice(uint256 tokenId, uint256 price) external onlyOwner {
        configurations[tokenId].tokenPrice = price;
    }

    /// @notice Pauses minting for a given token
    function pauseMint(uint256 tokenId) external onlyOwner {
        configurations[tokenId].mintPaused = true;
    }

    /// @notice Resumes minting for a given token
    function resumeMint(uint256 tokenId) external onlyOwner {
        configurations[tokenId].mintPaused = false;
    }

    /// @notice Sets the start time for a give token
    /// @dev Can't be called after mint ended for that token
    function setStartTime(uint256 tokenId, uint32 t) external onlyOwner {
        if (
            configurations[tokenId].endTime != 0 &&
            block.timestamp > configurations[tokenId].endTime
        ) revert MintEnded();
        configurations[tokenId].startTime = t;
    }

    /// @notice Sets the end time for a give token
    /// @dev Can't be called after mint ended for that token
    function setEndTime(uint256 tokenId, uint32 t) external onlyOwner {
        if (
            configurations[tokenId].endTime != 0 &&
            block.timestamp > configurations[tokenId].endTime
        ) revert MintEnded();
        configurations[tokenId].endTime = t;
    }

    /// @notice Sets the allowance per wallet for a given token
    function setAllowance(uint256 tokenId, uint256 allowance)
        external
        onlyOwner
    {
        configurations[tokenId].maxAllowance = allowance;
    }

    /// @notice Sets the token URI for a given token
    function setTokenURI(uint256 tokenId, string calldata _uri)
        external
        onlyOwner
    {
        configurations[tokenId].uri = _uri;
    }

    /// @notice Toggles an authority contract on or off
    function toggleAuthority(address addr, bool enabled) external onlyOwner {
        authorities[addr] = enabled;
    }

    /// @notice Sets collection royalties
    function setRoyalties(address receiver, uint96 amount) external onlyOwner {
        _setDefaultRoyalty(receiver, amount);
    }

    /// @notice Sets the collector address
    function setCollector(address addr) external onlyOwner {
        collector = addr;
    }

    /// @notice Sends funds to the collector address
    /// @dev Has a check to make sure the collector is set before allowing this to be called
    function collect() external onlyOwner {
        if (collector == address(0)) revert NotAllowed();
        payable(collector).transfer(address(this).balance);
    }

    /* -----------
        Overrides
       ----------- */

    /// @dev gets the URI for a given token
    function uri(uint256 tokenId) public view override returns (string memory) {
        return configurations[tokenId].uri;
    }

    /// @dev Implements operator filterer
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev Implements operator filterer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /// @dev Implements operator filterer
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @dev Implements operator filterer
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}