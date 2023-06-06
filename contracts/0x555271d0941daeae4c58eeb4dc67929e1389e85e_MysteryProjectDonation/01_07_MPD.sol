/**

By acquiring this token you are participating in a donation for a mystery project (the project name is not revealed on purpose).

Due to regulatory reasons, at this time we can only say the project is a ZUT: there are no promises or strings attached to your
contributions, no financial advice, any cryptocurrency investing is inherently extremely risky and you should have no expectations
about ROI. Your donation might well bring you absolutely noting in return and you might lose all of your investment.

Having said that...

...MPD token holders will be airdropped the real token on launch: 50% on listing, 25% the next day, 25% one day later.
The airdrop will be directly proportional to the number of MPD tokens held.

Note: you will get MPD tokens but PLEASE do not trade them. MPD is just a placeholder token for the donation,
if anyone adds liquidity paired with MPD please DO NOT trade it and wait for launch of the real token.

If you are uncomfortable donating here, absolutely wait for the official launch!

How to donate:
1. Send either 0.25 or 0.5 or 1 eth to this contract. Any other values will not work!
2. When submitting the transaction, make sure GAS LIMIT is set to at least 200 000, otherwise the tx might fail.
3. If the tx is successful, you will receive the (placeholder) tokens.
4. Done!

The hardcap for the donation is 200 eth.

Thank you!
**/

pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MysteryProjectDonation is Context, ERC20 {
    string private _name = "MysteryProjectDonation";
    string private _symbol = "MPD";
    uint256 public totalTokens = 1000000 * (10 ** 18);
    uint256 public contributedEth;
    address public owner;

    constructor () public ERC20(_name, _symbol) {
        owner = msg.sender;
        _mint(owner, totalTokens);
        approve(owner, totalTokens);
    }

    receive() external  payable {
        require(contributedEth < 200 ether, "Sorry, hardcap reached.");

        if (msg.value == 0.25 ether) {
            contributedEth += 0.25 ether;
            transferFrom(owner, msg.sender, 1250 * (10 ** 18));
        } else if (msg.value == 0.5 ether) {
            contributedEth += 0.5 ether;
            transferFrom(owner, msg.sender, 2500 * (10 ** 18));
        } else if (msg.value == 1 ether) {
            contributedEth += 1 ether;
            transferFrom(owner, msg.sender, 5000 * (10 ** 18));
        }
    }

    function withdrawEther() external {
        require(msg.sender == owner, "Only the owner can call this function.");

        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Ether withdrawal failed.");
    }
}