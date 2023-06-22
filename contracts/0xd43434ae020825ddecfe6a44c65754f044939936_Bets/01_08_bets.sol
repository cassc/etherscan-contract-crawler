// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import 'hardhat/console.sol';
interface IERC20 { function transfer(address to, uint256 amount) external returns (bool);}
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

// 1) Change pool address to Mainnet
// 2) Set the gas price
// 3) Deploy
// 4) Verify
// Whitelist: 0xfe0df05E19F44A433A40DEc048aaA1C8556A8554, 0x336e9F826aEFF7582c27102EA04479f675842331, 0xD4bf7337F9EfddFc2E069145455a9d60560A7B97, 0xf6F8Ded08692de28Cd0a164D1B8E0CbE70708B32, 0x43C7B6312A0BcA4B37d452bcC4Bd52Cc750262a4 , 0x83D23116a722B4a4335F90DbB00eA863d16932cA, 0x6Fe2F6884Da0C1Ce36089014BAa32148F087C519, 0x2eA4760750EbB54c6f40F583Bd635A9E7b437eEb

contract  Bets {
    
    address owner;
    address public constant pool_address = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; // Mainnet
    //address public constant pool_address = 0xfAe941346Ac34908b8D7d000f86056A18049146E; // Testnet

    uint256 public ticket_price = 50000000000000000; // 0.05 ETH
    bool    public closed    = false;
    uint256 public bets_up   = 0;
    uint256 public bets_down = 0;
    uint160 public initial_sqrt_price = 0;
    uint160 public final_sqrt_price   = 0;
    uint256 public outcome   = 0;
    uint256 public winners   = 0;
    uint256 public prize     = 0;
    uint256 public claimed   = 0;
    mapping (address => uint) public bets;
    mapping (address => bool) public whitelist;
    

    constructor() {
        owner = msg.sender;
    }

    // Whitelist

        function add_to_whitelist(address[] memory wallets) public {
            require(msg.sender==owner, "Only the owner can do this");
            for (uint i=0; i<wallets.length; i++){
                whitelist[wallets[i]] = true;
            }
        }

    // Phase 1 - Place your bets

        // +1 = betting ETH down, +2 = betting ETH up
        function place_bet(uint direction) public payable {
            
            require(closed==false,                     "Betting is closed");
            require(whitelist[msg.sender] == true,     "You are not in the whitelist");
            require(bets[msg.sender] == 0,             "You can bet only once");
            require(msg.value == ticket_price,         "The price of a ticket is 0.05 ETH");
            require(direction == 1 || direction == 2,  "Bet direction can be only 1 (down) or 2 (up)");

            bets[msg.sender] = direction;
            if (direction==2) { bets_up   +=1; } 
            else              { bets_down +=1; }
        }


    // Phase 2 and 3

        function get_current_price_from_uniswap() public view returns(uint160) {
            (uint160 sqrtPriceX96,  ,  ,  ,  ,  ,  ) = IUniswapV3Pool(pool_address).slot0();
            return sqrtPriceX96;
        }

        function get_initial_price_from_uniswap() internal {
            initial_sqrt_price = get_current_price_from_uniswap();
        }

        function get_final_price_from_uniswap() internal {
            final_sqrt_price = get_current_price_from_uniswap();
        }

        function close_betting() public {
            require(msg.sender==owner, "Only the owner can do this");
            require(closed==false,     "Betting already closed");

            closed = true;
            get_initial_price_from_uniswap();
        }    

        function resolve_bets() public {
            require(msg.sender==owner, "Only the owner can do this");

            get_final_price_from_uniswap();

            if (final_sqrt_price < initial_sqrt_price) {        // ETH price UP
                outcome = 2;
                winners = bets_up;
            } else if (final_sqrt_price > initial_sqrt_price) { // ETH price DOWN
                outcome = 1;
                winners = bets_down;
            } else {                                  // ETH price did not move
                outcome = 3;
                winners = bets_up + bets_down;
            }

            prize = address(this).balance / winners;

        }

    // Phase 4

        function claim_prize() public {
            require(outcome>0,                 "Bets not resolved yet");
            require(bets[msg.sender]==outcome, "You didn't win any prize");

            send_prize(msg.sender);
        }

        function claim_reimburse() public {
            require(outcome>0,          "Bets not resolved yet");
            require(outcome==3,         "Sorry, no reimbuirsement");
            require(bets[msg.sender]>0, "You are not entitled for a reimburse");             

            send_prize(msg.sender);
        }

        function send_prize(address to) internal {
            bets[to] = 0;
            claimed += 1;
            if (claimed < winners){ payable(to).transfer(prize);
            } else                { payable(to).transfer(address(this).balance); }   
        }

    
}