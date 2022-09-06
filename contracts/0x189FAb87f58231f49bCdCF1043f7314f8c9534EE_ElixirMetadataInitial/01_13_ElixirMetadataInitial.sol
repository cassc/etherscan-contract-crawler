// SPDX-License-Identifier: Unlicense
// Creator: 0xVeryBased

// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛  /‾‾‾‾\‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\  ⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛  / /‾‾\ \--------------------------\  ⊛⊛⊛⊛
// ⊛⊛⊛⊛  | |  _/ /__________________________/  ⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛  \ \___/__________________________/  ⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛  \                            \  ⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛  \   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   \  ⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛  \   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   \  ⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛  |   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   |  ⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛  |   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾           |  ⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛  |                            |  ⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛  /   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   /  ⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛  /   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾       /  ⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛  /                            /  ⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛  |   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛  |   ‾‾‾‾‾                    |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛  |                            |  ⊛⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛  \   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   \  ⊛⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛  \   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾   \  ⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛  |   ‾‾‾‾‾‾‾‾‾‾‾‾             |  ⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛  /____________________________/  ⊛⊛⊛⊛⊛⊛⊛
// ⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛⊛

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721.sol";

contract ElixirMetadataInitial is Ownable {
    using Strings for uint256;

    address public elixirBottleContract;

    modifier onlyBottleContract() {
        _isBottleContract();
        _;
    }
    function _isBottleContract() internal view virtual {
        require(msg.sender == elixirBottleContract, "ebc");
    }

    /*******************************************************************/
    /*** CONSTRUCTOR (Start) *******************************************/
    constructor(
        address _ebAddy
    ) {
        elixirBottleContract = _ebAddy;
    }
    /*** CONSTRUCTOR (End) *******************************************/
    /*****************************************************************/


    function registerIngredient(address ingredientContract, string memory ingredientName) public onlyOwner {}

    function getIngredientContract(uint256 ingredientType) public view returns (address) {
        return address(0);
    }

    function getCharges(uint256 elixirId) public view returns (uint256) {
        require(ElixirBottlesWithExists(elixirBottleContract).exists(elixirId), "z");
        return 0;
    }

    function setCharges(uint256 elixirId, uint256 numCharges) private {}

    function getElement(uint256 elixirId) public view returns (uint256) {
        require(ElixirBottlesWithExists(elixirBottleContract).exists(elixirId), "z");
        return 0;
    }

    function setElement(uint256 elixirId, uint256 whichElement) private {}

    function getAttributes(uint256 elixirId) public view returns (uint256[] memory) {
        require(ElixirBottlesWithExists(elixirBottleContract).exists(elixirId), "z");

        uint256[] memory toReturn = new uint256[](0);
        return toReturn;
    }

    function getElementAndAttributes(
        uint256 elixirId
    ) public view returns (uint256, uint256[] memory) {
        return (getElement(elixirId), getAttributes(elixirId));
    }

    function getChargesElementAndAttributes(
        uint256 elixirId
    ) public view returns (uint256, uint256, uint256[] memory) {
        return (getCharges(elixirId), getElement(elixirId), getAttributes(elixirId));
    }

    function getIngredientList() public view returns (string[] memory) {
        string[] memory toReturn = new string[](0);

        return toReturn;
    }

    function charge(
        uint256 elixirId,
        uint256[] memory ingredientTypes,
        uint256[] memory ingredientIDs
    ) public onlyBottleContract {}

    function drink(uint256 elixirId) public onlyBottleContract {}

    function spill(uint256 elixirId) public onlyBottleContract {}

    function getElixirMetadata(uint256 elixirId) public view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"Elixir ", elixirId.toString(),"\",",
                "\"description\":\"", "An empty elixir bottle... What will it be filled with???", "\",",
                "\"image\":\"", "https://crudeborne.mypinata.cloud/ipfs/Qme96t7UMkWYatkUCMUXA5XkYjWLcLUD6sPiftY9fM96wJ", "\",",
                "\"animation_url\":\"", "https://crudeborne.mypinata.cloud/ipfs/QmRiTY3sLQAxCvRhS7HYNiyTZnfL8ETyUq7cmbMrCPBHZg", "\",",
                "\"external_link\":\"https://crudeborne.wtf\",",
                "\"attributes\":[{\"trait_type\": \"Element\", \"value\": \"Unknown\"},",
                "{\"trait_type\": \"Charges\", \"value\": 0}]}"
            )
        );
    }
}

////////////////////

abstract contract ElixirBottlesWithExists {
    function exists(uint256 tokenId) public view virtual returns (bool);
}

////////////////////////////////////////