pragma solidity 0.8.19;

interface ISTBL {
    function mint(address _receiver, uint256 _value) external;
    function burn(uint256 _value) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}