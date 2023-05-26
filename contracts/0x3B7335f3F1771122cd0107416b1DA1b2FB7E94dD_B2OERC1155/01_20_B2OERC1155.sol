//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
$$$$$$$\   $$$$$$\   $$$$$$\ $$$$$$$$\ $$\   $$\ 
$$  __$$\ $$  __$$\ $$  __$$\\__$$  __|$$$\  $$ |
$$ |  $$ |\__/  $$ |$$ /  $$ |  $$ |   $$$$\ $$ |
$$$$$$$\ | $$$$$$  |$$ |  $$ |  $$ |   $$ $$\$$ |
$$  __$$\ $$  ____/ $$ |  $$ |  $$ |   $$ \$$$$ |
$$ |  $$ |$$ |      $$ |  $$ |  $$ |   $$ |\$$$ |
$$$$$$$  |$$$$$$$$\  $$$$$$  |  $$ |   $$ | \$$ |
\_______/ \________| \______/   \__|   \__|  \__| 
                                                 */

import "@openzeppelin/contracts/token/ERC1155/presets/ERC1155PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract B2OERC1155 is ERC1155PresetMinterPauser, Ownable {

    //Royalties info
    uint256 private _royaltyBps; // Divided per 10000
    address payable private _royaltyRecipient;
    
    //EIP-2981 royalties
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    
    //Rarible royalties
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    //Revealed state
    bool private _revealed;

    //Open sea metadata URI
    string private _metadata_uri;

    string private constant _name = 'BOOBA TN';
    string private constant _symbol = 'B2O_TN';

    //Constructor : msg.sender will be the minter and the royaltyRecipient
    constructor(string memory uri, string memory contractUri) ERC1155PresetMinterPauser(uri) {

        //Store Open Sea contract uri
        _metadata_uri = contractUri;

        // IMPORTANT: msg.sender must be a payabable address
        _royaltyRecipient = payable(msg.sender);
        _royaltyBps = 1000; // 1000 / 10000 -> 10%
        _revealed = false;
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external pure returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    //Open Sea meta-data
    function contractURI() public view returns (string memory) {
        return _metadata_uri;
    }

    //Update the URI when the contract is revealed (only once)
    function setRevealedURI(string memory uri) public  {
        require(hasRole(MINTER_ROLE, msg.sender), "B2OERC1155: must have minter role to reveal URI");
        require(_revealed == false, "B2OERC1155: already revealed");

        _revealed = true;
        _setURI(uri);
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PresetMinterPauser) returns (bool) {
        return interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || super.supportsInterface(interfaceId);
    } 

    //Redefine to limit to 5 tokens by wallet
    function _beforeTokenTransfer(
            address operator,
            address from,
            address to,
            uint256[] memory ids,
            uint256[] memory amounts,
            bytes memory data
        ) internal virtual override(ERC1155PresetMinterPauser) {

        //Only owner can have more than 5 tokens
        if (to != owner())
        {
            for (uint256 i = 0; i < ids.length; i++) {
                require(balanceOf(to, ids[i]) + amounts[i] <= 5, "B2OERC1155: account can't have more than 5 tokens");
            }
        }
        
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}