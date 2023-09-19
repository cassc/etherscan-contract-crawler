//  $$$$$$$$\ $$$$$$$$\  $$$$$$\  $$\      $$\       $$$$$$$$\  $$$$$$\  $$\   $$\ $$$$$$$$\ $$\   $$\
//  \__$$  __|$$  _____|$$  __$$\ $$$\    $$$ |      \__$$  __|$$  __$$\ $$ | $$  |$$  _____|$$$\  $$ |
//     $$ |   $$ |      $$ /  $$ |$$$$\  $$$$ |         $$ |   $$ /  $$ |$$ |$$  / $$ |      $$$$\ $$ |
//     $$ |   $$$$$\    $$$$$$$$ |$$\$$\$$ $$ |         $$ |   $$ |  $$ |$$$$$  /  $$$$$\    $$ $$\$$ |
//     $$ |   $$  __|   $$  __$$ |$$ \$$$  $$ |         $$ |   $$ |  $$ |$$  $$<   $$  __|   $$ \$$$$ |
//     $$ |   $$ |      $$ |  $$ |$$ |\$  /$$ |         $$ |   $$ |  $$ |$$ |\$$\  $$ |      $$ |\$$$ |
//     $$ |   $$$$$$$$\ $$ |  $$ |$$ | \_/ $$ |         $$ |    $$$$$$  |$$ | \$$\ $$$$$$$$\ $$ | \$$ |
//     \__|   \________|\__|  \__|\__|     \__|         \__|    \______/ \__|  \__|\________|\__|  \__|
//
//   Web: teamtoken.com
//   Twitter: twitter.com/TeamTokenCrypto
//   Contact Email: [email protected]
//
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./types/Structs.sol";

import "./interfaces/ITeamNFTRenderer.sol";
import "./interfaces/IOpenseaProxyRegistry.sol";
import "./interfaces/ITeamNFTManager.sol";

error NotTeamNFTManager();

/// @title Upgradeable TeamNFT ERC1155
/// @author TeamToken / CryptoAaron
/// @notice This contract is subject to upgrades in the future.
contract TeamNFT is
    Initializable,
    ERC2981Upgradeable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    /// @dev Mapping from tokenId to number of unique owners.
    mapping(uint256 => uint256) private _ownersOfTokenId;

    /// @dev Mapping from tokenId -> ownersIndex -> address
    mapping(uint256 => mapping(uint256 => address)) private _tokenOwners;

    /// @dev Mapping from account to index of the owner tokens list
    mapping(address => uint256) private _tokensOwnedIndex;

    /// @dev Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    /// @dev Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /// @dev OpenSea Proxy address
    address private openseaProxyRegistryAddress;

    /// @dev Onchain NFT metadata creation
    ITeamNFTRenderer private _teamNftRenderer;

    /// @dev Should use on-chain metadata
    bool private onChainMetadata;

    /// @dev TeamToken NFT Manager
    ITeamNFTManager private _teamNftManager;

    modifier onlyTeamNFTManager() {
        if (!_checkSenderIsTeamNFTManager()) {
            revert NotTeamNFTManager();
        }
        _;
    }

    modifier onlyOwnerOrTeamNFTManager() {
        if (!_checkSenderIsTeamNFTManager() && !_checkSenderIsOwner()) {
            revert NotTeamNFTManager();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Returns the address of the TeamNFT Manager
     */
    function teamNftManager() public view virtual returns (address) {
        return address(_teamNftManager);
    }

    function teamNftRenderer() public view virtual returns (address) {
        return address(_teamNftRenderer);
    }

    /// @dev Function to be called on initial deployment
    /// @param  _admin address The TeamToken admin
    function initialize(
        address _admin,
        address nftManager,
        address _openseaProxy
    ) public initializer {
        __ERC1155_init("https://api.teamtoken.com/metadata/{id}.json");
        __Ownable_init();
        __ERC1155Supply_init();
        __ERC2981_init();
        _setDefaultRoyalty(
            address(0xbac09bCd3C11168AE39028c145710Cc862E84d7C), //gnosis safe
            1000
        );
        _transferOwnership(_admin);
        openseaProxyRegistryAddress = _openseaProxy;
        onChainMetadata = false;
        if (nftManager != address(0)) {
            _teamNftManager = ITeamNFTManager(nftManager);
        }
    }

    /// @dev Set a new URI. Callable by owner only.
    /// @param  newuri The new URI for all tokens.
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @dev Set a new NFT Renderer contract. Callable by owner only.
    /// @param  newTeamNftRenderer The new address for TeamNFTRenderer
    function setTeamNftRenderer(
        address newTeamNftRenderer
    ) public onlyOwnerOrTeamNFTManager {
        _teamNftRenderer = ITeamNFTRenderer(newTeamNftRenderer);
        onChainMetadata = newTeamNftRenderer != address(0)
            ? onChainMetadata = true
            : onChainMetadata = false;
    }

    /// @dev Set a new NFT Renderer contract. Callable by owner only.
    /// @param  newTeamNftManager The new address for TeamNFTManager
    function setTeamNftManager(
        address newTeamNftManager
    ) public onlyOwnerOrTeamNFTManager {
        _teamNftManager = ITeamNFTManager(newTeamNftManager);
    }

    /// @dev ERC1155 Token Collection Name
    function name() public view virtual returns (string memory) {
        return "TeamNFT";
    }

    /// @dev ERC1155 Token Collection Symbol
    function symbol() public view virtual returns (string memory) {
        return "TeamNFT";
    }

    function nftData(
        uint256 tokenId
    )
        external
        view
        virtual
        returns (
            string memory sport,
            string memory seriesName,
            string memory cityName,
            string memory teamName,
            string memory color1,
            string memory color2
        )
    {
        (
            sport,
            seriesName,
            cityName,
            teamName,
            color1,
            color2
        ) = _teamNftManager.nftData(tokenId);
    }

    /// @dev ERC721 formatted tokenURI
    /// @param tokenId The tokenId to get the URI of
    /// @return The complete URI of the token
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(
            exists(tokenId),
            "Function created for compatibility with ERC721, tokenId must exist. See uri(tokenId) for ERC1155"
        );

        if (onChainMetadata) {
            return _teamNftRenderer.render(tokenId);
        } else {
            return
                string(
                    abi.encodePacked(
                        "https://api.teamtoken.com/metadata/",
                        addLeadingZerosToUint(tokenId),
                        ".json"
                    )
                );
        }
    }

    /// @dev uri function override for checking if NFT Renderer is set
    /// @param tokenId tokenId to get URI for.
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (onChainMetadata) {
            return _teamNftRenderer.render(tokenId);
        } else {
            return super.uri(tokenId);
        }
    }

    /// @dev URI of the collection metadata
    /// @return The complete URI of the collection metadata
    function contractURI() public view returns (string memory) {
        if (onChainMetadata) {
            return _teamNftRenderer.contractURI();
        } else {
            return "https://api.teamtoken.com/metadata/teamnft.json";
        }
    }

    /// @dev Mint batch of tokens.  Only callable by owner.
    /// @param to The account to mint the tokens to
    /// @param ids The tokenId(s) to mint.
    /// @param amounts The amount of tokens to mint.
    /// @param data Data bytes to pass if receiving address is contract.
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwnerOrTeamNFTManager {
        uint256 length = ids.length;
        require(length == amounts.length, "IDs must be same length as amounts");
        for (uint256 i = 0; i < length; i++) {
            require(totalSupply(ids[i]) == 0, "Token ID already exists");
        }
        _mintBatch(to, ids, amounts, data);
    }

    /// @dev Mint tokens.  Only callable by owner.
    /// @param account The account to mint the tokens to
    /// @param id The tokenId to mint.
    /// @param amount The amount of tokens to mint.
    /// @param data Data bytes to pass if receiving address is contract.
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwnerOrTeamNFTManager {
        // Do not all mint if token already exists
        require(totalSupply(id) == 0, "Do not mint if token already exists");
        _mint(account, id, amount, data);
    }

    /// @dev How many unique owners of a certain tokenId
    /// @param tokenId The tokenId to see how many unique owners.
    /// @return The number of unique owners
    function ownersOfTokenId(
        uint256 tokenId
    ) public view virtual returns (uint256) {
        require(exists(tokenId), "Token must exist");
        return _ownersOfTokenId[tokenId];
    }

    /// @dev Convenience function to return all owners of tokenId
    /// including the balance of each.
    /// @param tokenId The tokenId to check owners with balances.
    /// @return An array of owners with balances.
    function allOwnersWithBalances(
        uint256 tokenId
    ) public view returns (OwnersBalances[] memory) {
        uint256 tokenOwners = _ownersOfTokenId[tokenId];
        OwnersBalances[] memory ownersBalances = new OwnersBalances[](
            tokenOwners
        );

        for (uint256 i = 0; i < tokenOwners; i++) {
            address account = ownerOfTokenByIndex(tokenId, i);
            ownersBalances[i] = OwnersBalances({
                account: account,
                balance: balanceOf(account, tokenId)
            });
        }

        return (ownersBalances);
    }

    /// @dev Total number of unique tokens.
    /// @return Number of unique tokens.
    function totalTokenIds() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /// @dev Retrieve the owners of a certain token, by their index.
    /// @param tokenId The tokenId to retrieve the owners of.
    /// @param index The index of which owner to retrieve.
    /// @return The owner at particular index of tokenId.
    function ownerOfTokenByIndex(
        uint256 tokenId,
        uint256 index
    ) public view virtual returns (address) {
        require(
            index < ownersOfTokenId(tokenId),
            "ERC1155Enumerable: owner index out of bounds"
        );
        return _tokenOwners[tokenId][index];
    }

    /// @dev Retrieve the tokenId from the list of all tokenIds.
    /// @param index The index of which tokenId to retrieve.
    /// @return The tokenId at a particular index
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(
            index < totalTokenIds(),
            "ERC1155Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /// @dev Function to set defaul royalty metadata.
    /// @param _account The wallet address/account which should receive royalties.
    /// @param _feeNumerator The royalty fee. Should be in basis points, or percent expressed at amount out of 10,000.
    function setRoyaltyMetadata(
        address _account,
        uint96 _feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(_account, _feeNumerator);
    }

    /// @dev Internal function to create a 64 character string, padded with leading zeros.
    /// @param input Uint256 to be converted into a 64 character long string.
    /// @return A 64 character long string, padded with leading zeros
    function addLeadingZerosToUint(
        uint256 input
    ) internal pure returns (string memory) {
        uint256 length = MathUpgradeable.log10(input) + 1;
        string memory returnString = new string(64 - length);
        bytes memory byteString = bytes(returnString);
        for (uint i = 0; i < 64 - length; i++) {
            byteString[i] = "0";
        }
        return
            string(
                abi.encodePacked(
                    string(byteString),
                    StringsUpgradeable.toString(input)
                )
            );
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override(ERC1155Upgradeable) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.

        if (openseaProxyRegistryAddress != address(0)) {
            IOpenseaProxyRegistry proxyRegistry = IOpenseaProxyRegistry(
                openseaProxyRegistryAddress
            );
            if (address(proxyRegistry.proxies(account)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(account, operator);
    }

    /**
     * @dev Returns false is msgSender is not teamNFT Contract
     */
    function _checkSenderIsTeamNFTManager() private view returns (bool result) {
        if (address(_teamNftManager) != address(0)) {
            result = address(_teamNftManager) == _msgSender() ? true : false;
        }
    }

    /**
     * @dev Returns false is msgSender is not Owner
     */
    function _checkSenderIsOwner() private view returns (bool result) {
        result = owner() == _msgSender() ? true : false;
    }

    /**
     * @dev Private function to add an owner to this tokenIds tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        // Only add owner if they don't currently have this tokenId
        if (balanceOf(to, tokenId) == 0) {
            uint256 length = _ownersOfTokenId[tokenId];
            _tokenOwners[tokenId][length] = to;
            _tokensOwnedIndex[to] = length;

            // Increase the number of holders of this tokenId.
            _ownersOfTokenId[tokenId]++;
        }
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove an owner from this tokenId tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId,
        uint256 amount
    ) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        // We only remove the owner if the amount being transferred
        // is the same amount as what they currently hold.
        if (balanceOf(from, tokenId) == amount) {
            uint256 lastOwnerIndex = _ownersOfTokenId[tokenId] - 1;
            uint256 ownerIndex = _tokensOwnedIndex[from];

            // When the token to delete is the last token, the swap operation is unnecessary
            if (ownerIndex != lastOwnerIndex) {
                address lastOwner = _tokenOwners[tokenId][lastOwnerIndex];

                _tokenOwners[tokenId][ownerIndex] = lastOwner; // Move the last token to the slot of the to-delete token
                _tokensOwnedIndex[lastOwner] = ownerIndex; // Update the moved token's index
            }

            // Reduce the total owners of this tokenId
            _ownersOfTokenId[tokenId]--;

            // This also deletes the contents at the last position of the array
            delete _tokensOwnedIndex[from];
            delete _tokenOwners[tokenId][lastOwnerIndex];
        }
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 length = ids.length;
        if (from == address(0)) {
            for (uint256 i = 0; i < length; i++) {
                _addTokenToAllTokensEnumeration(ids[i]);
            }
        } else if (from != to) {
            for (uint256 i = 0; i < length; i++) {
                _removeTokenFromOwnerEnumeration(from, ids[i], amounts[i]);
            }
        }
        if (to == address(0)) {
            for (uint256 i = 0; i < length; i++) {
                if (amounts[i] == totalSupply(ids[i])) {
                    _removeTokenFromAllTokensEnumeration(ids[i]);
                }
            }
        } else if (to != from) {
            for (uint256 i = 0; i < length; i++) {
                _addTokenToOwnerEnumeration(to, ids[i]);
            }
        }
    }
}