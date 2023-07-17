// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*

        ┌─┐┬ ┬┬┌─┐┬┌─┌─┐┌┐┌ ┌─┐┬ ┬┌─┐┌┬┐┌─┐┌─┐
        │  ├─┤││  ├┴┐├┤ │││ ├─┘├─┤│ │ │ │ │└─┐
        └─┘┴ ┴┴└─┘┴ ┴└─┘┘└┘o┴  ┴ ┴└─┘ ┴ └─┘└─┘

                                      __
                                    _/o \
                                    /_    |               | /
                                    W\  /              |////
                                      \ \  __________||//|/
        \ | /                          \ \/         /|/-//-
      '  _  '                           |     -----  // --
     -  |_|  -                          |      -----   /-
      ' | | '                           |     -----    /
      _,_|___                            \            /
     |   _ []|                             \_/  \___/
     |  (O)  |                               \  //
     |_______|                                |||
                                              |||
                                              |||
                                              Z_>>

*/

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface IERC20 {
  function transfer(address _to, uint256 _amount) external returns (bool);
}

contract ChickenPhotos is ERC721, AccessControl {
  using Address for address payable;
  using SafeMath for uint256;

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  uint256 public totalSupply;

  address private MARCEL_ADDRESS;
  address private JACOB_ADDRESS;
  address private NOAH_ADDRESS;

  string private baseURI = 'https://chicken.photos/metadata/';

  constructor() ERC721('Chicken Photos', 'CHICKEN') {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);

    MARCEL_ADDRESS = msg.sender;
  }

  /// @notice allows changing baseURI to IPFS or otherwise
  /// @param uri new baseURI value
  function setBaseURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @notice allows MINTER_ROLE to mint new tokens, initially owned by MARCEL_ADDRESS
  /// @param tokenId tokenId to mint. should match datestamp on chicken.photos
  function mint(uint256 tokenId) public onlyRole(MINTER_ROLE) {
    _safeMint(MARCEL_ADDRESS, tokenId);

    // increment total supply
    totalSupply += 1;
  }

  /// @notice allows setting addresses to send withdraw splits to
  function setWithdrawAddresses(address noah, address jacob) external onlyRole(DEFAULT_ADMIN_ROLE) {
    NOAH_ADDRESS = noah;
    JACOB_ADDRESS = jacob;
  }

  /// @notice allows DEFAULT_ADMIN_ROLE to cash out, respecting splits
  /// @param amount total value in wei to transfer, before split
  /// @param token address of token to transfer. 0x0000000000000000000000000000000000000000 for ETH
  function withdraw(uint256 amount, address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(amount > 0, 'invalid input');
    require(NOAH_ADDRESS != address(0x0), 'missing address');
    require(JACOB_ADDRESS != address(0x0), 'missing address');

    if (token == address(0x0)) {
      // send ETH
      payable(NOAH_ADDRESS).sendValue(amount.div(2));
      payable(JACOB_ADDRESS).sendValue(amount.div(2));
    } else {
      // transfer tokens at given address
      IERC20 tokenContract = IERC20(token);
      tokenContract.transfer(NOAH_ADDRESS, amount.div(2));
      tokenContract.transfer(JACOB_ADDRESS, amount.div(2));
    }
  }

  // The following functions are overrides required by Solidity.
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}