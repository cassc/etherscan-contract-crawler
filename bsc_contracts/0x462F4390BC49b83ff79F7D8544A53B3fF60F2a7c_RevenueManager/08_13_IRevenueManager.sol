// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "NFTRental.sol";

interface IRevenueManager {
    function setWalletFactory(address _walletFactoryAdr) external;

    function setMissionManager(address _missionManagerAdr) external;

    function setOasisVault(address _oasisVault) external;

    function distributeChainTokensRewards(
        string calldata _uuid,
        uint256 _ownerAmount,
        uint256 _tenantAmount,
        uint256 _oasisAmount
    ) external;

    function distributeERC20Rewards(
        string calldata _uuid,
        uint256 _ownerAmount,
        uint256 _tenantAmount,
        uint256 _oasisAmount,
        address _token
    ) external;

    function distributeERC721Rewards(
        string calldata _uuid,
        address _receiver,
        address _collection,
        uint256 _tokenId
    ) external;

    function distributeERC1155Rewards(
        string calldata _uuid,
        address _receiver,
        address _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}