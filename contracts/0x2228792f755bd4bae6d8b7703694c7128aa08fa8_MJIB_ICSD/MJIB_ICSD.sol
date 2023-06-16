/**
 *Submitted for verification at Etherscan.io on 2019-07-31
*/

pragma solidity =0.5.10;


contract MJIB_ICSD {

    address owner;

    struct Case {
        bytes32 hash;
        uint time;
        uint8 updateCount;
    }

    mapping (uint256 => Case) public caseList;

    mapping (address => uint8) public unitCodeList;

    constructor() public {
        owner = msg.sender;
    }

    function setUnitCode(address unitAddress, uint8 unitCode) public {
        require(msg.sender == owner, "Only contract owner is allow to set unit code");
        unitCodeList[unitAddress] = unitCode;
    }

    function createCase(uint64 caseID, bytes32 hash) public {
        require(unitCodeList[msg.sender] != 0, "Unit code not found");
        require(unitCodeList[msg.sender] < 100, "Invalid unit code");
        require(caseID > 1000000 && caseID < 10000000, "Invalid case ID");

        uint256 reportID;
        reportID = caseID * 10000;
        reportID += unitCodeList[msg.sender] * 100;
        if (caseList[reportID].hash == 0x0 && caseList[reportID].time == 0) {
            caseList[reportID].hash = hash;
            caseList[reportID].time = now;
        } else {
            require(caseList[reportID].updateCount < 100, "Update count limit reached");
            caseList[reportID].updateCount += 1;
            reportID += caseList[reportID].updateCount;
            caseList[reportID].hash = hash;
            caseList[reportID].time = now;
        }
    }

    function getCase(uint64 caseID, uint8 unitCode) public view returns (bytes32, uint) {
        require(caseID > 1000000 && caseID < 10000000, "Invalid case ID");
        require(unitCode < 100, "Invalid group code");
        uint256 reportID;
        reportID = caseID * 10000;
        reportID += unitCode * 100;
        reportID += caseList[reportID].updateCount;
        return (caseList[reportID].hash, caseList[reportID].time);
    }

}