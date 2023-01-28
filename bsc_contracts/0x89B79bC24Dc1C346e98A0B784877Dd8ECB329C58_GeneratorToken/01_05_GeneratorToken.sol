pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GeneratorToken is ERC20 {

    struct HistoryItem {
        uint256 amount;
        uint256 timestamp;
        uint256 historyType;
    }

    uint256 constant public TOTAL_SUPPLY = 10_000_000 * 1e18;
    uint256 MIN_AMOUNT = 20000000 gwei;
    uint256 MAX_AMOUNT = 1000 ether;
    
    address payable public generator;

    uint256 public genSold;

    mapping(address => HistoryItem[]) history;

    modifier onlyContract() {
        require(msg.sender == generator, "Only generator address");
        _;
    }

    constructor(address payable _generator) ERC20("GeneratorToken", "GEN") {
        generator = _generator;
        _mint(address(this), TOTAL_SUPPLY);
    }

    function buyGen() external payable {
        require(msg.value + genSold <= TOTAL_SUPPLY, "Max supply was exceed");
        require(msg.value >= MIN_AMOUNT && msg.value <= MAX_AMOUNT, "Amount too small or big");
        
        genSold += msg.value;

        history[msg.sender].push(HistoryItem({
            amount: msg.value,
            timestamp: block.timestamp,
            historyType: 0
        }));

        _transfer(address(this), msg.sender, msg.value);
        sendValue(generator, msg.value);
    }

    function approveToken(address _from, address _to, uint256 _amount) external onlyContract {
        require(balanceOf(_from) >= _amount, "Insufficient balance");
        _approve(_from, _to, _amount);
    }

    function burnToken(address _from, uint256 _amount) external onlyContract {
        _burn(_from, _amount);
    }

    function sendRefBonus(address _user, uint256 _amount) external onlyContract {
        _transfer(address(this), _user, _amount);
    }

    function getHistory(address _user) external view returns(HistoryItem[] memory) {
        return history[_user];
    }

    function sendValue(address payable _recipient, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Address: insufficient balance");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}