// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import { Errors } from "./helpers/Errors.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";

import { MetavisorManagedVault } from "./vaults/MetavisorManagedVault.sol";
import { VaultType, VaultSpec } from "./vaults/MetavisorBaseVault.sol";

uint256 constant DENOMINATOR = 100_00; // 100%

contract MetavisorRegistry is Ownable2Step {
    IWETH9 public immutable weth;
    IUniswapV3Factory public immutable uniswapFactory;

    mapping(address => bool) private isOperator;

    bool public openRescale;
    bool public openDeploy;

    address private feeReceiver;
    uint256 private feeNumerator;

    uint256 public swapPercentage;

    address public immutable vaultMaster;

    // pool => VaultType => vault
    mapping(address => mapping(VaultType => address)) public deployedVaults;
    // vault => VaultSpec
    mapping(address => VaultSpec) public vaultSpec;
    address[] private allVaults;

    event VaultCreated(address indexed pool, VaultType indexed vaultType, address indexed vault);
    event OperatorSet(address indexed operator, bool enabled);
    event FeeParametersSet(address feeReceiver, uint256 feeNumerator);
    event VaultSpecUpdated(address indexed vault, VaultSpec spec);

    constructor(address _uniswapFactory, address _weth, uint256 _swapPercentage) {
        if (_uniswapFactory == address(0) || _weth == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (_swapPercentage >= DENOMINATOR) {
            revert Errors.InvalidNumerator(_swapPercentage);
        }

        uniswapFactory = IUniswapV3Factory(_uniswapFactory);
        weth = IWETH9(_weth);
        swapPercentage = _swapPercentage;

        vaultMaster = address(new MetavisorManagedVault());

        isOperator[msg.sender] = true;
    }

    /*
     ** Protocol Management
     */
    function setOperator(address _address, bool _enabled) external onlyOwner {
        isOperator[_address] = _enabled;
        emit OperatorSet(_address, _enabled);
    }

    function setFeeParameters(address _feeReceiver, uint256 _feeNumerator) external onlyOwner {
        if (feeReceiver == _feeReceiver && feeNumerator == _feeNumerator) {
            revert Errors.AlreadySet();
        }
        if (_feeNumerator >= DENOMINATOR) {
            revert Errors.InvalidNumerator(_feeNumerator);
        }

        feeReceiver = _feeReceiver;
        feeNumerator = _feeNumerator;
        emit FeeParametersSet(_feeReceiver, _feeNumerator);
    }

    function setSwapPercentage(uint256 _newSwapPercentage) external onlyOwner {
        if (swapPercentage == _newSwapPercentage) {
            revert Errors.AlreadySet();
        }
        if (swapPercentage >= DENOMINATOR) {
            revert Errors.InvalidNumerator(swapPercentage);
        }
        swapPercentage = _newSwapPercentage;
    }

    /*
     ** Vault Information
     */
    function deployVault(
        address _pool,
        VaultType _vaultType,
        VaultSpec calldata _vaultSpec
    ) external returns (address) {
        if (!openDeploy) {
            _checkOwner();
        }

        if (deployedVaults[_pool][_vaultType] != address(0)) {
            revert Errors.AlreadyDeployed();
        }

        address _newVault = Clones.cloneDeterministic(
            vaultMaster,
            keccak256(abi.encodePacked(_pool, _vaultType))
        );
        setVaultSpec(_newVault, _vaultSpec);

        MetavisorManagedVault(payable(_newVault)).__MetavisorManagedVault__init(
            address(this),
            _pool,
            _vaultType
        );
        deployedVaults[_pool][_vaultType] = _newVault;
        allVaults.push(_newVault);

        emit VaultCreated(_pool, _vaultType, _newVault);

        return _newVault;
    }

    function setVaultSpec(address _vault, VaultSpec memory _vaultSpec) public onlyOwner {
        vaultSpec[_vault] = _vaultSpec;

        emit VaultSpecUpdated(_vault, _vaultSpec);
    }

    /*
     ** Permissions
     */
    function isAllowedToRescale(address _sender) external view returns (bool) {
        return openRescale || isOperator[_sender];
    }

    function setOpenRescale(bool _isOpenRescale) external onlyOwner {
        if (openRescale == _isOpenRescale) {
            revert Errors.AlreadySet();
        }
        openRescale = _isOpenRescale;
    }

    function setOpenDeploy(bool _isOpenDeploy) external onlyOwner {
        if (openDeploy == _isOpenDeploy) {
            revert Errors.AlreadySet();
        }
        openDeploy = _isOpenDeploy;
    }

    /*
     ** Protocol Details
     */
    function getAllVaults() external view returns (address[] memory) {
        return allVaults;
    }

    function getProtocolDetails()
        external
        view
        returns (address _governer, address _feeReceiver, uint256 _feeNumerator)
    {
        return (owner(), feeReceiver, feeNumerator);
    }
}