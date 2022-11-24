// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ICurveLpToken {
    function set_minter(address _minter) external;

    function set_name(string calldata _name, string calldata _symbol) external;

    function totalSupply() external view returns (uint256);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function mint(address _to, uint256 _value) external returns (bool);

    function burnFrom(address _to, uint256 _value) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address arg0) external view returns (uint256);
}