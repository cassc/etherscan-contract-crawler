// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INftBank {

    function token() view external returns (IERC20);

    function deadAddress() view external returns (address);

    function paused() view external returns (bool);

    function nft(uint256 _index) view external returns (IERC20);

    function multiplier(address _nftAddress) view external returns (uint256);


    function totalSupplyNft() view external returns (uint256);

    function burnedNft() view external returns (uint256);

    function circulatingSupplyNft() view external returns (uint256);

    function nftLength() view external returns (uint256);

    function allMultiplier() view external returns (uint256);

    function totalBank() view external returns (uint256);

    function price(address _nft) view external returns (uint256);

    function swap(address[] calldata _nfts, uint256[] calldata _values) external;


    function setNfts(address[] calldata _nft, uint256[] calldata _multipler) external;

    function setPaused(bool _paused) external;

    function recoverTokens(address _address, uint256 _amount) external;

    function recoverTokensFor(address _address, uint256 _amount, address _to) external;

}