pragma solidity ^0.8.13;

// SPDX-License-Identifier: MIT

import { Test } from "lib/forge-std/src/Test.sol";

import { StakingFundsVault } from "../../contracts/liquid-staking/StakingFundsVault.sol";
import { SavETHVault } from "../../contracts/liquid-staking/SavETHVault.sol";
import { MockLiquidStakingManager } from "../../contracts/testing/liquid-staking/MockLiquidStakingManager.sol";
import { MockAccountManager } from "../../contracts/testing/stakehouse/MockAccountManager.sol";
import { SyndicateMock } from "../../contracts/testing/syndicate/SyndicateMock.sol";
import { LPToken } from "../../contracts/liquid-staking/LPToken.sol";
import { LPTokenFactory } from "../../contracts/liquid-staking/LPTokenFactory.sol";
import { GiantSavETHVaultPool } from "../../contracts/liquid-staking/GiantSavETHVaultPool.sol";
import { GiantMevAndFeesPool } from "../../contracts/liquid-staking/GiantMevAndFeesPool.sol";
import { MockGiantMevAndFeesPool } from "../../contracts/testing/liquid-staking/MockGiantMevAndFeesPool.sol";
import { MockBrandNFT } from "../../contracts/testing/stakehouse/MockBrandNFT.sol";
import { MockStakeHouseUniverse } from "../../contracts/testing/stakehouse/MockStakeHouseUniverse.sol";
import { MockSlotRegistry } from "../../contracts/testing/stakehouse/MockSlotRegistry.sol";
import { MockLSDNFactory } from "../../contracts/testing/liquid-staking/MockLSDNFactory.sol";
import { LSDNFactory } from "../../contracts/liquid-staking/LSDNFactory.sol";
import { OwnableSmartWalletFactory } from "../../contracts/smart-wallet/OwnableSmartWalletFactory.sol";
import { SavETHVaultDeployer } from "../../contracts/liquid-staking/SavETHVaultDeployer.sol";
import { GiantLPDeployer } from "../../contracts/liquid-staking/GiantLPDeployer.sol";
import { StakingFundsVaultDeployer } from "../../contracts/liquid-staking/StakingFundsVaultDeployer.sol";
import { OptionalGatekeeperFactory } from "../../contracts/liquid-staking/OptionalGatekeeperFactory.sol";
import { MockSavETHVault } from "../../contracts/testing/liquid-staking/MockSavETHVault.sol";
import { MockStakingFundsVault } from "../../contracts/testing/liquid-staking/MockStakingFundsVault.sol";
import { MockGiantSavETHVaultPool } from "../../contracts/testing/liquid-staking/MockGiantSavETHVaultPool.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";

contract TestUtils is Test {

    // Instances that can be shared across all test contracts
    MockLSDNFactory factory;
    MockLiquidStakingManager manager;
    MockSavETHVault savETHVault;
    MockStakingFundsVault stakingFundsVault;

    // Create implementation contracts
    MockLiquidStakingManager managerImplementation = new MockLiquidStakingManager();
    SyndicateMock syndicateImplementation = new SyndicateMock();
    LPToken lpTokenImplementation = new LPToken();

    // Create periphery contracts
    LPTokenFactory lpTokenFactory = new LPTokenFactory(address(lpTokenImplementation), msg.sender);
    OwnableSmartWalletFactory smartWalletFactory = new OwnableSmartWalletFactory();
    MockBrandNFT brand = new MockBrandNFT();
    SavETHVaultDeployer vaultDeployer = new SavETHVaultDeployer(msg.sender);
    StakingFundsVaultDeployer stakingFundsDeployer = new StakingFundsVaultDeployer(msg.sender);
    OptionalGatekeeperFactory keeperDeployer = new OptionalGatekeeperFactory();

    MockGiantSavETHVaultPool gSavETHVaultImplementation = new MockGiantSavETHVaultPool();
    MockGiantMevAndFeesPool gMevImplementation = new MockGiantMevAndFeesPool();
    GiantLPDeployer giantLPDeployer = new GiantLPDeployer();

    /// Define some test BLS keys
    bytes blsPubKeyOne = fromHex("94fdc9a61a34eb6a034e343f20732456443a2ed6668ede04677adc1e15d2a24500a3e05cf7ad3dc3b2f3cc13fdc12af5");
    bytes blsPubKeyTwo = fromHex("9AAdc9a61a34eb6a034e343f20732456443a2ed6668ede04677adc1e15d2a24500a3e05cf7ad3dc3b2f3cc13fdc12af5");
    bytes blsPubKeyThree = fromHex("9AAdcff61a34eb6a034e343f20732456443a2ed6668ede04677adc1e15d2a24500a3e05cf7ad3dc3b2f3cc13fdc12fff");
    bytes blsPubKeyFour = fromHex("2aBdcff61a34eb6a034e343f20732456443a2ed6668ede04677adc1e15d2a24500a3e05cf7ad3dc3b2f3cc13fdc12fff");
    // bytes blsPubKeyFive = fromHex("0xaa44b24a1498bf1a93aaca796a1eed603d6698b4fcfdc6ef653322ff703432200befa65d11211bc89815c17cd8ea260d");

    /// Define some test accounts
    address accountOne = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address accountTwo = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address accountThree = 0xdD2FD4581271e230360230F9337D5c0430Bf44C0;
    address accountFour = 0xbDA5747bFD65F08deb54cb465eB87D40e51B197E;
    address accountFive = 0x2546BcD3c84621e976D8185a91A922aE77ECEc30;
    address accountSix = 0x05a8458f59Ae37886A97B2E81127654D4f55dfFA;

    address admin = 0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199;

    address houseOne = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address houseTwo = 0xcd3B766CCDd6AE721141F452C550Ca635964ce71;

    function getSavETHVaultFromManager(MockLiquidStakingManager _manager) public view returns (MockSavETHVault) {
        return MockSavETHVault(address(_manager.savETHVault()));
    }

    function getStakingFundsVaultFromManager(MockLiquidStakingManager _manager) public view returns (MockStakingFundsVault) {
        return MockStakingFundsVault(payable(address(_manager.stakingFundsVault())));
    }

    function depositIntoDefaultSavETHVault(address _user, bytes memory _blsKey, uint256 _amount) public {
        vm.startPrank(_user);
        savETHVault.depositETHForStaking{value: _amount}(_blsKey, _amount);
        vm.stopPrank();
    }

    function depositIntoCustomSavETHVault(SavETHVault _savETHVault, address _user, bytes memory _blsKey, uint256 _amount) public {
        vm.startPrank(_user);
        vm.deal(_user, _amount);
        _savETHVault.depositETHForStaking{value: _amount}(_blsKey, _amount);
        vm.stopPrank();
    }

    function depositIntoDefaultStakingFundsVault(address _user, bytes memory _blsKey, uint256 _amount) public {
        vm.startPrank(_user);
        manager.stakingFundsVault().depositETHForStaking{value: _amount}(_blsKey, _amount);
        vm.stopPrank();
    }

    function depositIntoCustomStakingFundsVault(StakingFundsVault _stakingFundsVault, address _user, bytes memory _blsKey, uint256 _amount) public {
        vm.startPrank(_user);
        vm.deal(_user, _amount);
        _stakingFundsVault.depositETHForStaking{value: _amount}(_blsKey, _amount);
        vm.stopPrank();
    }

    function depositStakeAndMintDerivativesForDefaultNetwork(
        address _nodeRunner,
        address _feesAndMevUser,
        address _savETHUser,
        bytes memory _blsKey
    ) public {
        registerSingleBLSPubKey(_nodeRunner, _blsKey, accountFour);
        depositIntoDefaultSavETHVault(_savETHUser, _blsKey, 24 ether);
        depositIntoDefaultStakingFundsVault(_feesAndMevUser, _blsKey, 4 ether);
        stakeAndMintDerivativesSingleKey(_blsKey);
    }

    function depositStakeAndMintDerivativesForCustomAccountAndCustomNetwork(
        address _nodeRunner,
        address _feesAndMevUser,
        address _savETHUser,
        address user,
        bytes memory _blsKey,
        MockLiquidStakingManager _manager,
        StakingFundsVault _stakingFundsVault,
        SavETHVault _savETHVault
    ) public {
        registerSingleBLSPubKey(_nodeRunner, _blsKey, user, _manager);
        depositIntoCustomSavETHVault(_savETHVault, _savETHUser, _blsKey, 24 ether);
        depositIntoCustomStakingFundsVault(_stakingFundsVault, _feesAndMevUser, _blsKey, 4 ether);
        stakeAndMintDerivativesSingleKey(_blsKey, _manager);
    }

    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) public pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
        revert("fail");
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(string memory s) public pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }

    function getEmptyBytesArray() public pure returns (bytes[] memory) {
        bytes[] memory array = new bytes[](0);
        return array;
    }

    function getBytesArrayFromBytes(bytes memory data) public pure returns (bytes[] memory) {
        bytes[] memory array = new bytes[](1);
        array[0] = data;
        return array;
    }

    function getBytesArrayFromBytes(bytes memory data, bytes memory data2) public pure returns (bytes[] memory) {
        bytes[] memory array = new bytes[](2);
        array[0] = data;
        array[1] = data2;
        return array;
    }

    function getBytesArrayFromBytes(bytes memory data, bytes memory data2, bytes memory data3) public pure returns (bytes[] memory) {
        bytes[] memory array = new bytes[](3);
        array[0] = data;
        array[1] = data2;
        array[2] = data3;
        return array;
    }

    function getEmptyUint256Array() public pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](0);
        return array;
    }

    function getUint256ArrayFromValues(uint256 data) public pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = data;
        return array;
    }

    function getUint256ArrayFromValues(uint256 data, uint256 data2) public pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](2);
        array[0] = data;
        array[1] = data2;
        return array;
    }

    function getUint256ArrayFromValues(uint256 data, uint256 data2, uint256 data3) public pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](3);
        array[0] = data;
        array[1] = data2;
        array[2] = data3;
        return array;
    }

    function getAddressArrayFromValues(address data) public pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = data;
        return array;
    }

    function getAddressArrayFromValues(address data, address data2) public pure returns (address[] memory) {
        address[] memory array = new address[](2);
        array[0] = data;
        array[1] = data2;
        return array;
    }

    function getFakeEIP712Signature() public view returns (IDataStructures.EIP712Signature memory, IDataStructures.EIP712Signature[] memory) {
        IDataStructures.EIP712Signature memory sig;
        IDataStructures.EIP712Signature[] memory sigs = new IDataStructures.EIP712Signature[](1);
        sigs[0] = sig;
        return (sig, sigs);
    }

    function getFakeBalanceReport() public view returns (IDataStructures.ETH2DataReport memory, IDataStructures.ETH2DataReport[] memory) {
        IDataStructures.ETH2DataReport memory report;
        IDataStructures.ETH2DataReport[] memory reports = new IDataStructures.ETH2DataReport[](1);
        reports[0] = report;
        return (report, reports);
    }

    function getRandomArrayOfBytes32() public pure returns (bytes32[] memory) {
        bytes32[] memory roots = new bytes32[](1);
        roots[0] = keccak256(abi.encode(""));
        return roots;
    }

    function createMockLSDNFactory() public returns (MockLSDNFactory) {
        LSDNFactory.InitParams memory params = LSDNFactory.InitParams(
            address(managerImplementation),
            address(managerImplementation), // MockLSDNFactory will override the _syndicateFactory param
            address(lpTokenFactory),
            address(smartWalletFactory),
            address(brand),
            address(vaultDeployer),
            address(stakingFundsDeployer),
            address(keeperDeployer),
            address(gSavETHVaultImplementation),
            address(gMevImplementation),
            address(giantLPDeployer),
            accountFive
        );

        // Create LSDN factory
        return new MockLSDNFactory(params);
    }

    function deployNewLiquidStakingNetwork(
        MockLSDNFactory _factory,
        address _admin,
        bool _deployOptionalGatekeeper,
        string memory _ticker
    ) public returns (MockLiquidStakingManager) {
        return MockLiquidStakingManager(payable(_factory.deployNewMockLiquidStakingDerivativeNetwork(
                _admin,
                _deployOptionalGatekeeper,
                _ticker
            )));
    }

    function deployNewLiquidStakingNetworkWithCommission(
        MockLSDNFactory _factory,
        uint256 _commission,
        address _admin,
        bool _deployOptionalGatekeeper,
        string memory _ticker
    ) public returns (MockLiquidStakingManager) {
        return MockLiquidStakingManager(payable(_factory.deployNewMockLiquidStakingDerivativeNetworkWithCommission(
                _admin,
                _commission,
                _deployOptionalGatekeeper,
                _ticker
            )));
    }

    function deployDefaultLiquidStakingNetwork(
        MockLSDNFactory _factory,
        address _admin
    ) public returns (MockLiquidStakingManager) {
        return MockLiquidStakingManager(payable(_factory.deployNewMockLiquidStakingDerivativeNetwork(
                _admin,
                false,
                "LSDN"
            )));
    }

    function registerSingleBLSPubKey(
        address _nodeRunner,
        bytes memory _blsKey,
        address _eoaRepresentative
    ) public {
        vm.deal(_nodeRunner, 4 ether);
        vm.startPrank(_nodeRunner);
        manager.registerBLSPublicKeys{ value: 4 ether }(
            getBytesArrayFromBytes(_blsKey),
            getBytesArrayFromBytes(_blsKey),
            _eoaRepresentative
        );
        vm.stopPrank();

        // Simulate state transitions in lifecycle status to initials registered (value of 1)
        MockAccountManager(factory.accountMan()).setLifecycleStatus(_blsKey, 1);

        // set user as first collateralized owner
        MockSlotRegistry(factory.slot()).setNumberOfCollateralisedSlotOwnersForKnot(_blsKey, 1);
        MockSlotRegistry(factory.slot()).setCollateralisedOwnerAtIndex(
            _blsKey,
            0,
            manager.smartWalletOfNodeRunner(_nodeRunner)
        );
    }

    function registerSingleBLSPubKey(
        address _nodeRunner,
        bytes memory _blsKey,
        address _eoaRepresentative,
        MockLiquidStakingManager _manager
    ) public {
        vm.deal(_nodeRunner, 4 ether);
        vm.startPrank(_nodeRunner);
        _manager.registerBLSPublicKeys{ value: 4 ether }(
            getBytesArrayFromBytes(_blsKey),
            getBytesArrayFromBytes(_blsKey),
            _eoaRepresentative
        );
        vm.stopPrank();

        // Simulate state transitions in lifecycle status to initials registered (value of 1)
        MockAccountManager(factory.accountMan()).setLifecycleStatus(_blsKey, 1);

        // set user as first collateralized owner
        MockSlotRegistry(factory.slot()).setNumberOfCollateralisedSlotOwnersForKnot(_blsKey, 1);
        MockSlotRegistry(factory.slot()).setCollateralisedOwnerAtIndex(
            _blsKey,
            0,
            _manager.smartWalletOfNodeRunner(_nodeRunner)
        );
    }

    function stakeSingleBlsPubKey(
        bytes memory _blsKey,
        MockLiquidStakingManager _manager
    ) public {
        (,IDataStructures.EIP712Signature[] memory sigs) = getFakeEIP712Signature();
        _manager.stake(
            getBytesArrayFromBytes(_blsKey),
            getBytesArrayFromBytes(_blsKey),
            getBytesArrayFromBytes(_blsKey),
            sigs,
            getRandomArrayOfBytes32()
        );
    }

    // https://code4rena.com/reports/2022-11-stakehouse/#m-20-smartwallet-address-is-not-guaranteed-correct-eth-may-be-lost
    // We are checking in manager that smart wallet of KNOT is not address zero
    function stakeSingleBlsPubKey(bytes memory _blsKey) public {
        (,IDataStructures.EIP712Signature[] memory sigs) = getFakeEIP712Signature();
        manager.stake(
            getBytesArrayFromBytes(_blsKey),
            getBytesArrayFromBytes(_blsKey),
            getBytesArrayFromBytes(_blsKey),
            sigs,
            getRandomArrayOfBytes32()
        );
    }

    function mintDerivativesSingleBlsPubKey(bytes memory _blsKey) public {
        (,IDataStructures.ETH2DataReport[] memory reports) = getFakeBalanceReport();
        (,IDataStructures.EIP712Signature[] memory sigs) = getFakeEIP712Signature();

        MockStakeHouseUniverse(factory.uni()).setAssociatedHouseForKnot(_blsKey, manager.stakehouse());

        manager.mintDerivatives(
            getBytesArrayFromBytes(_blsKey),
            reports,
            sigs
        );

        // set associated house info
        MockSlotRegistry(factory.slot()).setUserCollateralisedSLOTBalanceForKnot(
            manager.stakehouse(),
            MockSlotRegistry(factory.slot()).getCollateralisedOwnerAtIndex(_blsKey, 0),  // get user that registered initials
            _blsKey,
            4 ether
        );
    }

    function mintDerivativesSingleBlsPubKey(
        bytes memory _blsKey,
        MockLiquidStakingManager _manager
    ) public {
        (,IDataStructures.ETH2DataReport[] memory reports) = getFakeBalanceReport();
        (,IDataStructures.EIP712Signature[] memory sigs) = getFakeEIP712Signature();

        MockStakeHouseUniverse(factory.uni()).setAssociatedHouseForKnot(_blsKey, _manager.stakehouse());

        _manager.mintDerivatives(
            getBytesArrayFromBytes(_blsKey),
            reports,
            sigs
        );

        // set associated house info
        MockSlotRegistry(factory.slot()).setUserCollateralisedSLOTBalanceForKnot(
            _manager.stakehouse(),
            MockSlotRegistry(factory.slot()).getCollateralisedOwnerAtIndex(_blsKey, 0),  // get user that registered initials
            _blsKey,
            4 ether
        );
    }

    function stakeAndMintDerivativesSingleKey(
        bytes memory _blsKey
    ) public {
        // Stake the ETH with the deposit contract by spending 4 + 4 + 24 ETH from the individual pools
        stakeSingleBlsPubKey(_blsKey);

        // Simulate state transitions in lifecycle status to ETH deposited (value of 2)
        MockAccountManager(factory.accountMan()).setLifecycleStatus(_blsKey, 2);

        // Mint derivatives for the knot
        mintDerivativesSingleBlsPubKey(_blsKey);

        // Simulate state transitions in lifecycle status to derivatives minted (value of 3)
        MockAccountManager(factory.accountMan()).setLifecycleStatus(_blsKey, 3);
    }

    function stakeAndMintDerivativesSingleKey(
        bytes memory _blsKey,
        MockLiquidStakingManager _manager
    ) public {
        // Stake the ETH with the deposit contract by spending 4 + 4 + 24 ETH from the individual pools
        stakeSingleBlsPubKey(_blsKey, _manager);

        // Simulate state transitions in lifecycle status to ETH deposited (value of 2)
        MockAccountManager(factory.accountMan()).setLifecycleStatus(_blsKey, 2);

        // Mint derivatives for the knot
        mintDerivativesSingleBlsPubKey(_blsKey, _manager);

        // Simulate state transitions in lifecycle status to derivatives minted (value of 3)
        MockAccountManager(factory.accountMan()).setLifecycleStatus(_blsKey, 3);
    }

    function sendEIP1559RewardsToSyndicateAtAddress(uint256 _eip1559Reward, address _syndicate) public {
        (bool success, ) = _syndicate.call{value: _eip1559Reward}("");
        assertEq(success, true);
        assertGe(_syndicate.balance, _eip1559Reward);
    }
}