// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ILido {
    function resume() external;

    function name() external pure returns (string memory);

    function stop() external;

    function hasInitialized() external view returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function initialize(
        address depositContract,
        address _oracle,
        address _operators,
        address _treasury,
        address _insuranceFund
    ) external;

    function getInsuranceFund() external view returns (address);

    function totalSupply() external view returns (uint256);

    function getSharesByPooledEth(uint256 _ethAmount)
        external
        view
        returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    function getOperators() external view returns (address);

    function getEVMScriptExecutor(bytes calldata _script)
        external
        view
        returns (address);

    function decimals() external pure returns (uint8);

    function getRecoveryVault() external view returns (address);

    function DEPOSIT_ROLE() external view returns (bytes32);

    function DEPOSIT_SIZE() external view returns (uint256);

    function getTotalPooledEther() external view returns (uint256);

    function PAUSE_ROLE() external view returns (bytes32);

    function increaseAllowance(address _spender, uint256 _addedValue)
        external
        returns (bool);

    function getTreasury() external view returns (address);

    function SET_ORACLE() external view returns (bytes32);

    function isStopped() external view returns (bool);

    function MANAGE_WITHDRAWAL_KEY() external view returns (bytes32);

    function getBufferedEther() external view returns (uint256);

    function SIGNATURE_LENGTH() external view returns (uint256);

    function getWithdrawalCredentials() external view returns (bytes32);

    function balanceOf(address _account) external view returns (uint256);

    function getFeeDistribution()
        external
        view
        returns (
            uint16 treasuryFeeBasisPoints,
            uint16 insuranceFeeBasisPoints,
            uint16 operatorsFeeBasisPoints
        );

    function getPooledEthByShares(uint256 _sharesAmount)
        external
        view
        returns (uint256);

    function setOracle(address _oracle) external;

    function allowRecoverability(address token) external view returns (bool);

    function appId() external view returns (bytes32);

    function getOracle() external view returns (address);

    function getInitializationBlock() external view returns (uint256);

    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints
    ) external;

    function setFee(uint16 _feeBasisPoints) external;

    function depositBufferedEther(uint256 _maxDeposits) external;

    function symbol() external pure returns (string memory);

    function MANAGE_FEE() external view returns (bytes32);

    function transferToVault(address _token) external;

    function SET_TREASURY() external view returns (bytes32);

    function canPerform(
        address _sender,
        bytes32 _role,
        uint256[] calldata _params
    ) external view returns (bool);

    function submit(address _referral) external payable returns (uint256);

    function WITHDRAWAL_CREDENTIALS_LENGTH() external view returns (uint256);

    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        external
        returns (bool);

    function getEVMScriptRegistry() external view returns (address);

    function PUBKEY_LENGTH() external view returns (uint256);

    function withdraw(uint256 _amount, bytes32 _pubkeyHash) external;

    function transfer(address _recipient, uint256 _amount)
        external
        returns (bool);

    function getDepositContract() external view returns (address);

    function getBeaconStat()
        external
        view
        returns (
            uint256 depositedValidators,
            uint256 beaconValidators,
            uint256 beaconBalance
        );

    function BURN_ROLE() external view returns (bytes32);

    function setInsuranceFund(address _insuranceFund) external;

    function getFee() external view returns (uint16 feeBasisPoints);

    function SET_INSURANCE_FUND() external view returns (bytes32);

    function kernel() external view returns (address);

    function getTotalShares() external view returns (uint256);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function isPetrified() external view returns (bool);

    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    function depositBufferedEther() external;

    function burnShares(address _account, uint256 _sharesAmount)
        external
        returns (uint256 newTotalShares);

    function setTreasury(address _treasury) external;

    function pushBeacon(uint256 _beaconValidators, uint256 _beaconBalance)
        external;

    function sharesOf(address _account) external view returns (uint256);
}