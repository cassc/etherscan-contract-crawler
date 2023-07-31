//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

import "./interfaces/IBlackPearl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title BlackPearl Token
 * @author https://github.com/swellnetworkio
 */
contract BlackPearl is ERC20, IBlackPearl, Ownable2Step {
    mapping(address => bool) public override whitelistedAddresses;
    mapping(address => bool) public override adminAddresses;

    bool public override transfersEnabled;
    address public override claimContract;

    constructor()
        ERC20("Swell Voyage Black Pearl", "BLACKPEARL")
        Ownable2Step()
    {
        // Initial supply of 1,000,000,000 tokens
        _mint(_msgSender(), 1_000_000_000 ether);

        // Logical defaults
        adminAddresses[_msgSender()] = true;
        whitelistedAddresses[_msgSender()] = true;
        transfersEnabled = true;
    }

    // ************************************
    // ***** Modifiers ******

    modifier checkAdmin(address _address) {
        bool isOwner = owner() == _msgSender();
        bool isAdmin = !!adminAddresses[_address];
        if (!isOwner && !isAdmin) {
            revert NotAdmin();
        }

        _;
    }

    modifier onlyContractCaller(address _address) {
        if (_address != claimContract) {
            revert NotClaimContract();
        }

        _;
    }

    // ************************************
    // ***** Admin only methods ******

    function enableTransfers() external override checkAdmin(_msgSender()) {
        transfersEnabled = true;

        emit TransfersEnabled();
    }

    function disableTransfers() external override checkAdmin(_msgSender()) {
        transfersEnabled = false;

        emit TransfersDisabled();
    }

    function addToAdminList(
        address[] calldata _addresses
    ) external override checkAdmin(_msgSender()) {
        for (uint256 i; i < _addresses.length; ) {
            adminAddresses[_addresses[i]] = true;

            emit AdminAdded(_addresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function removeFromAdminList(
        address[] calldata _addresses
    ) external override checkAdmin(_msgSender()) {
        for (uint256 i; i < _addresses.length; ) {
            adminAddresses[_addresses[i]] = false;

            emit AdminRemoved(_addresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function addToWhitelist(
        address[] calldata _addresses
    ) external override checkAdmin(_msgSender()) {
        for (uint256 i; i < _addresses.length; ) {
            whitelistedAddresses[_addresses[i]] = true;
            emit WhitelistAdded(_addresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function removeFromWhitelist(
        address[] calldata _addresses
    ) external override checkAdmin(_msgSender()) {
        for (uint256 i; i < _addresses.length; ) {
            whitelistedAddresses[_addresses[i]] = false;
            emit WhitelistRemoved(_addresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setClaimContract(
        address _address
    ) external override checkAdmin(_msgSender()) {
        claimContract = _address;
        emit SetClaimContract(_address);
    }

    // ************************************
    // ***** External Methods ******

    function burn(uint256 amount) external override {
        _burn(_msgSender(), amount);
    }

    function burnClaim(
        address account
    ) external override onlyContractCaller(_msgSender()) {
        _burn(account, balanceOf(account));
    }

    /**
     * Hook override to forbid transfers except from whitelisted addresses and minting
     * @param _from sender address
     * @param _to receiver address
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 /* _amount */
    ) internal view override {
        // Can mint/burn at any time, no further checks required
        if (!(_from == address(0) || (_to == address(0)))) {
            // Transfers must be enabled
            if (!transfersEnabled) {
                revert TransferDisabled();
            }

            // Either from/to address must be whitelisted
            if (!(whitelistedAddresses[_from] || whitelistedAddresses[_to])) {
                revert NotInWhitelist();
            }
        }
    }
}