// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

contract Astrobot is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable
{
    uint256 public airdropSupply;
    uint256 public maxSupply;
    uint256 public saleSupply;
    uint256 public saleMinted;
    uint256 public airdropMinted;

    bool public airdropState;

    mapping(address => uint256) public userAirdropMints;
    mapping(address => bool) public userWhitelisted;

    address public saleContract;

    string private _baseURIValue;

    // New mapping for blacklisted user.
    mapping(address => bool) public blacklisted;

    // Events emitted.

    event setBaseURIEvent(string indexed newBaseURI);
    event SaleMinted(address indexed _user, uint256 indexed _quantity);
    event AirdropWhitelisted(address indexed _user, uint256 indexed _quantity);
    event AirdropClaimed(address indexed _user, uint256 indexed _quantity);
    event AirdropStateUpdated(bool indexed _newState);
    event AddressBlacklisted(address indexed _user, bool indexed _status);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize function use in place of constructor function.
     */

    function initialize(
        uint256 _maxSupply,
        uint256 _airdropSupply,
        string memory _name,
        string memory _symbol
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __ERC721AQueryable_init();
        __Pausable_init();
        __Ownable_init();
        airdropSupply = _airdropSupply;
        maxSupply = _maxSupply;
        saleSupply = maxSupply - airdropSupply;
    }

    /**
     * @notice Pause Contract
     *
     * @dev Only owner can call this function.
     */

    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Un-pause Contract
     *
     * @dev Only owner can call this function.
     */

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Internal function to view base URI. This will be used internally by NFT library.
     */

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    /**
     * @notice View Base URI
     *
     * @dev External funciton to view base URI.
     */

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @notice Set Base URI
     *
     * @dev Update base uri for contract. Only owner can call this function.
     * @param newBase New base uri.
     */

    function setBaseURI(string memory newBase) external onlyOwner {
        _baseURIValue = newBase;
        emit setBaseURIEvent(newBase);
    }

    /**
     * @notice Update Sale Contract Address
     *
     * @dev Update sale contract address. Only owner can call this function.
     * @param _saleContract Sale contract address.
     */

    function updateSaleContract(address _saleContract) external onlyOwner {
        require(_saleContract != address(0), "Zero address");
        saleContract = _saleContract;
    }

    /**
     * @notice Mint Tokens
     *
     * @dev Mint new token. Only sale contract can call this function.
     * @param _user Address to mint token.
     * @param quantity Number of tokens to mint.
     */

    function mint(address _user, uint256 quantity) external whenNotPaused {
        require(saleSupply >= saleMinted + quantity, "mint: Sale completed");
        require(
            msg.sender == saleContract,
            "mint: Caller is not sale contract"
        );
        saleMinted = saleMinted + quantity;
        _mint(_user, quantity);
        emit SaleMinted(_user, quantity);
    }

    /**
     * @notice Update airdrop addresses.
     *
     * @dev Update airdrop whitelisted addresss. Only owner can call this function.
     * @param _addresses Address to mint token.
     * @param _quantity Number of tokens to mint.
     */
    function updateAirdropAddresses(
        address[] memory _addresses,
        uint256[] memory _quantity
    ) external onlyOwner {
        require(
            _addresses.length == _quantity.length,
            "update: Incorrect configuration"
        );
        require(
            _addresses.length <= 250,
            "update: airdrop size cannot be more than 250"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            userAirdropMints[_addresses[i]] = _quantity[i];
            userWhitelisted[_addresses[i]] = true;
            emit AirdropWhitelisted(_addresses[i], _quantity[i]);
        }
    }

    /**
     * @notice Update airdrop state.
     *
     * @dev Enable or disable airdrop claim by setting state. Only owner can call this function.
     * @param _newState Boolean value for state.Pass true to enable aridrop claim and false to disable.
     */
    function updateAirdropState(bool _newState) external onlyOwner {
        airdropState = _newState;
        emit AirdropStateUpdated(_newState);
    }

    /**
     * @notice Claim Airdrop Tokens
     *
     * @dev Claim token for airdrop. Only user whitelisted for airdrop can call this function.
     */

    function airdropClaim() external whenNotPaused {
        require(airdropState, "claim: Disabled");
        require(
            airdropSupply >= airdropMinted + userAirdropMints[msg.sender],
            "claim: All minted"
        );
        require(userWhitelisted[msg.sender], "claim: User cannot claim");
        airdropMinted = airdropMinted + userAirdropMints[msg.sender];
        userWhitelisted[msg.sender] = false;
        _mint(msg.sender, userAirdropMints[msg.sender]);
        emit AirdropClaimed(msg.sender, userAirdropMints[msg.sender]);
    }

    /**
     * @dev Authorize transfer of token. Transaction will be reverted if token is paused.
     */

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        require(!blacklisted[from], "Blacklisted address");
        require(!blacklisted[to], "Blacklisted address");
        require(!blacklisted[msg.sender], "Blacklisted address");

        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    /**
     * @dev Authorize upgradation of token. Transaction will be reverted if non owner tries to upgrade.
     */

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Blacklist user addresses.
     */
    function blackListAddresses(
        address[] memory _addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklisted[_addresses[i]] = true;
            emit AddressBlacklisted(_addresses[i], true);
        }
    }

    /**
     * @dev Remove addresses from blacklist.
     */
    function removeBlackListAddresses(
        address[] memory _addresses
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            blacklisted[_addresses[i]] = false;
            emit AddressBlacklisted(_addresses[i], false);
        }
    }
}