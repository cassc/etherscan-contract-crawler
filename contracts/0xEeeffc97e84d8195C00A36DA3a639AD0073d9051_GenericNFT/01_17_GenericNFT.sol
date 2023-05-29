// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IGenericMintableNFT.sol";

contract GenericNFT is ERC721A, AccessControlEnumerable, IGenericMintableNFT {
    using Strings for uint256;

    error OnlyMinterError();
    error OnlyAdminError();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string internal baseTokenURI;
    string internal contractLevelURI;

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
    /// @param _contractURI contract info uri
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        string memory _contractURI
    ) ERC721A(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        contractLevelURI = _contractURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


    /// @notice Mints an NFT. Can only be called by an address with the minter role and tokenId must be unique
    /// @param _quantity amount to mint
    function mint(uint256 _quantity, address _receiver) external override onlyMinter {
        _safeMint(_receiver, _quantity);
    }

    /// @notice Returns amount minted by the owner
    /// @param _owner owner
    function numberMinted(address _owner) external override view returns (uint256){
        return _numberMinted(_owner);
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
        override(ERC721A, AccessControlEnumerable)
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

    function setContractURI(string memory _newContractLevelURI) external onlyAdmin {
        contractLevelURI = _newContractLevelURI;
    }

    function contractURI() public view returns (string memory) {
        return contractLevelURI;
    }

    function totalMinted() external view returns (uint256) {
        return totalSupply();
    }
}