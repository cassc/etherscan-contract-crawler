// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "./interfaces/ILcSaftWNFT.sol";

contract LcSaftInvest is Ownable, EIP712 {
  using SafeERC20 for IERC20;

  string private SIGNING_DOMAIN;
  string private SIGNATURE_VERSION;

  struct InvestInfo {
    uint256 tier;
    uint256 amount;
    uint256 timestamp;
  }

  address public investToken;
  address public tokenX;
  address public wNFT;

  uint256[] public tierids;
  // map tierId to nft price i.e 1 -> $500
  mapping (uint256 => uint256) public tierPrice;
  // map tierId to numbers of max NFT i.e 1 -> 1000x
  mapping (uint256 => uint256) public tierLimit;
  mapping (uint256 => uint256) public tierSupplied;
  // map tierId to numbers of TokenX to transfer when invest i.e 1 -> 50,000 TokenX
  mapping (uint256 => uint256) public tierTokenX;
  // map tierId to numbers of Extra TokenX to transfer when invest i.e 1 -> 200000 (20%)
  mapping (uint256 => uint256) public tierExtraTokenX;

  mapping (address => bool) public managers;

  uint256 public manageDecimals = 6;

  modifier onlyManager() {
    require(managers[msg.sender], "LcSaftInvest: !manager");
    _;
  }

  constructor(
    address _investToken,
    address _tokenX,
    address _wNFT,
    string memory domain,
    string memory version
  ) EIP712(domain, version) {
    investToken = _investToken;
    tokenX = _tokenX;
    wNFT = _wNFT;

    SIGNING_DOMAIN = domain;
    SIGNATURE_VERSION = version;

    tierids.push(1);
    tierPrice[1] = 500_00_0000_0000_0000_0000;
    tierLimit[1] = 1000;
    tierTokenX[1] = 25000_00_0000_0000_0000_0000;
    tierExtraTokenX[1] = 200000;

    tierids.push(2);
    tierPrice[2] = 1000_00_0000_0000_0000_0000;
    tierLimit[2] = 500;
    tierTokenX[2] = 50000_00_0000_0000_0000_0000;
    tierExtraTokenX[1] = 300000;

    managers[msg.sender] = true;
  }

  receive() external payable {
  }

  function invest(
    address account,
    string[] memory uris,
    InvestInfo[] memory infos,
    bytes memory signature
  ) payable public returns (uint256[] memory, uint256[] memory) {
    address signer = _verify(infos[0], signature);
    require(managers[signer], "LcSaftInvest: wrong signature");

    require(infos.length == uris.length, "LcSaftInvest: wrong infomation");

    uint256[] memory localV = new uint256[](3);
    localV[0] = uris.length;
    uint256[] memory ids = new uint256[](localV[0]);
    uint256[] memory amounts = new uint256[](localV[0]);
    for (uint256 x = 0; x < localV[0]; x ++) {
      require (tierPrice[infos[x].tier] > 0, "LcSaftInvest: no exsit tier");
      require(tierLimit[infos[x].tier] > tierSupplied[infos[x].tier] + infos[x].amount, "LcSaftInvest: overflow limit");
      tierSupplied[infos[x].tier] += infos[x].amount;
      localV[1] += tierPrice[infos[x].tier] * infos[x].amount;
      localV[2] += tierTokenX[infos[x].tier] * (10**manageDecimals + tierExtraTokenX[infos[x].tier]) * infos[x].amount / (10**manageDecimals);

      uint256 tokenId = ILcSaftWNFT(wNFT).mint(account, infos[x].amount, uris[x]);
      ids[x] = tokenId;
      amounts[x] = infos[x].amount;
    }

    IERC20(investToken).safeTransferFrom(msg.sender, address(this), localV[1]);
    IERC20(tokenX).safeTransfer(msg.sender, localV[2]);

    return (ids, amounts);
  }

  function getAllTiers() public view returns(uint256[] memory) {
    return tierids;
  }

  function withdraw(address token, uint256 amount) public onlyOwner {
    if (token == address(0)) {
      (bool success, ) = msg.sender.call{value: amount}("");
      require(success, "LcSaftInvest: withdraw failed");
    }
    else {
      IERC20(token).safeTransfer(msg.sender, amount);
    }
  }

  function setTierInformation(uint256 id, uint256 price, uint256 limit, uint256 tokenXamount, uint256 extraAmount) public onlyManager {
    uint256 len = tierids.length;
    if (price > 0) {
      tierPrice[id] = price;
      tierLimit[id] = limit;
      tierTokenX[id] = tokenXamount;
      tierExtraTokenX[id] = extraAmount;
      for (uint256 x = 0; x < len; x ++) {
        if (tierids[x] == id) return;
      }
      tierids.push(id);
    }
    else {
      for (uint256 x = 0; x < len; x ++) {
        if (tierids[x] == id) {
          tierids[x] = tierids[len - 1];
          tierids.pop();
          delete tierPrice[id];
          delete tierLimit[id];
          delete tierTokenX[id];
          delete tierExtraTokenX[id];
          return;
        }
      }
    }
  }

  function setInvestToken(address _investToken) public onlyManager {
    investToken = _investToken;
  }

  function setSupplyToken(address _tokenX) public onlyManager {
    tokenX = _tokenX;
  }

  function setManager(address _account, bool _access) public onlyOwner {
    managers[_account] = _access;
  }

  function _hash(InvestInfo memory info) internal view returns (bytes32) {
    return _hashTypedDataV4(keccak256(abi.encode(
      keccak256("InvestInfo(uint256 tier,uint256 amount,uint256 timestamp)"),
      info.tier,
      info.amount,
      info.timestamp
    )));
  }

  function _verify(InvestInfo memory info, bytes memory signature) internal view returns (address) {
    bytes32 digest = _hash(info);
    return ECDSA.recover(digest, signature);
  }
}