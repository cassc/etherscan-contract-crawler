//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../libraries/DataTypes.sol";
import "../libraries/Errors.sol";
import "../libraries/Roles.sol";

/// @title PositionNFT
/// @notice An ERC721 NFT that represents ownership of each position created through the protocol
/// @dev Instances can only be minted by other contango contracts
contract PositionNFT is ERC721, AccessControl {

    event ContangoContractSet(address indexed contractAddr, bool indexed enabled);

    uint256 public counter = 1;
    mapping(address contractAddr => bool enabled) public contangoContracts;

    constructor(Timelock timelock) ERC721("Contango Position", "CTGP") {
        // Grant the admin role to the timelock by default
        _grantRole(DEFAULT_ADMIN_ROLE, Timelock.unwrap(timelock));
    }

    /// @notice creates a new position in the protocol by minting a new NFT instance
    /// @param positionId positionId of the new position without the number component set
    /// @param to The would be owner of the newly minted position
    /// @return positionId_ The newly created positionId
    function mint(PositionId positionId, address to) external onlyRole(MINTER_ROLE) returns (PositionId positionId_) {
        positionId_ = positionId.withNumber(counter++);
        _safeMint(to, uint256(PositionId.unwrap(positionId_)));
    }

    /// @notice closes a position in the protocol by burning the NFT instance
    /// @param positionId positionId of the closed position
    function burn(PositionId positionId) external onlyRole(MINTER_ROLE) {
        _burn(uint256(PositionId.unwrap(positionId)));
    }

    function positionOwner(PositionId positionId) public view returns (address) {
        return ownerOf(uint256(PositionId.unwrap(positionId)));
    }

    function exists(PositionId positionId) external view returns (bool) {
        return _exists(uint256(PositionId.unwrap(positionId)));
    }

    function setContangoContract(address contractAddr, bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contangoContracts[contractAddr] = enabled;
        emit ContangoContractSet(contractAddr, enabled);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return owner == operator || contangoContracts[operator] || super.isApprovedForAll(owner, operator);
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

}