// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';

contract Ey3k0nComicERC721a is
    ERC721AUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public maxSupply;
    string public baseURI;
    EnumerableSet.AddressSet internal minterList;

    /**
     * The caller must be a minter
     */
    error CallerNotMinter();

    /**
     * @notice Enforces sender to be a minter
     */
    modifier onlyMiner() {
        if(!minterList.contains(msg.sender)) revert CallerNotMinter();
        _;
    }

    /**
     * @notice instantiates contract
     * @param _name             the name of the token
     * @param _symbol           the symbol of the token
     * @param _initialBaseURI   the baseURI of the token
     * @param _maxSupply        the maximum number of tokens that can be minted
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _initialBaseURI,
        uint256 _maxSupply
    ) external initializerERC721A initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC721A_init(_name, _symbol);

        maxSupply = _maxSupply;
        baseURI = _initialBaseURI;
    }

    /**
     * @notice Returns the address of minter communityList
     *
     * @param _index index of the minter
     * @return address of the community
     */
    function minterListAt(uint256 _index) external view returns (address) {
        return minterList.at(_index);
    }

    /**
     * @notice Returns the number of minters
     *
     * @return uint256 number of minters
     */
    function minterListLength() external view returns (uint256) {
        return minterList.length();
    }

    /**
     * @notice Returns if an address is a minter
     *
     * @param _minterAddress address to verify
     * @return bool true if the address is a minter
     */
    function isMinter(address _minterAddress) external view returns (bool) {
        return minterList.contains(_minterAddress);
    }

    /**
     * @notice updates the max supply value
     * @param _newMaxSupply   the maximum number of tokens that can be minted
     */
    function updateMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(_newMaxSupply >= totalSupply(), 'maxSupply cannot be less than totalSupply');
        maxSupply = _newMaxSupply;
    }

    /**
     * @notice enables owner to pause / unpause minting
     * @param _paused   true / false for pausing / unpausing minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /**
     * @notice enables an address to mint
     * @param _minter the address to enable
     */
    function addMinter(address _minter) external onlyOwner {
        minterList.add(_minter);
    }

    /**
     * @notice disables an address from minting
     * @param _minter the address to disable
     */
    function removeMinter(address _minter) external onlyOwner {
        minterList.remove(_minter);
    }

    /**
     * @notice mints a new ERC721
     *
     * @param _recipient address to mint the token to
     * @param _amount number of tokens to be minted
     */
    function mint(address _recipient, uint256 _amount) public whenNotPaused onlyMiner {
        require(
            maxSupply >= totalSupply() + _amount,
            "Minted tokens would exceed max supply"
        );

        _mint(_recipient, _amount);
    }

    /**
     * @notice mints a new ERC721
     *
     * @param _recipients addresses to mint the token to
     * @param _amount number of tokens to be minted
     */
    function mintBulk(address[] calldata _recipients, uint256 _amount) public whenNotPaused onlyMiner {
        uint256 _length = _recipients.length;


        require(
            maxSupply >= totalSupply() + (_length * _amount),
            "Minted tokens would exceed max supply"
        );

        uint256 _index;
        while (_index < _length) {
            _mint(_recipients[_index], _amount);
            ++_index;
        }
    }

    /**
     * @notice sets the baseURI value to be returned by _baseURI() & tokenURI() methods.
     * @param _newBaseURI the new baseUri
     */
    function setBaseURI(string memory _newBaseURI) external virtual onlyOwner {
        baseURI = _newBaseURI;
    }

    /** INTERNAL */

    /**
     * @notice Implements the ERC721AUpgradeable._startTokenId function
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Implements the ERC721Upgradeable._baseURI empty function
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}