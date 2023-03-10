// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GathereumMembershipNFT is
    ReentrancyGuard,
    Context,
    Ownable,
    ERC1155Pausable,
    ERC1155Supply
{
    using Strings for uint256;

    string public constant name = "Gathereum Membership NFT";
    string public constant symbol = "GHT";
    string private _baseURI = "";

    address payable public treasury;
    address public burner;

    modifier onlyBurner() {
        require(msg.sender == burner, "Not authorized");
        _;
    }

    struct Membership {
        uint256 price;
        uint256 maxSupply;
        uint256 initialSupply;
        uint256 totalMinted;
    }

    mapping(uint256 => Membership) public memberships;

    constructor(string memory _uri, address payable _treasury) ERC1155("") {
        _baseURI = _uri;
        treasury = _treasury;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(memberships[_id].maxSupply > 0, "Wrong token id");
        return string(abi.encodePacked(_baseURI, _id.toString()));
    }

    function setBurner(address _burner) external onlyOwner {
        burner = _burner;
    }

    function setUri(string memory _uri) external onlyOwner {
        _baseURI = _uri;
    }

    function setMembership(
        uint256 _id,
        uint256 _price,
        uint256 _maxSupply
    ) external onlyOwner {
        require(_price != 0, "price cannot be zero");
        require(_maxSupply != 0, "max supply cannot be zero");
        Membership storage membership = memberships[_id];
        membership.price = _price;
        membership.maxSupply = _maxSupply;
        membership.initialSupply = _maxSupply;
    }

    function mint(uint256 _amount, uint256 _id) external payable nonReentrant {
        Membership storage membership = memberships[_id];
        require(
            msg.value == _amount * membership.price,
            "Not enough or too much ether"
        );
        require(
            totalSupply(_id) + _amount <= membership.maxSupply,
            "Purchase would exceed max supply"
        );
        _mint(_msgSender(), _id, _amount, "");
        membership.totalMinted += _amount;
        sendTreasury(msg.value);
    }

    function burn(
        uint256 _id,
        uint256 _amount,
        address _address
    ) external nonReentrant onlyBurner {
        _burn(_address, _id, _amount);
        Membership storage membership = memberships[_id];
        membership.maxSupply -= _amount;
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function sendTreasury(uint256 _amount) internal {
        (bool sent, ) = treasury.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
}