// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// external librares
import { ERC1155 } from "../../lib/solmate/src/tokens/ERC1155.sol";

// interfaces
import { IVaultShare } from "../interfaces/IVaultShare.sol";
import { IVaultShareDescriptor } from "../interfaces/IVaultShareDescriptor.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";

import "../libraries/Errors.sol";

contract HashnoteVaultShare is ERC1155, IVaultShare {
    ///@dev whitelist serve as the vault registry
    IWhitelist public immutable whitelist;

    IVaultShareDescriptor public immutable descriptor;

    // total supply of a particular tokenId
    mapping(uint256 => uint256) private _totalSupply;

    constructor(address _whitelist, address _descriptor) {
        // solhint-disable-next-line reason-string
        if (_whitelist == address(0)) revert();
        whitelist = IWhitelist(_whitelist);

        descriptor = IVaultShareDescriptor(_descriptor);
    }

    /**
     *  @dev return string as defined in token descriptor
     *
     */
    function uri(uint256 id) public view override returns (string memory) {
        return descriptor.tokenURI(id);
    }

    /**
     * @dev mint option token to an address. Can only be called by corresponding margin engine
     * @param _recipient    where to mint token to
     * @param _amount       amount to mint
     */
    function mint(address _recipient, address _vault, uint256 _amount) external override {
        if (!whitelist.isVault(msg.sender)) revert Unauthorized();

        uint256 tokenId = vaultToTokenId(_vault);

        _totalSupply[tokenId] += _amount;

        _mint(_recipient, tokenId, _amount, "");
    }

    /**
     * @dev burn option token from an address. Can only be called by corresponding margin engine
     * @param _from         account to burn from
     * @param _amount       amount to burn
     *
     */
    function burn(address _from, address _vault, uint256 _amount) external override {
        if (!whitelist.isVault(msg.sender)) revert Unauthorized();

        uint256 tokenId = vaultToTokenId(_vault);

        uint256 supply = _totalSupply[tokenId];

        if (supply < _amount) revert VS_SupplyExceeded();

        _totalSupply[tokenId] = supply - _amount;

        _burn(_from, tokenId, _amount);
    }

    function totalSupply(address _vault) external view override returns (uint256) {
        return _totalSupply[vaultToTokenId(_vault)];
    }

    function getBalanceOf(address _owner, address _vault) external view override returns (uint256) {
        return balanceOf[_owner][vaultToTokenId(_vault)];
    }

    function transferFrom(address _from, address _to, address _vault, uint256 _amount, bytes calldata _data) public override {
        ERC1155.safeTransferFrom(_from, _to, vaultToTokenId(_vault), _amount, _data);
    }

    function tokenIdToVault(uint256 tokenId) external pure returns (address) {
        return address(uint160(tokenId));
    }

    function vaultToTokenId(address _vault) internal pure returns (uint256) {
        return uint256(uint160(_vault));
    }
}