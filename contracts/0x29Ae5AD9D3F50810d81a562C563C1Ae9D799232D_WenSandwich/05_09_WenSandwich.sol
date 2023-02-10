// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

contract WenSandwich is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {
    bool public isOpen;
    mapping(uint256 => uint256[]) public ingredientData;
    mapping(uint256 => uint256) public priceData;
    mapping(uint256 => bool) public extraData;
    uint256 public constant MIN_INGREDIENTS = 3;

    uint256 public constant BG_RANGE_START = 1;
    uint256 public constant BG_RANGE_END = 36;

    uint256 public constant BREAD_RANGE_START = 37;
    uint256 public constant BREAD_RANGE_END = 57;

    uint256 public constant MAX_DECORATION = 1;
    uint256 public constant DECORATION_RANGE_START = 290;
    uint256 public constant DECORATION_RANGE_END = 367;

    uint256 public constant MAX_INGREDIENTS = 13;
    uint256 public constant MAX_ELDRITCH_INGREDIENTS = 8;
    uint256 public constant ELDRITCH_BREAD = 40;
    uint256 public constant BASE_PRICE = 0.05 ether;
    uint256 public constant BASE_CREDIT = 0.006 * 5 ether;
    uint256 public constant DISCOUNT = 0.05 ether;

    bytes32 public discountListMerkleRoot;

    string private _baseTokenURI = "https://www.wensandwich.xyz/api/prereveal/";

    constructor(uint256[] memory prices, uint256[] memory extras)
        ERC721A("Wen Sandwich", "WS")
    {
        uint256 i;
        unchecked {
            do {
                priceData[i + 1] = prices[i];
            } while (++i < prices.length);

            i = 0;
            do {
                extraData[extras[i]] = true;
            } while (++i < extras.length);
        }
    }

    function mint(
        uint256 quantity,
        uint256[][] calldata ingredients,
        bytes32[] calldata merkleProof
    ) external payable {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(isOpen, "The shop is closed.");
        require(
            quantity == ingredients.length,
            "Ingredient count does not match sandos."
        );

        uint256 ingredientCost;
        uint256 extraIngredientCost;
        uint256 breadCount;
        uint256 decorationCount;
        uint256 bgCount;

        uint256 i;
        uint256 j;

        unchecked {
            do {
                uint256 ingredientLength = ingredients[i].length;
                require(
                    ingredientLength >= MIN_INGREDIENTS,
                    "Not enough ingredients."
                );

                do {
                    uint256 ingredientId = ingredients[i][j];

                    if (
                        isWithinBoundaries(
                            BREAD_RANGE_START,
                            BREAD_RANGE_END,
                            ingredientId
                        )
                    ) breadCount++;
                    if (
                        isWithinBoundaries(
                            DECORATION_RANGE_START,
                            DECORATION_RANGE_END,
                            ingredientId
                        )
                    ) decorationCount++;
                    if (
                        isWithinBoundaries(
                            BG_RANGE_START,
                            BG_RANGE_END,
                            ingredientId
                        )
                    ) bgCount++;

                    uint256 ingredientPrice = priceData[ingredientId];
                    extraData[ingredientId]
                        ? extraIngredientCost += ingredientPrice
                        : ingredientCost += ingredientPrice;
                } while (++j < ingredientLength);

                j = 0;

                bool validIngredients = !_includes(
                    ELDRITCH_BREAD,
                    ingredients[i]
                )
                    ? ingredientLength <= MAX_INGREDIENTS
                    : ingredientLength <= MAX_ELDRITCH_INGREDIENTS;

                require(validIngredients, "Too many ingredients.");
            } while (++i < quantity);
        }

        require(breadCount == quantity, "You bread order is weird.");
        require(bgCount == quantity, "You need one background.");
        require(decorationCount <= quantity, "Too many decorations.");

        {
            uint256 credits = BASE_CREDIT * quantity;
            uint256 price = BASE_PRICE * quantity;

            uint256 costMinusCredit = ingredientCost > credits
                ? ingredientCost - credits
                : 0;

            uint256 baseWithDiscount = _isDiscountValid(msg.sender, merkleProof)
                ? price - DISCOUNT
                : price;

            require(
                baseWithDiscount + costMinusCredit + extraIngredientCost <=
                    msg.value,
                "Insufficient funds."
            );
        }

        if (_isDiscountValid(msg.sender, merkleProof)) _setAux(msg.sender, 1);

        i = 0;
        unchecked {
            do {
                ingredientData[_nextTokenId() + i] = ingredients[i];
            } while (++i < quantity);
        }

        _mint(msg.sender, quantity);
    }

    function setShopState(bool state) external onlyOwner {
        isOpen = state;
    }

    function setDiscountListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        discountListMerkleRoot = merkleRoot;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner nonReentrant {
        payable(0xA84563099458FC85430F8f08cfB1943Bd3dD0f74).transfer(
            (address(this).balance * 10) / 100
        );
        payable(0xEE3296A125b8d545de002E5Bbad524B065eC62f6).transfer(
            address(this).balance
        );
    }

    function contents(uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return ingredientData[tokenId];
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function getOwnershipAt(uint256 index)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipAt(index);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    function hasDiscount(address addr, bytes32[] calldata merkleProof)
        external
        view
        returns (bool)
    {
        return _isDiscountValid(addr, merkleProof);
    }

    function _isDiscountValid(address addr, bytes32[] memory merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                discountListMerkleRoot,
                keccak256(abi.encodePacked(addr))
            ) && _getAux(addr) != 1;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function isWithinBoundaries(
        uint256 start,
        uint256 end,
        uint256 input
    ) internal pure returns (bool) {
        return input >= start && input <= end;
    }

    function _includes(uint256 number, uint256[] calldata array)
        internal
        pure
        returns (bool)
    {
        uint256 i;
        uint256 arrayLength = array.length;

        unchecked {
            do {
                if (array[i] == number) return true;
            } while (++i < arrayLength);
        }

        return false;
    }
}