/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';

interface IDRNKtoken {
    function mintDRNK(address to, uint amount) external;
}

/* Main Happy Hour Protocol v3 Engine Contract */

contract HappyHourProtocolv3 is ERC20, Ownable {

    uint happyHourFee = 1;
    uint happyHourFeePool;
    uint timeIN;
    uint timeOUT;
    uint hoursSpentDrinking;
    uint HOUR2DRNKburnMinimum = 2000 * (10 ** 18);
    uint PDEcommissionRate = 10;
    uint HOURperhour = 100;

    event endHOURresults(uint hoursSpentDrinking, uint HOURearned, uint PDEcommissionEarned, uint PDEindex);
    event newPDEonboarded(string _name, string _location, address _address, uint _PDEid, uint PDEindexNum, uint accessCode);
    event newDRNKminted(uint HOURburned, uint DRNKminted);

    address public _admin;

    struct PDE {
        string _name;
        string _location;
        address _address;
        uint _accessCode;
        uint _PDEid;
    }

    PDE[] public pdes;

    mapping (uint => address) public PDEtoOwner;
    mapping (uint => uint) public drinkingIDtoPDEid;

    /* Initializing the HappyHourProtocolv3 contract */

    constructor() ERC20('Happy Hour Token v3', 'HOUR') {
        _mint(msg.sender, 1 * (10 ** 18));
        _admin = msg.sender;
    }

    /* Public onboarding function for PDE. Name, Location, ETH address, and a temporary Access Code are required. */

    function onboardPDE(string memory _name, string memory _location, address _address, uint _accessCode) public {
        uint PDEid = uint(keccak256(abi.encodePacked(_name, _location, _address)));
        pdes.push(PDE(_name, _location, _address, _accessCode, PDEid));
        uint PDEindexNum = pdes.length - 1;
        PDEtoOwner[PDEindexNum] = msg.sender;
        emit newPDEonboarded(_name, _location, _address, PDEid, PDEindexNum, _accessCode);
    }

    function totalPDE() public view returns (uint) {
        return pdes.length;
    }

    /* Enables PDEs to change their Access Code anytime */

    function _changeAccessCode(uint _PDEindexNum, uint _newAccessCode) public {
        require(PDEtoOwner[_PDEindexNum] == msg.sender);
        pdes[_PDEindexNum]._accessCode = _newAccessCode;
    }

    /* Contract owner may adjust HOUR burn minimum */

    function setHOUR2DRNKburnMinimum(uint _burnMinimum) external onlyOwner {
        HOUR2DRNKburnMinimum = _burnMinimum * (10 ** 18);
    }

    /* $DRNK mint function. Requires inputting DRNK governance token contract, ETH address, and a minimum $HOUR to burn. */

    function mintyDRNK(address _DRNKaddress, address to, uint _burnAmount) public {
        require((_burnAmount * (10 ** 18)) >= HOUR2DRNKburnMinimum, "Insufficient amount of HOUR tokens to burn.");
        uint DRNKneeded2mint = (_burnAmount * (10 ** 18)) / 10;
        burnHOUR(_burnAmount);
        IDRNKtoken(_DRNKaddress).mintDRNK(to, DRNKneeded2mint);
        emit newDRNKminted(_burnAmount, DRNKneeded2mint);
    }

    /* mintHOUR and burnHOUR functions will not be public */

    function mintHOUR(address to, uint amount) external onlyOwner {
        _mint(to, amount * (10 ** 18));
    }

    function burnHOUR(uint amount) internal {
        _burn(msg.sender, amount * (10 ** 18));
    }

    /* Drinkers need to stake a minimum happy hour fee in order to start earning $HOUR. Minimum happy hour fee may be adjusted. */

    function setHappyHourFee(uint _fee) external onlyOwner {
        happyHourFee = _fee;
    }

    /* Each Drinker is designated an ID in order to keep track of current hours accumulated per Drinker during 1 session. */

    mapping(address => uint256) public drinkingID;
    uint256 drinkingIDcounter;

    event createdDrinkingID(address user, uint256 id);

    function givePoolDrinkingId() internal returns (uint256)  { 
        require(drinkingID[msg.sender]==0, "You are already drinking.");
        drinkingIDcounter += 1;
        drinkingID[msg.sender] = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        emit createdDrinkingID(msg.sender,drinkingID[msg.sender]);
        return drinkingID[msg.sender];
    }

    function nullPoolDrinkingId() internal {
        require(drinkingID[msg.sender] != 0, "You haven't started drinking yet.");
        drinkingIDcounter -= 1;
        drinkingID[msg.sender] = 0;
    }

    function getPoolDrinkingId() public view returns(uint256) {
        return drinkingID[msg.sender];
    }

    function getNumberOfCurrentDrinkers() public view returns(uint) {
        return drinkingIDcounter;
    }

    /* Start earning $HOUR function. Requires a minimum happy hour fee stake, the PDE's PDEid and its Access Code. */

    function startHOUR(uint _PDEid, uint _accessCode) public payable {

        bool validPDE = false;

        for (uint i = 0; i < pdes.length; i++) {
            if (pdes[i]._PDEid == _PDEid && pdes[i]._accessCode == _accessCode) {
                validPDE = true;
            }
        }

        require(validPDE == true);
        require(msg.value == happyHourFee * (10 ** 16), "Invalid Happy Hour Fee.");
        givePoolDrinkingId();
        drinkingIDtoPDEid[drinkingID[msg.sender]] = _PDEid;
        happyHourFeePool += 1;
        timeIN = block.timestamp;
    }

    /* Getter function to view ETH amount staked in current happy hour fee pool. */

    function gethappyHourFeePool() public view returns (uint) {
        return happyHourFeePool;
    }

    /* Function to stop earning $HOUR */

    function endHOUR(address payable wiped) public {

        uint PDEindex;
        address PDEcommission;
        require(msg.sender == wiped);
        timeOUT = block.timestamp;
        hoursSpentDrinking = (timeOUT - timeIN) / 60 / 60;

        for (uint i = 0; i < pdes.length; i++) {
            if (pdes[i]._PDEid == drinkingIDtoPDEid[drinkingID[msg.sender]]) {
                PDEcommission = pdes[i]._address;
                PDEindex = i;
            }
        }

        if (hoursSpentDrinking < 8) {
            nullPoolDrinkingId();
            happyHourFeePool -= 1;
            wiped.transfer(happyHourFee * (10 ** 16));
            uint HOURearned = hoursSpentDrinking * (HOURperhour * (10 ** 18));
            uint PDEcommissionEarned = HOURearned / PDEcommissionRate;
            _mint(wiped, HOURearned);
            _mint(PDEcommission, PDEcommissionEarned);
            emit endHOURresults(hoursSpentDrinking, HOURearned, PDEcommissionEarned, PDEindex);
        } else {
            nullPoolDrinkingId();
            happyHourFeePool -= 1;
            wiped.transfer(happyHourFee * (10 ** 16));
            uint PDEcommissionEarned = (HOURperhour * (10 ** 18)) / PDEcommissionRate;
            uint penalHOURearned = HOURperhour * (10 ** 18);
            _mint(wiped, penalHOURearned);
            _mint(PDEcommission, PDEcommissionEarned);
            emit endHOURresults(hoursSpentDrinking, penalHOURearned, PDEcommissionEarned, PDEindex);
        }

        
    }

    /* Adjustable earned $HOUR/hour rate */

    function adjustHOURperhourRate(uint _newRate) external onlyOwner {
        HOURperhour = _newRate;
    }

    receive() external payable {}

}