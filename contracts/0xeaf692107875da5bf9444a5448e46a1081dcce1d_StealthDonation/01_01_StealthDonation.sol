/*
 * The stealth donation event is open and available to all but will not be marketed or advertised beyond 
 * the public deployment of this contract. Donated funds will be used primarily for audits pre-launch. 
 * Check proofofluck.io and https://twitter.com/proof_of_luck for details.
 * 
 * 
 *  /$$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$$$        /$$$$$$  /$$$$$$$$       /$$       /$$   /$$  /$$$$$$  /$$   /$$
 * | $$__  $$| $$__  $$ /$$__  $$ /$$__  $$| $$_____/       /$$__  $$| $$_____/      | $$      | $$  | $$ /$$__  $$| $$  /$$/
 * | $$  \ $$| $$  \ $$| $$  \ $$| $$  \ $$| $$            | $$  \ $$| $$            | $$      | $$  | $$| $$  \__/| $$ /$$/ 
 * | $$$$$$$/| $$$$$$$/| $$  | $$| $$  | $$| $$$$$         | $$  | $$| $$$$$         | $$      | $$  | $$| $$      | $$$$$/  
 * | $$____/ | $$__  $$| $$  | $$| $$  | $$| $$__/         | $$  | $$| $$__/         | $$      | $$  | $$| $$      | $$  $$  
 * | $$      | $$  \ $$| $$  | $$| $$  | $$| $$            | $$  | $$| $$            | $$      | $$  | $$| $$    $$| $$\  $$ 
 * | $$      | $$  | $$|  $$$$$$/|  $$$$$$/| $$            |  $$$$$$/| $$            | $$$$$$$$|  $$$$$$/|  $$$$$$/| $$ \  $$
 * |__/      |__/  |__/ \______/  \______/ |__/             \______/ |__/            |________/ \______/  \______/ |__/  \__/                                                                                                                                                                                                                                              
 * 
 */



contract StealthDonation {


    bool public open = false;
    uint public constant HARD_CAP = 25 ether;
    uint public constant WALLET_CAP = 2 ether;

    uint public count = 0;
    uint public total = 0;

    address public devAddress = 0x0D1A91Efc9e6fD56095F5860eE7d8d46B9B30B88; /* prod address */

    mapping(address => uint) public donators;


    function openDonation() external {
        require(msg.sender == devAddress, "not the dev.");
        open = true;
    }

    /* funds are sent dev address, anything over wallet cap or hard cap is sent back */
    function donate() external payable {
        require(open, "donations not enabled yet.");
        require(total != HARD_CAP, "hard cap has been reached.");
        require(donators[msg.sender] != WALLET_CAP, "already donated the max.");

        uint amount = msg.value;

        if (donators[msg.sender] == 0) count++;

        if (donators[msg.sender] + amount > WALLET_CAP) {
            amount = WALLET_CAP - donators[msg.sender];
        }

        if (total + amount > HARD_CAP) {
            amount = HARD_CAP - total;
        }

        if (amount != msg.value) {
            uint returnAmount = msg.value - amount;
            (bool success1, ) = msg.sender.call{value: returnAmount}("");
            require(success1, "Transfer failed.");
        }
        
        donators[msg.sender] += amount;
        total += amount;
        (bool success2, ) = devAddress.call{value: amount}("");
        require(success2, "Transfer failed.");
    }



    /* in case someone sends funds directly to contract, all funds are sent to dev address for manual recovery */
    function withdraw() external {
        uint balance = address(this).balance;
        (bool success, ) = devAddress.call{value: balance}("");
        require(success, "Transfer failed.");

    }


    receive() external payable {}

}