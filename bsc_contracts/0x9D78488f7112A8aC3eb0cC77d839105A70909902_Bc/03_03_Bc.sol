pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Bc is Ownable {
    event Bet(address indexed from, uint256 indexed id, uint256 _value);

    struct Match {
        bool isActive;
        uint256 price;
        uint256 endAt;
        uint256 royalties;
    }

    struct MatchData {
        uint256 pricePool;
        uint256 inA;
        uint256 inB;
        uint256 inEquality;
    }

    enum ResultMatchh {
        isA,
        isB,
        isEquality
    }

    mapping(uint256 => Match) public matchId;
    mapping(uint256 => ResultMatchh) public idResult;
    mapping(uint256 => MatchData) public idData;

    mapping(uint256 => mapping(address => uint256)) public idAddressNbrbet;
    mapping(uint256 => mapping(address => mapping(uint256 => ResultMatchh)))
        public idAddressBetResult;

    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public idAddressBetLeverage;

    mapping(uint256 => mapping(address => mapping(uint256 => bool)))
        public idAddressBetIsClaim;

    mapping(address => bool) public addressCanFreeBet;

    constructor() {}

    function bet(
        uint256 _id,
        uint256 _leverage,
        ResultMatchh _resultMatch
    ) public payable {
        Match memory _match = matchId[_id];
        require(_leverage > 0, "wrong leverage");
        require(_match.isActive, "not active");
        require(_match.endAt > block.timestamp, "out time");
        require(_match.price * _leverage == msg.value, "wrong value");

        uint256 _betId = idAddressNbrbet[_id][msg.sender];
        idAddressBetResult[_id][msg.sender][_betId] = _resultMatch;

        if (_resultMatch == ResultMatchh.isA) {
            idData[_id].inA += _leverage;
        } else if (_resultMatch == ResultMatchh.isB) {
            idData[_id].inB += _leverage;
        } else if (_resultMatch == ResultMatchh.isEquality) {
            idData[_id].inEquality += _leverage;
        }

        uint256 royalties = (msg.value * _match.royalties) / 100;
        payable(owner()).transfer(royalties);
        emit Bet(msg.sender, _id, msg.value);

        idData[_id].pricePool += msg.value - royalties;
        idAddressBetLeverage[_id][msg.sender][_betId] += _leverage;

        idAddressNbrbet[_id][msg.sender]++;
    }

    function claim(uint256 _id, uint256 _betId) public {
        require(
            idAddressBetLeverage[_id][msg.sender][_betId] > 0,
            "never participate"
        );
        require(!idAddressBetIsClaim[_id][msg.sender][_betId], "already claim");
        require(matchId[_id].endAt < block.timestamp, "out time");
        ResultMatchh _resultM = idResult[_id];
        require(
            idAddressBetResult[_id][msg.sender][_betId] == idResult[_id],
            "not eligible"
        );

        MatchData memory _data = idData[_id];
        uint256 place;
        if (_resultM == ResultMatchh.isA) {
            place = _data.pricePool / _data.inA;
        } else if (_resultM == ResultMatchh.isB) {
            place = _data.pricePool / _data.inB;
        } else if (_resultM == ResultMatchh.isEquality) {
            place = _data.pricePool / _data.inEquality;
        }

        idAddressBetIsClaim[_id][msg.sender][_betId] = true;
        uint256 gain = place * idAddressBetLeverage[_id][msg.sender][_betId];
        payable(msg.sender).transfer(gain);
    }

    function freeBet(uint256 _id, ResultMatchh _resultMatch) public {
        require(addressCanFreeBet[msg.sender], "cant freebet");

        Match memory _match = matchId[_id];

        require(_match.isActive, "not active");
        require(_match.endAt > block.timestamp, "out time");

        uint256 _betId = idAddressNbrbet[_id][msg.sender];
        idAddressBetResult[_id][msg.sender][_betId] = _resultMatch;

        addressCanFreeBet[msg.sender] = false;
        if (_resultMatch == ResultMatchh.isA) {
            idData[_id].inA++;
        } else if (_resultMatch == ResultMatchh.isB) {
            idData[_id].inB++;
        } else if (_resultMatch == ResultMatchh.isEquality) {
            idData[_id].inEquality++;
        }

        idAddressBetLeverage[_id][msg.sender][_betId]++;
        idAddressNbrbet[_id][msg.sender]++;

        emit Bet(msg.sender, _id, 0);
    }

    function setMatch(
        uint256 _id,
        bool _isActive,
        uint256 _price,
        uint256 _endAt,
        uint256 _royalties
    ) public onlyOwner {
        matchId[_id] = Match(_isActive, _price, _endAt, _royalties);
    }

    function setResult(uint256 _id, ResultMatchh _resultMatch)
        public
        onlyOwner
    {
        idResult[_id] = _resultMatch;
    }

    function setFreeBet(address _bettor, bool _canFB) public onlyOwner {
        addressCanFreeBet[_bettor] = _canFB;
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}