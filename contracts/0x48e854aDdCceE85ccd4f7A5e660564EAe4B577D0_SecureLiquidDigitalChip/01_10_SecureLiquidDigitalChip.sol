// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title Secure Liquid Digital Chip
/// @notice The research facility for SLD chips.
contract SecureLiquidDigitalChip is ERC1155, Ownable {

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event UpdateURI(string indexed _uri);
    event UpdateMinter(address indexed _minter, bool _value);
    event UpdateBurner(address indexed _burner, bool _value);

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    /// @notice Throws if called by any account other than a minter.
    modifier onlyMinter() {
        require(minters[msg.sender], 'cannot mint');
        _;
    }

    /// @notice Throws if called by any account other than a burner.
    modifier onlyBurner() {
        require(burners[msg.sender], 'cannot burn');
        _;
    }

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice The name of the token.
    string public constant name = 'Secure Liquid Digital Chip';
    
    /// @notice The symbol of the token.
    string public constant symbol = 'SLD';

    /// @notice Stores info pretaining to whether an account can mint cybernetics.
    /// @dev address => can mint
    mapping(address => bool) public minters;

    /// @notice Stores info pretaining to whether an account can burn cybernetics.
    /// @dev address => can burn
    mapping(address => bool) public burners;

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    constructor(string memory _uri) ERC1155(_uri) {
        emit UpdateURI(_uri);
    }

    /// -----------------------------------------------------------------------
    /// Actions
    /// -----------------------------------------------------------------------

    /// @notice Mints cybernetics of a single type per recipient. Only callable by a minter.
    /// @param recipients The recipients of the minted cybernetics.
    /// @param ids The types of cybernetics to mint.
    /// @param amounts The amounts of cybernetics to mint.
    function mint(address[] memory recipients, uint256[] memory ids, uint256[] memory amounts)
        external
        onlyMinter
    {
        uint256 length = recipients.length;
        for (uint256 i; i < length;) {
            _mint(recipients[i], ids[i], amounts[i], '');
            unchecked { ++i; }
        }
    }

    /// @notice Mints batches of cybernetics per recipient. Only callable by a minter.
    /// @param recipients The recipients of the minted cybernetics.
    /// @param ids The types of cybernetics to mint per batch.
    /// @param amounts The amounts of cybernetics to mint per batch.
    function mintBatch(address[] memory recipients, uint256[][] memory ids, uint256[][] memory amounts)
        external
        onlyMinter
    {
        uint256 length = recipients.length;
        for (uint256 i; i < length;) {
            _mintBatch(recipients[i], ids[i], amounts[i], '');
            unchecked { ++i; }
        }
    }

    /// @notice Burns a batch of cybernetics from single account. Only callable by a burner.
    /// @param account The owner of the cybernetics to burn.
    /// @param ids The types of cybernetics to burn.
    /// @param amounts The amounts of cybernetics to burn.
    function burn(address account, uint256[] memory ids, uint256[] memory amounts)
        external
        onlyBurner
    {
        _burnBatch(account, ids, amounts);
    }

    /// @notice Burns batches of cybernetics from multiple accounts. Only callable by a burner.
    /// @param accounts The owners of the cybernetics to burn.
    /// @param ids The types of cybernetics to burn.
    /// @param amounts The amounts of cybernetics to burn.
    function burnBatch(address[] memory accounts, uint256[][] memory ids, uint256[][] memory amounts)
        external
        onlyBurner
    {
        uint256 length = accounts.length;
        for (uint256 i; i < length;) {
            _burnBatch(accounts[i], ids[i], amounts[i]);
            unchecked { ++i; }
        }
    }

    /// -----------------------------------------------------------------------
    /// Setters
    /// -----------------------------------------------------------------------

    /// @notice Sets a new URI for all token types. Only callable by the owner.
    /// @param _newURI The new URI.
    function updateUri(string memory _newURI) external onlyOwner {
        _setURI(_newURI);
        emit UpdateURI(_newURI);
    }

    /// @notice Whitelists a minter account. Only callable by the owner.
    /// @param _minter The new minter account.
    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
        emit UpdateMinter(_minter, true);
    }

    /// @notice Deprecates a minter account. Only callable by the owner.
    /// @param _minter The old minter account.
    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
        emit UpdateMinter(_minter, false);
    }

    /// @notice Whitelists a burner account. Only callable by the owner.
    /// @param _burner The new burner account.
    function addBurner(address _burner) external onlyOwner {
        burners[_burner] = true;
        emit UpdateBurner(_burner, true);
    }

    /// @notice Deprecates a burner account. Only callable by the owner.
    /// @param _burner The old burner account.
    function removeBurner(address _burner) external onlyOwner {
        burners[_burner] = false;
        emit UpdateBurner(_burner, false);
    }
}