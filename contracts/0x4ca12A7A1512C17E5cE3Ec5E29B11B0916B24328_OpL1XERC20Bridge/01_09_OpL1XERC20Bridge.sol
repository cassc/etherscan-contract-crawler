// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import {IXERC20} from "xtokens/interfaces/IXERC20.sol";

import {ProposedOwnableUpgradeable} from "./ownership/ProposedOwnableUpgradeable.sol";

interface IOVML1CrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
    function sendMessage(address _target, bytes memory _message, uint32 _gasLimit) external;
}

contract OpL1XERC20Bridge is ProposedOwnableUpgradeable, PausableUpgradeable {
    IXERC20 public zoomer;
    IOVML1CrossDomainMessenger public l1CrossDomainMessenger;
    address public l2Contract;

    event MessageSent(address indexed _from, address indexed _to, uint256 _amount);
    event MessageReceived(address indexed _from, address indexed _to, uint256 _amount);

    error WrongSourceContract(address _sourceContract);
    error NotBridge(address _sender);

    modifier onlyBridge() {
        if (msg.sender != address(l1CrossDomainMessenger)) {
            revert NotBridge(msg.sender);
        }
        _;
    }

    function initialize(address _owner, address _zoomer, address _l1CrossDomainMessenger)
        public
        initializer
    {
        __ProposedOwnable_init();
        __Pausable_init();

        _setOwner(_owner);
        zoomer = IXERC20(_zoomer);
        l1CrossDomainMessenger = IOVML1CrossDomainMessenger(_l1CrossDomainMessenger);
    }

    function setL2Contract(address _l2Contract) external onlyOwner {
        l2Contract = _l2Contract;
    }

    function setZoomer(address _zoomer) external onlyOwner {
        zoomer = IXERC20(_zoomer);
    }

    function burnAndBridgeToL2(address _to, uint256 _amount) external whenNotPaused {
        zoomer.burn(msg.sender, _amount);
        l1CrossDomainMessenger.sendMessage(
            l2Contract,
            abi.encodeWithSignature("mintFromL1(address,address,uint256)", msg.sender, _to, _amount),
            1000000
        );
        emit MessageSent(msg.sender, _to, _amount);
    }

    function mintFromL2(address _from, address _to, uint256 _amount) external whenNotPaused onlyBridge {
        if (l1CrossDomainMessenger.xDomainMessageSender() != l2Contract) {
            revert WrongSourceContract(l1CrossDomainMessenger.xDomainMessageSender());
        }
        zoomer.mint(_to, _amount);
        emit MessageReceived(_from, _to, _amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    // ============ Upgrade Gap ============
    uint256[49] private __GAP; // gap for upgrade safety
}