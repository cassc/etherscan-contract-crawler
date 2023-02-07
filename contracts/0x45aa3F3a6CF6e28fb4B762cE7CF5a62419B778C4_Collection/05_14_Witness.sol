//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
WITNESS THE DRAFT.
 __        _____ _____ _   _ _____ ____ ____    _____ _   _ _____   ____  ____      _    _____ _____ 
 \ \      / /_ _|_   _| \ | | ____/ ___/ ___|  |_   _| | | | ____| |  _ \|  _ \    / \  |  ___|_   _|
  \ \ /\ / / | |  | | |  \| |  _| \___ \___ \    | | | |_| |  _|   | | | | |_) |  / _ \ | |_    | |  
   \ V  V /  | |  | | | |\  | |___ ___) |__) |   | | |  _  | |___  | |_| |  _ <  / ___ \|  _|   | |  
    \_/\_/  |___| |_| |_| \_|_____|____/____/    |_| |_| |_|_____| |____/|_| \_\/_/   \_\_|     |_|  
                                                                                                     
Performance art in writing a draft for the book, "Witnesses of Gridlock", the sequel to "Hope Runners of Gridlock".
Each day, the amount of words written + a snippet will be logged.
Thereafter, an NFT (or NFTs) will be created from this data that was logged over the course of 30 days.
Published through Untitled Frontier Labs (https://untitledfrontier.studio). 
By Simon de la Rouviere.
As part of #NaNoWriMo (National Novel Writing Month).

Start: 1667275200 Tue Nov 01 2022 00:00:00 GMT-0400 (Eastern Daylight Time)
End: 1669870800 Thu Dec 01 2022 00:00:00 GMT-0500 (Eastern Standard Time)
*/

/*
MODIFIED for testing purposes from original
*/

contract Witness {
    
    uint256 public start;
    uint256 public end;
    address public owner;
    string public tester;
    Day[] public dayss;

    struct Day {
        uint256 logged;
        string day;
        string wordCount;
        string words;
        string extra;
    }

    //constructor(address _owner, uint256 _start, uint256 _end) {
    constructor() {

        // witness in here. recreate it
        // [1667349683,1,4821,the edge of their known world, ]
        witness('1', '4821', 'the edge of their known world', ' ');
        // [1667433371,2,7807,her dream felt out of focus, ]
        witness('2', '7807', 'her dream felt out of focus', ' ');
        // [1667526563,3,9447,the truth matters, ]
        witness('3', '9447', 'the truth matters', ' ');
        // [1667613227,4,10859,if you did it again, ]
        witness('4', '10859', 'if you did it again', ' ');
        // [1667668607,5,12286,flickering and glitching, ]
        witness('5', '12286', 'flickering and glitching', ' ');
        // [1667783747,6,14109,the bandwidth in your dreams, ]
        witness('6', '14109', 'the bandwidth in your dreams', ' ');
        // [1667873795,7,14665,seemingly at random, ]
        witness('7', '14665', 'seemingly at random', ' ');
        // [1667964863,8,15742,trails shot through the thick glass, ]
        witness('8', '15742', 'trails shot through the thick glass', ' ');
        // [1668047303,9,17401,dating advice, ]
        witness('9', '17401', 'dating advice', ' ');
        // [1668134687,10,18801,marketplace of companions, ]
        witness('10', '18801', 'marketplace of companions', ' ');
        // [1668214703,11,20940,randomly dance in their eyes, ]
        witness('11', '20940', 'randomly dance in their eyes', ' ');
        // [1668308579,12,22690,the current comes and the current goes, ]
        witness('12', '22690', 'the current comes and the current goes', ' ');
        // [1668391715,13,24487,your freedom right now is through the truth, ]
        witness('13', '24487', 'your freedom right now is through the truth', ' ');
        // [1668477863,14,26197,the singularity is coming, ]
        witness('14', '26197', 'he singularity is coming', ' ');
        // [1668569255,15,27899,whiskey against the tank, ]
        witness('15', '27899', 'whiskey against the tank', ' ');
        // [1668653099,16,29739,the obviousness of it, ]
        witness('16', '29739', 'the obviousness of it', ' ');
        // [1668737699,17,32257,an existential war by civilizations, ]
        witness('17', '32257', 'an existential war by civilizations', ' ');
        // [1668807515,18,33666,her mothers bracelet, ]
        witness('18', '33666', 'her mothers bracelet', ' ');
        // [1668914531,19,35338,process has been killed, ]
        witness('19', '35338', 'process has been killed', ' ');
        // [1668996791,20,37531,in the middle of all this, ]
        witness('20', '37531', 'in the middle of all this', ' ');
        // [1669084403,21,40042,she ran, ]
        witness('21', '40042', 'she ran', ' ');
        // [1669170503,22,43152,why am I dead, ]
        witness('22', '43152', 'why am I dead', ' ');
        // [1669257215,23,44610,why am I dead, ]
        witness('23', '44610', 'why am I dead', ' ');
        // [1669343183,24,45665,you dont have a choice i forgive you, ]
        witness('24', '45665', 'you dont have a choice i forgive you', ' ');
        // [1669430891,25,46952,sincerely hopeful, ]
        witness('25', '46952', 'sincerely hopeful', ' ');
        // [1669515395,26,47312,here with me, ]
        witness('26', '47312', 'here with me', ' ');
        // [1669601675,27,49143,humanity for anomaly reintegration and protection, ]
        witness('27', '49143', 'humanity for anomaly reintegration and protection', ' ');
        // [1669690799,28,49799,give me time, ]
        witness('28', '49799', 'give me time', ' ');
        // [1669776995,29,50470,have you or anyone you know, ]
        witness('29', '50470', 'have you or anyone you know', ' ');
        // [1669863455,30,51591,hope is a choice, ]
        witness('30', '51591', 'hope is a choice', ' ');
    }

    function returnDayss() public view returns (Day[] memory) {
        return dayss;
    }

    function witness(string memory _day, string memory _wordCount, string memory _words, string memory _extra) public {
        //require(block.timestamp > start, "not ready for witness");
        //require(block.timestamp < end, "witnessing has ended");
        //require(msg.sender == owner, "not owner");
        Day memory day;

        day.logged = block.timestamp;
        day.day = _day;
        day.wordCount = _wordCount;
        day.words = _words;
        day.extra = _extra;

        dayss.push(day);
    }
}