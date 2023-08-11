// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract StrongXNFT is ERC1155, AccessControl {
    using Address for address payable;
    using SafeMath for uint;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    struct Boost {
        uint id;
        uint initialQuantity;
        uint cost;
    }

    string public name = "StrongXNFT";
    string public symbol = "STRONGXNFT";

    Boost public BRONZE = Boost(1, 1000, 0.05 ether);
    Boost public SILVER = Boost(2, 250, 0.15 ether);
    Boost public GOLD = Boost(3, 100, 0.5 ether);
    Boost public PLATINUM = Boost(4, 25, 1.05 ether);

    mapping (uint => Boost) public boosts;
        
    address private immutable admin;
    address private fund;

    event Purchased(
        address indexed account,
        uint id,
        uint amount
    );

    constructor() ERC1155("https://strongx.net/api/token/{id}") {
        admin = _msgSender();

        _mint(address(this), BRONZE.id, BRONZE.initialQuantity, "");
        _mint(address(this), SILVER.id, SILVER.initialQuantity, "");
        _mint(address(this), GOLD.id, GOLD.initialQuantity, "");
        _mint(address(this), PLATINUM.id, PLATINUM.initialQuantity, "");

        boosts[BRONZE.id] = BRONZE;
        boosts[SILVER.id] = SILVER;
        boosts[GOLD.id] = GOLD;
        boosts[PLATINUM.id] = PLATINUM;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    /** PUBLIC FUNCTIONS */

    function purchase(uint id, uint amount) external payable {
        require(address(fund) != address(0), "Fund address not set");
        require(id > 0 && id <= 4, "Invalid token id");
        require(amount > 0, "Amount must be more than zero");
        require(balanceOf(address(this), id) >= amount, "Amount can not be purchased");

        uint cost = amount.mul(boosts[id].cost);
        require(msg.value >= cost, "Value is too low");

        payable(fund).sendValue(msg.value);
        _safeTransferFrom(address(this), _msgSender(), id, amount, "");

        emit Purchased(_msgSender(), id, amount);
    }

    function uri(uint256 _tokenid) override public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "https://strongx.net/api/token/",
                Strings.toString(_tokenid)
            )
        );
    }

    /** RESTRICTED FUNCTIONS */

    function setFund(address _fund) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fund = _fund;
    }

    function mint(address to, uint id, uint amount, bytes calldata data) external onlyRole(MANAGER_ROLE) {
        return _mint(to, id, amount, data);
    }

    function burn(address from, uint id, uint amount) external onlyRole(MANAGER_ROLE) {
        return _burn(from, id, amount);
    }

    function claimBatch(address[] calldata recipients, uint id, uint amount) external onlyRole(MANAGER_ROLE) {
        for (uint index = 0; index < recipients.length; index++) {
            _mint(recipients[index], id, amount, "");
        }
    }

    function setBoostCost(uint id, uint cost) external onlyRole(MANAGER_ROLE) {
        require(id > 0 && id <= 4, "Invalid token id");

        if (id == 1) {
            BRONZE = Boost(BRONZE.id, BRONZE.initialQuantity, cost);
            boosts[BRONZE.id] = BRONZE;
        } else if (id == 2) {
            SILVER = Boost(SILVER.id, SILVER.initialQuantity, cost);
            boosts[SILVER.id] = SILVER;
        } else if (id == 3) {
            GOLD = Boost(GOLD.id, GOLD.initialQuantity, cost);
            boosts[GOLD.id] = GOLD;
        } else {
            PLATINUM = Boost(PLATINUM.id, PLATINUM.initialQuantity, cost);
            boosts[PLATINUM.id] = PLATINUM;
        }
    }

    /** INTERFACE FUNCTIONS */

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}