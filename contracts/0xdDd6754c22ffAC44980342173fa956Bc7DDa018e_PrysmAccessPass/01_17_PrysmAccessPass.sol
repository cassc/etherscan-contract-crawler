// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./IERC2981Royalties.sol";
import "./ERC2981Base.sol";

/// @custom:security-contact [email protected]
contract PrysmAccessPass is ERC1155, Ownable, Pausable, ERC1155Supply, ERC2981Base {
    RoyaltyInfo private _royalties;
    string public name = "Squads Access Pass";
    string public symbol = "SAP";

    constructor() ERC1155("") {
        _setRoyalties(msg.sender, 0);
        _pause();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
    public
    onlyOwner
    {
        bool wasPaused = paused();
        if (wasPaused) {
            unpause();
        }
        _mint(account, id, amount, data);
        if (wasPaused) {
            pause();
        }
    }

    function mintDistribute(address[] memory toAccounts, uint256 id, uint256 amount, bytes memory data)
    public
    onlyOwner
    {
        bool wasPaused = paused();
        if (wasPaused) {
            unpause();
        }
        for (uint256 i = 0; i < toAccounts.length; ++i) {
            _mint(toAccounts[i], id, amount, data);
        }
        if (wasPaused) {
            pause();
        }
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Value is in basis points so 10000 = 100% , 100 = 1% etc
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    function setRoyalties(address recipient, uint256 value)
    public
    onlyOwner
    {
        _setRoyalties(recipient, value);
    }

    function royaltyInfo(uint256, uint256 value)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, ERC2981Base)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}