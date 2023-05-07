// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface AggregatorV3Interface {
    
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PresaleContract is Ownable {

    IERC20Metadata constant private usdt_interface = IERC20Metadata(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20Metadata constant private usdc_interface = IERC20Metadata(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20Metadata constant private token_interface = IERC20Metadata(0xD61b54ED1a7d4522810d9c5D694B06b52dC4F4B5);
    AggregatorV3Interface private price_feed;

    mapping(address => User) public users_list;
    Round[] public round_list;

    uint8 public current_round_index;
    bool public presale_ended;

  struct User {
        //tokens collected
        uint256 tokens_amount;
        //amount of usdt deposited
        uint256 usdt_deposited;
        //claimed or not
        bool has_claimed;
    }

    struct Round {
        //address for withdrawal
        address payable wallet;
        //no. of tokens you can buy with usdt
        uint256 usdt_to_token_rate;
        //usdt + eth in usdt
        uint256 usdt_round_raised;
        //usdt + eth in usdt
        uint256 usdt_round_cap;
    }
 event Deposit(address indexed _user_wallet, uint indexed _pay_method, uint _user_usdt_trans, uint _user_tokens_trans);
constructor(
        address oracle_, 
        address payable wallet_,
        uint256 usdt_to_token_rate_,
        uint256 usdt_round_cap_
    ) {
        price_feed = AggregatorV3Interface(oracle_);
        current_round_index = 0;
        presale_ended = false;
        round_list.push(
            Round(wallet_, usdt_to_token_rate_, 0, usdt_round_cap_ * (10**6))
        );
    }

modifier canPurchase(uint256 amount) {
        require(amount > 0, "null amount");
        require(presale_ended == false, "Presale ended");
        _;
    }

      function get_eth_in_usdt() internal view returns (uint256) { 
        (, int256 price, , , ) = price_feed.latestRoundData();
        price = price * 1e10;
        return uint256(price);
    }

        function buy_with_usdt(uint256 amount_) external canPurchase( amount_) returns (bool) { 

        uint256 amount_in_usdt = amount_;

        require(round_list[current_round_index].usdt_round_raised + amount_in_usdt < round_list[current_round_index].usdt_round_cap,
            "max deposited"
        );

        uint256 allowance = usdt_interface.allowance(msg.sender, address(this));

        require(amount_ <= allowance, "Insufficient Allowance");

        (bool success_receive, ) = address(usdt_interface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                round_list[current_round_index].wallet,
                amount_in_usdt
            )
        );

        require(success_receive, "Tx Failed");

        uint256 amount_in_tokens = (amount_in_usdt * round_list[current_round_index].usdt_to_token_rate) * (10 ** token_interface.decimals()) / (10 ** usdt_interface.decimals());

        users_list[_msgSender()].usdt_deposited += amount_in_usdt;
        users_list[_msgSender()].tokens_amount += amount_in_tokens;

        round_list[current_round_index].usdt_round_raised += amount_in_usdt;

         emit Deposit(_msgSender(), 3, amount_in_usdt, amount_in_tokens);
        return true;
    }

  function buy_with_usdc(uint256 amount_) external canPurchase(amount_) returns (bool) { 
        uint256 amount_in_usdt = amount_;
        require(round_list[current_round_index].usdt_round_raised + amount_in_usdt < round_list[current_round_index].usdt_round_cap,
            "Max Deposited"
        );

        uint256 allowance = usdc_interface.allowance(msg.sender, address(this));

        require(amount_ <= allowance, "Insufficient Allowance");

        (bool success_receive, ) = address(usdc_interface).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                round_list[current_round_index].wallet,
                amount_in_usdt
            )
        );

        require(success_receive, "Tx Failed");

        uint256 amount_in_tokens = (amount_in_usdt * round_list[current_round_index].usdt_to_token_rate) * (10 ** token_interface.decimals()) / (10 ** usdc_interface.decimals());

        users_list[_msgSender()].usdt_deposited += amount_in_usdt;
        users_list[_msgSender()].tokens_amount += amount_in_tokens;

        round_list[current_round_index].usdt_round_raised += amount_in_usdt;

         emit Deposit(_msgSender(), 3, amount_in_usdt, amount_in_tokens);

        return true;
    }
        function buy_with_eth() external payable canPurchase( msg.value) returns (bool) { 

        uint256 amount_in_usdt = (msg.value * get_eth_in_usdt()) / 1e30;
        require(round_list[current_round_index].usdt_round_raised + amount_in_usdt < round_list[current_round_index].usdt_round_cap,
            "Max Deposited"
        );

        uint256 amount_in_tokens = (amount_in_usdt * round_list[current_round_index].usdt_to_token_rate) * (10 ** token_interface.decimals()) / (10 ** usdt_interface.decimals());

        users_list[_msgSender()].usdt_deposited += amount_in_usdt;
        users_list[_msgSender()].tokens_amount += amount_in_tokens;

        round_list[current_round_index].usdt_round_raised += amount_in_usdt;

        (bool sent,) = round_list[current_round_index].wallet.call{value: msg.value}("");
        require(sent, "Tx Failed");

        emit Deposit(_msgSender(), 1, amount_in_usdt, amount_in_tokens);
        return true;
    }
     
     function buy_with_eth_wert(address user) external payable canPurchase(msg.value) returns (bool) { 

        uint256 amount_in_usdt = (msg.value * get_eth_in_usdt()) / 1e30;
        require( round_list[current_round_index].usdt_round_raised + amount_in_usdt < round_list[current_round_index].usdt_round_cap,
            "Max Deposited"
        );

        uint256 amount_in_tokens = (amount_in_usdt * round_list[current_round_index].usdt_to_token_rate) * (10 ** token_interface.decimals()) / (10 ** usdt_interface.decimals());

        users_list[user].usdt_deposited += amount_in_usdt;
        users_list[user].tokens_amount += amount_in_tokens;

        round_list[current_round_index].usdt_round_raised += amount_in_usdt;

        (bool sent,) = round_list[current_round_index].wallet.call{value: msg.value}("");
        require(sent, "Tx Failed");

         emit Deposit(user, 2, amount_in_usdt, amount_in_tokens);

        return true;
    }
         function claim_tokens() external returns (bool) {  
        require(presale_ended, "Presale not ended");
        require(users_list[_msgSender()].tokens_amount != 0, "Already claimed");
        require(!users_list[_msgSender()].has_claimed, "Already claimed");

        uint256 tokens_to_claim = users_list[_msgSender()].tokens_amount;
        users_list[_msgSender()].tokens_amount = 0;
        users_list[_msgSender()].has_claimed = true;

        (bool success, ) = address(token_interface).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                tokens_to_claim
            )
        );
        require(success, "");

        return true;
    }

    function start_next_round(address payable wallet_, uint256 usdt_to_token_rate_, uint256 usdt_round_cap_) external onlyOwner { 
        current_round_index = current_round_index + 1;

        round_list.push(
            Round(wallet_, usdt_to_token_rate_, 0, usdt_round_cap_ * (10**6))
        );
    }
    
     function set_current_round(address payable wallet_, uint256 usdt_to_token_rate_, uint256 usdt_round_cap_) external onlyOwner { 
        round_list[current_round_index].wallet = wallet_;
        round_list[current_round_index].usdt_to_token_rate = usdt_to_token_rate_;
        round_list[current_round_index].usdt_round_cap = usdt_round_cap_ * (10**6);
    }

     function get_current_round() external view returns (address, uint256, uint256, uint256){ 
        return (
             round_list[current_round_index].wallet,
            round_list[current_round_index].usdt_to_token_rate,
            round_list[current_round_index].usdt_round_raised,
            round_list[current_round_index].usdt_round_cap
             
        );
    }

     function get_current_raised() external view returns (uint256) { 
        return round_list[current_round_index].usdt_round_raised;
    }
    
     function end_presale() external onlyOwner { 
        presale_ended = true;
    }

      function withdrawToken(address tokenContract, uint256 amount) external onlyOwner { 
        (bool success, ) = address(tokenContract).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                amount
            )
        );
        require(success, "Tx Failed");
    }


}