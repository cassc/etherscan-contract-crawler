// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/* ------------
    Interfaces
   ------------ */

interface ITokenURIOverride {
    function tokenURI(uint256, uint256) external view returns (string memory);
}

/* ------
    Main
   ------ */

contract KillaSocks is
    ERC721A("KillaSocks", "KillaSocks"),
    ERC2981,
    DefaultOperatorFilterer,
    Ownable
{
    bool public burningEnabled;
    string public baseURI = "https://tokens.killabears.com/killasocks/";
    mapping(address => bool) public authorities;
    ITokenURIOverride public tokenURIOverride;

    error SupplyOverflow();
    error NotAllowwed();
    error ArrayLengthMismatch();
    error BurningNotEnabled();

    constructor() {
        _setDefaultRoyalty(msg.sender, 500);
    }

    uint256[] public typeProbabilities = [
        22,
        22,
        22,
        20,
        20,
        20,
        16,
        16,
        12,
        10,
        8,
        5,
        4,
        2,
        1
    ];

    /* ---------
        Minting
       --------- */

    /// @notice Airdrop to KB holders
    function airdrop(
        address[] calldata wallets,
        uint256[] calldata amounts
    ) external onlyOwner {
        if (wallets.length != amounts.length) revert ArrayLengthMismatch();
        for (uint256 i = 0; i < wallets.length; i++) {
            _mint(wallets[i], amounts[i]);
        }
        if (totalSupply() > 3333) revert SupplyOverflow();
    }

    /* ---------
        Burning
       --------- */

    /// @notice Called by user
    function burnStinkySocks(uint256[] calldata ids) external {
        if (!burningEnabled) revert BurningNotEnabled();
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (ownerOf(id) != msg.sender && !authorities[msg.sender])
                revert NotAllowwed();
            _burn(ids[i], false);
        }
    }

    /* -------
        Admin
       ------- */

    /// @notice Toggles burning
    function toggleBurning(bool enabled) external onlyOwner {
        burningEnabled = enabled;
    }

    /// @notice Sets base URIs per upgradeId
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    /// @notice Toggle authority
    function toggleAuthority(address addr, bool enabled) external onlyOwner {
        authorities[addr] = enabled;
    }

    /// @notice Set Token URI override
    function setTokenURIOverride(address addr) external onlyOwner {
        tokenURIOverride = ITokenURIOverride(addr);
    }

    /// @notice Sets collection royalties
    function setRoyalties(address receiver, uint96 amount) external onlyOwner {
        _setDefaultRoyalty(receiver, amount);
    }

    /* -------
        Other
       ------- */

    /// @dev Used to get the URI for a given token
    function tokenURI(
        uint256 token
    ) public view override returns (string memory) {
        if (address(tokenURIOverride) != address(0))
            return tokenURIOverride.tokenURI(token, getType(token));

        uint256 typeId = getType(token);
        return string(abi.encodePacked(baseURI, _toString(typeId)));
    }

    /// @dev Gets the type of sock for a given token
    function getType(uint256 token) public view returns (uint256) {
        if (!_exists(token)) return 0;

        uint256 probability = uint256(
            keccak256(abi.encodePacked(address(this), token))
        ) % 200;
        uint256 cumulativeProbability = 0;

        uint256 ret = 0;
        while (true) {
            cumulativeProbability += typeProbabilities[ret];
            if (probability < cumulativeProbability) {
                return ret + 1;
            }
            ret++;
        }
        return 0;
    }

    /// @dev Collection starts at 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev Implements operator filterer
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev Implements operator filterer
    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /// @dev Implements operator filterer
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev Implements operator filterer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev Implements operator filterer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev Implements operator filterer
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}