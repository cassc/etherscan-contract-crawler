// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IVesting } from "./IVesting.sol";

contract VestingFactory is Initializable, Ownable {
    address public vestingImplementation;

    mapping(address => bool) public admins;

    event VestingDeployed(address indexed vesting);

    event VestingInitialized(
        address vestingAddress,
        address vestedTokenAddress,
        address deployer,
        address indexed recipient,
        uint256 lockedAmount,
        uint256 unlockTime,
        uint256 cliffTime
    );

    constructor(address[] memory _admins, address _vestingImplementation) {
        for (uint256 i = 0; i < _admins.length; i++) {
            require(_admins[i] != address(0), "Admin cannot be zero address");
            admins[_admins[i]] = true;
        }

        vestingImplementation = _vestingImplementation;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can call this function");
        _;
    }

    function addAdmin(address _newAdmin) external {
        require(admins[msg.sender], "Only admins may add new admins");
        require(_newAdmin != address(0));
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _oldAdmin) external {
        require(admins[msg.sender], "Only admins may remove admins");
        require(_oldAdmin != address(0));
        admins[_oldAdmin] = false;
    }

    function deployVestings(uint256 numberOfContracts) external onlyAdmin returns (address[] memory) {
        require(numberOfContracts > 0, "Number of contracts must be greater than zero");

        address[] memory vestings = new address[](numberOfContracts);
        for (uint256 i = 0; i < numberOfContracts; i++) {
            address vesting = Clones.clone(vestingImplementation);
            IVesting(vesting).setInitializeAdmin(address(this));
            vestings[i] = vesting;
            emit VestingDeployed(vesting);
        }

        return vestings;
    }

    function initVestings(
        address _vestedTokenAddress,
        address[] memory _vestings,
        address[] memory _recipients,
        uint256[] memory _lockPeriods,
        uint256[] memory _cliffTimes,
        uint256[] memory _amounts
    ) external onlyAdmin {
        require(_vestedTokenAddress != address(0), "Token address cannot be zero address");
        require(_recipients.length > 0, "Must init at least one vesting contract");
        require(
            _recipients.length == _vestings.length &&
                _recipients.length == _lockPeriods.length &&
                _recipients.length == _amounts.length &&
                _recipients.length == _cliffTimes.length,
            "Arrays must be of equal length"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            IVesting(_vestings[i]).initialize(
                address(_vestedTokenAddress),
                _recipients[i],
                _lockPeriods[i],
                _cliffTimes[i],
                _amounts[i]
            );

            emit VestingInitialized(
                _vestings[i],
                _vestedTokenAddress,
                msg.sender,
                _recipients[i],
                _amounts[i],
                _lockPeriods[i],
                _cliffTimes[i]
            );
        }
    }

    function createVestingsFactoryBalance(
        address _vestedTokenAddress,
        address[] memory _recipients,
        uint256[] memory _lockPeriods,
        uint256[] memory _cliffTimes,
        uint256[] memory _amounts
    ) external onlyAdmin returns (address[] memory) {
        uint256 numberOfContracts = _recipients.length;
        require(numberOfContracts > 0, "Must deploy at least one vesting contract");
        require(
            numberOfContracts == _lockPeriods.length &&
                numberOfContracts == _amounts.length &&
                numberOfContracts == _cliffTimes.length,
            "Arrays must be of equal length"
        );

        address[] memory vestings = new address[](numberOfContracts);
        for (uint256 i = 0; i < numberOfContracts; i++) {
            address vesting = Clones.clone(vestingImplementation);
            vestings[i] = vesting;
            emit VestingDeployed(vesting);

            IERC20(_vestedTokenAddress).transfer(vesting, _amounts[i]);

            IVesting(vesting).initialize(
                address(_vestedTokenAddress),
                _recipients[i],
                _lockPeriods[i],
                _cliffTimes[i],
                _amounts[i]
            );

            emit VestingInitialized(
                vesting,
                _vestedTokenAddress,
                msg.sender,
                _recipients[i],
                _amounts[i],
                _lockPeriods[i],
                _cliffTimes[i]
            );
        }

        return vestings;
    }
}