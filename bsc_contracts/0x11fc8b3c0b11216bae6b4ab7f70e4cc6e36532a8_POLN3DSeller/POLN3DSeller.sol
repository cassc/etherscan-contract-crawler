/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)
library Address {

  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  function verifyCallResultFromTarget(address target, bool success, bytes memory returndata, string memory errorMessage) internal view returns (bytes memory) {
    if (success) {
      if (returndata.length == 0) {
        // only check isContract if the call was successful and the return data is empty
        // otherwise we already know that it was a contract
        require(isContract(target), "Address: call to non-contract");
      }
      return returndata;
    } else {
      _revert(returndata, errorMessage);
    }
  }

  function _revert(bytes memory returndata, string memory errorMessage) private pure {
    // Look for revert reason and bubble it up if present
    if (returndata.length > 0) {
      // The easiest way to bubble the revert reason is using memory via assembly
      /// @solidity memory-safe-assembly
      assembly {
        let returndata_size := mload(returndata)
        revert(add(32, returndata), returndata_size)
      }
    } else {
      revert(errorMessage);
    }
  }
}

interface IERC20Token {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function decimals() external view returns (uint8);
}

interface IERC721 {
  function mint(address to, uint32 _assetType, uint256 _value, uint32 _customDetails) external returns (bool success);
}

interface IUniswap {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract POLN3DSeller {
  using Address for address;
  IERC721 nft;
  IERC20Token token;
  address public tcFeesWallet;
  IUniswap swapRouter;
  uint256 detailsCounter;
  address[] route;
  struct Asset {
    uint256 price;
    uint256 coin;
    uint32 sold;
    uint32 max;
    uint32 aType;
    uint32 defDetails;
    bool dLock;
    bool c;
    address w1;
    address w2;
    uint256 p;
  }

  struct Token {
    address tAddress;
    uint256 tDecimals;
  }
  
  mapping (bytes32 => Asset) public assets;
  mapping (uint256 => Token) public tokens;
  mapping (address => bool) public managers;
  bytes32[] aID;
  bool public paused = false;

  modifier onlyManagers() {
    require(managers[msg.sender] == true, "Caller is not manager");
    _;
  }
  constructor() {
    nft = IERC721(0x364151EDBAC312C7a636CfA7996C3A2B6C2eC590);
    tcFeesWallet = 0xDd891EF85A52eA95f1C63f0EdE148A37d45B16eB;
    tokens[2].tAddress = 0x6Ae9701B9c423F40d54556C9a443409D79cE170a;
    tokens[2].tDecimals = 10 ** 18;
    tokens[5].tAddress = 0x55d398326f99059fF775485246999027B3197955;
    tokens[5].tDecimals = 10 ** 18;
    route.push(0x55d398326f99059fF775485246999027B3197955);
    route.push(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    route.push(0x6Ae9701B9c423F40d54556C9a443409D79cE170a);
    managers[msg.sender] = true;
    swapRouter = IUniswap(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    setAsset(137, 100, 5, 1000, true,  0x0960c3666eB5e6A0ED96114f4F8b0FEF9aBB4269, 0x0000000000000000000000000000000000000000, 0, false);
    setAsset(138, 90, 2, 1000, true,  0x0960c3666eB5e6A0ED96114f4F8b0FEF9aBB4269, 0x7A49B787803879901eD8dCF5085C5d9222c46253, 50, true);
    setAsset(139, 90, 2, 1000, true,  0x0960c3666eB5e6A0ED96114f4F8b0FEF9aBB4269, 0x7A49B787803879901eD8dCF5085C5d9222c46253, 50, true);
    setAsset(140, 100, 2, 1000, true,  0x0960c3666eB5e6A0ED96114f4F8b0FEF9aBB4269, 0x7A49B787803879901eD8dCF5085C5d9222c46253, 50, true);
    setAsset(141, 100, 2, 1000, true,  0x0960c3666eB5e6A0ED96114f4F8b0FEF9aBB4269, 0x7A49B787803879901eD8dCF5085C5d9222c46253, 50, true);
    setAsset(142, 100, 5, 1000, true,  0x0960c3666eB5e6A0ED96114f4F8b0FEF9aBB4269, 0x0000000000000000000000000000000000000000, 0, false);
  }
  
  function setAsset(uint32 _aType, uint256 _newPrice, uint256 _coin, uint32 _max, bool _dLock, address _w1, address _w2, uint256 _p, bool _c) public onlyManagers {
    uint32 defDetails = (_aType * (10 ** 6));
    bytes32 _assetId = keccak256(abi.encode(_aType, _coin));
    bool old;
    if (assets[_assetId].aType > 0) old = true;
    assets[_assetId].price = _newPrice;
    assets[_assetId].coin = _coin;
    assets[_assetId].max = _max;
    assets[_assetId].aType = _aType;
    assets[_assetId].defDetails = defDetails;
    assets[_assetId].dLock = _dLock;
    assets[_assetId].w1 = _w1;
    assets[_assetId].w2 = _w2;
    assets[_assetId].p = _p;
    assets[_assetId].c = _c;
    if (!old) aID.push(_assetId);
  }
  
  function getPrice(bytes32 _assetId) public view returns(uint256) {
    uint256 wprice = assets[_assetId].price * tokens[assets[_assetId].coin].tDecimals;
    return _getPrice(wprice, assets[_assetId].c);
  }

  function _getPrice(uint256 _amount, bool _c) private view returns(uint256) {
    if (_c == false) {
      return _amount;
    } else {
      uint256[] memory sprice = swapRouter.getAmountsOut(_amount, route);
      return sprice[2];
    }
  }

  function incrementPrice(uint256 _increment, bytes32[] memory _ids) public onlyManagers {
    for (uint i = 0;i <= _ids.length; i++) {
      if (assets[_ids[i]].price > 0) {
        assets[_ids[i]].price += ((assets[_ids[i]].price*_increment)/100);
      }
    }
  }
  
  function incrementPriceSingle(uint256 _price, bytes32 _id) public onlyManagers {
    assets[_id].price = _price;
  }

  function buyAsset(bytes32 _assetId, uint32 _details) public {
    require(!paused, "Contract paused");
    Asset memory ca = assets[_assetId];
    require(ca.aType != 0, "Invalid asset");
    require(ca.max >= (ca.sold+1), "Max amount sold");
    require(_details < 999999, "Invalid details");
    uint256 _fPrice;
    if (ca.price != 0) {
        _fPrice = _getPrice((ca.price * tokens[ca.coin].tDecimals), ca.c);
        (uint256 w1, uint256 w2, uint256 tc) = calcTransfers(_fPrice, ca.p, ca.coin);
        if (w1 > 0) tTransfer(tokens[ca.coin].tAddress, msg.sender, ca.w1, w1);
        if (w2 > 0) tTransfer(tokens[ca.coin].tAddress, msg.sender, ca.w2, w2);
        if (tc > 0) tTransfer(tokens[ca.coin].tAddress, msg.sender, tcFeesWallet, tc);
    }
    mintToken(_assetId, _details, msg.sender, _fPrice);
  }

  function calcTransfers(uint256 _price, uint256 _p, uint256 _coin) private pure returns (uint256 w1, uint256 w2, uint256 tc) {
    if (_p == 0) {
      w1 = _price;
    } else {
      w1 = ((_price)*_p) / 100;
      w2 = _price - w1;
    }
    if (_coin == 2) {
      tc = (w1*25)/100;
      w1 = w1 - tc;
    }
  }

  function tTransfer(address cc, address from, address to, uint256 value) internal {
    _callOptionalReturn(IERC20Token(cc), abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function mintToken(bytes32 _id, uint32 _details, address _wallet, uint256 _value) private {
    uint32 ad;
    if (assets[_id].dLock) {
      detailsCounter += 1;
      ad = assets[_id].defDetails + uint32(detailsCounter);
    } else {
      ad = assets[_id].defDetails + _details;
    }
    assets[_id].sold += 1;
    require(nft.mint(_wallet, assets[_id].aType, _value, ad), "Not possible to mint this type of asset");
  }

  function _callOptionalReturn(IERC20Token _token, bytes memory data) private {
    bytes memory returndata = address(_token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
        require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }

  function assetByIndex(uint256 _index) public view returns(bytes32 id) {
      return(aID[_index]);
  }

  function setToken(uint256 _index, address _tAddress, uint256 _decimals) public onlyManagers {
      tokens[_index].tAddress = _tAddress;
      tokens[_index].tDecimals = 10 ** _decimals;
  }

  function setManager(address _wallet, bool _manager) public onlyManagers {
    managers[_wallet] = _manager;
  }

  function setTCFeesWallet(address _wallet) public onlyManagers {
    tcFeesWallet = _wallet;
  }

  function pauseContract(bool _paused) public onlyManagers {
    paused = _paused;
  }
}