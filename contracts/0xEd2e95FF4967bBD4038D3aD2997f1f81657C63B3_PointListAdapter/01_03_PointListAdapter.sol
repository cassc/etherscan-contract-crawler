pragma solidity ^0.8.0;
import "./interfaces/IPointList.sol";
import "../interfaces/IINFPermissionManager.sol";
contract PointListAdapter is IPointList {
    IINFPermissionManager public immutable permissionManager;

    constructor(IINFPermissionManager _permissionManager) {
        permissionManager = _permissionManager;
    }

    /**
     * @notice Initializes point list with admin address.
     * @param _admin Admins address.
     */
    function initPointList(address _admin) public override {
        return;
    }

    /**
     * @notice Checks if account address is in the list (has any points).
     * @param _account Account address.
     * @return exempt True or False.
     */
    function isInList(address _account) public view override returns (bool exempt) {
        exempt = permissionManager.whitelistedInvestors(_account);
    }

    /**
     * @notice Checks if account has more or equal points as the number given.
     * @param _account Account address.
     * @param _amount Desired amount of points.
     * @return exempt True or False.
     */
    function hasPoints(address _account, uint256 _amount) public view override returns (bool exempt) {
        exempt = permissionManager.whitelistedInvestors(_account);
    }

    /**
     * @notice Sets points to accounts in one batch.
     * @param _accounts An array of accounts.
     * @param _amounts An array of corresponding amounts.
     */
    function setPoints(address[] memory _accounts, uint256[] memory _amounts) external override {
        return;
    }
}