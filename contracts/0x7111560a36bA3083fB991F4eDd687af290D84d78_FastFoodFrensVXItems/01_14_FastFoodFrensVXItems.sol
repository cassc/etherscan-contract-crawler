//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./base/ERC1155Factory.sol";

contract FastFoodFrensVXItems is ERC1155Factory {
  /// @notice Event emitted on buyItem
  event ItemSale(address indexed buyer, uint32 indexed id, uint32 quantity);

  /// @notice FRY token address.
  address public fryToken;

  /// @notice FRY burn address.
  address public fryBurn = address(0xDEAD);

  constructor(
    string memory name_,
    string memory symbol_,
    string memory baseURI_,
    address fryToken_
  ) ERC1155Factory(name_, symbol_, baseURI_) {
    fryToken = fryToken_;
  }

  /* -------------------------------------------------------------------------- */
  /*                                external                                    */
  /* -------------------------------------------------------------------------- */

  function buyItem(uint256 id, uint256 quantity) external {
    if (!exists(id)) revert ERC1155_Error404();

    Item storage item = items[id];

    if (item.isPaused) revert ERC1155_Paused();

    // get totalPrice in 'ether'
    uint256 totalPrice = uint256(item.price * quantity) * 10**18;

    // burn fries
    IERC20(fryToken).transferFrom(msg.sender, fryBurn, totalPrice);

    //mint item(s)
    _mint(_msgSender(), id, quantity);

    emit ItemSale(_msgSender(), uint32(id), uint32(quantity));
  }

  /* -------------------------------------------------------------------------- */
  /*                           onlyOwnerOrController                            */
  /* -------------------------------------------------------------------------- */

  /// @notice Set the fry token address.
  function setFryToken(address newFryToken) external onlyOwner {
    fryToken = newFryToken;
  }

  /// @notice Set the fries burn address.
  function setFryBurn(address newFryBurn) external onlyOwner {
    fryBurn = newFryBurn;
  }

  function drop(
    address to,
    uint256 id,
    uint256 amount
  ) public onlyOwnerOrController {
    _mint(to, id, amount);
  }

  function dropBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public onlyOwnerOrController {
    _mintBatch(to, ids, amounts);
  }

  /* -------------------------------------------------------------------------- */
  /*                                     Burn                                   */
  /* -------------------------------------------------------------------------- */

  function burn(uint256 id, uint256 amount) external {
    _burn(_msgSender(), id, amount);
  }

  /// @notice burn from controller
  function cBurn(
    address from,
    uint256 id,
    uint256 amount
  ) public onlyController {
    _burn(from, id, amount);
  }
}