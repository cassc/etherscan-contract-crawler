//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { NonblockingLzAppUpgradeable } from "./lzApp/NonblockingLzAppUpgradeable.sol";

enum MessageType {
    CLAIM
}

struct ProjectConfig {
    address contractAddress;
    address repositoryAddress;
    bool configured;
}

contract SpectreClaim is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    NonblockingLzAppUpgradeable
{
    event Claim(
        bytes32 indexed project,
        address indexed to,
        uint256 indexed amount
    );
    event Configure(bytes32 project);
    event SendMessage(uint256 indexed nonce, bytes indexed payload);
    event ReceiveMessage(uint256 indexed nonce, bytes indexed payload);

    mapping(bytes32 => ProjectConfig) configuredProjects;

    function initialize(address _endpoint) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __LzAppUpgradeable_init(_endpoint);
    }

    function project(bytes32 project)
        external
        view
        returns (ProjectConfig memory)
    {
        ProjectConfig storage conf = configuredProjects[project];
        require(conf.configured, "project: not configured");
        return conf;
    }

    function configureProject(
        bytes32 project,
        address contractAddress,
        address repositoryAddress
    ) external onlyOwner {
        require(
            contractAddress != address(0),
            "configureProject: contractAddress is zero"
        );
        require(
            repositoryAddress != address(0),
            "configureProject: repositoryAddress is zero"
        );

        ProjectConfig storage conf = configuredProjects[project];
        require(
            !conf.configured,
            "configureProject: project already configured"
        );

        conf.configured = true;
        conf.contractAddress = contractAddress;
        conf.repositoryAddress = repositoryAddress;
        emit Configure(project);
    }

    function updateConfig(
        bytes32 project,
        address contractAddress,
        address repositoryAddress
    ) external onlyOwner {
        ProjectConfig storage conf = configuredProjects[project];
        require(conf.configured, "updateConfig: project not configured");
        conf.contractAddress = contractAddress;
        conf.repositoryAddress = repositoryAddress;
        emit Configure(project);
    }

    function projectConfig(bytes32 project)
        external
        view
        returns (ProjectConfig memory)
    {
        require(
            configuredProjects[project].configured,
            "projectConfig: not configured"
        );
        return configuredProjects[project];
    }

    function claim(
        bytes32 project,
        address to,
        uint256 amount
    ) internal nonReentrant {
        ProjectConfig storage conf = configuredProjects[project];
        require(conf.configured, "claim: project not configured");

        IERC20 token = IERC20(conf.contractAddress);
        require(
            token.allowance(conf.repositoryAddress, address(this)) >= amount,
            "claim: insufficient allowance"
        );

        require(
            token.transferFrom(conf.repositoryAddress, to, amount),
            "claim: transfer failed"
        );

        emit Claim(project, to, amount);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (bytes32 project, address to, uint128 amount) = abi.decode(
            _payload,
            (bytes32, address, uint128)
        );
        require(
            minDstGasLookup[_srcChainId][uint16(MessageType.CLAIM)] > 0,
            "_nonblockingLzReceive: minGasLimit not set"
        );

        emit ReceiveMessage(_nonce, _payload);

        claim(project, to, amount);

        bytes memory payload = abi.encode(project, to, true);

        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            minDstGasLookup[_srcChainId][uint16(MessageType.CLAIM)]
        );

        (uint256 nativeFee, ) = lzEndpoint.estimateFees(
            _srcChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        _lzSend(
            _srcChainId,
            payload,
            payable(address(this)),
            address(0),
            adapterParams,
            nativeFee
        );

        emit SendMessage(
            lzEndpoint.getOutboundNonce(_srcChainId, address(this)),
            payload
        );
    }

    receive() external payable {}
}