// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ERC2981/ERC2981PerTokenRoyalties.sol";

contract SpaceFarmNFT is ERC1155, ERC2981PerTokenRoyalties, AccessControl {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public name = "SpaceFarm";
    string public symbol = "SPF";

    uint256 private _totalSupply = 0;

    mapping(uint256 => bool) private _minted;
    mapping(address => bool) private _tradingContracts;

    constructor() ERC1155("https://space.farm/api/{addr}/{id}") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(URI_SETTER_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function updateRoyaltyReceiver(uint256 id, address royaltyReceiver) public {
        require(
            msg.sender == _royaltyReceivers[id],
            "Not the actual royalty receiver"
        );
        _setTokenRoyalty(id, royaltyReceiver);
    }

    function mint(
        address to,
        uint256 id,
        address royaltyReceiver
    ) public onlyRole(MINTER_ROLE) {
        require(_minted[id] == false, "Double minting");
        _mint(to, id, 1, "");
        _setTokenRoyalty(id, royaltyReceiver);
        _minted[id] = true;
        _totalSupply += 1;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        address[] memory royaltyReceiver
    ) public onlyRole(MINTER_ROLE) {
        uint256[] memory amounts = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            require(_minted[ids[i]] == false, "Double minting");
            amounts[i] = 1;
            _minted[ids[i]] = true;
            _setTokenRoyalty(ids[i], royaltyReceiver[i]);
        }
        _mintBatch(to, ids, amounts, "");
        _totalSupply += ids.length;
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        if (_tradingContracts[address(operator)]) {
            return true;
        }
        return super.isApprovedForAll(account, operator);
    }

    function setTradingContract(address _tradingContract, bool value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _tradingContracts[_tradingContract] = value;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981Base, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}