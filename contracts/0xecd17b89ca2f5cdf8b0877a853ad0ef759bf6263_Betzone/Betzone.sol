/**
 *Submitted for verification at Etherscan.io on 2023-08-14
*/

// SPDX-Licence-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Betzone {
    address public _owner = 0x866811B5D54ba17B04eE095de26b2E0c0F79d529; // change owner
    address public _baseToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7; /// chang this

    struct Bet {
        bool paid;
        address customer;
        uint256 amount;
        uint256[] selectedNumbers;
    }

    struct Bet_Details {
        mapping(uint256 => Bet) bets;
        uint256 length;
    }

    uint256 public __jackpot_odd = 40;
    uint256 public __number_odd = 30;
    uint256 public __high_low_odd = 1;
    uint256 public __odd_even_odd = 1;
    uint256 public __blocks_odd = 2;

    mapping(uint256 => Bet_Details) public bets;

    function __changeOwner(address newOwner) public {
        require(
            msg.sender == _owner,
            "Only owner can change the contract owner."
        );
        _owner = newOwner;
    }

    event betList(
        uint256 indexed draw,
        string indexed gametype,
        address indexed winner,
        uint256 payout,
        uint256 odd,
        uint256 win
    );

    function __setOdds(
        uint256 _jackpot,
        uint256 _number,
        uint256 _highLow,
        uint256 _oddEven,
        uint256 _blocks
    ) public {
        require(msg.sender == _owner, "Only owner can set odds.");
        __jackpot_odd = _jackpot;
        __number_odd = _number;
        __high_low_odd = _highLow;
        __odd_even_odd = _oddEven;
        __blocks_odd = _blocks;
    }

    function __getGameType(
        uint256[] memory selectedNumbers
    ) public pure returns (string memory) {
        string memory gameType = "number";

        if (selectedNumbers.length == 1 && selectedNumbers[0] == 0) {
            gameType = "jackpot";
        }

        uint256 highCount = 0;
        for (uint256 i = 0; i < selectedNumbers.length; i++) {
            for (uint256 j = 1; j <= 19; j++) {
                if (selectedNumbers[i] == j) {
                    highCount++;
                    break;
                }
            }
        }
        if (highCount == selectedNumbers.length) {
            gameType = "high_low";
        }

        uint256 lowCount = 0;
        for (uint256 i = 0; i < selectedNumbers.length; i++) {
            for (uint256 j = 20; j <= 38; j++) {
                if (selectedNumbers[i] == j) {
                    lowCount++;
                    break;
                }
            }
        }
        if (lowCount == selectedNumbers.length) {
            gameType = "high_low";
        }

        uint256 oddCount = 0;
        for (uint256 i = 0; i < selectedNumbers.length; i++) {
            for (uint256 j = 1; j <= 38; j++) {
                if (j % 2 != 0) {
                    if (selectedNumbers[i] == j) {
                        oddCount++;
                        break;
                    }
                }
            }
        }
        if (oddCount == selectedNumbers.length) {
            gameType = "odd_even";
        }

        uint256 evenCount = 0;
        for (uint256 i = 0; i < selectedNumbers.length; i++) {
            for (uint256 j = 1; j <= 38; j++) {
                if (j % 2 == 0) {
                    if (selectedNumbers[i] == j) {
                        evenCount++;
                        break;
                    }
                }
            }
        }
        if (evenCount == selectedNumbers.length) {
            gameType = "odd_even";
        }

        uint256 onesCount = 0;
        for (uint256 i = 0; i < selectedNumbers.length; i++) {
            for (uint256 j = 1; j <= 9; j++) {
                if (selectedNumbers[i] == j) {
                    onesCount++;
                    break;
                }
            }
        }
        if (onesCount == selectedNumbers.length) {
            gameType = "blocks";
        }

        uint256 tensCount = 0;
        for (uint256 i = 0; i < selectedNumbers.length; i++) {
            for (uint256 j = 10; j <= 19; j++) {
                if (selectedNumbers[i] == j) {
                    tensCount++;
                    break;
                }
            }
        }
        if (tensCount == selectedNumbers.length) {
            gameType = "blocks";
        }

        uint256 twentiesCount = 0;
        for (uint256 i = 0; i < selectedNumbers.length; i++) {
            for (uint256 j = 20; j <= 29; j++) {
                if (selectedNumbers[i] == j) {
                    twentiesCount++;
                    break;
                }
            }
        }
        if (twentiesCount == selectedNumbers.length) {
            gameType = "blocks";
        }

        uint256 thirtiesCount = 0;
        for (uint256 i = 0; i < selectedNumbers.length; i++) {
            for (uint256 j = 30; j <= 38; j++) {
                if (selectedNumbers[i] == j) {
                    thirtiesCount++;
                    break;
                }
            }
        }
        if (thirtiesCount == selectedNumbers.length) {
            gameType = "blocks";
        }

        return gameType;
    }

    function __bet(
        uint256 draw,
        uint256 betAmount,
        uint256[] memory selectedNumbers
    ) external {
        require(
            betAmount > 0,
            "The bet must be greater than the minimum value."
        );

        uint256 subTotal = betAmount * selectedNumbers.length;
        uint256 index = bets[draw].length;

        bets[draw].bets[index].customer = msg.sender;
        bets[draw].bets[index].amount = subTotal;
        bets[draw].bets[index].selectedNumbers = selectedNumbers;
        bets[draw].length += 1;

        IBEP20(_baseToken).transferFrom(msg.sender, address(this), subTotal);
    }

    function __payOut(uint256 winningNumber, uint256 draw) public payable {
        require(
            msg.sender == _owner,
            "Only the owner has the ability to pay out."
        );
        uint256 index = bets[draw].length;

        for (uint256 i = 0; i < index + 1; i++) {
            Bet memory bet = bets[draw].bets[i];
            require(bet.paid == false, "There are no bets.");
            string memory gameType = __getGameType(bet.selectedNumbers);
            uint256 odd = __number_odd;
            uint256 pay = 0;
            uint256 winning = 0;

            for (uint256 j = 0; j < bet.selectedNumbers.length; j++) {
                if (bet.selectedNumbers[j] == winningNumber) {
                    if (
                        keccak256(abi.encodePacked(gameType)) ==
                        keccak256(abi.encodePacked("jackpot"))
                    ) {
                        odd = __jackpot_odd;
                    }
                    if (
                        keccak256(abi.encodePacked(gameType)) ==
                        keccak256(abi.encodePacked("high_low"))
                    ) {
                        odd = __high_low_odd;
                    }
                    if (
                        keccak256(abi.encodePacked(gameType)) ==
                        keccak256(abi.encodePacked("odd_even"))
                    ) {
                        odd = __odd_even_odd;
                    }
                    if (
                        keccak256(abi.encodePacked(gameType)) ==
                        keccak256(abi.encodePacked("blocks"))
                    ) {
                        odd = __blocks_odd;
                    }

                    uint256 win = bet.amount * odd;
                    uint256 subTotal = bet.amount * bet.selectedNumbers.length;
                    uint256 payOut = subTotal + win;

                    pay += payOut;
                    winning += win;
                }
            }
            bet.paid = true;

            if (pay > 0) {
                IBEP20(_baseToken).transfer(address(bet.customer), pay);
            }

            emit betList(
                draw,
                gameType,
                address(bet.customer),
                pay,
                odd,
                winning
            ); // index
        }
    }

    function __getOwnerBalance() public view returns (uint256) {
        return IBEP20(_baseToken).balanceOf(address(this));
    }

    function __withdraw(address payable destinationAddress) public {
        require(
            msg.sender == _owner,
            "Only the owner has the ability to withdraw funds."
        );
        uint256 balance = address(this).balance;
        destinationAddress.transfer(balance);
    }

    function _setBaseToken(address token) public {
        require(
            msg.sender == _owner,
            "Only the owner has the ability to set base token."
        );

        _baseToken = token;
    }

    function __withdraw(address destinationAddress, address Token) public {
        require(
            msg.sender == _owner,
            "Only the owner has the ability to withdraw funds."
        );
        uint256 balance = IBEP20(Token).balanceOf(address(this));
        IBEP20(Token).transfer(destinationAddress, balance);
    }
}