// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./Withdrawable.sol";

contract ERC1155AMintable is ERC1155Burnable, Withdrawable {
    using SafeMath for uint256;
    using Strings for uint256;
    string public name;
    string public symbol;

    constructor() ERC1155("") {}

    /**
   * @dev Allows users with the admin role to
   * grant/revoke the admin role from other users

    * Params:
    * _admin: address of the first admin
    */
    bool initialized = false;

    //Allows contract to inherit both ERC1155 and Accesscontrol
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function init(
        address _admin,
        string memory _name,
        string memory _symbol,
        uint256[] calldata _globalSupplyConfigs
    ) external {
        if (initialized) revert InvalidAction("Already initialized");
        if (_globalSupplyConfigs.length < 3)
            revert InvalidAction("Incomplete _globalSupplyConfigs");

        initialized = true;
        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);
        name = _name;
        symbol = _symbol;
        maxSupply = _globalSupplyConfigs[0];
        maxQuantityGlobal = _globalSupplyConfigs[1];
        maxMintsPerTxGlobal = _globalSupplyConfigs[2];
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory uriString)
    {
        if (!revealed && !hasRole(ROLE_ADMIN, msg.sender)) {
            uriString = hiddenMetadataUri;

            return uriString;
        }

        uriString = tokenURIs[id];

        if (bytes(uriString).length == 0) {
            uriString = string(
                abi.encodePacked(baseURI, Strings.toString(id), baseExtension)
            );
        }

        return uriString;
    }

    function getTotalCost(
        address _tokenAddress, // Address of token for payment
        uint256[] memory _tokensIds, // Ids planned to be minted
        uint256[] memory _mintAmounts // how much of each id you want to mint
    ) public view returns (uint256 cost) {
        cost = 0;

        for (uint256 x = 0; x < _tokensIds.length; x++) {
            uint256 price = _getPrice(
                _tokensIds[x],
                _mintAmounts[x],
                _tokenAddress
            );
            cost += (price * _mintAmounts[x]);
        }
    }

    function verifySupply(uint256 _amount, uint256 _tokenId) internal view {
        uint256 newQuantity = totalSupply[_tokenId] + _amount;

        if (
            ((maxMintPerTx[_tokenId] > 0 && _amount > maxMintPerTx[_tokenId]) ||
                (maxMintPerTx[_tokenId] == 0 &&
                    _amount > maxMintsPerTxGlobal)) ||
            ((maxQuantity[_tokenId] > 0 &&
                newQuantity > maxQuantity[_tokenId]) ||
                (maxQuantity[_tokenId] == 0 &&
                    newQuantity > maxQuantityGlobal)) ||
            _tokenId >= maxSupply
        ) {
            revert InvalidAction("Invalid amount or tokenId");
        }
    }

    modifier verifyMintAmount(
        uint256[] memory _tokenIds,
        uint256[] memory _mintAmounts
    ) {
        if (_tokenIds.length > maxMintsPerTxGlobal) {
            revert InvalidAction("Global mint limit exceeded");
        }

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            verifySupply(_mintAmounts[i], _tokenIds[i]);
        }
        _;
    }
}