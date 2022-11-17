// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MajrERC20 is Ownable, ERC20 {
  /// @notice The max supply of the MajrERC20 tokens that will ever exist
  uint256 public constant MAX_SUPPLY = 100000000 * 1e18; // 100 million tokens

  /**  
   * @notice Shows whether the token transfers are live or not,
   * @dev Can be enabled only once and cannot ever be disabled again
   */
  bool public areTransfersEnabled;

  /// @notice The old name of the token, before transfers go live
  string private constant oldName =  "XPS";

  /// @notice The old symbol of the token, before transfers go live
  string private constant oldSymbol = "XPS";

  /// @notice The new name of the token, after transfers go live
  string private newName;

  /// @notice The new symbol of the token, after transfers go live
  string private newSymbol;

  /// @notice Mapping from address to boolean that shows whether that address can transfer tokens or not before the transfers go live
  mapping(address => bool) public canTransferBeforeTransfersAreEnabled;

  /// @notice An event that gets emitted before each token transfer
  event BeforeTokenTransfer(bool areTransfersLive, address indexed from, address indexed to, uint256 amount);

  /// @notice An event emitted when the token transfers are enabled
  event TransfersEnabled(bool areTransfersEnabled, uint256 timestamp, string newName, string newSymbol);

  /// @notice An event emitted when the address has been added to whitelist
  event Whitelisted(address indexed account, uint256 timestamp);

  /**
   * @notice Constructor
   */
  constructor()
    ERC20 (oldName, oldSymbol) 
  {
    canTransferBeforeTransfersAreEnabled[msg.sender] = true;
    // Added to support the minting of tokens to the contract owner's address (since the minting is considered to be a transfer 'from' the address(0))
    canTransferBeforeTransfersAreEnabled[address(0)] = true; 
    
    _mint(msg.sender, MAX_SUPPLY);
  }

  /** 
   * @notice Returns the name of the token
   * @return string memory
   */
  function name() public view override returns (string memory) {
    return areTransfersEnabled ? newName : oldName;
  }

  /** 
   * @notice Returns the symbol of the token
   * @return string memory
   */
  function symbol() public view override returns (string memory) {
    return areTransfersEnabled ? newSymbol : oldSymbol;
  }

  /**
   * @notice Enables transfers of tokens for everyone and sets the new name and symbol for the token
   * @param _newName string calldata
   * @param _newSymbol string calldata
   * @dev Only owner can call it
   */
  function enableTransfers(string calldata _newName, string calldata _newSymbol) external onlyOwner {
    require(!areTransfersEnabled, "MajrERC20: Transfers are already enabled.");

    areTransfersEnabled = true;
    newName = _newName;
    newSymbol = _newSymbol;

    emit TransfersEnabled(true, block.timestamp, _newName, _newSymbol);
  }

  /**
   * @notice Adds the address to the list of addresses that can transfer tokens before the transfers go live for everyone
   * @param _account address
   * @dev Only owner can call it
   */
  function addToWhitelist(address _account) external onlyOwner {
    require(!canTransferBeforeTransfersAreEnabled[_account], "MajrERC20: Address is already in the whitelist.");

    canTransferBeforeTransfersAreEnabled[_account] = true;

    emit Whitelisted(_account, block.timestamp);
  }

  /**
   * @notice Checks if the address can transfer tokens, based on whether the transfers are enabled or not and whether the address is in the whitelist or not
   * @param from address
   * @param to address
   * @param amount uint256
   * @dev A hook that gets called before each token transfer
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    if (!areTransfersEnabled) {
      require(canTransferBeforeTransfersAreEnabled[from], "MajrERC20: Transfers are not enabled yet and this address is not in the whitelist.");
    }

    emit BeforeTokenTransfer(areTransfersEnabled, from, to, amount);
  }

  /** 
   * @notice Burns the given amount of tokens from the sender's balance
   * @param _amount uint256
   * @dev User can only burn up to their own token balance
   */
  function burn(uint256 _amount) external {
    require(_amount > 0, "MajrERC20: Cannot burn zero tokens.");
    require(balanceOf(msg.sender) >= _amount, "MajrERC20: Burn amount exceeds balance.");

    _burn(msg.sender, _amount);
  }
}