// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721WithPermitUpgradable.sol";
import "./interfaces/IDeNFT.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DeNFT is ERC721WithPermitUpgradable, OwnableUpgradeable, IDeNFT {
    using StringsUpgradeable for uint256;

    /* ========== STATE VARIABLES ========== */

    /// @dev DeNftBridge contract who deployed this collection
    address public deNftBridge;

    /// @dev List of addresses who may call mint()/burn() methods of this contract
    ///      It is expected it has no duplicates
    address[] public minters;

    /// @notice See [ERC721URIStorageUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol)
    mapping(uint256 => string) private _tokenURIs;

    /// @dev Prefix for NFTs' URIs
    string private _baseURIValue;

    /* ========== ERRORS ========== */

    error AdminBadRole();
    error MinterBadRole();
    error ZeroAddress();
    error WrongLengthOfArguments();

    /* ========== MODIFIER ========== */

    modifier onlyMinter() {
        if (!hasMinterAccess(msg.sender)) revert AdminBadRole();
        _;
    }

    /* ========== EVENTS ========== */

    event MinterAdded(address minter);
    event MinterRemoved(address minter);

    /* ========== CONSTRUCTOR  ========== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address[] memory _minters,
        address _deNftBridge,
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) public initializer {
        if (_deNftBridge == address(0)) revert ZeroAddress();
        __ERC721WithPermitUpgradable_init(name_, symbol_);
        __DeNFT_init_unchained(owner_, _minters, _deNftBridge, baseURI_);
    }

    function __DeNFT_init_unchained(
        address owner_,
        address[] memory _minters,
        address _deNftBridge,
        string memory baseURI_
    ) internal initializer {
        _baseURIValue = baseURI_;
        deNftBridge = _deNftBridge;

        // avoid duplicates in the minters array
        for (uint256 i = 0; i < _minters.length; ++i) {
            _addMinter(_minters[i]);
        }
        // couldn't call __Ownable_init() here, because msg.sender will become an owner
        _transferOwnership(owner_);
    }

    /* ========== MINTER METHODS  ========== */

    /// @dev Mints a new token and transfers it to `to` address
    /// @param _to new token's owner
    /// @param _tokenId new token's id
    /// @param _tokenUri new token's URI
    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenUri
    ) external override onlyMinter {
        _tokenURIs[_tokenId] = _tokenUri;
        _safeMint(_to, _tokenId);
    }

    /// @dev Mints multiple tokens sequentially in a single call, taking each token's ID and URI
    ///      from the given arrays correspondingly, and transfers each token to the `msg.sender`
    function mintMany(uint256[] memory _tokenIds, string[] memory _tokenUris)
        external
        override
        onlyMinter
    {
        mintMany(msg.sender, _tokenIds, _tokenUris);
    }

    /// @dev Mints multiple tokens sequentially in a single call, taking each object's ID and URI
    ///      from the given arrays correspondingly, and transfers each token to the given `_to` recipient
    function mintMany(
        address _to,
        uint256[] memory _tokenIds,
        string[] memory _tokenUris
    ) public override onlyMinter {
        if (_tokenIds.length != _tokenUris.length) revert WrongLengthOfArguments();

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            _tokenURIs[tokenId] = _tokenUris[i];
            _safeMint(_to, tokenId);
        }
    }

    /// @dev Mints multiple tokens sequentially in a single call, taking each object's owner, ID and URI
    ///      from the given arrays correspondingly, and transfers each token to the corresponding owner's address
    function mintMany(
        address[] memory _to,
        uint256[] memory _tokenIds,
        string[] memory _tokenUris
    ) external override onlyMinter {
        if (_tokenIds.length != _to.length || _tokenIds.length != _tokenUris.length)
            revert WrongLengthOfArguments();

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            uint256 tokenId = _tokenIds[i];
            _tokenURIs[tokenId] = _tokenUris[i];
            _safeMint(_to[i], tokenId);
        }
    }

    /// @dev Destroys a token identified by the `_tokenId`. See `ERC721Upgradeable._burn()`
    ///      Only addresses listed in the minters array may burn objects, and only if
    ///      the object holder has given explicit approval to the minter
    /// @notice Portions of code have been ported from
    ///         [ERC721BurnableUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Burnable.sol)
    ///         and [ERC721URIStorageUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol)
    function burn(uint256 _tokenId) public virtual override onlyMinter {
        // code ported from @openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );

        _burn(_tokenId);

        // code ported from @openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol
        if (bytes(_tokenURIs[_tokenId]).length != 0) {
            delete _tokenURIs[_tokenId];
        }
    }

    /* ========== OWNER METHODS  ========== */

    function addMinter(address _minter) external override onlyOwner {
        _addMinter(_minter);
    }

    function revokeMinter(address _minter) external override onlyOwner {
        for (uint256 i = 0; i < minters.length; ++i) {
            if (minters[i] == _minter) {
                address oldMinter = minters[i];
                minters[i] = minters[minters.length - 1];
                minters.pop();
                emit MinterRemoved(oldMinter);

                // addresses are unique in the minters array, as per addMinter()
                return;
            }
        }
    }

    /// @dev This method revokes owner and all registered minters, leaving only the DeNftBridge
    ///      as a minter, which is necessary to burn/mint objects which travel across chains
    function revokeOwnerAndMinters() external override onlyOwner {
        // clear minter array
        uint256 count = minters.length;
        for (uint256 i = 0; i < count; ++i) {
            minters.pop();
        }
        // add deNftBridge to minters
        minters.push(deNftBridge);
        renounceOwnership();
    }

    /* ========== VIEWS  ========== */

    function exists(uint256 tokenId) public view override returns (bool) {
        return _exists(tokenId);
    }

    function hasMinterAccess(address sender) public view override returns (bool hasAccess) {
        for (uint256 i = 0; i < minters.length; ++i) {
            if (minters[i] == sender) {
                return true;
            }
        }
        return false;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    /// @inheritdoc IERC721MetadataUpgradeable
    /// @notice Implementation has been ported from OpenZeppelin's ERC721URIStorageUpgradeable
    ///         (see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol)
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function getMintersLength() public view returns (uint256) {
        return minters.length;
    }

    /* ========== INTERNAL ========== */

    function _addMinter(address _minter) internal returns (bool) {
        // avoid duplicates
        if (hasMinterAccess(_minter)) {
            return false;
        }

        minters.push(_minter);
        emit MinterAdded(_minter);

        return true;
    }
}