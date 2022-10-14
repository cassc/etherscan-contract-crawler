// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// Should be kept in sync with ./lib.js

library Test {
  /* 
   * Expect events from contracts
   */
  event ExpectFrom(address from);
  event StopExpecting();

  // Usage: from a test contract `t`, call `expectFrom(a)`. 
  // Any subsequent non-special event emitted by `t` will mean 
  // "I expect `a` to emit the exact same event". 
  // The order of expectations must be respected.
  function expectFrom(address from) internal {
    emit ExpectFrom(from);
  }

  // After using `expectFrom` and emitting some events you expect
  // to see emitted elsewhere, you can use `stopExpecting` to emit 
  // further, normal events from your test.
  function stopExpecting() internal {
    emit StopExpecting();
  }


  /* 
   * Boolean test
   */
  event TestTrue(bool success, string message);

  // Succeed iff success is true
  function check(bool success, string memory message) internal {
    emit TestTrue(success, message);
  }


  /* 
   * Always fail, always succeed
   */
  function fail(string memory message) internal {
    emit TestTrue(false, message);
  }

  function succeed() internal {
    emit TestTrue(true, "Success");
  }

  /* 
   * Equality testing
   * ! overloaded as `eq` for everything except for bytes use `eq0`.
   */

  // Bytes
  event TestEqBytes(bool success, bytes actual, bytes expected, string message);

  function eq0(
    bytes memory actual,
    bytes memory expected,
    string memory message
  ) internal returns (bool) {
    bool success = keccak256((actual)) == keccak256((expected));
    emit TestEqBytes(success, actual, expected, message);
    return success;
  }

   // Byte32
  event TestEqBytes32(
    bool success,
    bytes32 actual,
    bytes32 expected,
    string message
  );

  function eq(
    bytes32 actual,
    bytes32 expected,
    string memory message
  ) internal returns (bool) {
    bool success = (actual == expected);
    emit TestEqBytes32(success, actual, expected, message);
    return success;
  }

  // Bool
  event TestEqBool(bool success, bool actual, bool expected, string message);
  function eq(
    bool actual,
    bool expected,
    string memory message
  ) internal returns (bool) {
    bool success = (actual == expected);
    emit TestEqBool(success, actual, expected, message);
    return success;
  }

  // uints
  event TestEqUint(bool success, uint actual, uint expected, string message);

  function eq(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual == expected;
    emit TestEqUint(success, actual, expected, message);
    return success;
  }

  // strings
  event TestEqString(
    bool success,
    string actual,
    string expected,
    string message
  );

  function eq(
    string memory actual,
    string memory expected,
    string memory message
  ) internal returns (bool) {
    bool success = keccak256(bytes((actual))) == keccak256(bytes((expected)));
    emit TestEqString(success, actual, expected, message);
    return success;
  }

  // addresses
  event TestEqAddress(
    bool success,
    address actual,
    address expected,
    string message
  );


  function eq(
    address actual,
    address expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual == expected;
    emit TestEqAddress(success, actual, expected, message);
    return success;
  }

  /* 
   * Inequality testing
   */
  event TestLess(bool success, uint actual, uint expected, string message);
  function less(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual < expected;
    emit TestLess(success, actual, expected, message);
    return success;
  }

  event TestLessEq(bool success, uint actual, uint expected, string message);
  function lessEq(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual <= expected;
    emit TestLessEq(success, actual, expected, message);
    return success;
  }

  event TestMore(bool success, uint actual, uint expected, string message);
  function more(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual > expected;
    emit TestMore(success, actual, expected, message);
    return success;
  }

  event TestMoreEq(bool success, uint actual, uint expected, string message);
  function moreEq(
    uint actual,
    uint expected,
    string memory message
  ) internal returns (bool) {
    bool success = actual >= expected;
    emit TestMoreEq(success, actual, expected, message);
    return success;
  }
}

// /* Either cast your arguments to address when you call balanceOf logging functions
//    or add `is address` to your ERC20s
//    or use the overloads with `address` types */
interface ERC20BalanceOf {
  function balanceOf(address account) view external returns (uint);
}


library Display {
  /* ****************************************************************
   * Register/read address->name mappings to make logs easier to read.
   *****************************************************************/
  /* 
   * Names are stored in the contract using the library.
   */

  // Disgusting hack so a library can manipulate storage refs.
  bytes32 constant NAMES_POS = keccak256("Display.NAMES_POS");
  // Store mapping in library caller's storage.
  // That's quite fragile.
  struct Registers {
    mapping(address => string) map;
  }

  // Also send mapping to javascript test interpreter.  The interpreter COULD
  // just make an EVM call to map every name but that would probably be very
  // slow.  So we cache locally.
  event Register(address addr, string name);

  function registers() internal view returns (Registers storage) {
    this; // silence warning about pure mutability
    Registers storage regs;
    bytes32 _slot = NAMES_POS;
    assembly {
      regs.slot := _slot
    }
    return regs;
  }

  /*
   * Give a name to an address for logging purposes
   * @example
   * ```solidity
   * address addr = address(new Contract());
   * register(addr,"My Contract instance");
   * ```
   */

  function register(address addr, string memory name) internal {
    registers().map[addr] = name;
    emit Register(addr, name);
  }

  /*
   * Read the name of a registered address. Default: "<not found>". 
   */
  function nameOf(address addr) internal view returns (string memory) {
    string memory s = registers().map[addr];
    if (keccak256(bytes(s)) != keccak256(bytes(""))) {
      return s;
    } else {
      return "<not found>";
    }
  }

  /* 1 arg logging (string/uint) */

  event LogString(string a);

  function log(string memory a) internal {
    emit LogString(a);
  }

  event LogUint(uint a);

  function log(uint a) internal {
    emit LogUint(a);
  }

  /* 2 arg logging (string/uint) */

  event LogStringString(string a, string b);

  function log(string memory a, string memory b) internal {
    emit LogStringString(a, b);
  }

  event LogStringUint(string a, uint b);

  function log(string memory a, uint b) internal {
    emit LogStringUint(a, b);
  }

  event LogUintUint(uint a, uint b);

  function log(uint a, uint b) internal {
    emit LogUintUint(a, b);
  }

  event LogUintString(uint a, string b);

  function log(uint a, string memory b) internal {
    emit LogUintString(a, b);
  }

  /* 3 arg logging (string/uint) */

  event LogStringStringString(string a, string b, string c);

  function log(
    string memory a,
    string memory b,
    string memory c
  ) internal {
    emit LogStringStringString(a, b, c);
  }

  event LogStringStringUint(string a, string b, uint c);

  function log(
    string memory a,
    string memory b,
    uint c
  ) internal {
    emit LogStringStringUint(a, b, c);
  }

  event LogStringUintUint(string a, uint b, uint c);

  function log(
    string memory a,
    uint b,
    uint c
  ) internal {
    emit LogStringUintUint(a, b, c);
  }

  event LogStringUintString(string a, uint b, string c);

  function log(
    string memory a,
    uint b,
    string memory c
  ) internal {
    emit LogStringUintString(a, b, c);
  }

  event LogUintUintUint(uint a, uint b, uint c);

  function log(
    uint a,
    uint b,
    uint c
  ) internal {
    emit LogUintUintUint(a, b, c);
  }

  event LogUintStringUint(uint a, string b, uint c);

  function log(
    uint a,
    string memory b,
    uint c
  ) internal {
    emit LogUintStringUint(a, b, c);
  }

  event LogUintStringString(uint a, string b, string c);

  function log(
    uint a,
    string memory b,
    string memory c
  ) internal {
    emit LogUintStringString(a, b, c);
  }

  /* End of register/read section */
  event ERC20Balances(address[] tokens, address[] accounts, uint[] balances);

  function logBalances(
    address[1] memory _tokens, 
    address _a0
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](1);
    accounts[0] = _a0;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[1] memory _tokens,
    address _a0,
    address _a1
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](2);
    accounts[0] = _a0;
    accounts[1] = _a1;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[1] memory _tokens,
    address _a0,
    address _a1,
    address _a2
  ) internal {
    address[] memory tokens = new address[](1);
    tokens[0] = _tokens[0];
    address[] memory accounts = new address[](3);
    accounts[0] = _a0;
    accounts[1] = _a1;
    accounts[2] = _a2;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](1);
    accounts[0] = _a0;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0,
    address _a1
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](2);
    accounts[0] = _a0;
    accounts[1] = _a1;
    logBalances(tokens, accounts);
  }

  function logBalances(
    address[2] memory _tokens,
    address _a0,
    address _a1,
    address _a2
  ) internal {
    address[] memory tokens = new address[](2);
    tokens[0] = _tokens[0];
    tokens[1] = _tokens[1];
    address[] memory accounts = new address[](3);
    accounts[0] = _a0;
    accounts[1] = _a1;
    accounts[2] = _a2;
    logBalances(tokens, accounts);
  }

  /* takes [t1,...,tM], [a1,...,aN]
       logs also [...b(t1,aj) ... b(tM,aj) ...] */

  function logBalances(address[] memory tokens, address[] memory accounts)
    internal
  {
    uint[] memory balances = new uint[](tokens.length * accounts.length);
    for (uint i = 0; i < tokens.length; i++) {
      for (uint j = 0; j < accounts.length; j++) {
        uint bal = ERC20BalanceOf(tokens[i]).balanceOf(accounts[j]);
        balances[i * accounts.length + j] = bal;
        //console.log(tokens[i].symbol(),nameOf(accounts[j]),bal);
      }
    }
    emit ERC20Balances(tokens, accounts, balances);
  }

}