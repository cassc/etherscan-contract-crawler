// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IWasabiPool.sol";
import "./IWasabiPoolFactory.sol";
import "./fees/IWasabiFeeManager.sol";

/**
 * @dev An ERC721 which tracks Wasabi Option positions of accounts
 */
contract WasabiOption is ERC721, IERC2981, Ownable {
    
    address private lastFactory;
    mapping(address => bool) private factoryAddresses;
    mapping(uint256 => address) private optionPools;
    uint256 private _currentId = 1;
    string private _baseURIextended;

    /**
     * @dev Constructs WasabiOption
     */
    constructor() ERC721("Wasabi Option NFTs", "WASAB") {}

    /**
     * @dev Toggles the owning factory
     */
    function toggleFactory(address _factory, bool _enabled) external onlyOwner {
        factoryAddresses[_factory] = _enabled;
        if (_enabled) {
            lastFactory = _factory;
        }
    }

    /**
     * @dev Mints a new WasabiOption
     */
    function mint(address _to, address _factory) external returns (uint256 mintedId) {
        require(factoryAddresses[_factory] == true, "Invalid Factory");
        require(IWasabiPoolFactory(_factory).isValidPool(_msgSender()), "Only valid pools can mint");

        _safeMint(_to, _currentId);
        mintedId = _currentId;
        optionPools[mintedId] = _msgSender();
        _currentId++;
    }

    /**
     * @dev Burns the specified option
     */
    function burn(uint256 _optionId) external {
        require(optionPools[_optionId] == _msgSender(), "Caller can't burn option");
        _burn(_optionId);
    }

    /**
     * @dev Sets the base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev Returns the address of the pool which created the given option
     */
    function getPool(uint256 _optionId) external view returns (address) {
        return optionPools[_optionId];
    }
    
    /// @inheritdoc ERC721
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256) {
        IWasabiPool pool = IWasabiPool(optionPools[_tokenId]);
        IWasabiPoolFactory factory = IWasabiPoolFactory(pool.getFactory());
        IWasabiFeeManager feeManager = IWasabiFeeManager(factory.getFeeManager());
        return feeManager.getFeeDataForOption(_tokenId, _salePrice);
    }
    
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}