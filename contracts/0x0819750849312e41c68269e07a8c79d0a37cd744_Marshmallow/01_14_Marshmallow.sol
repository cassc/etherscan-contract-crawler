// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMarshmallow.sol";
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Marshmallow is IMarshmallow, ERC1155Supply, ERC1155Burnable, Ownable {

    uint256 public constant TOKEN_ID = 0;

    uint256 public constant MAX_SUPPLY = 10111;

    uint256 public constant ONE_HUNDRED = 1e18;

    string public override name;
    string public override symbol;

    bool public override canAddWhitelist = true;
    bool public override canChangeMetadata = true;
    bool public override canChangeRoyaltyPercentage = true;

    mapping(address => bool) public override isWhitelisted;

    uint256 public override royaltyPercentage;
    address public override royaltyReceiver;

    constructor(string memory name_, string memory symbol_, string memory uri_, uint256 royaltyPercentage_, address royaltyReceiver_) ERC1155(uri_) {
        name = name_;
        symbol = symbol_;
        royaltyPercentage = royaltyPercentage_;
        royaltyReceiver = royaltyReceiver_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    function whitelistTheseToObtainMarshmallows(address[] calldata whitelist) external override onlyOwner {
        require(canAddWhitelist, "unauthorized");

        for(uint256 i = 0; i < whitelist.length; i++) {
            isWhitelisted[whitelist[i]] = true;
        }
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "uri: nonexistent token");

        return string(abi.encodePacked(super.uri(_id)));
    }

    function setURI(string memory newuri) external override onlyOwner {
        require(canChangeMetadata, "unauthorized");
        _setURI(newuri);

        emit URI(newuri, TOKEN_ID);
    }

    function setRoyaltyPercentage(uint256 newRoyaltyPercentage) external override onlyOwner {
        require(canChangeRoyaltyPercentage, "unauthorized");

        uint256 oldRoyaltyPercentage = royaltyPercentage;

        royaltyPercentage = newRoyaltyPercentage;

        emit RoyaltyPercentageChanged(oldRoyaltyPercentage, newRoyaltyPercentage);
    }

    function setRoyaltyReceiver(address newRoyaltyReceiver) external override {
        require(msg.sender == royaltyReceiver, "unauthorized");

        royaltyReceiver = newRoyaltyReceiver;
    }

    function renounceAddWhitelist() external override onlyOwner {
        canAddWhitelist = false;
    }

    function renounceChangeMetadata() external override onlyOwner {
        canChangeMetadata = false;
    }

    function renounceChangeRoyaltyPercentage() external override onlyOwner {
        canChangeRoyaltyPercentage = false;
    }

    function createMarshmallow() external override {
        require(totalSupply(TOKEN_ID) < MAX_SUPPLY, "mint: Max supply reached");

        require(isWhitelisted[msg.sender], "unauthorized or already withdrawed");

        isWhitelisted[msg.sender] = false;

        _mint(msg.sender, TOKEN_ID, 1, "");
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external override view returns (address receiver, uint256 royaltyAmount) {
        require(exists(_tokenId), "royaltyInfo: nonexistent token");

        royaltyAmount = _calculatePercentage(_salePrice, royaltyPercentage);

        receiver = royaltyAmount == 0 ? address(0) : royaltyReceiver;

        royaltyAmount = receiver == address(0) ? 0 : royaltyAmount;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _calculatePercentage(uint256 amount, uint256 percentage) private pure returns (uint256) {
        return (amount * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }
}