// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRelayerPool {
    enum RelayerType {
        Validator,
        Fisher
    }
    enum RelayerStatus {
        Inactive,
        Online,
        Offline,
        BlackListed
    }

    struct Deposit {
        address user;
        uint256 lockTill;
        uint256 amount;
    }

    function getTotalDeposit() external view returns (uint256);

    function getDeposit(uint256 _depositId)
        external
        view
        returns (
            address user,
            uint256 amount,
            uint256 lockTill
        );

    function withdraw(uint256 _depositId, uint256 _amount) external;

    function deposit(uint256 _amount) external;

    function harvestMyReward() external;

    function harvestPoolReward() external;

    function setRelayerStatus(RelayerStatus _status) external;

    function setRelayerFeeNumerator(uint256 _value) external;

    function setEmissionAnnualRateNumerator(uint256 _value) external;
}