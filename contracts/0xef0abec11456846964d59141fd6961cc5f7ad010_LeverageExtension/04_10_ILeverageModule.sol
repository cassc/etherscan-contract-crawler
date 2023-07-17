pragma solidity 0.6.10;
import {ISetToken} from "./ISetToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILeverageModule {
    function initialize(
        ISetToken _setToken,
        IERC20[] memory _collateralAssets,
        IERC20[] memory _borrowAssets
    ) external;

    function lever(
        ISetToken _setToken,
        IERC20 _borrowAsset,
        IERC20 _collateralAsset,
        uint256 _borrowQuantityUnits,
        uint256 _minReceiveQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function delever(
        ISetToken _setToken,
        IERC20 _collateralAsset,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        uint256 _minRepayQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function deleverToZeroBorrowBalance(
        ISetToken _setToken,
        IERC20 _collateralAsset,
        IERC20 _repayAsset,
        uint256 _redeemQuantityUnits,
        string memory _tradeAdapterName,
        bytes memory _tradeData
    ) external;

    function addCollateralAssets(
        ISetToken _setToken,
        IERC20[] memory _newCollateralAssets
    ) external;

    function removeCollateralAssets(
        ISetToken _setToken,
        IERC20[] memory _collateralAssets
    ) external;

    function addBorrowAssets(
        ISetToken _setToken,
        IERC20[] memory _newBorrowAssets
    ) external;

    function removeBorrowAssets(
        ISetToken _setToken,
        IERC20[] memory _borrowAssets
    ) external;
}