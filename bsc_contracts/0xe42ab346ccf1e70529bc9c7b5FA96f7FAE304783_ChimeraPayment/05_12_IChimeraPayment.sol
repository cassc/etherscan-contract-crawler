// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IChimeraPayment {
    event OpenPlan(
        address indexed user_,
        address indexed token_,
        address[] target_,
        uint256[] amount_,
        string userName_,
        uint256 plan_,
        uint256 nonce_,
        bytes operatorSign_,
        uint256 timestamp_
    );

    event SetOperator(
        address indexed sender_,
        address indexed oldOperator_,
        address indexed newOperator_,
        uint256 timestamp_
    );

    event ClaimReward(address indexed user_, address indexed token_, uint256 claimResult_, uint256 timestamp_);

    function operator() external view returns (address);

    function balance(address, address) external view returns (uint256);

    function usedNonces(uint256) external view returns (bool);

    function initialize(address operator_) external;

    function setOperator(address newOperator_) external;

    function openPlan(
        address token_,
        address[] memory target_,
        uint256[] memory amount_,
        string memory userName_,
        uint256 plan_,
        uint256 nonce_,
        bytes memory operatorSign
    ) external;

    function claimReward(address token_) external returns (uint256 claimResult_);
}