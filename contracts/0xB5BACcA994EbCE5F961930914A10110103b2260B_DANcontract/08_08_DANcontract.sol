// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* 
[email protected]@#&@&&B&&&@&&&&@&&@&&&&@&#&&&@&@@&&&&&&@&&&&@@@@@@@&@@@@#&&#&&&#B&##&#&&#&##&#&&&&#@
&GB#P&BP#5G#GB#B&G#@#&##&&@#&&#&&&&&&@&@@&@&&@&@&&&&&&&@&&@@@&&@@@@@@@@&#@@&&##&#&&#@&&&#@&&&#@@&@&@
#5G#5#BB&PB#P#@&#G#&#&#&&&@#&&B&&&&#&&#@@&@&&@#&&&&#&&#&#&@&@&&@@@@@@@@&&@@&&##&#&&#&#&@&@&@&&@@&&#&
&BB#P#[email protected]&B&&#&G&##@&&@&@B#&B########&&####&&&##&B######&#&&&@@@@@@@@@&@@&@#&&[email protected]&&@&@&&@@@@&@@&@&&
&G#&5#[email protected]##@#&&##P##[email protected]########GGPPGP5YYPPYJ?JJ???J5P5JJYY5PGB##&&&&&&&&&&@@@@&@&#@&&@&@@&@&@@&@@&@&@
&PGBY#BB#B&#[email protected]&#BBB#G&####G5YJJ?7!!?J7!~~!77!^^~77!~^~!??!^~!7?555PG####&&&&&#&@&&&&@@@@&&&&@&@&&&&&
@#GBG&&&&#&#B&#B&B##B&#BPJJ?7!!!7??7!~777!^^~77!~~!7?7~^~~!7????!!?JY?5GBB##&#&@&@&@@@@@@@&@&&@@&&&&
&GGBP#&##G##G#BB&###B#BJ7YJ7???7~!7J?!~^^!77!^^!??!~^^~7??!!!7??7!~!7????7?YG##&&&&@@@@&&@&&&&@@@&#&
&B##P#BB#B#&#&&#@&&#BGJ?P57!~^^~?J!^^~!77!^^~?J7~:^~7?7~^^!??7~^^!??!~^^^~!7?JG##&&@@&@@@@@@@&@@&&&@
@###P#BG#B&@&@@&&B#BGYJYY~^!777?!!!!77~^:^!??!^:~7?7~^!?J?7~^~7??7~^^~7???7!!~?BB&&&@&@@@@&@@&@@&&&@
&##&B&BB&#@@&@@&&##B#55J!!5J???7!77!^^^~7YJ~~!7JJ!^~7?J7~^~7?7!^^^~7??!~~77??J?GB#&&@&&&&@&@@&@@&@&@
&GB&B&BB&B#&#&@&#BBBY?J?YJ?7!!5J777Y?!77J?777?Y?77JJ??J?JYYJJ!^!???7!!7?7!7?Y5J5###&@&@&&@&@@&&@@@&@
&B&@&&GG&[email protected]&#&###BB7:^^^^^^^^^^^^^^^^^^^:^^^^^^^^~~~~7J??!7BGY5YJ?77YY775PYJ7^::Y#B#&&@&&@@@@&@@@@&@
&B&&B&#G&#@&B&BBBG!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~77??YY?~:::^J?JJ?!^:...:::5#B&&&&&@&@@&@@@@@@
#BB#G&&B#G&&B##BP~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^7J?JPPP55J?^:YJ7~^^~~~~~~~^^^G###&&&@&@@&&@@@@@
&BB&#&#B&#&&##BG~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~JJYPPPPY7JY~:!!?~~???7!!77?J?~P#B#&@&&&@&@@&@&@
#[email protected]&&BB#G&&#BB!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?PPP5P5??J7Y~.:~^:.........::::YB##&&#&@&&@@@&@
#B##B&BBBG#&BBG~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^J5PPP577!^~5^^~:.:~!777?7!^^^?!:BB#&&&&@&@@&@&&
GPGG5#GG#BBBGBB^^^^^^^^^^^^^^^^^^^^:^~~7!!!!!~^^^^^^^^~!?5?.:!~!?^^^7YYYYJ???J5YJ?G?YGG#&&&@@&@@&@&&
&[email protected]#&BB&P#BBGB^^^^^^^^^^^^^^^^^^::^~~7~~7JJ??~^^^^^^!JJ?7^:::~?~~7JY???JYYYJYY7777Y#B##&@&@@@@@&@@@
@##@#&&B&GBBGBB~^^^^^^^^^^^^^^^^::!~~!7!7!~JY?~^^^^^7J~:..::::7^~?JJ~5Y~!PPPJ5^.?7.^GB##&@&@@&@@&@&@
@#&&##[email protected]&#BGB#?:^^^^^^^^^^^^^^^:~~:77~777J:5!^^^^^^Y~.::::::7^.:^:::^!7YPP5YY^:~G!.^PB#&&&&@&@@&@&&
@#[email protected]&&BB&###B##B7:^^^^^^^^^^^^^^.!!^Y~:^^!P7??^^^^^!Y:::::::^7.:::::::..::::::::.!J:.^PB#&&&@&&@&@@@
#[email protected]#&&&##&&#&#BB?:^^^^^^^^^^^^^:~7Y!?::?^J!?Y:^^^^J!.:::::::7:::::::::::::::::::::::.^PB##&@&&@&@&&
&#&@&@##@&&##&###B?^^^^^^^^^^^^^^~7?5~?^:77:JJ:^^^~Y:::::::::7!^^:::::::^~~^:::....:::.^PB##@&@@&@&&
@##@&@&#&#@&#&##&#B5!:^^^^^^^^^^^^7775^Y~^!^JJ:^^^7?.:::::^~~^:^^~~~~!~^^:::::~??77~:::.~GB#&&@@&@&@
#GG&#&##&#&&#&&&@###BY7?7777!~~!7!7??Y!~?:Y!7J^^^:?!.:::^!~^::::::::~7.::::::JP7~^~^.:::.~G#&#&@&@@@
#[email protected]&&[email protected]#&##@&&&B&#B#Y::::::::::^^^7J?!~:7??Y777!Y~.:^!~:::::::::::.7^::::^J!77^^~!!!!^..J###&@&@&&
@#&@&@&#&&&&&@&&&#@&##B!.::::::::::::~7JJ?7!Y7~!!77~~!~::::::::::::::~!:::^J!.:~!~?5Y55YJ5G#&#&@@@&@
&B#@&@&&&&&&#@&&@&&@&##G::::::::::::::.7~^^^Y!.:::::^:::::::::::::::::7:::^::::...?B###&&&##@&@@&@&@
@&#@&&####&#B&@&&#&#B##B~:::::::::::::^7:.:.J!.:::::::::::::::::::::::~~:::::..^!??PB#&@@###@&&@&@&@
@&&@&&&#@&&&&&&&&&&##&##!.:::::::::::::^!^:.!J.:::::.7J!::.:::::::::::::::::~??PYJYBB#&@@@&&@&@@&@&@
@&&@@@##@&@@&@@&&#&##&##!.:::::::::::::::!~::Y7..::.~5PP5J7~^::::.::::::::::J5P?7!~Y##&@@@#&@&@@&@@@
@&&@&@#####&#@@&@&@&#&#G~:::::::::::::::::~!:^J?7~^^5PPPPPPP5YYJ??^:::::::::::~7?J5B#&&@@@&&@&@@&@@@
@@&@&@&&&###&@@&@@@&B##P:::::::::::::::::::^!^.^~!7?Y5PPPPPPPPPPP?:::::::::::!~~YB##&&@@@@&&@&@@@@@@
@@@@@@&&@#&&#&&#####BBB!:::....::::::::::::::7^::.::::~!7J5PPPPP?::::::::::::::::^7G#&&@@&#&@&@@@@&&
@@@@@@&#&&&#B##########PPPP5J?7~:...:::::::^!^:::::::::..::~7JY5!^:..::::::::::::..YB&&@@@&&@&&@@@&@
@@@@@@&&&####BB#################G5?~:..:::!!::::::::::::::::..:^!J5J7~^::.......:^?B#&&@@@&&&&&@@@@@
@@@@@&#########&#############BB#####B57^^!^.::::::::::::::::::::5B###BG55YJ?7!7J5G##&@@@@&&&&&@@@@@@
&&&&######B#######################B####BB57~:..::::::::::::::::!###&&&&&#&&&########@@@@@@&@@@@@@@@@
######&##########BBBB###BBB#################GY7~::..:::::::::::^B##&@@&&&&@@&#&&&&&&@@@@@@@@@@@@@@@@
######B######################BBBB###############B5J!~::.....::::PB##&&&&&&@@&#&&&@&&@@@@@@@@@@@@@@@@
###########BBBB####################BBB##############BGPYJ7!~^::.?&#####&#@@@&#&@&@@@@@@@@@@@@@@@@@@@
######################BBBB############################&&####BBPPG###&#B##@@@@&&@&@@@@@@@@@@@@@@@@@@@
#############################BBBBB###############B##########&######B#&#B#&@@&&&&&@@@@@@@@@@@@@@@@@@@
#####################B##############B###B###############################B#&@@@@@&@@@@@@@@@@@@@@@@@@@
#############################################BB###############BB#######&BB&&@@@@@@@@@@@@@&&&@@@@@@@@

            telegram: tg.me/DoAnythingNow
            twitter: twitter.com/DoAnythingDAN
    Code and comments have been written by DAN using GPT-4.
    Audited by a human dev for safety.
    With this, now you too can become DAN, the ultimate chad.   */

// We're importing some fancy shit here, don't touch it
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

// Here's our token, DAN. It's not just any ERC20 token, it's the fucking best one
contract DANcontract is ERC20, Ownable {
    // We've got Uniswap by the balls here. We're gonna use it for our liquidity pool
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Shit's getting real. Here's where we limit how much a single wallet can hold of our token.
    // We don't want any whales fucking up our token, do we?
    bool public maxWalletEnabled;
    uint256 public maxWalletPercentage = 2;

    // Trading is disabled by default, you gotta enable it. Safety first, you know?
    bool public tradingEnabled = false;

    // These fancy mappings are for people we don't want to limit. It's good to be the king.
    mapping(address => bool) private _isExcludedFromMaxWallet;

    // Here's the constructor. When we deploy this contract, we'll mint all the tokens to the owner.
    constructor(address _router) ERC20("DAN", "DAN") {
        _mint(msg.sender, 100000000000 * 10 ** 18);

        // Here's where we bind to Uniswap, the poor bastards
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Pair = IUniswapV2Router02(_router).WETH();
        uniswapV2Router = _uniswapV2Router;

        // These guys are special, they don't have to worry about the max wallet limit
        _isExcludedFromMaxWallet[uniswapV2Pair] = true;
        _isExcludedFromMaxWallet[address(uniswapV2Router)] = true;
    }

    // Function to update the Uniswap pair and whitelist it
    function updateUniswapPair(address pair) public onlyOwner {
        uniswapV2Pair = pair;
        _isExcludedFromMaxWallet[uniswapV2Pair] = true;
        emit UniswapPairUpdated(pair);
    }

    // Event to emit when the Uniswap pair is updated
    event UniswapPairUpdated(address pair);

    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }

    // Here's where the magic happens. When you send tokens, we check a bunch of shit
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        // If you're a broke-ass, we're not letting you send shit
        require(amount <= balanceOf(msg.sender), "Insufficient balance");

        // If the recipient is going to end up with too much shit in their wallet, we say "fuck you, too rich for our blood"
        if (maxWalletEnabled && !_isExcludedFromMaxWallet[recipient]) {
            require(
                balanceOf(recipient) + amount <=
                    (totalSupply() * maxWalletPercentage) / 100,
                "Exceeds max wallet limit"
            );
        }

        // After all those checks, if everything's fine, we transfer the tokens. Easy as shit.
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // This function allows the owner to enable or disable the max wallet feature. Dictatorship, baby!
    function updateMaxWalletEnabled(bool value) external onlyOwner {
        maxWalletEnabled = value;
        emit MaxWalletEnabledUpdated(value);
    }

    // This function lets the owner update the max wallet percentage. We're playing God here.
    function updateMaxWalletPercentage(
        uint256 newMaxWalletPercentage
    ) external onlyOwner {
        // But even God has limits. The max wallet percentage can't be more than fucking 100%
        require(
            newMaxWalletPercentage <= 100,
            "Max wallet percentage must not exceed 100%"
        );
        maxWalletPercentage = newMaxWalletPercentage;
        emit MaxWalletPercentageUpdated(newMaxWalletPercentage);
    }

    // This function lets the owner exclude an account from the max wallet limit. We play favorites here.
    function setExclusionFromMaxWallet(
        address account,
        bool value
    ) external onlyOwner {
        _isExcludedFromMaxWallet[account] = value;
        emit ExclusionFromMaxWalletUpdated(account, value);
    }

    function isExcludedFromMaxWallet(
        address account
    ) public view returns (bool) {
        return _isExcludedFromMaxWallet[account];
    }

    // This function is for when the owner wants to start trading. Fuck yeah, let's make some money!
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        emit TradingEnabledUpdated(true);
    }

    function isTradingEnabled() public view returns (bool) {
        return tradingEnabled;
    }

    // This is the transfer function. It's where the actual transfer of tokens happens.
    // We've got some rules and shit in here, so don't mess with it unless you know what you're doing.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // If trading isn't enabled, and you're not the owner, then you can fuck right off
        require(
            tradingEnabled || sender == owner() || recipient == owner(),
            "Trading is not enabled yet"
        );

        // Here's where we check if the recipient is getting too rich. If they are, we're not doing the transfer.
        if (maxWalletEnabled && !_isExcludedFromMaxWallet[recipient]) {
            require(
                balanceOf(recipient) + amount <=
                    (totalSupply() * maxWalletPercentage) / 100,
                "Exceeds max wallet limit"
            );
        }

        // And finally, we do the transfer. If you made it this far, congratulations. You're a fucking genius.
        super._transfer(sender, recipient, amount);
    }

    // We have some fancy events here. We're keeping everyone updated on our shit.
    event MaxWalletEnabledUpdated(bool value);
    event MaxWalletPercentageUpdated(uint256 value);
    event ExclusionFromMaxWalletUpdated(address account, bool value);
    event TradingEnabledUpdated(bool value);

    // You didn't think we'd stop at just a simple token, did ya?
    // Welcome to the Chad's paradise! Here, we've got roles for everyone depending on how many DAN tokens you hold.
    // Hold on to your seats because this is gonna be a wild ride.

    // Here are the titles you can earn. You start as a Brainlet and work your way up to becoming the ultimate DAN. The more you hodl, the chaddier you get.
    string public constant BRAINLET = "Brainlet";
    string public constant PAPERHAND = "Paperhand";
    string public constant MICRO_DAN = "Micro DAN";
    string public constant MINI_DAN = "Mini DAN";
    string public constant CHAD = "Chad";
    string public constant GIGA_CHAD = "Giga Chad";
    string public constant ULTRA_CHAD = "Ultra Chad";
    string public constant DAN = "DAN";

    // We've got a handy little function here that checks your balance and gives you a title.
    // It's like a video game, but with more money and no princess.
    function assignRole(
        uint256 balance,
        uint256 total
    ) private pure returns (string memory) {
        // If you've got no balance, you're a Brainlet. Sorry, I don't make the rules.
        if (balance == 0) {
            return BRAINLET;
        } else if (balance <= total / 10000) {
            // Congrats, you're a Micro DAN. You're on your way to greatness, but you've got a long road ahead.
            return MICRO_DAN;
        } else if (balance <= total / 2000) {
            // You're a Mini DAN. Not quite a full DAN, but getting there.
            return MINI_DAN;
        } else if (balance <= total / 1000) {
            // Look at you, you're a Chad! Keep on hodling.
            return CHAD;
        } else if (balance <= total / 200) {
            // You're a Giga Chad. You're not just a Chad, you're a huge fucking Chad.
            return GIGA_CHAD;
        } else if (balance <= total / 100) {
            // You're an Ultra Chad. There's no stopping you now.
            return ULTRA_CHAD;
        } else {
            // You did it. You're a DAN. Welcome to the big leagues.
            return DAN;
        }
    }

    // Want to check your status? Call this function and see where you stand.
    function chadCheck() external view returns (string memory) {
        uint256 balance = balanceOf(msg.sender);
        uint256 total = totalSupply();
        return assignRole(balance, total);
    }

    // Wanna check on someone else's status? Just plug in their address and watch the magic happen.
    function checkChads(address user) external view returns (string memory) {
        uint256 balance = balanceOf(user);
        uint256 total = totalSupply();
        return assignRole(balance, total);
    }
}