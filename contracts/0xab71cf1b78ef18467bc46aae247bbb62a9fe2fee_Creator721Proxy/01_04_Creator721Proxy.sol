// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../openzeppelin/proxy/Proxy.sol";
import "../../openzeppelin/utils/Address.sol";
import "../../openzeppelin/utils/StorageSlot.sol";

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&#AESPASM#&@@@@@@@@@@@@@@@@@@@@@@@@@@@&#AEGIRLS#@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@&G?~^^~!77!~^::~?5#@@@@@@@@@@@@@@@@@@@#PJ!~!BKXAE?4^^4P#@@@@@@@@@@@@
// @@@@@@@@@@G7. ~BK&@@@@@@&B4!.  ~Y#@@@@@@@@@@@@@#Y~..!4B&@@@@@@@&5^ .?#@@@@@@@@@@
// @@@@@@@@&J^:[email protected]@@@@@@@@@@@@@&5^  .?#@@@@@@@@@G!. .J#@@@@@@@@@@@@@&7  [email protected]@@@@@@@@
// @@@@@@@@&&&&@@@@@@@@@@@@@@@@@@@5:  [email protected]@@@@@B!   ?#@@@@@@@@@@@@@@@@&:  [email protected]@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#~   7&@@@Y.  :[email protected]@@@@@@@@@@@@@@@@@@!   [email protected]@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&!   [email protected]@7   ^#@@@@@@@@@@@@@@@@@@@#.   [email protected]@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&:   Y?   [email protected]@@@@@@@@@@@@@@@@@@#~   :#@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@#5JP#&@@@@@5        [email protected]@@@@@@@@@@@@@@@@@@K:   [email protected]@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&G7.   :DOTS&@@:      ^@@@@@@@@@@@@@@@@@@G~    [email protected]@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@BJ^    ^Y#&BK??SM~      [email protected]@@@@@@@@@@@@@@&5~    ^[email protected]@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&5~    :[email protected]@@@@@@&AE~      [email protected]@@@@@@@@@@@@BJ:    ~W&@@@@@@@@@@@@@
// @@@@@@@@@@@@@@B?:    ~5&@@@@@@@@@@@@J      J#@@@@@@@@@&5~    :[email protected]@@@@@@@@@@@@@@@
// @@@@@@@@@@@@SM.   :[email protected]@@@@@@@@@@@@@@7      !J?SM#@@@G?:   .~5#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@#7    :Y#@@@@@@@@@@@@@@@@&:      [email protected]&AE???^    ^[email protected]@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@B:   .K&@@@@@@@@@@@@@@@@@@5       .#@@@@&INVNTG&@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@#:   ^[email protected]@@@@@@@@@@@@@@@@@@#:   7~   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@?   :#@@@@@@@@@@@@@@@@@@@&^   [email protected]#:   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@!   [email protected]@@@@@@@@@@@@@@@@@@B^   ?&@@N:   [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@Y   [email protected]@@@@@@@@@@@@@@@@@5.  :[email protected]@@@@#!   7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@&!  [email protected]@@@@@@@@@@@@@@P~  ^W&@@@@@@@@4^  .Y#@@@@@@@@@@@@@@@#[email protected]@@@@@@@
// @@@@@@@@@@Y:  Y&@@@@@@@@@&BJ^ .!K&@@@@@@@@@@@BK!. .SM#@@@@@@@@@&BK. :4#@@@@@@@@@
// @@@@@@@@@@@&5!.:INVNTATOM~^~?G&@@@@@@@@@@@@@@@@@#57^.:~KWANGYA!^[email protected]@@@@@@@@@@
// @@@@@@@@@@@@@@&BKWANGYA4SM&@@@@@@@@@@@@@@@@@@@@@@@@@#CONNECTING#[email protected]@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

contract Creator721Proxy is Proxy {
    constructor(
        string memory name,
        string memory symbol,
        address creatorImplementation
    ) {
        assert(
            _IMPLEMENTATION_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
        );
        StorageSlot
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = creatorImplementation;
        Address.functionDelegateCall(
            creatorImplementation,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}