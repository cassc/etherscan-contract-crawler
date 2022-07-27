/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IRcaShield.sol";

interface IRcaController {
    event Mint(
        address indexed rcaShield,
        address indexed user,
        uint256 timestamp
    );
    event NewCapOracle(address indexed oldOracle, address indexed newOracle);
    event NewGuardian(address indexed oldGuardian, address indexed newGuardian);
    event NewPriceOracle(address indexed oldOracle, address indexed newOracle);
    event OwnershipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );
    event PendingOwnershipTransfer(address indexed from, address indexed to);
    event Purchase(
        address indexed rcaShield,
        address indexed user,
        uint256 timestamp
    );
    event RedeemFinalize(
        address indexed rcaShield,
        address indexed user,
        uint256 timestamp
    );
    event RedeemRequest(
        address indexed rcaShield,
        address indexed user,
        uint256 timestamp
    );
    event ShieldCancelled(address indexed rcaShield);
    event ShieldCreated(
        address indexed rcaShield,
        address indexed underlyingToken,
        string name,
        string symbol,
        uint256 timestamp
    );

    function activeShields(address) external view returns (bool);

    function apr() external view returns (uint256);

    function balanceOfs(address _user, address[] memory _tokens)
        external
        view
        returns (uint256[] memory balances);

    function cancelShield(address[] memory _shields) external;

    function capOracle() external view returns (address);

    function discount() external view returns (uint256);

    function getAprUpdate() external view returns (uint32);

    function getMessageHash(
        address _user,
        address _shield,
        uint256 _amount,
        uint256 _nonce,
        uint256 _expiry
    ) external view returns (bytes32);

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function initializeShield(address _shield) external;

    function isGov() external view returns (bool);

    function isRouterVerified(address) external view returns (bool);

    function lastShieldUpdate(address) external view returns (uint256);

    function liqForClaimsRoot() external view returns (bytes32);

    function mint(
        address _user,
        uint256 _uAmount,
        uint256 _expiry,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _newCumLiqForClaims,
        bytes32[] memory _liqForClaimsProof
    ) external;

    function nonces(address) external view returns (uint256);

    function priceOracle() external view returns (address);

    function priceRoot() external view returns (bytes32);

    function purchase(
        address _user,
        address _uToken,
        uint256 _ethPrice,
        bytes32[] memory _priceProof,
        uint256 _newCumLiqForClaims,
        bytes32[] memory _liqForClaimsProof
    ) external;

    function receiveOwnership() external;

    function redeemFinalize(
        address _user,
        address _to,
        uint256 _newCumLiqForClaims,
        bytes32[] memory _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] memory _percentReservedProof
    ) external returns (bool);

    function redeemRequest(
        address _user,
        uint256 _newCumLiqForClaims,
        bytes32[] memory _liqForClaimsProof,
        uint256 _newPercentReserved,
        bytes32[] memory _percentReservedProof
    ) external;

    function requestOfs(address _user, address[] memory _shields)
        external
        view
        returns (IRcaShield.WithdrawRequest[] memory requests);

    function reservedRoot() external view returns (bytes32);

    function setApr(uint256 _newApr) external;

    function setCapOracle(address _newCapOracle) external;

    function setDiscount(uint256 _newDiscount) external;

    function setGuardian(address _newGuardian) external;

    function setLiqTotal(bytes32 _newLiqRoot, bytes32 _newReservedRoot)
        external;

    function setPercentReserved(bytes32 _newReservedRoot) external;

    function setPriceOracle(address _newPriceOracle) external;

    function setPrices(bytes32 _newPriceRoot) external;

    function setRouterVerified(address _routerAddress, bool _verified) external;

    function setTreasury(address _newTreasury) external;

    function setWithdrawalDelay(uint256 _newWithdrawalDelay) external;

    function shieldMapping(address) external view returns (bool);

    function systemUpdates()
        external
        view
        returns (
            uint32 liqUpdate,
            uint32 reservedUpdate,
            uint32 withdrawalDelayUpdate,
            uint32 discountUpdate,
            uint32 aprUpdate,
            uint32 treasuryUpdate
        );

    function transferOwnership(address newGovernor) external;

    function treasury() external view returns (address);

    function verifyLiq(
        address _shield,
        uint256 _newCumLiqForClaims,
        bytes32[] memory _liqForClaimsProof
    ) external view;

    function verifyPrice(
        address _shield,
        uint256 _value,
        bytes32[] memory _proof
    ) external view;

    function verifyReserved(
        address _shield,
        uint256 _percentReserved,
        bytes32[] memory _proof
    ) external view;

    function withdrawalDelay() external view returns (uint256);
}