// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC20Upgradeable} from "@oz-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@oz-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ITearToken} from "./interfaces/ITearToken.sol";

/**
 * MMMMMW0dxxxdkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMM0cdKNNKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMKolk00kloXMWNK0KKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMXkxxddkXWKdoddxxxxkOKXXXNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMWWMMMXllO000KKKOkxxxxkkkkkkkkkO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMKccO000000KKXNNNNNNNXXXK0OkkkkkkOKNMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMN0xocck0000000000KKKKXXXNNNNWWWWNX0kkkkOKWMMMMMMMMMMMMMMMMM
 * MMMMMMMMWXkoodkOOO00000000000000000000KKXXNNWWWMWXOxxk0NMMMMMMMMMMMMMM
 * MMMMMMWKxlokO000000000000000000000000000000KXWMMMMMMN0kxkKWMMMMMMMMMMM
 * MMMMMXxlok0000000000000000000000000000000000KNMMMMMMMMMN0xxONMMMMMMMMM
 * MMMW0ook0000000000000000000000000000000000000XWMMMMMMMMMMWKxdONMMMMMMM
 * MMWkldO000000000000000000000000000000000000000KXNWMMWNNWMMMWKxd0WMMMMM
 * MNxcx00000000000000000000000000000000000000000000KXOc,':ONWWMW0dkNMMMM
 * Wkcd0000000000000000Oo;,:dO00000000000000000000000d.    .oXWWMMXxdKMMM
 * KloO000000000000000k;    .:k000000000000000000000O:    ;'.dNNWWMNxoKMM
 * dck000000000000000Oc    '..lO00000000000000000000O:       ;KNNWWMNxoXM
 * lo0000000000000000x'   .:;.;k00000000000000000000Ol.      'ONNNWWMXdxN
 * cd0000000000000000x'       ,k000000000000000000000x'      .xNNNNWWM0o0
 * cd0000000000000000x'       ;O000000000000000000000Oo.     ;kXNNNNWMNdd
 * cd0000000000000000k;      .lO0000000000000000000000Od:'.,ck0KXNNNWWWko
 * olO0000000000000000d'     'x000000000000000O0000000000Okxk000XNNNNWMOl
 * kcx00000000000000000x:...;xOOxkO00000OOxolc::cclooodolccok000KNNNNWMOl
 * XolO00000000000000000OkkkO00kollccclcc:;,,;;;;,,,,,'.,lk00000KNNNNWMko
 * M0loO0000000000000000000000000Oko:,''',,,,,,,,,,,;;:okO000000KNNNNWWxd
 * MWOloO000000000000000000000000000OkkxdddddddoodddxkO000000000XNNNWMKoO
 * MMW0lok00000000000000000000000000000000000000000000000000000KXNNWWNddN
 * MMMMXdlxO000000000000000000000000000000000000000000000000000XNNNWNxdXM
 * MMMMMWOolxO000000000000000000000000000000000000000000000000KNNNWKxdKMM
 * MMMMMMMNOoldO000000000000000000000000000000000000000000000KNNNXkdkNMMM
 * MMMMMMMMMN0dooxO00000000000000000000000000000000000000000KXKkxdkXWMMMM
 * MMMMMMMMMMMWXOxdooxkO0000000000000000000000000000000Okxxdxxxk0NMMMMMMM
 * MMMMMMMMMMMMMMMNKOxdddoooddxxxxkkkkkkkxxxxxddddoooodddxkOKNWMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMWNKOxdollccccccccccccccccllodxk0KNWMMMMMMMMMMMMMMMM
 *
 * @title TearToken
 * @custom:website www.descend.gg
 * @custom:version 2
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Implementation contract for $TEAR token, used in the Descend
 *         Crawler game by Squishiverse. No longer mintable.
 */
contract TearTokenV2 is
    Initializable,
    ITearToken,
    ERC20Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @dev Externally owned accounts that may issue token
    mapping(address => bool) _eoaContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC20_init("Tear Token", "TEAR");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Set an EOA that can issue said token
     * @param address_ Address to toggle
     * @param toggle Stage of the EOA, true for active, false for inactive
     */
    function setEoa(address address_, bool toggle) external onlyOwner {
        _eoaContract[address_] = toggle;
    }

    /**
     * @notice Allow the EOA to mint tokens
     * @param recipient Recipient to receive tokens
     * @param amount Amount of token to issue
     */
    function eoaMint(address recipient, uint256 amount) public onlyEoa {
        _mint(recipient, amount);
    }

    modifier onlyEoa() {
        if (_eoaContract[msg.sender] != true) {
            revert NonApprovedEOA(msg.sender);
        }
        _;
    }

    /**
     * @dev No decimal places for this token will be set
     */
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    /**
     * @dev Part of IERC1967
     * @param newImplementation New implementation contract
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @notice Get the implementation contract
     */
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}