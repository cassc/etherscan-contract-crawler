// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./openzeppelin/ERC20.sol";
import "./openzeppelin/extensions/ERC20Burnable.sol";
import "./openzeppelin/security/Pausable.sol";
import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/extensions/draft-ERC20Permit.sol";
import "./openzeppelin/security/ReentrancyGuard.sol";
import "./openzeppelin/utils/SafeERC20.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error IsPaused();
error CapIsZero();
error CapExceeded();
error SweepFailed();
error RedirectionUpdateFailed();
error FourOhFourNotFound();

/**
  @title 418: redirecting through smart contracts
  @author 0xpEaTH
*/
contract Lite418Token is 
    ERC20Burnable, 
    Pausable, 
    Ownable, 
    ReentrancyGuard,
    ERC20Permit {

    using SafeERC20 for IERC20;

    uint256 private immutable supplyCap = 418 * (10**6) * (10**18);

    /// A mapping to record per-address CIDs
    mapping (address => string) private cids;
    event NewAddress(address indexed source, string identifier); 

    event Received(address, uint);
    receive () external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
      @dev Construct a new Token by providing it a name, ticker, and supply cap.

      @param name name of the new Token
      @param ticker ticker symbol of the new Token
    */
    constructor (string memory name, string memory ticker) ERC20(name, ticker) ERC20Permit(name) { 
    }

    function pause () public onlyOwner {
        _pause();
    }

    function unpause () public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer (address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);

        /// the contract must not be paused.
        if (paused()) { revert IsPaused(); } 
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap () public view virtual returns (uint256) {
        return supplyCap;
    }

    /**
      @dev Allows Token creator to mint `amount` of this Token to the address `to`. New tokens of this Token cannot be minted if it would exceed the supply cap.

      @param to the address to mint Tokens to.
      @param amount the amount of new Token to mint.
    */
    function mint (address to, uint256 amount) external onlyOwner {
          if (ERC20.totalSupply() + amount > cap()) { revert CapExceeded(); }
          super._mint(to, amount);
    }

    /**
      @dev Allow any caller to send this contract's balance of Ether to the owner
    */
    function claim () external nonReentrant {
      (bool success, ) = payable(super.owner()).call{
        value: address(this).balance
      }("");
      if (!success) { revert SweepFailed(); }
    }

    /**
      @dev Allow owner to sweep contract and send (ether or ERC20 token) to another address.

      @param token token to sweep the balance from; zero === ether swept
      @param amount amount of token to sweep
      @param destination address to send the swept tokens to
    */
    function sweep (
      address token,
      address destination,
      uint256 amount
    ) external onlyOwner nonReentrant {

      // zero address represents ether
      if (token == address(0)) {
        (bool ok, ) = payable(destination).call{ value: amount }("");
        if (!ok) { revert SweepFailed(); }
      } else {
        IERC20(token).safeTransfer(destination, amount);
      }
    }

    function threeOhThree (string memory newCID) external nonReentrant {
        address owner = _msgSender();
        if (owner == address(0)) { revert RedirectionUpdateFailed(); }
        cids[owner] = newCID;
        emit NewAddress(owner, newCID);
    }
    
    /**
     * @dev Returns
     */
    function contentIdentifier (address owner) public view virtual returns (string memory) {
        if (bytes(cids[owner]).length == 0) { revert FourOhFourNotFound(); }
        return cids[owner];
    }

}