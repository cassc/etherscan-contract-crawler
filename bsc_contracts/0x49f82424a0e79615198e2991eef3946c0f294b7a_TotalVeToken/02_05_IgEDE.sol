interface IgEDE {

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function get_last_user_slope(address addr) external view returns (int128);

    function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

    function checkpoint() external;

    function balanceOf(address addr) external view returns (uint256);

    function balanceOf(address addr, uint256 _t) external view returns (uint256);

    function balanceOfAt(address addr, uint256 _block) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupply(uint256 t) external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function totalSupplyAtNow() external view returns (uint256);

    function totalEDESupply() external view returns (uint256);

    function totalEDESupply(uint256 _block) external view returns (uint256);

    function token() external view returns (address);

    function supply() external view returns (uint256);

    function locked(address addr) external view returns (LockedBalance memory);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint256);

    function admin() external view returns (address);

}