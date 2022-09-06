// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IMemberships {
    struct Membership {
        address tokenAddress; // token to pay for purchases or renewals
        uint256 price; // price
        uint256 validity; // validity duration in seconds for which a membership is valid after each purchase
        uint256 cap; // total number of memberships
        address airdropToken; // address of the token for airdrop
        uint256 airdropAmount; // number of tokens to airdrop in `airdropToken` decimals
    }

    function owner() external view returns (address);

    function factory() external view returns (address);

    function treasury() external view returns (address payable);

    function price() external view returns (uint256);

    function validity() external view returns (uint256);

    function cap() external view returns (uint256);

    function airdropToken() external view returns (address);

    function airdropAmount() external view returns (uint256);

    function initialize(
        address _owner,
        address payable _treasury,
        string memory _name,
        string memory _symbol,
        string memory contractURI_,
        string memory baseURI_,
        IMemberships.Membership memory _membership
    ) external;

    function pause() external;

    function unpause() external;

    function purchase(address recipient) external payable returns (uint256, uint256);

    function mint(address recipient) external returns (uint256, uint256);

    function renew(uint256 tokenId) external payable returns (uint256);

    function withdraw() external;

    function expirationTimestampOf(uint256 tokenId) external view returns (uint256);

    function isValid(uint256 tokenId) external view returns (bool);

    function hasValidToken(address _owner) external view returns (bool);

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external;

    function contractURI() external view returns (string memory);

    function version() external pure returns (uint16);
}