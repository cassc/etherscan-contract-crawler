// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

// external libraries
import {ERC1155} from "solmate/tokens/ERC1155.sol";

// interfaces
import {IVaultShare} from "../../interfaces/IVaultShare.sol";
import {IVaultShareDescriptor} from "../../interfaces/IVaultShareDescriptor.sol";
import {IWhitelistManager} from "../../interfaces/IWhitelistManager.sol";

import "../../config/errors.sol";

contract HashnoteVaultShare is ERC1155, IVaultShare, OwnableUpgradeable, UUPSUpgradeable {
    ///@dev whitelist serve as the vault registry
    IWhitelistManager public immutable whitelist;

    IVaultShareDescriptor public immutable descriptor;

    // total supply of a particular tokenId
    mapping(uint256 => uint256) private _totalSupply;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address _whitelist, address _descriptor) {
        if (_whitelist == address(0)) revert BadAddress();

        whitelist = IWhitelistManager(_whitelist);
        descriptor = IVaultShareDescriptor(_descriptor);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert BadAddress();

        _transferOwnership(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @dev return string as defined in token descriptor
     *
     */
    function uri(uint256 id) public view override returns (string memory) {
        return descriptor.tokenURI(id);
    }

    /**
     * @dev mint option token to an address. Can only be called by corresponding vault
     * @param _recipient    where to mint token to
     * @param _amount       amount to mint
     */
    function mint(address _recipient, uint256 _amount) external override {
        if (!whitelist.isVault(msg.sender)) revert Unauthorized();

        uint256 tokenId = _vaultToTokenId(msg.sender);

        _totalSupply[tokenId] += _amount;

        _mint(_recipient, tokenId, _amount, "");
    }

    /**
     * @dev burn option token from an address. Can only be called by corresponding vault
     * @param _from         account to burn from
     * @param _amount       amount to burn
     *
     */
    function burn(address _from, uint256 _amount) external override {
        if (!whitelist.isVault(msg.sender)) revert Unauthorized();

        uint256 tokenId = _vaultToTokenId(msg.sender);

        uint256 supply = _totalSupply[tokenId];

        if (supply < _amount) revert VS_SupplyExceeded();

        _totalSupply[tokenId] = supply - _amount;

        _burn(_from, tokenId, _amount);
    }

    function batchBurn(address[] memory _froms, uint256[] memory _amounts) external override {
        if (!whitelist.isVault(msg.sender)) revert Unauthorized();

        uint256 tokenId = _vaultToTokenId(msg.sender);

        uint256 burnCount = _froms.length;

        require(burnCount == _amounts.length, "LENGTH_MISMATCH");

        uint256 supply = _totalSupply[tokenId];

        for (uint256 i = 0; i < burnCount;) {
            uint256 amount = _amounts[i];

            if (supply < amount) revert VS_SupplyExceeded();

            balanceOf[_froms[i]][tokenId] -= amount;
            supply -= amount;

            unchecked {
                ++i;
            }
        }
    }

    function totalSupply(address _vault) external view override returns (uint256) {
        return _totalSupply[_vaultToTokenId(_vault)];
    }

    function getBalanceOf(address _owner, address _vault) external view override returns (uint256) {
        return balanceOf[_owner][_vaultToTokenId(_vault)];
    }

    function transferFromWithVault(address _from, address _to, address _vault, uint256 _amount, bytes calldata _data)
        public
        override
    {
        ERC1155.safeTransferFrom(_from, _to, _vaultToTokenId(_vault), _amount, _data);
    }

    function transferVaultOnly(address _from, address _to, uint256 _amount, bytes calldata _data) public override {
        if (!whitelist.isVault(msg.sender)) revert Unauthorized();

        uint256 tokenId = _vaultToTokenId(msg.sender);

        if (_from != msg.sender && _to == msg.sender) {
            if (!isApprovedForAll[_from][msg.sender]) isApprovedForAll[_from][msg.sender] = true;
        }

        ERC1155.safeTransferFrom(_from, _to, tokenId, _amount, _data);
    }

    function tokenIdToVault(uint256 tokenId) external pure returns (address) {
        return address(uint160(tokenId));
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _vaultToTokenId(address _vault) internal pure returns (uint256) {
        return uint256(uint160(_vault));
    }
}