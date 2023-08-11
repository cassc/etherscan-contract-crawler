// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./AbstractERC1155Factory.sol";

/// @custom:security-contact [email protected]
contract GmGn is AbstractERC1155Factory, PaymentSplitter {
    using SafeMath for uint256;

    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_TEAM_SUPPLY = 22;
    uint256 public constant MAX_AIRDROP_SUPPLY = 68;

    uint8 public maxAmountPerTx = 3;
    uint256 public mintPrice = 100000000000000000;

    uint256 public publicSaleOpens  = 0;
    uint256 public publicSaleCloses = 1;

    event Purchased(uint256 indexed index, address indexed account, uint256 amount);

    constructor(string memory _name, string memory _symbol, string memory _uri, address _governor, address[] memory payees, uint256[] memory shares_) ERC1155(_uri) PaymentSplitter(payees, shares_) {
        name_ = _name;
        symbol_ = _symbol;
        _mintGmGnForTeam(_governor);
    }

    function release(address payable account) public override {
        require(msg.sender == account || msg.sender == owner(), "release: no permission");
        super.release(account);
    }

    function editWindow(
        uint256 _publicSaleOpens,
        uint256 _publicSaleCloses
    ) external onlyOwner {
        require(
            _publicSaleCloses > _publicSaleOpens,
            "Time combination not allowed"
        );

        publicSaleOpens = _publicSaleOpens;
        publicSaleCloses = _publicSaleCloses;
    }

    function airdrop(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) { 
            super.safeTransferFrom(msg.sender, accounts[i], 0, 1, "0x00"); 
        }
    }

    function purchaseGmGn(uint256 amount) external payable whenNotPaused {
        require(block.timestamp >= publicSaleOpens && block.timestamp <= publicSaleCloses, "purchaseGmGn: window closed");
        _purchase(0, amount);
    }

    function _purchase(uint256 id, uint256 amount) private {
        require(msg.sender == tx.origin, "_purchase: sender != origin");
        require(amount > 0 && amount <= maxAmountPerTx, "_purchase: exceed max per tx");
        require(totalSupply(id) + amount <= MAX_SUPPLY, "_purchase: exceed max supply");
        require(msg.value == amount * mintPrice, "_purchase: Incorrect value");
        _mint(msg.sender, id, amount, "");
        emit Purchased(id, msg.sender, amount);
    }

    function _mintGmGnForTeam(address governor) private onlyOwner {
        require(totalSupply(0) == 0, "GmGn for team already minted");
        _mint(governor, 0, MAX_TEAM_SUPPLY + MAX_AIRDROP_SUPPLY, "");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}