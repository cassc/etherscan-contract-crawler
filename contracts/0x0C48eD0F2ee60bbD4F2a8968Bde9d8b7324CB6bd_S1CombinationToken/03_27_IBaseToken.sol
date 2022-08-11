pragma solidity ^0.8.6;

import "./ICombinableTokenBasis.sol";

interface IBaseToken is ICombinableTokenBasis {
    function initialize(address _membershipToken, address _childAddress)
        external;

    function publicSaleMint(
        address _to,
        uint256 _amount
    ) external payable;

    function presaleMint(
        address _to,
        uint256 _amount
    ) external payable;

    function setSaleStartTime(uint256 _saleStartTime) external;

    function setPresaleTime(uint256 _presaleStartTime, uint256 _presaleEndTime) external;

    function baseTokenMainTraits(uint256 _tokenId) external view returns (uint8, uint8, uint8, uint16);

    function membershipMintPass(address _minter) external view returns (bool);
}