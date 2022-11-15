// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/INft.sol";
import "./Dynamic.sol";

contract Treasury is ITreasury, AccessControl, ReentrancyGuard {
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address private cap3Wallet;
    address private genesisAddress;
    address public dynamicNftAddress;

    uint256 public referralAmount = 0.02 ether;

    bool public isShutdown;

    mapping(address => uint256) private projectBalances;
    mapping(address => uint256) public totalReferralFundsRecieved;

    constructor(
        address _cap3Wallet,
        address _genesisAddress,
        address[] memory _admins
    ) {
        require(_cap3Wallet != address(0), "ADDRESS ZERO");
        require(_genesisAddress != address(0), "ADDRESS ZERO");

        cap3Wallet = _cap3Wallet;
        genesisAddress = _genesisAddress;

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _admins[0]);
        _setupRole(ADMIN_ROLE, _admins[1]);
        _setupRole(ADMIN_ROLE, address(this));
    }

    /*------ Events -------*/

    event Received(address sender, uint256 amount);
    event WithdrawnToProjectWallet(address _projectWallet, uint256 _amount);
    event Shutdown();
    event DynamicNftAddressSet(address dynamicNftAddress, string Role1);
    event GenesisLimitSet(uint256 genesisCap);
    event ProjectBalanceSet(address projectWallet, uint256 balance);
    event FundsMovedToCap3Wallet(uint256 amount, address wallet);
    event UpdatedCoreContractAddress(address coreContractAddress, string Role);
    event Refunded(address to, uint256 _amount);
    event UpdatedReferralAmount(uint256 oldAmount, uint256 newAmount);
    event ReferralPaid(address reciever, uint256 amount);

    /* ----- State changing functions ------ */

    function shutdown(bool _isShutdown) public onlyRole(ADMIN_ROLE) {
        isShutdown = _isShutdown;
        emit Shutdown();
    }

    function setDynamicNFTAddress(address _dynamicNftAddress) public onlyRole(ADMIN_ROLE) {
        require(_dynamicNftAddress != address(0), "ADDRESS ZERO");

        dynamicNftAddress = _dynamicNftAddress;
        _setupRole(EXECUTOR_ROLE, _dynamicNftAddress);
        _setupRole(ADMIN_ROLE, _dynamicNftAddress);
        emit DynamicNftAddressSet(_dynamicNftAddress, "EXECUTOR_ROLE");
    }

    function setProjectBalance(address _projectWallet, uint256 _balance) public onlyRole(EXECUTOR_ROLE) {
        require(_projectWallet != address(0), "ADDRESS ZERO");
        projectBalances[_projectWallet] = _balance;
        emit ProjectBalanceSet(_projectWallet, _balance);
    }

    function setAdminRole(address _adminAddress) public onlyRole(ADMIN_ROLE) {
        _setupRole(ADMIN_ROLE, _adminAddress);
    }

    function setReferralAmount(uint256 _newAmount) public onlyRole(ADMIN_ROLE) {
        uint256 oldAmount = referralAmount;
        referralAmount = _newAmount;
        emit UpdatedReferralAmount(oldAmount, _newAmount);
    }

    function withdrawToProjectWallet(address _projectWallet, uint256 _amount)
        public
        onlyRole(EXECUTOR_ROLE)
        notShutdown
        nonReentrant
    {
        require(_projectWallet != address(0), "NO ZERO ADDRESS WITHDRAWAL");
        require(address(this).balance >= _amount, "INSUFFICIENT FUNDS");
        require(_amount > 0, "CANNOT WITHDRAW ZERO");
        require(_amount <= projectBalances[_projectWallet], "INSUFFICIENT FUNDS ALLOCATION");
        projectBalances[_projectWallet] -= _amount;

        (bool sent, ) = _projectWallet.call{value: _amount}("");
        require(sent, "FAILED TO SEND ETHER");

        emit WithdrawnToProjectWallet(_projectWallet, _amount);
    }

    function moveFundsOutOfTreasury() public onlyRole(ADMIN_ROLE) notShutdown nonReentrant {
        require(dynamicNftAddress != address(0), "DYNAMIC ADDRESS NOT SET");

        INft genesisNFT = INft(genesisAddress);
        DynamicNft dynamicContract = DynamicNft(dynamicNftAddress);
        require(genesisNFT.totalSupply() == dynamicContract.getGenesisSupply(), "GENESIS NFT SALE NOT COMPLETED");
        _moveFundsOutOfTreasury();
    }

    function payRefund(address _to, uint256 _amount) external nonReentrant onlyRole(EXECUTOR_ROLE) {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "FAILED TO SEND ETHER");
        emit Refunded(_to, _amount);
    }

    function payReward(address _to) external nonReentrant {
        require(msg.sender == dynamicNftAddress, "Can only be called by contract");

        (bool sent, ) = _to.call{value: referralAmount}("");
        require(sent, "FAILED TO SEND ETHER");

        totalReferralFundsRecieved[_to] += referralAmount;

        emit ReferralPaid(_to, referralAmount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /* ------ View Functions ------*/

    function viewFundsInTreasury() public view onlyRole(ADMIN_ROLE) returns (uint256) {
        return address(this).balance;
    }

    function getProjectBalance(address _projectWallet) public view onlyRole(ADMIN_ROLE) returns (uint256) {
        return projectBalances[_projectWallet];
    }

    /*------ Internal functions ------*/

    function _moveFundsOutOfTreasury() internal {
        uint256 _amount = address(this).balance;
        (bool sent, ) = cap3Wallet.call{value: _amount}("");
        require(sent, "FAILED TO SEND ETHER");
        emit FundsMovedToCap3Wallet(_amount, cap3Wallet);
    }

    /*------ Modifiers ------*/

    modifier notShutdown() {
        require(!isShutdown, "TREASURY IS SHUTDOWN");
        _;
    }
}