// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./interfaces/IERC20.sol";
import "./utils/UpgradeableAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Upgradeable ERC1155 Implementation
 *
 * @dev Open Zeppelin based ERC1155 implementation, supporting burning, minting
 *      and total supply tracking per token id
 *
 * @dev Based on Open Zeppelin ERC1155BurnableUpgradeable and ERC1155SupplyUpgradeable
 */
abstract contract UpgradeableERC1155 is Initializable, ERC1155SupplyUpgradeable, UpgradeableAccessControl {
    /**
     * @notice Enables ERC1155 transfers of the tokens
     *      (transfer by the token owner himself)
     * @dev Feature FEATURE_TRANSFERS must be enabled in order for
     *      `transferFrom()` function to succeed when executed by token owner
     */
    uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

    /**
     * @notice Enables ERC1155 transfers on behalf
     *      (transfer by someone else on behalf of token owner)
     * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
     *      `transferFrom()` function to succeed whe executed by approved operator
     * @dev Token owner must call `approve()` or `setApprovalForAll()`
     *      first to authorize the transfer on behalf
     */
    uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

    /**
     * @notice Enables token owners to burn their own tokens
     *
     * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
     *      `burn()` function to succeed when called by token owner
     */
    uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

    /**
     * @notice Enables approved operators to burn tokens on behalf of their owners
     *
     * @dev Feature FEATURE_BURNS_ON_BEHALF must be enabled in order for
     *      `burn()` function to succeed when called by approved operator
     */
    uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

    /**
     * @notice Token creator is responsible for creating (minting)
     *      tokens to an arbitrary address
     * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
     *      (calling `mint` function)
     */
    uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

    /**
     * @notice Token destroyer is responsible for destroying (burning)
     *      tokens owned by an arbitrary address
     * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
     *      (calling `burn` function)
     */
    uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

    /**
     * @notice URI manager is responsible for managing base URI
     *      part of the token URI ERC1155Metadata interface
     *
     * @dev Role ROLE_URI_MANAGER allows updating the base URI
     *      (executing `setBaseURI` function)
     */
    uint32 public constant ROLE_URI_MANAGER = 0x0004_0000;

    /**
     * @notice People do mistakes and may send ERC20 tokens by mistake; since
     *      NFT smart contract is not designed to accept and hold any ERC20 tokens,
     *      it allows the rescue manager to "rescue" such lost tokens
     *
     * @notice Rescue manager is responsible for "rescuing" ERC20 tokens accidentally
     *      sent to the smart contract
     *
     * @dev Role ROLE_RESCUE_MANAGER allows withdrawing any ERC20 tokens stored
     *      on the smart contract balance
     */
    uint32 public constant ROLE_RESCUE_MANAGER = 0x0008_0000;

    /**
     * @dev "Constructor replacement" for upgradeable, must be execute immediately after deployment
     *      see https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializers
     *
     * @param uri_ collection uri (ERC1155)
     * @param _owner smart contract owner having full privileges
     */
    function __UpgradeableERC1155_init(string memory uri_, address _owner) internal initializer {
        // execute all parent initializers in cascade
        __ERC1155_init(uri_);
        __ERC1155Supply_init_unchained();
        __AccessControl_init(_owner);
    }

    /**
     * @inheritdoc IERC165Upgradeable
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Restricted access function which updates base URI used to construct
     *      IERC1155MetadataURIUpgradeable.uri
     *
     * @dev Requires executor to have ROLE_URI_MANAGER permission
     *
     * @param newuri new URI to set
     */
    function setURI(string memory newuri) public virtual {
        // verify the access permission
        require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

        _setURI(newuri);
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `ROLE_TOKEN_CREATOR`.
     */
    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual {
        // check if caller has sufficient permissions to mint tokens
        require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

        // mint token - delegate to `_mint`
        _mint(_to, _id, _amount, _data);
    }

    /**
     * @dev Destroys the token with token ID specified
     *
     * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
     *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
     *
     * @dev Can be disabled by the contract creator forever by disabling
     *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
     *      its own roles to burn tokens and to enable burning features
     *
     * @param _from address to burn the token from
     * @param _id ID of the token to burn
     * @param _amount number of tokens to burn
     */
    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) public virtual {
        // check if caller has sufficient permissions to burn tokens
        // and if not - check for possibility to burn own tokens or to burn on behalf
        if (!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
            // if `_from` is equal to sender, require own burns feature to be enabled
            // otherwise require burns on behalf feature to be enabled
            require(
                (_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)) ||
                    (_from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF)),
                _from == msg.sender ? "burns are disabled" : "burns on behalf are disabled"
            );

            // verify sender is either token owner, or approved by the token owner to burn tokens
            require(_from == msg.sender || isApprovedForAll(_from, msg.sender), "access denied");
        }
        // delegate to the super implementation
        super._burn(_from, _id, _amount);
    }

    /**
     * @inheritdoc ERC1155Upgradeable
     */
    function _beforeTokenTransfer(
        address _operator,
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) internal virtual override {
        super._beforeTokenTransfer(_operator, _from, _to, _ids, _amounts, _data);
        // for transfers only - verify if transfers are enabled
        require(
            _from == address(0) ||
                _to == address(0) || // won't affect minting/burning
                (_from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)) ||
                (_from != msg.sender && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF)),
            _from == msg.sender ? "transfers are disabled" : "transfers on behalf are disabled"
        );
    }

    /**
     * @dev Restricted access function to rescue accidentally sent ERC20 tokens,
     *      the tokens are rescued via `transfer` function call on the
     *      contract address specified and with the parameters specified:
     *      `_contract.transfer(_to, _value)`
     *
     * @dev Requires executor to have `ROLE_RESCUE_MANAGER` permission
     *
     * @param _contract smart contract address to execute `transfer` function on
     * @param _to to address in `transfer(_to, _value)`
     * @param _value value to transfer in `transfer(_to, _value)`
     */
    function rescueErc20(
        address _contract,
        address _to,
        uint256 _value
    ) public {
        // verify the access permission
        require(isSenderInRole(ROLE_RESCUE_MANAGER), "access denied");

        // perform the transfer as requested, without any checks
        IERC20(_contract).transfer(_to, _value);
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}