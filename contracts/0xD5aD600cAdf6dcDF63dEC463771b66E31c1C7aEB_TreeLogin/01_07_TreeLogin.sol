// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title TreeLogin
 * @dev made by Treemaru Studio
 */

import "@openzeppelin/contracts/access/AccessControl.sol";

contract TreeLogin is AccessControl {
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");

    struct ValidTx {
        address[] coldWallets;
        uint256 blockStamp;
    }
    mapping(address => ValidTx) tempValidTx;
    mapping(address => address[]) addressLink;
    mapping(address => address) addressSaved;
    uint256 public maxLinksPerWallet = 2;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MOD_ROLE, msg.sender);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setMaxLinksPerWallet(uint256 _numb)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        maxLinksPerWallet = _numb;
    }

    function deleteAdminOwnershipLinks(address _address)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address[] memory linkedAddresses = addressLink[_address];
        require(linkedAddresses.length > 0, "No Ownership Links");

        for (uint256 j = 0; j < linkedAddresses.length; j++) {
            addressSaved[linkedAddresses[j]] = address(0);
        }
        delete addressLink[_address];
    }

    //validate ownership
    function addValidTX(address _hotWallet, address[] memory _addresses)
        external
        onlyRole(MOD_ROLE)
    {
        tempValidTx[_hotWallet] = ValidTx(_addresses, block.timestamp);
    }

    function checkAddressIsSaved(address _address)
        external
        view
        onlyRole(MOD_ROLE)
        returns (address)
    {
        return addressSaved[_address];
    }

    function getOwnershipData(address _address)
        external
        view
        onlyRole(MOD_ROLE)
        returns (address[] memory)
    {
        return addressLink[_address];
    }

    function getBalanceOnProject(address _scAddress, address _hotWallet)
        external
        view
        onlyRole(MOD_ROLE)
        returns (uint256)
    {
        uint256 sumBalance = 0;
        address[] memory linkedAddresses = addressLink[_hotWallet];
        for (uint256 i = 0; i < linkedAddresses.length; i++) {
            (bool success, bytes memory data) = address(_scAddress).staticcall(
                abi.encodeWithSignature(
                    "balanceOf(address)",
                    linkedAddresses[i]
                )
            );
            require(success, "Callback ERROR");
            sumBalance += abi.decode(data, (uint256));
        }
        (bool _success, bytes memory _data) = address(_scAddress).staticcall(
            abi.encodeWithSignature("balanceOf(address)", _hotWallet)
        );
        require(_success, "Callback ERROR");
        sumBalance += abi.decode(_data, (uint256));
        return sumBalance;
    }

    //add hot wallets and corresponding cold to storage
    function addAddresses(address[] memory _addresses, uint256 _timeStamp)
        external
        callerIsUser
    {
        require(
            tempValidTx[msg.sender].blockStamp > 0,
            "This Ownership was not authorized"
        );

        require(_addresses.length <= maxLinksPerWallet, "Too many wallets");

        for (uint256 j = 0; j < _addresses.length; j++) {
            require(
                addressSaved[_addresses[j]] == address(0),
                "Already Linked Cold Wallet"
            );
            require(
                _addresses[j] == tempValidTx[msg.sender].coldWallets[j],
                "Wrong Cold Wallets"
            );
        }
        require(
            tempValidTx[msg.sender].blockStamp == _timeStamp,
            "Wrong Validation Code"
        );
        address[] memory oldLinks = addressLink[msg.sender];
        for (uint256 k = 0; k < oldLinks.length; k++) {
            addressSaved[oldLinks[k]] = address(0);
        }
        addressLink[msg.sender] = _addresses;
        for (uint256 j = 0; j < _addresses.length; j++) {
            addressSaved[_addresses[j]] = msg.sender;
        }
        delete tempValidTx[msg.sender];
    }

    function deleteOwnershipLinks() external callerIsUser {
        address[] memory linkedAddresses = addressLink[msg.sender];
        require(linkedAddresses.length > 0, "No Ownership Links");
        for (uint256 j = 0; j < linkedAddresses.length; j++) {
            addressSaved[linkedAddresses[j]] = address(0);
        }
        delete addressLink[msg.sender];
    }

    function getTempTx(address _address) external view returns (uint256) {
        return tempValidTx[_address].blockStamp;
    }
}