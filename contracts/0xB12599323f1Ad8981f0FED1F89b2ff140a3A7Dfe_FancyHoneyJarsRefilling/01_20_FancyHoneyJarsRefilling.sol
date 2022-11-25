// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IHoneyToken.sol";
import "./interfaces/IFancyHoneyJars.sol";
import "./interfaces/IHive.sol";

contract FancyHoneyJarsRefilling is AccessControlEnumerable, ReentrancyGuard {
    
    using SafeERC20 for IHoneyToken;
 
    enum RefillingStatus {
        Off,
        Active
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    
    IHoneyToken public honeyContract;
    IHive public hiveContract;
    IFancyHoneyJars public fancyHoneyJarsContract;

    uint256 public pricePerHoneyETH;
    uint256 public maxAllowedHoneyAmountInHoneyJar;

    RefillingStatus public refillingStatus;

    event Refilled(address indexed _sender, uint256 indexed _tokenId, uint256 _honeyAmount);

    modifier whenRefillingActive {
        require(refillingStatus == RefillingStatus.Active, "Refilling must be active!");
        _;
    }

    constructor(
        IHoneyToken _honeyContractAddress, 
        IHive _hiveContract,
        IFancyHoneyJars _fancyHoneyJarsContract,
        uint256 _pricePerHoneyETH
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        honeyContract = _honeyContractAddress;
        hiveContract = _hiveContract;
        fancyHoneyJarsContract = _fancyHoneyJarsContract;
        pricePerHoneyETH = _pricePerHoneyETH;
        refillingStatus = RefillingStatus.Off;
        maxAllowedHoneyAmountInHoneyJar = 71000 ether;
    }

    function setRefillingStatus(RefillingStatus _refillingStatus) public onlyRole(MANAGER_ROLE) {
        refillingStatus = _refillingStatus;
    }

    function setPricePerHoneyETH(uint256 _pricePerHoneyETH) public onlyRole(MANAGER_ROLE) {
         pricePerHoneyETH = _pricePerHoneyETH;
    }

    function setMaxAllowedHoneyAmountInHoneyJar(uint256 _maxAllowedHoneyAmountInHoneyJar) public onlyRole(MANAGER_ROLE) {
         maxAllowedHoneyAmountInHoneyJar = _maxAllowedHoneyAmountInHoneyJar;
    }

    function calculateEthPriceForHoneyAmount(uint256 _amountOfHoney) public view returns(uint256) {
        return ((_amountOfHoney/(1 ether)) * pricePerHoneyETH) + (((_amountOfHoney%(1 ether)) * pricePerHoneyETH)/1 ether);
    }

    // refilling ------------------------

    function purchaseHoneyToJarWithETH(uint256 _tokenId, uint256 _amountOfHoney) external payable whenRefillingActive {

        require(fancyHoneyJarsContract.ownerOf(_tokenId) == msg.sender, "Sender is not the owner of the Honey Jar token!");
        require(_amountOfHoney + _getHoneyBalanceOfHoneyJarInHive(_tokenId) <= maxAllowedHoneyAmountInHoneyJar, "Amount of the honey exceeded maximum honey amount per honey jar in hive!");        

        require(msg.value >= calculateEthPriceForHoneyAmount(_amountOfHoney), "Insufficient funds!");

        _depositHoneyInHive(_tokenId, _amountOfHoney);

    }

    function refillHoneyJar(uint256 _tokenId, uint256 _amountOfHoney) external onlyRole(MANAGER_ROLE) {                        
        _depositHoneyInHive(_tokenId, _amountOfHoney);
    }

    function _depositHoneyInHive(uint256 _tokenId, uint256 _amountOfHoney) internal {
        
        emit Refilled(msg.sender, _tokenId, _amountOfHoney);

        address[] memory collections = new address[](1);
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amountOfHoneyToTransfer = new uint256[](1);

        collections[0] = address(fancyHoneyJarsContract);
        tokenIds[0] = _tokenId;
        amountOfHoneyToTransfer[0] = _amountOfHoney;

        honeyContract.approve(address(hiveContract), _amountOfHoney);
        hiveContract.depositHoneyToTokenIdsOfCollections(collections, tokenIds, amountOfHoneyToTransfer);

    }

    function _getHoneyBalanceOfHoneyJarInHive(uint256 _tokenId) internal returns(uint256) {
     
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        return hiveContract.getBalanceByTokenIdsOfCollection(address(fancyHoneyJarsContract), tokenIds)[0];

    }

    // withdrawing ------------------------

    function withdrawETHBalance(address _address) public nonReentrant onlyRole(WITHDRAW_ROLE)
    {
        uint256 balance = address(this).balance;
        require(payable(_address).send(balance));
    }

}