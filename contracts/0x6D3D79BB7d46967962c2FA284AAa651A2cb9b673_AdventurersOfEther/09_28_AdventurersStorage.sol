// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract AdventurersStorage is
    Ownable,
    ERC721("Adventurers Of Ether", "KOE"),
    ERC2981,
    IERC721Enumerable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 internal MAX_SUPPLY = 6001; // +1 extra 1 for <
    uint256 public maxSupply = 3001;

    event Minted(address to, uint256 amount);

    /// @notice Address of the receiver of the smart contract funds.
    address payable public treasury;

    /// @notice The suffix to use at the end of the baseTokenURI.
    string internal _uriSuffix;

    string internal _contractURI;

    /// @notice The Base uri string for these tokens.
    string internal _baseTokenURI;

    /// @notice The internal condition is used to validate if the { whitelist } feature is active.
    bool internal mintSelectedActive;

    string internal constant _MerkleLeafMatchError = "Don't match Merkle leaf";
    string internal constant _MerkleLeafValidationError =
        "Not a valid Merkle Leaf";
    string internal constant _RemainingAllocationError =
        "Can't mint more than remaining allocation";

    /// @notice Thrown by { transferToTreasury } method if the treasury address is a zero address.
    error NoZeroAddress();

    error NoZeroValues();

    /// @notice Thrown by { transferToTreasury } method if the transaction fails.
    error TreasuryError();

    /// @dev Emitted with a message.
    /// @param message The error message.
    error ErrorMessage(string message);

    /// @notice Thrown by { tierChecks } modifier if the msg.value is to low.
    /// @param sent Is the transacted value.
    /// @param expected Is the expected value.
    error ErrorPrice(uint256 sent, uint256 expected);

    /// @notice Emitted when the MaxSupply has been adjusted.
    /// @param maxSupply The new maxSupply set for this contract.
    event SetMaxSupply(uint256 maxSupply);

    /// @notice Emitted when the Treasury address has been adjusted.
    /// @param treasury The new Treasury address.
    event TreasurySet(address treasury);

    /// @notice Emitted when the default royalty data has been adjusted.
    /// @param receiver The new Royalty receiver address.
    /// @param feeNumerator The new Royalty amount. Example: 750 is equal to 7.5%
    event UpdatedDefaultRoyalty(
        address indexed receiver,
        uint96 indexed feeNumerator
    );

    /// @notice Emitted when the royalty data of a given token has been adjusted.
    /// @param tokenId The tokenId of the token.
    /// @param receiver The new Royalty receiver address.
    /// @param feeNumerator The new Royalty amount. Example: 750 is equal to 7.5%
    event UpdatedTokenRoyalty(
        uint256 indexed tokenId,
        address indexed receiver,
        uint96 indexed feeNumerator
    );

    /// @notice Emmited when a new whitelisted account mint a new token.
    /// @param account Indexed - The address of the minter.
    /// @param amount The amount minted.
    event MintSelected(address indexed account, uint256 amount);

    /* ------------------------------------------------------------  ADMIN ROYALTY FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Adjust the royalty data of a given token id {will override default royalty for this contact}.
    /// @dev Restricted to onlyOwner.
    /// @param tokenId The id of the token.
    /// @param receiver The account to receive the royalty amount.
    /// @param feeNumerator The royalty amount in BIPS. example: 750 is 7,5%.
    function setTokenRoyalty(
        uint256 tokenId,
        address payable receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);

        emit UpdatedTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @notice Adjust the current default royalty data.
    /// @dev Restricted to onlyOwner.
    /// @param receiver The account to receive the royalty amount.
    /// @param feeNumerator The royalty amount in BIPS. example: 750 is 7,5%.
    function setDefaultRoyalty(
        address payable receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
        emit UpdatedDefaultRoyalty(receiver, feeNumerator);
    }

    /// @notice Method is used by openSea to read contract information.
    /// @dev Go to { https://docs.opensea.io/docs/contract-level-metadata } to learn more about this method.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Method is used to adjust the baseTokenURI.
    /// @param baseTokenURI The new baseTokenUri to use.
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /// @notice Method is used to adjust the baseTokenURI suffix.
    /// @param suffix The suffix to use at the end of the baseTokenURI.
    function setSuffix(string memory suffix) external onlyOwner {
        _uriSuffix = suffix;
    }

    /// @notice Function is used to adjust the maxSupply variable.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _maxSupply The new max supply amount.
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < MAX_SUPPLY, "max supply exceeded");
        maxSupply = _maxSupply;

        emit SetMaxSupply(maxSupply);
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        MAX_SUPPLY = _totalSupply;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(ERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function _mint(address _to, uint256 _amount) internal override {
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIdTracker.increment();
            super._mint(_to, _tokenIdTracker.current());
        }

        emit Minted(_to, _tokenIdTracker.current());
    }

    function mintBatch(address[] memory to, uint256[] memory amount) external onlyOwner {
        for (uint256 i; i < to.length; i++) {
            _mint(to[i], amount[i]);
        }
    }



    function totalSupply() external view override returns (uint256) {}

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view override returns (uint256) {}

    function tokenByIndex(
        uint256 index
    ) external view override returns (uint256) {}
}