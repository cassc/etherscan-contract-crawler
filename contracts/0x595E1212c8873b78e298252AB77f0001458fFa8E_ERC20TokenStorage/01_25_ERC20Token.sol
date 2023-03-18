// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.5.16;

import { StorageBase } from './StorageBase.sol';
import { NonReentrant } from './NonReentrant.sol';
import { ERC20TokenAutoProxy } from './ERC20TokenAutoProxy.sol';

import { LibClaimAirdrop } from './libraries/LibClaimAirdrop.sol';

import { IERC20Token } from './interfaces/IERC20Token.sol';
import { IGovernedProxy } from './interfaces/IGovernedProxy.sol';
import { IERC20TokenStorage } from './interfaces/IERC20TokenStorage.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';
import { IERC20TokenGovernedProxy } from './interfaces/IERC20TokenGovernedProxy.sol';

contract ERC20TokenStorage is StorageBase, IERC20TokenStorage {
    string private name;

    string private symbol;

    uint8 private decimals;

    address private airdropService; // Signs ERC20 airdrop rewards claims

    address private eRC721ManagerProxy; // Can burn tokens

    // ERC20 airdrops lastClaimNonce mappings are stored by airdropId
    mapping(bytes4 => mapping(address => uint256)) private airdropLastClaimNonce;

    constructor(
        address _airdropService,
        address _eRC721ManagerProxy,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public {
        airdropService = _airdropService;
        eRC721ManagerProxy = _eRC721ManagerProxy;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function getName() external view returns (string memory _name) {
        _name = name;
    }

    function getSymbol() external view returns (string memory _symbol) {
        _symbol = symbol;
    }

    function getDecimals() external view returns (uint8 _decimals) {
        _decimals = decimals;
    }

    function getAirdropService() external view returns (address _airdropService) {
        _airdropService = airdropService;
    }

    function getERC721ManagerProxy() external view returns (address _eRC721ManagerProxy) {
        _eRC721ManagerProxy = eRC721ManagerProxy;
    }

    function getAirdropLastClaimNonce(bytes4 airdropId, address _user)
        external
        view
        returns (uint256 _lastClaimNonce)
    {
        _lastClaimNonce = airdropLastClaimNonce[airdropId][_user];
    }

    function setName(string calldata _name) external requireOwner {
        name = _name;
    }

    function setSymbol(string calldata _symbol) external requireOwner {
        symbol = _symbol;
    }

    function setDecimals(uint8 _decimals) external requireOwner {
        decimals = _decimals;
    }

    function setAirdropService(address _airdropService) external requireOwner {
        airdropService = _airdropService;
    }

    function setERC721ManagerProxy(address _eRC721ManagerProxy) external requireOwner {
        eRC721ManagerProxy = _eRC721ManagerProxy;
    }

    function setAirdropLastClaimNonce(
        bytes4 airdropId,
        address _user,
        uint256 _lastClaimNonce
    ) external requireOwner {
        airdropLastClaimNonce[airdropId][_user] = _lastClaimNonce;
    }
}

contract ERC20Token is NonReentrant, ERC20TokenAutoProxy, IERC20Token {
    // Data for migration
    //---------------------------------
    ERC20TokenStorage public eRC20TokenStorage;
    //---------------------------------

    modifier onlyERC20TokenOwner() {
        require(_callerAddress() == owner, 'ERC20Token: FORBIDDEN');
        _;
    }

    modifier onlyERC20TokenOwnerOrERC721Manager() {
        require(
            _callerAddress() == owner ||
                msg.sender ==
                address(
                    IGovernedProxy(address(uint160(eRC20TokenStorage.getERC721ManagerProxy())))
                        .impl()
                ),
            'ERC20Token: FORBIDDEN'
        );
        _;
    }

    constructor(
        address _proxy, // If set to address(0), ERC20TokenGovernedProxy will be deployed by ERC20TokenAutoProxy
        address _airdropService,
        address _eRC721ManagerProxy,
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) public ERC20TokenAutoProxy(_proxy, this, _owner) {
        // Deploy ERC20 Token storage
        eRC20TokenStorage = new ERC20TokenStorage(
            _airdropService,
            _eRC721ManagerProxy,
            _name,
            _symbol,
            _decimals
        );
    }

    // Governance functions
    //
    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyERC20TokenOwner {
        IERC20TokenGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new implementation
    function destroy(IGovernedContract _newImpl) external requireProxy {
        eRC20TokenStorage.setOwner(_newImpl);
        _destroyERC20(_newImpl);
        _destroy(_newImpl);
    }

    // This function would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrateERC20(address(_oldImpl));
        _migrate(_oldImpl);
    }

    // Getter functions
    //
    function name() external view returns (string memory _name) {
        _name = eRC20TokenStorage.getName();
    }

    function symbol() external view returns (string memory _symbol) {
        _symbol = eRC20TokenStorage.getSymbol();
    }

    function decimals() external view returns (uint8 _decimals) {
        _decimals = eRC20TokenStorage.getDecimals();
    }

    function getAirdropService() external view returns (address _airdropService) {
        _airdropService = eRC20TokenStorage.getAirdropService();
    }

    function getAirdropLastClaimNonce(bytes4 airdropId, address _user)
        external
        view
        returns (uint256 _lastClaimNonce)
    {
        _lastClaimNonce = eRC20TokenStorage.getAirdropLastClaimNonce(airdropId, _user);
    }

    // Setter functions
    //
    function setName(string calldata _name) external onlyERC20TokenOwner {
        eRC20TokenStorage.setName(_name);
    }

    function setSymbol(string calldata _symbol) external onlyERC20TokenOwner {
        eRC20TokenStorage.setSymbol(_symbol);
    }

    function setDecimals(uint8 _decimals) external onlyERC20TokenOwner {
        eRC20TokenStorage.setDecimals(_decimals);
    }

    function setAirdropService(address _airdropService) external onlyERC20TokenOwner {
        eRC20TokenStorage.setAirdropService(_airdropService);
    }

    function setERC721ManagerProxy(address _eRC721ManagerProxy) external onlyERC20TokenOwner {
        eRC20TokenStorage.setERC721ManagerProxy(_eRC721ManagerProxy);
    }

    // Mint/burn functions
    //
    function mint(address recipient, uint256 amount) external onlyERC20TokenOwner {
        _mint(recipient, amount);
        IERC20TokenGovernedProxy(proxy).emitTransfer(address(0x0), recipient, amount);
    }

    function burn(address account, uint256 amount) external onlyERC20TokenOwnerOrERC721Manager {
        _burn(account, amount);
        IERC20TokenGovernedProxy(proxy).emitTransfer(account, address(0x0), amount);
    }

    // ERC20 airdrop and airdrop referral rewards claim function
    function claimAirdrop(
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3,
        bytes4 airdropId,
        uint256 lastClaimNonce,
        uint256 claimNonce,
        bytes calldata airdropServiceSignature
    ) external noReentry {
        // Get rewards recipient address
        address recipient = _callerAddress();
        // Make sure claim has not been processed yet
        require(
            lastClaimNonce == eRC20TokenStorage.getAirdropLastClaimNonce(airdropId, recipient),
            'ERC20Token: invalid lastClaimNonce value'
        );
        // Check that claimNonce > lastClaimNonce
        require(
            lastClaimNonce < claimNonce,
            'ERC20Token: claimNonce must be larger than lastClaimNonce'
        );
        // Validate airdrop claim
        LibClaimAirdrop.validateClaim(
            recipient, // Referral rewards claim recipient address
            claimAmountAirdrop, // Claim amount corresponding to ERC20 airdrop
            claimAmountReferral1, // Claim amount corresponding to first level of ERC20 airdrop referral rewards
            claimAmountReferral2, // Claim amount corresponding to second level of ERC20 airdrop referral rewards
            claimAmountReferral3, // Claim amount corresponding to third level of ERC20 airdrop referral rewards
            airdropId, // Airdrop campaign Id
            lastClaimNonce, // Recipient's last claim nonce
            claimNonce, // Recipient's current claim nonce
            airdropServiceSignature, // Claim signature from ERC20 airdrop service
            proxy, // Verifying contract address
            eRC20TokenStorage.getAirdropService() // Airdrop service address
        );
        // Update recipient's last claim nonce to current claim nonce
        eRC20TokenStorage.setAirdropLastClaimNonce(airdropId, recipient, claimNonce);
        // Mint total claim amount to recipient
        mintAirdropClaim(
            recipient,
            claimAmountAirdrop,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3
        );
        // Emit AirdropRewardsClaimed event
        IERC20TokenGovernedProxy(proxy).emitAirdropRewardsClaimed(
            recipient,
            claimAmountAirdrop,
            claimAmountReferral1,
            claimAmountReferral2,
            claimAmountReferral3,
            airdropId,
            lastClaimNonce,
            claimNonce,
            airdropServiceSignature
        );
    }

    function mintAirdropClaim(
        address recipient,
        uint256 claimAmountAirdrop,
        uint256 claimAmountReferral1,
        uint256 claimAmountReferral2,
        uint256 claimAmountReferral3
    ) private {
        // Calculate total claim amount
        uint256 totalClaimAmount = claimAmountAirdrop
            .add(claimAmountReferral1)
            .add(claimAmountReferral2)
            .add(claimAmountReferral3);
        // Mint total claim amount to recipient
        _mint(recipient, totalClaimAmount);
        // Emit Transfer event
        IERC20TokenGovernedProxy(proxy).emitTransfer(address(0x0), recipient, totalClaimAmount);
    }
}