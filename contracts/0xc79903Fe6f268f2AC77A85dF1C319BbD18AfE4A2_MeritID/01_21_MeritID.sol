// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "./interfaces/IMeritBurnableNFT.sol";

contract MeritID is ERC721Enumerable, AccessControlEnumerable, ERC2981 {
    using Strings for uint256;

    error OnlyMinterError();
    error OnlyAdminError();
    error NotBurnableError();
    error NotOwnerError();
    error MaxSupplyError();
    error NotTactileError();

    address public immutable NFT;
    uint256 public immutable maxSupply;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string internal baseTokenURI;
    bool public burnable = false;

    modifier onlyMinter {
        if(!hasRole(MINTER_ROLE, msg.sender)) {
            revert OnlyMinterError();
        }
        _;
    }

    modifier onlyAdmin {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert OnlyAdminError();
        }
        _;
    }

    /// @notice Constructor
    /// @param _name The name of the NFT
    /// @param _symbol Symbol aka ticker
    /// @param _baseTokenURI Prepends the tokenId for the tokenURI
    /// @param _NFT NFT to be burned
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _NFT,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        NFT = _NFT;
        maxSupply = _maxSupply;
    }

    /// @notice Mints an NFT. Only mints from burning Tactile NFTs
    /// @param _tokenId Id of the token
    /// @param _receiver Address receiving the NFT
    function tactileMint(uint256 _tokenId, address _receiver) external {
        // Owner approves, then transfers and this contracts burns it (Only owners can burn).
        IMeritBurnableNFT(NFT).safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    /// @notice Mints an NFT. Can only be called by an address with the minter role and tokenId must be unique
    /// @param _tokenId Id of the token
    /// @param _receiver Address receiving the NFT
    function mint(uint256 _tokenId, address _receiver) external onlyMinter {
        if (_tokenId > maxSupply) {
            revert MaxSupplyError();
        }
        _mint(_receiver, _tokenId);
    }

    /// @notice Burns an NFT. Can only be called by the owner if burning is activated.
    /// @param _tokenId Id of the token
    function burn(uint256 _tokenId) external {
        if (!burnable) {
            revert NotBurnableError();
        }
        if (msg.sender != ownerOf(_tokenId)) {
            revert NotOwnerError();
        }

        _burn(_tokenId);
    }

    /// @notice Sets the burnable variable.
    /// @param _burnable If the NFT is burnable or not.
    function setBurnable(bool _burnable) external onlyAdmin {
        burnable = _burnable;
    }

    /// @notice Required to receive ERC721 tokens.
    function onERC721Received(address, address _from, uint256 _tokenId, bytes calldata) external returns (bytes4) {
        if (msg.sender != address(NFT)) {
            revert NotTactileError();
        }
        if (IMeritBurnableNFT(NFT).ownerOf(_tokenId) != address(this)) {
            revert NotOwnerError();
        }
        IMeritBurnableNFT(NFT).burn(_tokenId);
        _mint(_from, _tokenId);
        return this.onERC721Received.selector;
    }
    
    /// @notice Sets the receiver and fee info
    /// @param _receiver Address that receives the fees
    /// @param _feeNumerator Basis points of the fee to be received
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyAdmin {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
    
    /// @notice Sets the base token URI. Can only be called by an address with the default admin role
    /// @param _newBaseURI New baseURI
    function setBaseURI(string memory _newBaseURI) external onlyAdmin {
        baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice returns the baseURI
    /// @return The tokenURI
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /// @notice Signals support for a given interface
    /// @param interfaceId 4bytes signature of the interface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, AccessControlEnumerable, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
}