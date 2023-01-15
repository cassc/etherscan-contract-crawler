// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./proxy.sol";
import "./emitter.sol";
import "./implementation.sol";

/// @title StationXFactory Cloning Contract
/// @dev Contract create proxies of DAO Token and Governor contract
contract FactoryCloneContract is Ownable {
    address public ImplementationAddress;
    address public USDCAddress;
    address public emitterAddress;

    struct DAO {
        string DaoName;
        string DaoSymbol;
        uint256 totalRaiseAmount;
        uint256 minDepositPerUser;
        uint256 maxDepositPerUser;
        uint256 ownerFeePerDeposit;
        uint256 depositFunctioningDays;
        bool feeUSDC;
        uint256 quorum;
        uint256 threshold;
        address gnosisAddress;
        address[] daoAdmins;
    }

    /// @dev Initial Deployment of Token and Governor contract and storing their addresses for proxies creation
    constructor(address _USDC) {
        require(_USDC != address(0), "Invalid address");

        //Deploying implementation contract for the reference
        ImplementationAddress = address(new ERC20NonTransferable());

        //USDC address
        USDCAddress = _USDC;

        //Deploying Emitter contract
        address emitterImplementation = address(new Emitter());

        //data
        bytes memory data = abi.encodeWithSignature(
            "Initialize(address,address,address)",
            ImplementationAddress,
            _USDC,
            address(this)
        );

        //owner
        address owner = msg.sender;

        //proxy
        emitterAddress = address(
            new ProxyContract(emitterImplementation, owner, data)
        );
    }

    /// @dev Function to change base Governor contract address
    /// @param _newImplementationAddress address of new Governor contract
    function changeDAOImplementation(address _newImplementationAddress)
        external
        onlyOwner
    {
        require(_newImplementationAddress != address(0), "Invalid address");

        ImplementationAddress = _newImplementationAddress;
        Emitter(emitterAddress).changeImplementationAddress(
            _newImplementationAddress
        );
    }

    /// @dev Function to create proxies and initialization of Token and Governor contract
    function createDAO(DAO calldata _params, bool _isGovernanceActive)
        external
        returns (address)
    {
        bytes memory data = abi.encodeWithSignature(
            "initializeERC20(string,string,uint256,uint256,uint256,uint256,uint256,bool,uint256,uint256,address,address,address,address[],bool)",
            _params.DaoName,
            _params.DaoSymbol,
            _params.totalRaiseAmount,
            _params.minDepositPerUser,
            _params.maxDepositPerUser,
            _params.ownerFeePerDeposit,
            _params.depositFunctioningDays,
            _params.feeUSDC,
            _params.quorum,
            _params.threshold,
            _params.gnosisAddress,
            USDCAddress,
            emitterAddress,
            _params.daoAdmins,
            _isGovernanceActive
        );
        address owner = owner();
        address proxy = address(
            new ProxyContract(ImplementationAddress, owner, data)
        );
        Emitter(emitterAddress).createDao(
            _params.gnosisAddress,
            proxy,
            _params.DaoName,
            _params.DaoSymbol,
            _params.totalRaiseAmount,
            _params.minDepositPerUser,
            _params.maxDepositPerUser,
            _params.ownerFeePerDeposit,
            _params.depositFunctioningDays,
            _params.feeUSDC,
            _params.quorum,
            _params.threshold,
            emitterAddress,
            USDCAddress,
            _params.daoAdmins,
            _isGovernanceActive
        );

        return proxy;
    }

    /// @dev Function to assign USDC address
    /// @param _newUSDCAddress address of USDC token
    function changeUSDCAddress(address _newUSDCAddress) external onlyOwner {
        require(_newUSDCAddress != address(0), "Invalid address");

        USDCAddress = _newUSDCAddress;
        Emitter(emitterAddress).changedUSDCAddress(_newUSDCAddress);
    }
}