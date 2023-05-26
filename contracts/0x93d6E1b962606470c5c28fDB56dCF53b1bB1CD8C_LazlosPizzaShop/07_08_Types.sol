// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

enum IngredientType {
    Base,
    Sauce,
    Cheese,
    Meat,
    Topping
}

struct Ingredient {
    string name;
    IngredientType ingredientType;
    address artist;
    uint256 price;
    uint256 supply;
    uint256 initialSupply;
}

struct Pizza {
    uint16 base;
    uint16 sauce;
    uint16[3] cheeses;
    uint16[4] meats;
    uint16[4] toppings;
}

interface ILazlosIngredients {
    function getNumIngredients() external view returns (uint256);
    function getIngredient(uint256 tokenId) external view returns (Ingredient memory);
    function increaseIngredientSupply(uint256 tokenId, uint256 amount) external;
    function decreaseIngredientSupply(uint256 tokenId, uint256 amount) external;
    function mintIngredients(address addr, uint256[] memory tokenIds, uint256[] memory amounts) external;
    function burnIngredients(address addr, uint256[] memory tokenIds, uint256[] memory amounts) external;
    function balanceOfAddress(address addr, uint256 tokenId) external view returns (uint256);
}

interface ILazlosPizzas {
    function bake(address baker, Pizza memory pizza) external returns (uint256);
    function rebake(address baker, uint256 pizzaTokenId, Pizza memory pizza) external;
    function pizza(uint256 tokenId) external view returns (Pizza memory);
    function burn(uint256 tokenId) external;
}

interface ILazlosRendering {
    function ingredientTokenMetadata(uint256 id) external view returns (string memory); 
    function pizzaTokenMetadata(uint256 id) external view returns (string memory); 
}