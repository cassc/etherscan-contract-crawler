// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* $YIPPEE                                                   ...........................:::::::::::
                                                              ............................:::::::::
                                                                  ..........................:::::::
                         ...:^:^^^~~^^^^::...                        ........................::::::
                    .^^~!!~^^^^:::::::^^~^~~7~!!!^..                     ......................::::
                 :!J!:.                       ...:^^!~:                   ......................:::
               ~?7:.                                .:!Y~.                  ......................:
             ~Y~.                                    . .!5^                   .....................
            J!. .                                    ... .7?                   ....................
           P^ ..      ..                   .:^:.     ......^J                   ...................
          ?7.... .^YB&&&#BJ.            :5&@@@###5^.  ......7J                   ..................
         .G.... :?&@@@&. ~@@7          J@@@@@G  7@&!. .......G.                   .................
         JJ.....~#@@@@&??G@@@:        ^@@@&&&&GP#@@#^. ......?!                    ................
         5^.....~GP55YYY5G#@&:        ^&&GY???JYJJPG^. ......!J                    ................
        .B.......7P5YJY5G&@&~          !#&#G5YYYPGG~.  ......??                     ...............
         Y7.......:75BB#BP7.            .7PB#&#B5!.   .......P~                     ...............
          Y7.:....     .                    ...     ......:.!G                      ...............
           Y!.:......                             ......:::^G.                      ...............
            ?7::.......        ...             ........:::~P:                       ...............
             ?Y^:::........    .:.. ...   ..........::^^~YJ.                       ................
              :YJ~^:::..........  ..............:::^~~7YG!                        .................
                ^?5J!^^::::...........:::.::::^~!7?Y5GP!                          .................
                  .~?Y?7~~^^^:::::::^^^~~!7?J5PGGGP??Y7!!^^.                    ...................
                      .^!?YY?YJJJJJY55PPGGGP5Y77!^:.......:^!7.                ....................
                           ..:GY~~~!!~~~^^::::::::::....... .~Y!              .....................
                              B^.:.....:.......................Y^           ......................:
                             .G::..........  .      ...........^P         .......................::
                             :5.^^:.......          .....:::...~G       .......................::::
                             ^G.:~7?!:...     ........:^~~^:...~P     ........................:::::
                             .G..:^!5J...    ...:^~~!7JJ7~:....~G  .........................:::::::
.                             G^....:^:..   ..:Y?~~~!7J7^::....7J ........................:::::::::
....                          P!....:^^..  ...5P5......^::.....YJ .....................::::::::::::
..........                    ??....:^^... ...G.P~....:^:......5! ...................:::::::::::::^
.................             ~5....:^^......:B.:5....~J......:B...................:::::::::::::^^^
............................. .B:...::7^.....~J  ^J^.^YP!.....!P...............:::::::::::::::^^^^^
.............................. 7Y...:7J5.....5:...:7!?:.7?^:.^5:.............::::::::::::::^^^^^^^^
................................7Y~^Y7.P^...??...........^7!??:..........:::::::::::::::^^^^^^^^^^^
..................................^:....J!^?J........................::::::::::::::::^^^^^^^^^^^^^~
:........................................^^^...................::::::::::::::::::^^^^^^^^^^^^^^~~~~
:::::::................................................::::::::::::::::::::::^^^^^^^^^^^^^^^^~~~~~~
:::::::::::::::::::...........................:::::::::::::::::::::::::::^^^^^^^^ @yippeecoineth */

import "solady/src/tokens/ERC20.sol";
import "solady/src/auth/Ownable.sol";

contract Yippee is ERC20, Ownable {

    error NotActive(); // Throw when transferring before UniswapV2Pair set
    error CapExceeded(); // Throw when max wallet balance cap is exceeded in transfer
    error ZeroAddress(); // Throw when zero address is put into a function
    error UniswapV2Pair(); // Throw when the UniswapV2Pair address is used in functions

    event MaxWalletBalanceChanged(uint256 indexed oldCap, uint256 indexed newCap);
    event UniswapV2PairChanged(address indexed oldPair, address indexed newPair);
    event CapExclusionChanged(address indexed wallet, bool indexed status);
    event BlacklistChanged(address indexed wallet, bool indexed status);

    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    uint256 public maxWalletBal; // Maximum balance a wallet is allowed to have
    address public uniswapV2Pair; // UniswapV2Pair address to exclude from caps
    mapping(address => bool) public capExclusions; // Addresses excluded from maxWalletBal
    bool public limitsEnabled; // Bool tracking if transfer limitations are active or not.

    constructor(
        address _owner,
        string memory __name,
        string memory __symbol,
        uint256 __totalSupply,
        uint256 _maxWalletBal
    ) payable {
        _initializeOwner(_owner);
        _name = __name;
        _symbol = __symbol;
        _totalSupply = __totalSupply;
        if (_maxWalletBal > 0) {
            maxWalletBal = _maxWalletBal;
            emit MaxWalletBalanceChanged(0, _maxWalletBal);
        }
        capExclusions[_owner] = true;
        emit CapExclusionChanged(_owner, true);
        capExclusions[address(this)] = true;
        emit CapExclusionChanged(address(this), true);
        capExclusions[address(0)] = true;
        emit CapExclusionChanged(address(0), true);
        capExclusions[address(0xdead)] = true;
        emit CapExclusionChanged(address(0xdead), true);
        _mint(_owner, _totalSupply);
        limitsEnabled = true;
    }

    function name() public view override returns (string memory) { return (_name); }
    function symbol() public view override returns (string memory) { return (_symbol); }
    function totalSupply() public view override returns (uint256) { return (_totalSupply); }

    // Set max wallet balance cap
    function setMaxWalletBal(uint256 _maxWalletBal) public onlyOwner {
        emit MaxWalletBalanceChanged(maxWalletBal, _maxWalletBal);
        maxWalletBal = _maxWalletBal;
    }
    // Set UniswapV2Pair
    function setUniswapV2Pair(address _uniswapV2Pair) public onlyOwner {
        // Prevent setting zero address to avoid locking transfers once unlocked
        if (_uniswapV2Pair == address(0)) { revert ZeroAddress(); }
        emit UniswapV2PairChanged(uniswapV2Pair, _uniswapV2Pair);
        uniswapV2Pair = _uniswapV2Pair;
        capExclusions[_uniswapV2Pair] = true; // Exclude UniswapV2Pair from max wallet balance cap
    }
    // Set max wallet balance cap exclusions
    function setCapExclusions(address _wallet, bool _status) public onlyOwner {
        // Prevent removing UniswapV2Pair or zero address cap exclusion
        if (_wallet == uniswapV2Pair) { revert UniswapV2Pair(); }
        if (_wallet == address(0)) { revert ZeroAddress(); }
        capExclusions[_wallet] = _status;
        emit CapExclusionChanged(_wallet, _status);
    }
    // Toggles all transaction limits
    function toggleLimits() public onlyOwner { limitsEnabled = !limitsEnabled; }

    // Allow addresses to burn their own tokens
    function burn(uint256 _value) external {
        _burn(msg.sender, _value);
    }

    // Impose blacklist, trading lock, and max wallet balance cap on all transactions
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal view override {
        if (limitsEnabled) {
            // Restrict transfers until UniV2Pair is live
            if (uniswapV2Pair == address(0)) {
                if (_from != owner() && _to != owner()) { revert NotActive(); }
            }

            // Prevent exceeding wallet cap
            if (maxWalletBal != 0) {
                if (!capExclusions[_to]) {
                    if (_amount + balanceOf(_to) > maxWalletBal) { revert CapExceeded(); }
                }
            }
        }
    }
}