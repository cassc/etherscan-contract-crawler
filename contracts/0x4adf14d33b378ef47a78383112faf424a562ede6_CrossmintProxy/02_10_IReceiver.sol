interface IReceiver {
    function accumulator() external returns (uint256);

    function mint(uint256, bool) external payable;

    function retrieve(address, uint256) external;

    function init(address) external;
}