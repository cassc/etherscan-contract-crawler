// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GStarDrops is ERC1155, AccessControl, Ownable {
    bytes32 public constant GSTAR_ADMIN_ROLE = keccak256("GSTAR_ADMIN_ROLE");

    mapping(uint256 => uint256) public maxTokenSupply;
    mapping(uint256 => uint256) public mintedTokenSupply;

    struct Drop {
        address to;
        uint256 amount;
    }

    constructor() ERC1155("") {
        _setupRole(GSTAR_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(0), Strings.toString(id), ".json"));
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "GStarDrops: caller is not owner nor approved"
        );
        _burn(account, id, amount);
    }

    function _checkMaximumAndIncreaseSupply(uint256 id, uint256 amount) private {
        require((mintedTokenSupply[id] + amount) <= maxTokenSupply[id], "GStarDrops: maximum is reached for this token id.");
        mintedTokenSupply[id] += amount;
    }

    function setTokenSupply(uint256 id, uint supply)
        public
        onlyRole(GSTAR_ADMIN_ROLE) {
        maxTokenSupply[id] = supply;
    }

    function setURI(string memory newURI) public onlyRole(GSTAR_ADMIN_ROLE) {
        _setURI(newURI);
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyRole(GSTAR_ADMIN_ROLE)
    {
        _checkMaximumAndIncreaseSupply(id, amount);
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyRole(GSTAR_ADMIN_ROLE)
    {
        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            _checkMaximumAndIncreaseSupply(id, amount);
        }

        _mintBatch(to, ids, amounts, data);
    }

    function airdrop(uint256 id, Drop[] calldata drops)
        public
        onlyRole(GSTAR_ADMIN_ROLE) {
        for (uint i = 0; i < drops.length; i++) {
            Drop calldata drop = drops[i];
            mint(drop.to, id, drop.amount, "");
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}