//  _  _  _  _  _ __
// | || || || || '_ \ ___
// | __ | \_. || .__// -_)
// |_||_| |__/ |_|   \___|
//
// $Hype Token
// Website: https://hypetoken.vip
// Telegram: https://t.me/HypetokenVIP
// Twitter: https://twitter.com/HypeToken_vip

pragma solidity ^0.8.4;

contract Hype is ERC20, Ownable {
    constructor() ERC20("HypeToken.vip", "HYPE") {
        // Total max supply set at 100 Billion
        uint256 maxSupply = 100_000_000_000 * (10 ** decimals());

        // Wallets
        address team = 0x73311b904659693970991D18E20217f91FeB5768;
        address marketing = 0x4d3b4744FDB5166F33Ec7ae99E32b9DDcaF2520a;

        // Mint for team and marketing
        _mint(team, (maxSupply * 2) / 100); // 2%
        _mint(marketing, (maxSupply * 2) / 100); // 2%

        // Mint to deployer to be used for Uniswap
        _mint(msg.sender, (maxSupply * 96) / 100); // 96%

        // Renounce ownership
        renounceOwnership();
    }
}

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";