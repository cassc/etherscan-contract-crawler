pragma solidity 0.6.6;

import {FlashERC20} from "../FlashERC20.sol";

contract MockFlashERC20 is FlashERC20 {
  bytes32 public DOMAIN_SEPARATOR;

  // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32
    public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

  mapping(address => uint256) public nonces;

  constructor(
    string memory name,
    string memory symbol,
    uint256 supply
  ) public {
    _mint(msg.sender, supply);
    __Flash_init(name, symbol);
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("Strudel BTC")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  function deposit() public payable {
    _mint(msg.sender, msg.value);
  }

  event Data(bytes);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(deadline >= block.timestamp, "vBTC: EXPIRED");
    bytes memory msg = abi.encode(
      PERMIT_TYPEHASH,
      owner,
      spender,
      value,
      nonces[owner]++,
      deadline
    );
    emit Data(msg);
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(msg)));
    address recoveredAddress = ecrecover(digest, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == owner, "VBTC: INVALID_SIGNATURE");
    _approve(owner, spender, value);
  }
}