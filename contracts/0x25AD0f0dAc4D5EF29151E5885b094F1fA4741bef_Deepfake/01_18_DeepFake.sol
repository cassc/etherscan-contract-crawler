// SPDX-License-Identifier: UNLICESENED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Tag.sol";

// __/\\\\\\\\\\\\_____/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\\\\__/\\\\\\\\\\\\\___
//  _\/\\\////////\\\__\/\\\///////////__\/\\\///////////__\/\\\/////////\\\_
//   _\/\\\______\//\\\_\/\\\_____________\/\\\_____________\/\\\_______\/\\\_
//    _\/\\\_______\/\\\_\/\\\\\\\\\\\_____\/\\\\\\\\\\\_____\/\\\\\\\\\\\\\/__
//     _\/\\\_______\/\\\_\/\\\///////______\/\\\///////______\/\\\/////////____
//      _\/\\\_______\/\\\_\/\\\_____________\/\\\_____________\/\\\_____________
//       _\/\\\_______/\\\__\/\\\_____________\/\\\_____________\/\\\_____________
//        _\/\\\\\\\\\\\\/___\/\\\\\\\\\\\\\\\_\/\\\\\\\\\\\\\\\_\/\\\_____________
//         _\////////////_____\///////////////__\///////////////__\///______________
// __/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\________/\\\__/\\\\\\\\\\\\\\\_
//  _\/\\\///////////____/\\\\\\\\\\\\\__\/\\\_____/\\\//__\/\\\///////////__
//   _\/\\\______________/\\\/////////\\\_\/\\\__/\\\//_____\/\\\_____________
//    _\/\\\\\\\\\\\_____\/\\\_______\/\\\_\/\\\\\\//\\\_____\/\\\\\\\\\\\_____
//     _\/\\\///////______\/\\\\\\\\\\\\\\\_\/\\\//_\//\\\____\/\\\///////______
//      _\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___\/\\\_____________
//       _\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__\/\\\_____________
//        _\/\\\_____________\/\\\_______\/\\\_\/\\\______\//\\\_\/\\\\\\\\\\\\\\\_
//         _\///______________\///________\///__\///________\///__\///////////////__

/// @title Deep Fake
/// @author Atlas C.O.R.P.
contract Deepfake is ERC1155Supply, AccessControlEnumerable, Ownable {
    struct TokenData {
        MintState mintState;
        uint256 price;
        bool approved;
    }

    enum MintState {
        OFF,
        ACTIVE
    }

    string public constant name = "Deepfake";
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    uint256 public tokenCounter;

    mapping(uint256 => TokenData) public tokenData;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @param _tokenId which token you want to mint
    function mint(uint256 _tokenId) external payable {
        require(tokenData[_tokenId].approved, "mint: token must be approved");
        require(
            tokenData[_tokenId].mintState == MintState.ACTIVE,
            "mint: mint must be active"
        );
        require(
            msg.value >= tokenData[_tokenId].price,
            "mint: incorrect value"
        );

        _mint(msg.sender, _tokenId, 1, "");
    }

    /// @dev caller needs MANAGER_ROLE
    /// @notice to create new token to mint
    function createToken(uint256 _price) external onlyRole(MANAGER_ROLE) {
        ++tokenCounter;
        tokenData[tokenCounter].price = _price;
        tokenData[tokenCounter].approved = true;
    }

    /// @dev caller needs MANAGER_ROLE
    /// @notice to change the IPFS URI link
    /// @param _newuri the new link
    function setURI(string calldata _newuri) external onlyRole(MANAGER_ROLE) {
        _setURI(_newuri);
    }

    /// @dev caller needs MANAGER_ROLE
    /// @notice starts the claim
    /// @param _tokenId the token you would like to start
    function setMintStateActive(uint256 _tokenId)
        external
        onlyRole(MANAGER_ROLE)
    {
        require(
            tokenData[_tokenId].approved,
            "setMintStateActive: claim already live"
        );
        require(
            tokenData[_tokenId].mintState == MintState.OFF,
            "mint: mint must be off"
        );
        tokenData[_tokenId].approved = true;
    }

    /// @dev caller needs MANAGER_ROLE
    /// @notice pauses the claim
    /// @param _tokenId the token you would like to pause
    function setMintStateOff(uint256 _tokenId) external onlyRole(MANAGER_ROLE) {
        require(
            tokenData[_tokenId].approved,
            "setMintStateOff: claim not live"
        );
        require(
            tokenData[_tokenId].mintState == MintState.ACTIVE,
            "mint: mint must be active"
        );
        tokenData[_tokenId].approved = false;
    }

    /// @dev caller needs MANAGER_ROLE
    /// @param _tokenId is the token you would like to change the price on
    /// @param _price the new price of the tokenId
    function setPrice(uint256 _tokenId, uint256 _price)
        external
        onlyRole(MANAGER_ROLE)
    {
        tokenData[_tokenId].price = _price;
    }

    /// @dev caller needs MANAGER_ROLE
    /// @param _destination is the address you want to withdraw to
    function withdraw(address _destination) external onlyRole(MANAGER_ROLE) {
        uint256 balance = address(this).balance;
        require(payable(_destination).send(balance));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return (ERC1155.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId));
    }
}