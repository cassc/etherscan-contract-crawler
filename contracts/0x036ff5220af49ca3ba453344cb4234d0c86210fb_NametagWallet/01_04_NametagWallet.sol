// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./INametag.sol";

contract NametagWallet is Ownable {
    event ContractAdded(address indexed nametagContract);
    event ContractRemoved(address indexed nametagContract);
    event NametagWalletChanged(address indexed owner, string indexed name, address wallet);

    bytes32 constant private TAIL = keccak256(".tag");

    address[] public nametagContracts;
    mapping(string => mapping(address => address)) internal nametagWallet;
    constructor(address[] memory addresses) {
        for (uint256 i = 0; i < addresses.length; ++i) {
            addNametagContract(addresses[i]);
        }
    }

    /**
     * @dev Adds new contract for looking for nametag
     */
    function addNametagContract(address _contract) public onlyOwner {
        nametagContracts.push(_contract);

        emit ContractAdded(_contract);
    }

    /**
     * @dev Removes the nametag contract
     */
    function removeNametagContract(address _contract) external onlyOwner {
        uint256 last = nametagContracts.length - 1;
        for (uint256 i = 0; i <= last; ++i) {
            if (nametagContracts[i] != _contract) continue;
            if (i != last) nametagContracts[i] = nametagContracts[last];
            nametagContracts.pop();
            emit ContractRemoved(_contract);
            return;
        }
        revert("NametagWallet: Contract not found");
    }

    /**
     * @dev Sets wallet for the nametag for sender. Nametag must be present on a contract.
     */
    function setNametagWallet(string calldata nametag, address wallet) external {
        require(wallet != address(0), "NametagWallet: Zero wallet address");

        _setNametagWallet(nametag, wallet);
    }

    /**
     * @dev Sets default wallet for the nametag for sender. Nametag must be present on a contract.
     */
    function clearNametagWallet(string calldata nametag) external {
        _setNametagWallet(nametag, address(0));
    }

    /**
     * @dev Returns the wallet address for the current owner of Nametag or just the owner's address
     */
    function getNametagWallet(string calldata nametag) external view returns (address wallet)  {
        (address _contract, uint256 tokenId, string memory name) = _resolveNametag(nametag);

        if (_contract == address(0)) return address(0);

        address owner = INametag(_contract).ownerOf(tokenId);
        wallet = nametagWallet[name][owner];

        if (wallet == address(0)) wallet = owner;
    }

    function _setNametagWallet(string calldata nametag, address wallet) private {
        require(bytes(nametag).length > 0, "NametagWallet: Nametag is empty");
        (address _contract,,string memory name) = _resolveNametag(nametag);
        require(_contract != address(0), "NametagWallet: Nametag not found");

        nametagWallet[name][_msgSender()] = wallet;

        emit NametagWalletChanged(_msgSender(), name, wallet);
    }

    function _resolveNametag(string calldata nametag) internal view returns (address, uint256, string memory) {
        string memory nametag2 = _getNametag(nametag);
        for (uint256 i = 0; i < nametagContracts.length; ++i) {
            address _contract = nametagContracts[i];
            uint256 tokenId = INametag(_contract).getByName(nametag2);
            if (tokenId != 0) {
                return (
                    _contract,
                    tokenId,
                    INametag(_contract).getTokenName(tokenId)
                );
            }
        }
        return (address(0), 0, "");
    }

    function _getNametag(string calldata nametag) private pure returns (string memory) {
        bytes calldata str = bytes(nametag);
        if (str.length >= 7) {
            bytes calldata a = str[str.length - 4 : str.length];
            if (keccak256(a) == TAIL) {
                return string(nametag[0 : str.length - 4]);
            }
        }

        return string(nametag);
    }
}