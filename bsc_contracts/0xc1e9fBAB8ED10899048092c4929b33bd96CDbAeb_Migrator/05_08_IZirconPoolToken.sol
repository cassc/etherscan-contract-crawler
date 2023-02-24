pragma solidity >=0.5.16;

interface IZirconPoolToken {
    function factory() external view returns (address);
    function isAnchor() external view returns (bool);
    function token() external view returns (address);
    function pair() external view returns (address);
    function pylonFactory() external view returns (address);
    function pylon() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);

    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function initialize(address _token0, address _pair, address _pylon, bool _isAnchor) external;
    function transferFrom(address from, address to, uint value) external returns (bool);
}