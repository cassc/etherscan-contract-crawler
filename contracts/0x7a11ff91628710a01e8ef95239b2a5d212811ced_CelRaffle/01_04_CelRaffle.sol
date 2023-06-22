pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IHH {
    function collectFromGateway(uint256 _id, address _owner) external;
}

interface IDR {
    function getPoints(address _owner) external view returns (uint256);
}

contract CelRaffle is Ownable {
    using SafeMath for uint256;
    IHH private HH;
    IDR private DR;

    uint256 public price = 690000000000000000;
    uint256 public mintCounter = 20001;
    uint256 public supply = 6;
    uint256 public minted;
    bool public opened;
    uint256 public mintPhase;
    address[] public players;
    address[] public winners;
    uint256 private randId = 0;
    uint256 public endTime;
    bool public completed;

    function mint() external payable {
        require(getPhase() != 0, "Not opened.");
        require(DR.getPoints(msg.sender) > 1, "Need more steaks!");
        require(msg.value >= price, "Eth too low");
        require(mintCounter < 20007, "Sold out!");
        if (getPhase() == 1) {
            require(!_contains(players, msg.sender),"Already in!");
            require(!completed, "Raffle Eneded. Wait for public mint.");
            players.push(msg.sender);
            if(minted<supply){
                minted++;
            }
        } else if (getPhase() == 2) {
            require(minted<supply, "Sold out!");
            HH.collectFromGateway(mintCounter, msg.sender);
            mintCounter++;
            minted++;
        }
    }

    function raffle(uint256 _size) public onlyOwner {
        require(players.length >= _size, "Not enough players.");

        uint256[] memory selectedIndexes = new uint256[](_size);
        uint256 found = 0;

        while (found < _size) {
            uint256 selectedIndex = _chooseRand(players.length);
            bool alreadySelected = false;
            for (uint256 i = 0; i < found; i++) {
                if (selectedIndexes[i] == selectedIndex) {
                    alreadySelected = true;
                    break;
                }
            }

            if (!alreadySelected) {
                selectedIndexes[found] = selectedIndex;
                found++;
            }
        }
        for (uint256 i = 0; i < _size; i++) {
            winners.push(players[selectedIndexes[i]]);
        }
        for (uint256 i = 0; i < players.length; i++) {
            if (_contains(winners, players[i])) {
                HH.collectFromGateway(mintCounter, players[i]);
                mintCounter++;
            } else {
                require(payable(players[i]).send(price));
            }
        }

         uint256 luckyMinter = _chooseRand(players.length);
         require(payable(players[luckyMinter]).send(price));

        completed=true;
    }

    function _chooseRand(uint256 size) private returns (uint256) {
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.difficulty, randId)
            )
        );
        randId++;
        return rand % size;
    }

    function _contains(address[] memory _arr, address _try) internal pure returns (bool) {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _try) {
                return true;
            }
        }
        return false;
    }


    function getPhase() public view returns (uint256) {
        if (!opened) return 0;
        return block.timestamp < endTime ? 1 : 2;
    }

    function getPlayers() external view returns (address[] memory){
        return players;
    }

    function getWinners() external view returns (address[] memory){
        return winners;
    }

    function soldOut() external view returns(bool){
        return mintCounter >= 20007;
    }

    function setData(
        address _hhGallery,
        address _deathrow
    ) external onlyOwner {
        HH = IHH(_hhGallery);
        DR = IDR(_deathrow);
    }

    function setOpened(bool _flag) external onlyOwner {
        opened = _flag;
    }

    function setEnd(uint256 _endTime) external onlyOwner{
        endTime = _endTime;
    }

    function withdraw() external onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }
}