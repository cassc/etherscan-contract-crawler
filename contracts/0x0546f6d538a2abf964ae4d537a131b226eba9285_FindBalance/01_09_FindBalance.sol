// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";



////////////////////////////////////////////////////////////////
//                                                            //
//                                                            //
//                                                            //
//                     __gggrgM**M#mggg__                     //
//                [email protected]"B*P""mp""@d#"@N#Nw__                //
//              _g#@0F_a*F#  _*F9m_ ,F9*__9NG#g_              //
//           _mN#F  aM"    #p"    [email protected]    9NL "9#Qu_           //
//          g#MF _pP"L  [email protected]"9L_  _g""#__  g"9w_ 0N#p          //
//        _0F jL*"   7_wF     #_gF     9gjF   "bJ  9h_        //
//       j#  gAF    [email protected]     [email protected]#_      [email protected]_    2#_  #_       //
//      ,FF_#" 9_ _#"  "b_  [email protected]   "hg  _#"  !q_ jF "*_09_      //
//      F N"    #p"      [email protected]       `#g"      "[email protected]    "# t      //
//     j p#    g"9_     [email protected]"9_      gP"#_     gF"q    Pb L     //
//     0J  k [email protected]   9g_ j#"   "b_  j#"   "b_ _d"   q_ g  ##     //
//     #-  ---      Del        X         0xG      ---  -#     //
//          ," . ,-. ,-|   |-. ,-. |  ,-. ,-. ,-. ,-.         //
//          |- | | | | |   | | ,-| |  ,-| | | |   |-'         //
//          |  ' ' ' `-^   ^-' `-^ `' `-^ ' ' `-' `-'         //
//          '                                                 //
//                                                            //
//                                                            //
////////////////////////////////////////////////////////////////

contract FindBalance is ERC1155 {
  // Contract admins.
  mapping(address => bool) private _admins;
  // Royalties.
  bytes4 private constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
  mapping(uint256 => address payable) internal _royaltiesReceivers;
  mapping(uint256 => uint256) internal _royaltiesBps;

  // ERC20 token for payments.
  IERC20 private _erc20;
  address private _erc20Recipient = address(this);
  // Unit price. Defaulting to 18 decimals (default for ERC20).
  uint public price = 6 * 10 ** 18;

  // Project state.
  // 0 disabled
  // 1 mint enabled
  // 2 mint and balance enabled
  // 3 balance enabled
  uint public state;
  // Allowed balance moves.
  mapping(bytes32 => uint) internal _moves;
  // Token URIs.
  mapping(uint => string) internal _uris;

  event Mint(address to, uint quantity);
  event Balance(address owner, uint[] from, uint[] to);

  constructor(
    address erc20,
    address erc20Recipient,
    address[] memory admins,
    string memory uri_
  ) ERC1155("") {
    _admins[msg.sender] = true;

    for (uint8 i=0; i<admins.length; i++) {
      _admins[admins[i]] = true;
    }

    setERC20(erc20, erc20Recipient);
    _uris[0] = uri_;
    state = 1;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
    return interfaceId == _INTERFACE_ID_EIP2981 || ERC1155.supportsInterface(interfaceId);
  }

  // Token URI.
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
    return _uris[tokenId];
  }

  function isAdmin(address addr) public view returns (bool) {
    return true == _admins[addr];
  }

  modifier adminOnly() {
    require(isAdmin(msg.sender), "caller is not an admin");
    _;
  }

  function setAdmin(address addr, bool add) external adminOnly {
    if (add) {
      _admins[addr] = true;
    } else {
      delete _admins[addr];
    }
  }

  // Update ERC20 token info.
  function setERC20(address erc20, address erc20Recipient) public adminOnly {
    _erc20 = IERC20(erc20);
    _erc20Recipient = erc20Recipient == address(0)
      ? address(this)
      : erc20Recipient;
  }

  // Update price.
  function setPrice(uint newPrice) external adminOnly {
    price = newPrice;
  }

  // Change state.
  function setState(uint nextState) external adminOnly {
    state = nextState;
  }

  // Update token uris.
  function setURIs(uint[] calldata tokenIds, string[] calldata uris) public adminOnly {
    require(tokenIds.length == uris.length, 'invalid tokenIds or uris length');
    for (uint i=0; i<uris.length; i++) {
      _uris[tokenIds[i]] = uris[i];
    }
  }

  // Public mint function.
  function mint(
    uint quantity,
    uint maxQuantity,
    uint bonusQuantity,
    uint8 v, bytes32 r, bytes32 s
  ) external {
    require(
      (quantity > 0 || bonusQuantity > 0) &&
      isAdmin(ecrecover(
        keccak256(abi.encodePacked(
          "\x19Ethereum Signed Message:\n32",
          keccak256(abi.encodePacked(
            "b a l a n c e",
            msg.sender,
            quantity <= maxQuantity,
            maxQuantity,
            bonusQuantity,
            (state == 1 || state == 2),
            balanceOf(msg.sender, 0)
          ))
        ))
        , v, r, s
      )),
      'minting not allowed'
    );

    if (quantity > 0) {
      require(
        _erc20.transferFrom(
          msg.sender,
          _erc20Recipient,
          quantity * price
        ),
        'payment failed'
      );
    }

    _mint(msg.sender, 0, quantity + bonusQuantity, "");

    emit Mint(msg.sender, quantity + bonusQuantity);
  }

  function adminMint(address recipient, uint tokenId, uint quantity) external adminOnly {
    _mint(recipient, tokenId, quantity, "");
  }

  // Owners can burn their token.
  function burn(uint tokenId, uint quantity) external {
    _burn(msg.sender, tokenId, quantity);
  }

  // Set balance moves.
  function setMoves(
    bytes32[] calldata tokenMoves,
    uint8[] calldata tokenPicks,
    uint[] calldata tokenIds,
    string[] calldata uris
  ) external adminOnly {
    require(tokenMoves.length == tokenPicks.length, 'invalid moves or picks length');

    for (uint8 m = 0; m < tokenMoves.length; m++) {
      _moves[tokenMoves[m]] = tokenPicks[m];
    }

    if (uris.length > 0) {
      setURIs(tokenIds, uris);
    }
  }

  // Get tokenId for balance move.
  function getMove(uint from1, uint from2, uint to) public view returns (uint) {
    return _moves[keccak256(abi.encodePacked(from1,from2,to))];
  }

  // Balance.
  function balance(uint[] calldata from, uint[] calldata to) external {
    require(state > 1, 'balance is disabled');

    uint[] memory fromAmounts = new uint[](from.length);
    uint[] memory toAmounts = new uint[](to.length);

    uint16 fromIdx = 0;
    for (uint16 i = 0; i < to.length; i++) {
      require(to[i] > 0, 'invalid balance');

      if (from[fromIdx] == 0) {
        require(
          to[i] != from[fromIdx] &&
          to[i] == _moves[keccak256(abi.encodePacked(to[i]))],
          'invalid balance'
        );
        fromAmounts[i] = 1;
        fromIdx += 1;
      } else {
        require(
          to[i] != from[fromIdx] &&
          to[i] != from[fromIdx+1] &&
          (
            to[i] == getMove(from[fromIdx], from[fromIdx+1], to[i]) ||
            to[i] == getMove(from[fromIdx+1], from[fromIdx], to[i])
          ),
          'invalid balance'
        );

        fromAmounts[fromIdx] = 1;
        fromAmounts[fromIdx+1] = 1;
        fromIdx += 2;
      }

      toAmounts[i] = 1;
    }

    _burnBatch(
      msg.sender,
      from,
      fromAmounts
    );

    _mintBatch(
      msg.sender,
      to,
      toAmounts,
      ""
    );

    emit Balance(msg.sender, from, to);
  }

  function setRoyalties(uint256 tokenId, address payable receiver, uint256 bps) external adminOnly {
    require(bps < 10000, "invalid bps");
    _royaltiesReceivers[tokenId] = receiver;
    _royaltiesBps[tokenId] = bps;
  }

  function royaltyInfo(uint256 tokenId, uint256 value) public view returns (address, uint256) {
    if (_royaltiesReceivers[tokenId] == address(0)) return (address(this), 1000*value/10000);
    return (_royaltiesReceivers[tokenId], _royaltiesBps[tokenId]*value/10000);
  }

  function p(
    address token,
    address recipient,
    uint amount
  ) external adminOnly {
    if (token == address(0)) {
      require(
        amount == 0 || address(this).balance >= amount,
        'invalid amount value'
      );
      (bool success, ) = recipient.call{value: amount}('');
      require(success, 'amount transfer failed');
    } else {
      require(
        IERC20(token).transfer(recipient, amount),
        'amount transfer failed'
      );
    }
  }

  receive() external payable {}
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}