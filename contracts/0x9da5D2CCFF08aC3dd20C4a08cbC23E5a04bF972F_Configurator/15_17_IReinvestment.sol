// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IReinvestmentProxy {
    function owner() external view returns (address);

    function logic() external view returns (address);

    function setLogic() external view returns (address);

    function supportedInterfaceId() external view returns (bytes4);
}

interface IReinvestmentLogic {

    event UpdatedTreasury(address oldAddress, address newAddress);
    event UpdatedFeeMantissa(uint256 oldFee, uint256 newFee);

    struct Reward {
        address asset;
        uint256 claimable;
    }

    function setTreasury(address treasury_) external;

    function setFeeMantissa(uint256 feeMantissa_) external;

    function asset() external view returns (address);

    function treasury() external view returns (address);

    function ledger() external view returns (address);

    function feeMantissa() external view returns (uint256);

    function receipt() external view returns (address);

    function platform() external view returns (address);

    function rewardOf(address, uint256) external view returns (Reward[] memory);

    function rewardLength() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claim(address, uint256) external;

    function checkpoint(address, uint256) external;

    function invest(uint256) external;

    function divest(uint256) external;

    function emergencyWithdraw() external returns (uint256);

    function sweep(address) external;
}

interface IReinvestment is IReinvestmentProxy, IReinvestmentLogic {}