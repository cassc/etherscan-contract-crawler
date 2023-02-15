// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./IValidatorShare.sol";
import "./INodeOperatorRegistry.sol";
import "./INodeOperatorRegistry.sol";
import "./IStakeManager.sol";
import "./IPoLidoNFT.sol";
import "./IFxStateRootTunnel.sol";

/// @title StMATIC interface.
/// @author 2021 ShardLabs
interface IStMATIC is IERC20Upgradeable {
    struct RequestWithdraw {
        uint256 amount2WithdrawFromStMATIC;
        uint256 validatorNonce;
        uint256 requestEpoch;
        address validatorAddress;
    }

    struct FeeDistribution {
        uint8 dao;
        uint8 operators;
        uint8 insurance;
    }

    function withdrawTotalDelegated(address _validatorShare) external;

    function nodeOperatorRegistry() external returns (INodeOperatorRegistry);

    function entityFees()
        external
        returns (
            uint8,
            uint8,
            uint8
        );

    function getMaticFromTokenId(uint256 _tokenId)
        external
        view
        returns (uint256);

    function stakeManager() external view returns (IStakeManager);

    function poLidoNFT() external view returns (IPoLidoNFT);

    function fxStateRootTunnel() external view returns (IFxStateRootTunnel);

    function version() external view returns (string memory);

    function dao() external view returns (address);

    function insurance() external view returns (address);

    function token() external view returns (address);

    function lastWithdrawnValidatorId() external view returns (uint256);

    function totalBuffered() external view returns (uint256);

    function delegationLowerBound() external view returns (uint256);

    function rewardDistributionLowerBound() external view returns (uint256);

    function reservedFunds() external view returns (uint256);

    function submitThreshold() external view returns (uint256);

    function submitHandler() external view returns (bool);

    function getMinValidatorBalance() external view returns (uint256);

    function token2WithdrawRequest(uint256 _requestId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address
        );

    function DAO() external view returns (bytes32);

    function initialize(
        address _nodeOperatorRegistry,
        address _token,
        address _dao,
        address _insurance,
        address _stakeManager,
        address _poLidoNFT,
        address _fxStateRootTunnel,
        uint256 _submitThreshold
    ) external;

    function submit(uint256 _amount) external returns (uint256);

    function requestWithdraw(uint256 _amount) external;

    function delegate() external;

    function claimTokens(uint256 _tokenId) external;

    function distributeRewards() external;

    function claimTotalDelegated2StMatic(uint256 _index) external;

    function togglePause() external;

    function getTotalStake(IValidatorShare _validatorShare)
        external
        view
        returns (uint256, uint256);

    function getLiquidRewards(IValidatorShare _validatorShare)
        external
        view
        returns (uint256);

    function getTotalStakeAcrossAllValidators() external view returns (uint256);

    function getTotalPooledMatic() external view returns (uint256);

    function convertStMaticToMatic(uint256 _balance)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function convertMaticToStMatic(uint256 _balance)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function setFees(
        uint8 _daoFee,
        uint8 _operatorsFee,
        uint8 _insuranceFee
    ) external;

    function setDaoAddress(address _address) external;

    function setInsuranceAddress(address _address) external;

    function setNodeOperatorRegistryAddress(address _address) external;

    function setDelegationLowerBound(uint256 _delegationLowerBound) external;

    function setRewardDistributionLowerBound(
        uint256 _rewardDistributionLowerBound
    ) external;

    function setPoLidoNFT(address _poLidoNFT) external;

    function setFxStateRootTunnel(address _fxStateRootTunnel) external;

    function setSubmitThreshold(uint256 _submitThreshold) external;

    function flipSubmitHandler() external;

    function setVersion(string calldata _version) external;
}