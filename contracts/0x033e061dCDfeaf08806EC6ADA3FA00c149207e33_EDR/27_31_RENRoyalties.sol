//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract RENRoyalties is ERC165 {

    //Royalties info
    uint256 private _royaltyBps; // Divided per 10000
    address payable private _royaltyRecipient;

    //EIP-2981 royalties
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    //Rarible royalties
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;


    //Constructor
    constructor(uint256 bps) {
        _royaltyRecipient = payable(msg.sender); // sender must be a payable address
        _royaltyBps = bps; // bps=1000 means 10% (1000 / 10000)
    }

	//Subclass can call this
	function setRoyalties(address addr, uint256 bps) internal {
		_royaltyRecipient = payable(addr);
        _royaltyBps = bps;
	}

    //Rarible royalties impl
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

    //EIP-2981 royalties impl
    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }


    // IERC165-supportsInterface.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || super.supportsInterface(interfaceId);
    }
}