//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./MetarunCollection.sol";
import "./MetarunToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface AggregatorInterface {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

/**
 * @title Metarun Sale
 * @dev Ensures purchase of characters
 */

contract MetarunSale is AccessControlUpgradeable {
    MetarunCollection public collection;
    MetarunToken public token;
    IERC20 public BUSD;
    AggregatorInterface public router;

    struct Character {
        uint256 price;
        uint256 sold;
        uint256 currentPosition;
    }

    struct KindsInfo {
        uint256 kind;
        uint256 value;
    }

    mapping(uint256 => Character) public characters;

    event CharacterBought(address owner, uint256 characterId, uint256 price);

    /**
     * @dev the constructor arguments:
     * @param _token address of token - the same used for purchases
     * @param _collection ERC1155 token of NFT collection
     */

    function initialize(
        address _token,
        address _collection,
        address _router,
        address _busd
    ) public initializer {
        __AccessControl_init();
        require(_collection != address(0), "collection address cannot be zero");
        require(_token != address(0), "token address cannot be zero");
        require(_router != address(0), "router address cannot be zero");
        require(_busd != address(0), "busd address cannot be zero");
        token = MetarunToken(_token);
        collection = MetarunCollection(_collection);
        router = AggregatorInterface(_router);
        BUSD = IERC20(_busd);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Buy character
     * @param kind - kind of a purchased character
     */

    function buy(uint256 kind) external {
        require(characters[kind].price != 0, "Price not set");
        uint256 characterId = (kind << 16) | characters[kind].currentPosition;
        require(_isCharacter(characterId), "Incorrect character kind");

        while (collection.exists(characterId)) {
            characterId += 1;
            characters[kind].currentPosition += 1;
        }

        require(collection.isKind(characterId, kind), "KIND_OVERFLOW");

        uint256 price = characters[kind].price;

        characters[kind].sold += 1;
        characters[kind].currentPosition += 1;

        BUSD.transferFrom(msg.sender, address(this), price);
        collection.mint(msg.sender, characterId, 1);

        emit CharacterBought(msg.sender, characterId, price);
    }

    /**
     * @dev Update character prices
     * @param kinds - struct with new prices of characters
     */

    function setCharacterPrices(KindsInfo[] memory kinds) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        for (uint256 i = 0; i < kinds.length; i++) {
            characters[kinds[i].kind].price = kinds[i].value;
        }
    }

    function setSoldCharacters(KindsInfo[] memory kinds) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        for (uint256 i = 0; i < kinds.length; i++) {
            characters[kinds[i].kind].sold = kinds[i].value;
        }
    }

    function setCurrentCharacterIds(KindsInfo[] memory kinds) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        for (uint256 i = 0; i < kinds.length; i++) {
            characters[kinds[i].kind].currentPosition = kinds[i].value;
        }
    }

    /**
     * @dev Send all metarun tokens from the contract address to msg.sender with DEFAULT_ADMIN_ROLE
     */

    function withdrawPayments() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        uint256 payment = token.balanceOf(address(this));
        require(payment != 0, "Zero balance");
        token.transfer(msg.sender, payment);
    }

    /**
     * @dev Send all BUSD tokens from the contract address to msg.sender with DEFAULT_ADMIN_ROLE
     */

    function withdrawBUSDPayments() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You should have DEFAULT_ADMIN_ROLE");
        uint256 payment = BUSD.balanceOf(address(this));
        require(payment != 0, "Zero balance");
        BUSD.transfer(msg.sender, payment);
    }

    function _isCharacter(uint256 id) internal view returns (bool) {
        return
            collection.getType(id) == collection.IGNIS_CLASSIC_COMMON() >> 16 ||
            collection.getType(id) == collection.PENNA_CLASSIC_COMMON() >> 16 ||
            collection.getType(id) == collection.ORO_CLASSIC_COMMON() >> 16 ||
            collection.isKind(id, collection.MYSTERY_BOX_KIND());
    }
}