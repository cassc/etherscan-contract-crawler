//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/DataTypes.sol";

/// @title ContangoPositionNFT
/// @notice An ERC721 NFT that represents ownership of each position created through the protocol
/// @author Bruno Bonanno
/// @dev Instances can only be minted by other contango contracts
contract ContangoPositionNFT is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER = keccak256("MINTER");
    bytes32 public constant ARTIST = keccak256("ARTIST");

    PositionId public nextPositionId = PositionId.wrap(1);

    constructor() ERC721("Contango Position", "CTGP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice creates a new position in the protocol by minting a new NFT instance
    /// @param to The would be owner of the newly minted position
    /// @return positionId The newly created positionId
    function mint(address to) external onlyRole(MINTER) returns (PositionId positionId) {
        positionId = nextPositionId;
        uint256 _positionId = PositionId.unwrap(positionId);
        nextPositionId = PositionId.wrap(_positionId + 1);
        _safeMint(to, _positionId);
    }

    /// @notice closes a position in the protocol by burning the NFT instance
    /// @param positionId positionId of the closed position
    function burn(PositionId positionId) external onlyRole(MINTER) {
        _burn(PositionId.unwrap(positionId));
    }

    function positionOwner(PositionId positionId) external view returns (address) {
        return ownerOf(PositionId.unwrap(positionId));
    }

    function positionURI(PositionId positionId) external view returns (string memory) {
        return tokenURI(PositionId.unwrap(positionId));
    }

    function setPositionURI(PositionId positionId, string memory _tokenURI) external onlyRole(ARTIST) {
        _setTokenURI(PositionId.unwrap(positionId), _tokenURI);
    }

    /**
     * @dev See EIP-165: ERC-165 Standard Interface Detection
     * https://eips.ethereum.org/EIPS/eip-165.
     *
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return AccessControl.supportsInterface(interfaceId) || ERC721.supportsInterface(interfaceId);
    }

    /// @dev returns all the positions a trader has between the provided boundaries
    /// @param owner Trader that owns the positions
    /// @param from Starting position to consider for the search (inclusive)
    /// @param to Ending position to consider for the search (exclusive)
    /// @return tokens Array with all the positions the trader owns within the range.
    /// Array size could be bigger than effective result set if the trader owns positions outside the range
    /// PositionId == 0 is always invalid, so as soon it shows up in the array is safe to assume the rest of it is empty
    function positions(address owner, PositionId from, PositionId to)
        external
        view
        returns (PositionId[] memory tokens)
    {
        uint256 count;
        uint256 balance = balanceOf(owner);
        tokens = new PositionId[](balance);
        uint256 _from = PositionId.unwrap(from);
        uint256 _to = Math.min(PositionId.unwrap(to), PositionId.unwrap(nextPositionId));

        for (uint256 i = _from; i < _to; i++) {
            if (_exists(i) && ownerOf(i) == owner) {
                tokens[count++] = PositionId.wrap(i);
            }
        }
    }
}