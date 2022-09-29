// SPDX-License-Identifier: MIT

/*

██╗  ██╗██╗██╗     ██╗      █████╗ ████████╗██████╗  █████╗ ██╗████████╗███████╗
██║ ██╔╝██║██║     ██║     ██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██║╚══██╔══╝██╔════╝
█████╔╝ ██║██║     ██║     ███████║   ██║   ██████╔╝███████║██║   ██║   ███████╗
██╔═██╗ ██║██║     ██║     ██╔══██║   ██║   ██╔══██╗██╔══██║██║   ██║   ╚════██║
██║  ██╗██║███████╗███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║   ██║   ███████║
╚═╝  ╚═╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝

*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct Recipe {
    uint256 result;
    uint256[] ingredients;
}

contract KILLATRAITS is ERC1155, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    error InvalidSignature();
    error TokenizationRequestExpired();
    error LengthMismatch();
    error NonceAlreadyTokenized();
    error NotAllowed();
    error NonExistentRecipe();
    error DetokenizationDisabled();

    bool public detokenizationEnabled;
    address public signer;
    string public baseURI;
    mapping(uint256 => string) tokenURIs;
    mapping(address => bool) authorities;
    mapping(uint256 => Recipe) recipes;

    mapping(uint256 => bool) public usedNonces;

    event TokenizedRequest(address indexed operator, uint256 indexed nonce);
    event Detokenized(
        address indexed operator,
        uint256[] ids,
        uint256[] amounts
    );

    constructor() ERC1155("") {}

    /* --------------
        Tokenization
       -------------- */

    /// @notice Tokenize traits based on a signed message
    function tokenize(
        uint256 nonce,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256 expires,
        bytes calldata signature
    ) external {
        checkSignature(nonce, ids, amounts, expires, signature);
        if (block.timestamp > expires) revert TokenizationRequestExpired();
        if (usedNonces[nonce]) revert NonceAlreadyTokenized();
        if (ids.length != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _mint(msg.sender, id, amount, "");
        }
        usedNonces[nonce] = true;
        emit TokenizedRequest(msg.sender, nonce);
    }

    /// @notice Tokenize traits, called by authority
    function tokenize(
        address addr,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        if (!authorities[msg.sender]) revert NotAllowed();
        if (ids.length != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _mint(addr, id, amount, "");
        }
    }

    /// @notice Airdrop traits
    function airdrop(
        address[] calldata to,
        uint256[] calldata typeId,
        uint256[] calldata n
    ) external onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], typeId[i], n[i], "");
        }
    }

    /* ----------------
        Detokenization
       ---------------- */

    /// @notice Detokenize traits to move them off-chain
    function detokenize(
        address addr,
        uint256[] calldata types,
        uint256[] calldata amounts
    ) external {
        if (!detokenizationEnabled) revert DetokenizationDisabled();
        if (addr != msg.sender && !authorities[msg.sender]) revert NotAllowed();
        _burnBatch(addr, types, amounts);
        emit Detokenized(addr, types, amounts);
    }

    /* ---------
        Merging
       --------- */

    /// @notice Merge traits to get another trait
    function merge(uint256 id) external {
        Recipe storage recipe = recipes[id];
        if (recipe.result == 0) revert NonExistentRecipe();
        for (uint256 i = 0; i < recipe.ingredients.length; i++) {
            _burn(msg.sender, recipe.ingredients[i], 1);
        }
        _mint(msg.sender, recipe.result, 1, "");
    }

    /* ---------------
        Configuration
       --------------- */

    /// @notice Set the signer public address
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /// @notice Set the base URI
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /// @notice Override the URI for a given typeId
    function setTokenURI(uint256 typeId, string calldata _uri)
        external
        onlyOwner
    {
        tokenURIs[typeId] = _uri;
    }

    /// @notice Toggle detokenization
    function toggleDetokenization(bool enabled) external onlyOwner {
        detokenizationEnabled = enabled;
    }

    /// @notice Configure a merge recipe
    function configureRecipe(uint256 id, Recipe calldata recipe)
        external
        onlyOwner
    {
        recipes[id] = recipe;
    }

    /// @notice Configure multiple merge recipes
    function configureRecipes(
        uint256[] calldata ids,
        Recipe[] calldata _recipes
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            recipes[id] = _recipes[i];
        }
    }

    /// @notice Toggle authority
    function toggleAuthority(address addr, bool enabled) external onlyOwner {
        authorities[addr] = enabled;
    }

    /* --------
        Others
       -------- */

    /// @dev Returns the URI for a given trait
    function uri(uint256 typeId) public view override returns (string memory) {
        if (bytes(tokenURIs[typeId]).length == 0)
            return string(abi.encodePacked(baseURI, typeId.toString()));
        return tokenURIs[typeId];
    }

    /// @dev Check if a signature is valid
    function checkSignature(
        uint256 nonce,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        uint256 expires,
        bytes calldata signature
    ) private view {
        if (
            signer !=
            ECDSA
                .toEthSignedMessageHash(
                    abi.encodePacked(msg.sender, nonce, ids, amounts, expires)
                )
                .recover(signature)
        ) revert InvalidSignature();
    }
}