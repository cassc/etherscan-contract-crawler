pragma solidity >0.6.1 <0.7.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./LuckyManekiNFT.sol";
import "./LuckyProvable.sol";

interface ILuckyRaffle {
    function raffleIndex() external view returns (uint256);

    function RAFFLE_TICKETS() external view returns (uint256);
}

contract LuckyRaffle {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    address public creator;
    LuckyManekiNFT public ctxManeki;
    LuckyProvable public ctxProvable;
    uint256 public constant RAFFLE_TICKETS = 30;
    struct Raffle {
        EnumerableSet.AddressSet accounts;
        mapping(address => uint256) balances;
        uint256 tokensLen;
        uint256 totalValue;
        address winner;
        bool isPaid;
        bool compiled;
    }
    uint256 public nextToken = 1;
    event RaffleWinner(address winner, uint256 amt);
    mapping(uint256 => Raffle) private _raffles;
    uint256 public raffleIndex = 0;

    constructor() public {
        creator = msg.sender;
    }

    function setupManekiProvable(address maneki, address provable)
        public
        payable
    {
        require(msg.sender == creator, "!creator");
        ctxManeki = LuckyManekiNFT(payable(maneki));
        ctxProvable = LuckyProvable(payable(provable));
    } /*--------------------------------------------------------------*/

    function compileRaffle() public returns (uint256 index) {
        require(msg.sender == creator, "sender!=creator");
        uint256 token = nextToken;
        Raffle storage r = _raffles[raffleIndex];
        address lastAddress = address(0);
        uint256 lastCount = 0;
        uint256 unitPrice = ctxManeki.salePrice();
        uint startToken = token;
        while (
            (r.accounts.length() < RAFFLE_TICKETS) &&
            (token < ctxManeki.totalSupply()) &&
            (token < (ctxManeki.MAX_SUPPLY())) &&
            (startToken + 300 > token)
        ) {
            address owner = ctxManeki.ownerOfAux(token);
            if (owner == address(0) || owner == creator) {
                token += 1;
                continue;
            }
            r.tokensLen += 1;
            r.totalValue += unitPrice;
            if (owner == lastAddress) {
                lastCount += 1;
            } else {
                lastAddress = owner;
                lastCount = 1;
            }
            r.balances[owner] += 1;
            r.accounts.add(owner);
            token += 1;
        }
        if (lastAddress != address(0x0)) {
            while (
                (ctxManeki.ownerOfAux(token) == lastAddress) &&
                (token < ctxManeki.totalSupply()) &&
                (lastCount < RAFFLE_TICKETS)
            ) {
                r.tokensLen += 1;
                lastCount += 1;
                r.totalValue += unitPrice;
                r.balances[lastAddress] += 1;
                token += 1;
            }
        }

        if (
            (r.accounts.length() == RAFFLE_TICKETS) ||
            (token == (ctxManeki.MAX_SUPPLY()) && r.accounts.length() > 0 )
        ) {
            r.compiled = true;
        }

        _raffles[raffleIndex] = r;
        nextToken = token;

        if (r.compiled) {
            raffleIndex += 1;
        }
        require(r.accounts.length() > 0, "raffles compiled");
        return raffleIndex;
    }

    function __execRaffle(uint256 index, uint256 rand) public {
        require(msg.sender == address(ctxProvable), "!provable");
        require(index <= raffleIndex, "i<=raffle");
        Raffle storage raffle = _raffles[index];
        require(raffle.compiled, 'Not compiled');
        require(!raffle.isPaid, "paid");
        require(
            (ctxManeki.MAX_SUPPLY() == ctxManeki.totalSupply()) ||
                (raffle.accounts.length() >= RAFFLE_TICKETS),
            "not-complete"
        );
        require(raffle.tokensLen > 0, "tokensLen > 0");
        int256 needle = int256(rand % raffle.tokensLen);

        uint256 accountIndex = 0;
        while (needle > 0) {
            needle -= int256(raffle.balances[raffle.accounts.at(accountIndex)]);
            if (needle < 0) break;
            accountIndex++;
        }
        address winner = raffle.accounts.at(accountIndex);
        uint256 amt = raffle.totalValue.mul(10).div(100);

        raffle.isPaid = true;
        raffle.winner = winner;
        bool success = ctxManeki.sendRafflePrize(winner, amt);
        require(success, "Send Prize not Success");
        emit RaffleWinner(winner, amt);
    }

    function raffleByIndex(uint256 index)
        public
        view
        returns (
            uint256 numAccounts,
            uint256 prize,
            bool isPaid,
            bool compiled,
            uint256 tokensLen,
            address winner
        )
    {
        require(index < raffleIndex);
        Raffle storage r = _raffles[index];
        return (
            r.accounts.length(),
            r.totalValue.mul(10).div(100),
            r.isPaid,
            r.compiled,
            r.tokensLen,
            r.winner
        );
    }

    function raffleAccounts(uint256 index)
        public
        view
        returns (address[] memory)
    {
        require(index <= raffleIndex);
        Raffle storage r = _raffles[index];
        uint256 count = r.accounts.length();
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = r.accounts.at(i);
        }
        return result;
    }

    function withdraw(address recipient, uint256 amt) external {
        require(msg.sender == creator);
        (bool success, ) = payable(recipient).call{value: amt}("");
        require(success, "ERROR");
    }

    receive() external payable {}
}