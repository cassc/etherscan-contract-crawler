pragma solidity ^0.8.17;

interface IERC20MintableBurnable {
    function mint(
        address _receiver,
        uint256 _amount
    ) external returns (bool);

    function burnFrom(
        address _sender,
        uint256 _amount
    ) external returns (bool);
}