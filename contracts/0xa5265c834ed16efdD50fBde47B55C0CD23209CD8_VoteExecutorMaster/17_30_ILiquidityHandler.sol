// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface ILiquidityHandler is IAccessControl{

    function adapterIdsToAdapterInfo(uint256)
        external
        view
        returns (
            string memory name,
            uint256 percentage,
            address adapterAddress,
            bool status
        );

    function changeAdapterStatus(uint256 _id, bool _status) external;

    function changeUpgradeStatus(bool _status) external;

    function deposit(address _token, uint256 _amount) external;
    function deposit ( address _token, uint256 _amount, address _targetToken) external;

    function getActiveAdapters()
        external
        view
        returns (ILiquidityHandlerStructs.AdapterInfo[] memory, address[] memory);

    function getAdapterAmount(address _ibAlluo) external view returns (uint256);

    function getAdapterId(address _ibAlluo) external view returns (uint256);

    function getAllAdapters()
        external
        view
        returns (ILiquidityHandlerStructs.AdapterInfo[] memory, address[] memory);

    function getExpectedAdapterAmount(address _ibAlluo, uint256 _newAmount)
        external
        view
        returns (uint256);

    function getIbAlluoByAdapterId(uint256 _adapterId)
        external
        view
        returns (address);

    function getLastAdapterIndex() external view returns (uint256);

    function getListOfIbAlluos() external view returns (address[] memory);

    function getWithdrawal(address _ibAlluo, uint256 _id)
        external
        view
        returns (ILiquidityHandlerStructs.Withdrawal memory);


    function ibAlluoToWithdrawalSystems(address)
        external
        view
        returns (
            uint256 lastWithdrawalRequest,
            uint256 lastSatisfiedWithdrawal,
            uint256 totalWithdrawalAmount,
            bool resolverTrigger
        );

    function isUserWaiting(address _ibAlluo, address _user)
        external
        view
        returns (bool);

    function pause() external;

    function paused() external view returns (bool);

    function removeTokenByAddress(
        address _address,
        address _to,
        uint256 _amount
    ) external;


    function satisfyAdapterWithdrawals(address _ibAlluo) external;

    function satisfyAllWithdrawals() external;

    function setAdapter(
        uint256 _id,
        string memory _name,
        uint256 _percentage,
        address _adapterAddress,
        bool _status
    ) external;

    function setIbAlluoToAdapterId(address _ibAlluo, uint256 _adapterId)
        external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function upgradeStatus() external view returns (bool);

    function withdraw(
        address _user,
        address _token,
        uint256 _amount
    ) external;
    function withdraw ( address _user, address _token, uint256 _amount, address _outputToken ) external;

    function getAdapterCoreTokensFromIbAlluo(address _ibAlluo) external view returns (address,address);

}

interface ILiquidityHandlerStructs {
    struct AdapterInfo {
        string name;
        uint256 percentage;
        address adapterAddress;
        bool status;
    }

    struct Withdrawal {
        address user;
        address token;
        uint256 amount;
        uint256 time;
    }
}