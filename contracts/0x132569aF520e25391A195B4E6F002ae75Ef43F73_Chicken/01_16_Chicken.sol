// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

// 🐓
contract Chicken is ReentrancyGuard, AdminControl, ERC1155, ERC1155Supply {

    using Address for address;
    using Strings for uint256;

    string public _name;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    string _tokenURI;

    uint public _price = 0.0069 ether;
    uint public _endTime;

    address[] public _lastTenMinters;
    uint public _mintIndex;
    uint public _totalMints;

    constructor() ERC1155("Chicken") {
        _name = "Chicken";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC1155) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId || AdminControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId) || interfaceId == type(IERC1155MetadataURI).interfaceId || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || 
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function configure() public adminRequired {
        require(_lastTenMinters.length < 10, "Chicken");
        for (uint i; i < 10; i++) {
            _lastTenMinters.push(address(0x0));
        }
    }

    function reconfigure(uint price, uint endTime) public adminRequired {
        _price = price;
        _endTime = endTime;
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _tokenURI;
    }

    function updateTokenURI(string memory newURI) public adminRequired {
        _tokenURI = newURI;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return super.isApprovedForAll(account, operator) || operator == address(this);
    }

    function withdraw(address _to) public adminRequired {
        payable(_to).transfer(address(this).balance);
    }

    function mint(uint amount) public payable {
        require(amount <= 10 && amount * _price == msg.value && block.timestamp < _endTime, "Chicken");

        _totalMints += amount;
        uint tokenSupply = totalSupply(1);

        // If the total supply will become more than 10
        if (tokenSupply + amount > 10) {
            // Delete the 10 that currently exist.
            for (uint i = 0; i < 10; i++) {
                if (_lastTenMinters[i] != address(0x0)) {
                    _burn(_lastTenMinters[i], 1, 1);
                }
            }

            // Mint remainder to this person
            uint remaining = tokenSupply + amount - 10;
            // Set mint index
            _mintIndex = remaining;
            // Reset mint index array
            for (uint i = 0; i < 10; i++) {
                if (i < _mintIndex) {
                    _lastTenMinters[i] = msg.sender;
                } else {
                    _lastTenMinters[i] = address(0x0);
                }
            }
            _mint(msg.sender, 1, remaining, "");
        } else {
            // Otherwise, update latest minters
            for (uint i = 0; i < amount; i++) {
                _lastTenMinters[_mintIndex] = msg.sender;
                _mintIndex++;
                if (_mintIndex > 9) {
                    _mintIndex = 0;
                }
            }

            // Mint remainder to this person
            _mint(msg.sender, 1, amount, "");
        }
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }
}