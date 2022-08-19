// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Wrapped3x3Land is ERC721Burnable {

    event Wrap3x3Land(address from, address to, uint256 tokenId, uint256 LAND33Id);
    event Unwrap3x3Land(address from, address to, uint256 tokenId);

    // Sandbox ethereum address
    address public constant SANDBOX = 0x5CC5B05a8A13E3fBDB0BB9FcCd98D38e50F90c38;
    // Sandbox constant grid size is 408 * 408 lands
    uint256 internal constant LAND_GRID_SIZE = 408;
    // Sandbox 3x3 estate layer
    uint256 internal constant LAYER_3x3 =      0x0100000000000000000000000000000000000000000000000000000000000000;
    // Bitmask for sandbox tokenId layer
    uint256 internal constant MASK =           0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    constructor() ERC721('Wrapped 3x3 Sandbox Lands', 'LAND33') {}

    /// @notice Wrap a 3x3 sandbox estate to one ERC721 token, whose tokenId will be equal
    ///     to the regrouped 3x3 estate tokenid
    /// @param from The owner of desired 3x3 estate
    /// @param to Adress to receive LAND33
    /// @param tokenId TokenId of the # bottom left # 1x1 land of the 3x3 estate or a parent estate quadId
    function safeWrap(address from, address to, uint256 tokenId) external {
        // Get 1x1 land id
        uint256 landId = tokenId & MASK;
        // Sandbox land tokenid is calculated by: landId = x + y * GRID_SIZE
        // Thus we can get the coordinates as follows:
        uint256 x = landId % LAND_GRID_SIZE;
        uint256 y = landId / LAND_GRID_SIZE;
        ILandBaseTokenV2(SANDBOX).transferQuad(from, address(this), 3, x, y, '');
        require(ILandBaseTokenV2(SANDBOX)._owners(landId + LAYER_3x3)
            == uint256(uint160(address(this))), 'Fracton: transfer quad in failed');

        _safeMint(to, landId + LAYER_3x3);
        emit Wrap3x3Land(from, to, tokenId, landId + LAYER_3x3);
    }

    /// @notice Burn a LAND33 to unwrap the correspoding 3x3 estate
    /// @dev The caller must be the owner or an approved operator
    /// @param to Address to receive released 3x3 sandbox estate
    /// @param tokenId TokenId of the wrapped sandbox lands
    function safeUnwrap(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        burn(tokenId);

        uint256 landId = tokenId & MASK;
        uint256 x = landId % LAND_GRID_SIZE;
        uint256 y = landId / LAND_GRID_SIZE;
        ILandBaseTokenV2(SANDBOX).transferQuad(address(this), to, 3, x, y,'');
        require(ILandBaseTokenV2(SANDBOX)._owners(tokenId)
            == uint256(uint160(to)), 'Fracton: transfer quad out failed');

        emit Unwrap3x3Land(owner, to, tokenId);
    }

    /// @notice Get LAND33 token uri, which will link directly to sandbox 1x1 land token uri
    /// @param tokenId TokenId of the LAND33
    /// @return uri Uri of the LAND33
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        require(
        _exists(tokenId),
        'ERC721URIStorage: URI query for nonexistent token'
        );

        tokenId &= MASK;
        uri = ILandBaseTokenV2(SANDBOX).tokenURI(tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC721BatchReceived(
        address,
        address,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721BatchReceived.selector;
    }
}

interface ILandBaseTokenV2 {
    function _owners(uint256 tokenId) external view returns(uint256);
    function transferQuad(address from, address to, uint256 size, uint256 x, uint256 y, bytes calldata data) external;
    function tokenURI(uint256 id) external view returns(string memory);
}