pragma solidity ^0.7.4;pragma experimental ABIEncoderV2;
import "./Namehash.sol";
import '@ensdomains/ens/contracts/ENS.sol';
import '@ensdomains/ens/contracts/ReverseRegistrar.sol';
import '@ensdomains/resolver/contracts/Resolver.sol';

contract TwitterRecords {
    ENS ens;
    ReverseRegistrar registrar;
    bytes32 private constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    constructor() {
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        registrar = ReverseRegistrar(ens.owner(ADDR_REVERSE_NODE));
    }

    function getHandles(string[] calldata names) external view returns (string[] memory r) {
        r = new string[](2 * names.length);
        for(uint i = 0; i < names.length; i++) {
            string memory name = names[i];
            bytes32 namehash = Namehash.namehash(name);
            address resolverAddress = ens.resolver(namehash);
            if(resolverAddress != address(0x0)){
                Resolver resolver = Resolver(resolverAddress);
                address resolvedAddress = resolver.addr(namehash);
                bytes32 node = node(resolvedAddress);
                address reverseResolverAddress = ens.resolver(node);
                if(reverseResolverAddress != address(0x0)){
                    Resolver reverseResolver = Resolver(reverseResolverAddress);
                    string memory reverseName = reverseResolver.name(node);
                    if((keccak256(abi.encodePacked((reverseName))) == keccak256(abi.encodePacked((name))))){
                        string memory handle = resolver.text(namehash, "com.twitter");
                        if(bytes(handle).length > 0){
                            r[2 * i] = toChecksumString(resolvedAddress);
                            r[2 * i + 1] = handle;
                        }
                    }
                }
            }
        }
        return r;
    }

    function node(address addr) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(ADDR_REVERSE_NODE, sha3HexAddress(addr)));
    }

    function sha3HexAddress(address addr) private pure returns (bytes32 ret) {
        addr;
        ret; // Stop warning us about unused variables
        assembly {
            let lookup := 0x3031323334353637383961626364656600000000000000000000000000000000

            for { let i := 40 } gt(i, 0) { } {
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
                i := sub(i, 1)
                mstore8(i, byte(and(addr, 0xf), lookup))
                addr := div(addr, 0x10)
            }

            ret := keccak256(0, 40)
        }
    }

  function toChecksumString(
    address account
  ) private pure returns (string memory asciiString) {
    // convert the account argument from address to bytes.
    bytes20 data = bytes20(account);

    // create an in-memory fixed-size bytes array.
    bytes memory asciiBytes = new bytes(40);

    // declare variable types.
    uint8 b;
    uint8 leftNibble;
    uint8 rightNibble;
    bool leftCaps;
    bool rightCaps;
    uint8 asciiOffset;

    // get the capitalized characters in the actual checksum.
    bool[40] memory caps = toChecksumCapsFlags(account);

    // iterate over bytes, processing left and right nibble in each iteration.
    for (uint256 i = 0; i < data.length; i++) {
      // locate the byte and extract each nibble.
      b = uint8(uint160(data) / (2**(8*(19 - i))));
      leftNibble = b / 16;
      rightNibble = b - 16 * leftNibble;

      // locate and extract each capitalization status.
      leftCaps = caps[2*i];
      rightCaps = caps[2*i + 1];

      // get the offset from nibble value to ascii character for left nibble.
      asciiOffset = getAsciiOffset(leftNibble, leftCaps);

      // add the converted character to the byte array.
      asciiBytes[2 * i] = byte(leftNibble + asciiOffset);

      // get the offset from nibble value to ascii character for right nibble.
      asciiOffset = getAsciiOffset(rightNibble, rightCaps);

      // add the converted character to the byte array.
      asciiBytes[2 * i + 1] = byte(rightNibble + asciiOffset);
    }

    return string(asciiBytes);
  }

  function toChecksumCapsFlags(address account) private pure returns (
    bool[40] memory characterCapitalized
  ) {
    // convert the address to bytes.
    bytes20 a = bytes20(account);

    // hash the address (used to calculate checksum).
    bytes32 b = keccak256(abi.encodePacked(toAsciiString(a)));

    // declare variable types.
    uint8 leftNibbleAddress;
    uint8 rightNibbleAddress;
    uint8 leftNibbleHash;
    uint8 rightNibbleHash;

    // iterate over bytes, processing left and right nibble in each iteration.
    for (uint256 i; i < a.length; i++) {
      // locate the byte and extract each nibble for the address and the hash.
      rightNibbleAddress = uint8(a[i]) % 16;
      leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
      rightNibbleHash = uint8(b[i]) % 16;
      leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

      characterCapitalized[2 * i] = (
        leftNibbleAddress > 9 &&
        leftNibbleHash > 7
      );
      characterCapitalized[2 * i + 1] = (
        rightNibbleAddress > 9 &&
        rightNibbleHash > 7
      );
    }
  }

  function getAsciiOffset(
    uint8 nibble, bool caps
  ) private pure returns (uint8 offset) {
    // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
    if (nibble < 10) {
      offset = 48;
    } else if (caps) {
      offset = 55;
    } else {
      offset = 87;
    }
  }

 function toAsciiString(
    bytes20 data
  ) private pure returns (string memory asciiString) {
    // create an in-memory fixed-size bytes array.
    bytes memory asciiBytes = new bytes(40);

    // declare variable types.
    uint8 b;
    uint8 leftNibble;
    uint8 rightNibble;

    // iterate over bytes, processing left and right nibble in each iteration.
    for (uint256 i = 0; i < data.length; i++) {
      // locate the byte and extract each nibble.
      b = uint8(uint160(data) / (2 ** (8 * (19 - i))));
      leftNibble = b / 16;
      rightNibble = b - 16 * leftNibble;

      // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
      asciiBytes[2 * i] = byte(leftNibble + (leftNibble < 10 ? 48 : 87));
      asciiBytes[2 * i + 1] = byte(rightNibble + (rightNibble < 10 ? 48 : 87));
    }

    return string(asciiBytes);
  }
}