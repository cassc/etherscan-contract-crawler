pragma solidity >=0.4.22 <0.9.0;

import {Errors} from "../libraries/helpers/Errors.sol";
import {SettingStorage} from "../libraries/proxy/SettingStorage.sol";
import {OwnableUpgradeable} from "../libraries/openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
import {ISettings} from "../interfaces/ISettings.sol";
import {IVault} from "../interfaces/IVault.sol";
import {ERC721Upgradeable} from "../libraries/openzeppelin/upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from "../libraries/openzeppelin/upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {StringsUpgradeable} from "../libraries/openzeppelin/upgradeable/utils/StringsUpgradeable.sol";

contract TokenVaultBnft is
    SettingStorage,
    OwnableUpgradeable,
    ERC721Upgradeable
{
    using StringsUpgradeable for address;
    using StringsUpgradeable for uint256;
    //
    address public vaultToken;
    /// @notice  gap for reserve, minus 1 if use
    uint256[10] public __gapUint256;
    /// @notice  gap for reserve, minus 1 if use
    uint256[5] public __gapAddress;

    //
    constructor(address _settings) SettingStorage(_settings) {}

    function initialize(
        address _vaultToken,
        string memory name,
        string memory symbol
    ) public initializer {
        __Ownable_init();
        __ERC721_init(name, symbol);
        // update data
        require(_vaultToken != address(0), "no zero address");
        vaultToken = _vaultToken;
    }

    function _getVault() internal view returns (IVault) {
        return IVault(vaultToken);
    }

    modifier onlyStaking() {
        require(
            _getVault().staking() == _msgSender(),
            Errors.VAULT_NOT_STAKING
        );
        _;
    }

    function tokenIdOf(address user) public view virtual returns (uint256) {
        uint256 tokenId = uint256(uint160(user));
        _requireMinted(tokenId);
        return tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory bnftURI = ISettings(settings).bnftURI();
        IVault vault = _getVault();
        return
            bytes(bnftURI).length > 0
                ? string(
                    abi.encodePacked(
                        bnftURI,
                        address(vault).toHexString(),
                        "/",
                        tokenId.toString(),
                        ".json"
                    )
                )
                : IERC721MetadataUpgradeable(vault.listTokens(0)).tokenURI(
                    vault.listIds(0)
                );
    }

    // untransferable

    function approve(address to, uint256 tokenId) public virtual override {
        revert("not allow");
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        revert("not allow");
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("not allow");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("not allow");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        revert("not allow");
    }

    //

    function mintToUser(address user) external onlyStaking returns (uint256) {
        uint256 tokenId = uint256(uint160(user));
        if (!_exists(tokenId)) {
            _mint(user, tokenId);
        }
        return tokenId;
    }

    function burnFromUser(address user) external onlyStaking returns (uint256) {
        uint256 tokenId = uint256(uint160(user));
        if (_exists(tokenId)) {
            _burn(tokenId);
        }
        return tokenId;
    }
}