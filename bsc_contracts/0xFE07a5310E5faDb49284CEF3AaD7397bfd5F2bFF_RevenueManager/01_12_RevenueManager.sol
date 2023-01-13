// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "IMissionManager.sol";
import "IWalletFactory.sol";
import "IGamingWallet.sol";
import "IRevenueManager.sol";
import "IOasisVault.sol";
import "NFTRental.sol";
import "AccessManager.sol";

contract RevenueManager is AccessManager, IRevenueManager {
    IWalletFactory public walletFactory;
    IMissionManager public missionManager;
    address public oasisVault;

    constructor(IRoleRegistry _roleRegistry) {
        setRoleRegistry(_roleRegistry);
    }

    function setWalletFactory(address _walletFactoryAdr)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        walletFactory = IWalletFactory(_walletFactoryAdr);
    }

    function setMissionManager(address _missionManagerAdr)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        missionManager = IMissionManager(_missionManagerAdr);
    }

    function setOasisVault(address _oasisVault)
        external
        override
        onlyRole(Roles.ADMIN)
    {
        oasisVault = _oasisVault;
    }

    function distributeERC20Rewards(
        string calldata _uuid,
        uint256 ownerAmount,
        uint256 tenantAmount,
        uint256 oasisAmount,
        address token
    ) external override onlyRole(Roles.REVENUE_MANAGER) {
        NFTRental.Mission memory curMission = missionManager.getOngoingMission(
            _uuid
        );
        address _gamingWalletAddress = walletFactory.getGamingWallet(
            curMission.tenant
        );
        IGamingWallet gamingWallet = IGamingWallet(_gamingWalletAddress);
        gamingWallet.oasisDistributeERC20Rewards(
            token,
            curMission.owner,
            ownerAmount
        );
        gamingWallet.oasisDistributeERC20Rewards(
            token,
            curMission.tenant,
            tenantAmount
        );
        if (oasisAmount > 0) {
            gamingWallet.oasisDistributeERC20Rewards(
                token,
                oasisVault,
                oasisAmount
            );
        }
    }

    function distributeERC721Rewards(
        string calldata _uuid,
        address _receiver,
        address _collection,
        uint256 _tokenId
    ) external override onlyRole(Roles.REVENUE_MANAGER) {
        NFTRental.Mission memory curMission = missionManager.getOngoingMission(
            _uuid
        );
        address tenant = curMission.tenant;
        require(
            _receiver == tenant || _receiver == curMission.owner,
            "Incorrect receiver"
        );
        address _gamingWalletAddress = walletFactory.getGamingWallet(tenant);
        IGamingWallet(_gamingWalletAddress).oasisDistributeERC721Rewards(
            _receiver,
            _collection,
            _tokenId
        );
    }

    function distributeERC1155Rewards(
        string calldata _uuid,
        address _receiver,
        address _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external override onlyRole(Roles.REVENUE_MANAGER) {
        NFTRental.Mission memory curMission = missionManager.getOngoingMission(
            _uuid
        );
        address tenant = curMission.tenant;
        require(
            _receiver == tenant || _receiver == curMission.owner,
            "Incorrect receiver"
        );
        address _gamingWalletAddress = walletFactory.getGamingWallet(tenant);
        IGamingWallet(_gamingWalletAddress).oasisDistributeERC1155Rewards(
            _receiver,
            _collection,
            _tokenId,
            _amount
        );
    }
}