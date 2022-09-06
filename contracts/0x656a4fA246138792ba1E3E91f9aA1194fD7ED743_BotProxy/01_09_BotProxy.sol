// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface EtherRock {
    function giftRock(uint256 rockNumber, address receiver) external;

    function rockOwners(address, uint256) external view returns (uint256);

    function dontSellRock(uint256 rockNumber) external;

    function withdraw() external;

    function buyRock(uint256 rockNumber) external payable;

    function rocks(uint256)
        external
        view
        returns (
            address owner,
            bool currentlyForSale,
            uint256 price,
            uint256 timesSold
        );

    function getRockInfo(uint256 rockNumber)
        external
        returns (
            address,
            bool,
            uint256,
            uint256
        );

    // function rockOwningHistory(address _address) external returns (uint256[]);

    function latestNewRockForSale() external view returns (uint256);

    function sellRock(uint256 rockNumber, uint256 price) external;
}

// Upgradeable contracts have a proxy which stores no code but stores the memory space of the program, and a logic contract which
// stores the code but has (almost) nothing stored in its memory. The proxy has a special storage slot where it stores the address of the logic contract.
// We deploy the proxy, then deploy the logic contract, then set the proxy's implementation slot to that of the
// This setup poses some weirdness, like no constructor or initialized non-constant global vars, a potential memory collision with this one reserved slot, and that
// upgraded implementations of the logic contract must have the same memory layout as the original code. When it is time to upgrade, see: https://docs.openzeppelin.com/upgrades-plugins/1.x/faq#what-does-it-mean-for-a-contract-to-be-upgrade-safe
contract BotProxy is Initializable, OwnableUpgradeable {
    address public bot;
    uint256 public bribe;
    EtherRock public rockContract;

    // proxy contracts cannot have a constructor, b/c constructor code is only run once, on deploy, so it is never run against the proxy contract's state
    // Hence we use an initializer. See  https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    function initialize() public initializer {
        // These calls are weird, but documented here: https://forum.openzeppelin.com/t/how-to-use-ownable-with-upgradeable-contract/3336/4
        __Context_init_unchained();
        __Ownable_init_unchained();

        // non-constant variables initialized at top of contract are equivalent to code in the constructor (doesn't run in memory space of proxy contract)
        // So all non-constant variables must be initialized in the initializer:

        bot = address(0);
        bribe = 5 ether;
        rockContract = EtherRock(0x41f28833Be34e6EDe3c58D1f597bef429861c4E2);
    }

    function setBot(address _bot) public onlyOwner {
        bot = _bot;
    }

    function setBribe(uint256 _bribe) public onlyOwner {
        bribe = _bribe;
    }

    function setRockContract(address _rockContract) public onlyOwner {
        rockContract = EtherRock(_rockContract);
    }

    function buyRock(uint256 rockNumber, uint256 price) public {
        require(msg.sender == bot);

        rockContract.buyRock{value: price}(rockNumber);

        block.coinbase.transfer(bribe);
    }

    function ownerWithdrawal(address _token) public onlyOwner {
        if (_token == address(0)) {
            (bool sent, ) = owner().call{value: address(this).balance}(""); // see: https://solidity-by-example.org/sending-ether/
            require(sent, "Failed to send Ether");
        } else {
            IERC20 token = IERC20(_token);

            uint256 bal = token.balanceOf(address(this));

            token.approve(address(this), bal);
            token.transfer(owner(), bal);
        }
    }

    function ownerWithdrawRock(uint256 rockNumber) public onlyOwner {
        rockContract.giftRock(rockNumber, owner());
    }

    receive() external payable {} // enable contract to receive ether (note we don't need fallback function: https://stackoverflow.com/questions/59651032/why-does-solidity-suggest-me-to-implement-a-receive-ether-function-when-i-have-a)
}