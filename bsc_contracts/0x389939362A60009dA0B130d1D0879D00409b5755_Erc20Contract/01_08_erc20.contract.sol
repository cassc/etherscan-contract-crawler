// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20Contract is ERC20, ERC20Pausable, Ownable {

  // Address of wallet contract to allow external token minting and burning
  address private _walletContractAddress;

  /**
    * @dev Initializes the contract by setting `name` and `symbol` to the token.
    */
  constructor(string memory name_, string memory symbol_, uint256 initialSupply_) ERC20(name_, symbol_) {
    _mint(msg.sender, initialSupply_);
  }

  function decimals() public view virtual override returns (uint8) {
    return 8;
  }

  /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must be owner.
     */
  function mint(address to, uint256 amount) public virtual onlyOwnerOrWallet {
    _mint(to, amount);
  }

  /**
     * @dev Burns `amount` tokens from `from` address.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the caller must be admin.
     */
  function burn(address to, uint256 amount) public virtual onlyOwnerOrWallet {
    _burn(to, amount);
  }

  /**
    * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be owner`.
     */
  function pause() public virtual onlyOwner {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be owner`.
     */
  function unpause() public virtual onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  /**
    * @dev Returns the address of the wallet contract approved to mint and burn.
    */
  function _getWalletContractAddress() private view returns (address) {
    return _walletContractAddress;
  }

  /**
    * @dev Set new wallet contract address approved to mint and burn.
    * Requirements:
    *
    * - the caller must be owner.
    */
  function setWalletContractAddress(address newAddress) public onlyOwner {
    _setWalletContractAddress(newAddress);
  }

  /**
    * @dev Set new wallet contract address approved to mint and burn.
    */
  function _setWalletContractAddress(address newAddress) private {
    require(newAddress != address(0), "Erc20Contract: new wallet contract address can't be zero address");
    _walletContractAddress = newAddress;
  }

  /**
    * @dev Throws if called by any account other than the owner or wallet contract.
    */
  modifier onlyOwnerOrWallet() {
    require(owner() == _msgSender() || _getWalletContractAddress() == _msgSender(), "Erc20Contract: caller is not the owner nor wallet contract");
    _;
  }
}