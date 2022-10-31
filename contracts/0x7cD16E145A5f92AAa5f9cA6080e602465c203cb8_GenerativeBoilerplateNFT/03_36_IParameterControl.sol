interface IParameterControl {
    function get(string memory key) external view returns (string memory);

    function getInt(string memory key) external view returns (int);

    function getUInt256(string memory key) external view returns (uint256);

    function getAddress(string memory key) external view returns (address);

    function set(string memory key, string memory value) external;

    function setInt(string memory key, int value) external;

    function setUInt256(string memory key, uint256 value) external;

    function setAddress(string memory key, address value) external;
}