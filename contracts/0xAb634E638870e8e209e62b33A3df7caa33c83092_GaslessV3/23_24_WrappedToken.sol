interface WrappedToken {
    function withdraw(uint256 amount) external payable;
    function deposit(address user, uint256 amount) external;
    function transfer(address to, uint256 value) external payable returns (bool);
}