// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMusicNFT is IERC165 {
    event Minted(uint256 indexed tokenId, address indexed user);

    /**
    ////////////////////////////////////////////////////
    // Admin Functions 
    ///////////////////////////////////////////////////
    */

    // Set merkle root
    function setMerkleRoot(bytes32 merkleRoot_) external;

    // Set treasury address
    function setTreasury(address newTreaasury_) external;

    // Set NFT base URI
    function setBaseURI(string memory newBaseURI_) external;

    function setContractURI(string memory newContractURI) external;

    // Start presale
    function startPresale(
        uint256 maxAlbums_,
        uint256 maxAlbumsPerWallet_,
        uint256 newPrice_,
        uint256 presaleStartTime_,
        uint256 presaleEndTime_
    ) external;

    // extend presale period
    function extendPresale(uint256 presaleEndTime_) external;

    // Start sale
    function startSale(
        uint256 maxAlbums_,
        uint256 maxAlbumsPerWallet_,
        uint256 newPrice_
    ) external;

    function stopSale() external;

    // withdraw all incomes
    function withdraw() external;

    /**
    ////////////////////////////////////////////////////
    // Public Functions 
    ///////////////////////////////////////////////////
    */

    // Mint album in presale
    function presaleMint(uint256 albums_, bytes32[] calldata proof_)
        external
        payable;

    // mint album in sale
    function mint(uint256 albums_) external payable;

    /**
    ////////////////////////////////////////////////////
    // View only functions
    ///////////////////////////////////////////////////
    */

    function tracksPerAlbum() external view returns (uint256);

    function maxTracksOnSale() external view returns (uint256);

    function maxAlbumsOnSale() external view returns (uint256);

    function maxAlbumsPerWallet() external view returns (uint256);

    function maxAlbumsPerTx() external view returns (uint256);

    function price() external view returns (uint256);

    function presaleActive() external view returns (bool);

    function saleActive() external view returns (bool);

    function presaleStart() external view returns (uint256);

    function presaleEnd() external view returns (uint256);

    function tracksMinted(address user) external view returns (uint256);

    function albumsMinted(address user) external view returns (uint256);

    function totalAlbumsMinted() external view returns (uint256);

    function treasury() external view returns (address);

    function totalRevenue() external view returns (uint256);

    function contractURI() external view returns (string memory);
}