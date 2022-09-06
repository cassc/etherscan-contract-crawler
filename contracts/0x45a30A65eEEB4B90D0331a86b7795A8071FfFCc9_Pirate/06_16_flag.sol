// SPDX-License-Identifier: GPL-3.0

/*
 *   /\
 *   ||_____-----_____-----______
 *   ||   O O            O O     \
 *   ||     \\    ___   //       /
 *   ||       \\ /   \//         \
 *   ||         |_O O_|          /
 *   ||          \ ' /           \
 *   ||        // ||| \\         /
 *   ||      //         \\       \
 *   ||    O O           O O     /
 *   ||_____-----_____-----______\
 *   ||
 *   ||
 */


pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


/// @title 
/// @notice 
library Flag {
    using Strings for uint256;

    string private constant header = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" style="background-color: #289EFF;">\n';
    string private constant style = '<style>@font-face{font-family:"monkey";src:url(data:application/octet-stream;base64,d09GMgABAAAAAATUAAoAAAAAFUQAAASJAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAABlYAdAqfdJU3ATYCJAOCGAuBEAAEIAWDEgcgG8QOEVWcW8h+HMbukTAKzUjM+o9++Vq0FnZsWMbDf2v87szOd4kflaaaRDR59X0JGiUQqSQLiUNSjXTxVVFHyXbS9m0pzTGsv21EKw0jx//Vfq/2swuRYwnoVwZIyAgXe7gb5PfCLPkueCmMBxKSNLHrRNXHmU5lheoibuJTBQ8hlfeZtcibK2U4JP5nzl+4cNFqk1yWhOn2SYKBbs03jOpXWTyYYob5llhli60OuNwAJc21MLgmcZvj//Tmy+cPb14/e3r/yWOe4U23ewvHKDdpGQTQDQAyF4wxXuHZD44hZC/CfhqADR7PQ16x0q5b/o2tNTbOvD4+Pm7TCzTe9TXut3FjnhLOvl6OZ/LD711vnMfX83y07Mw22hyNLdt2nIe54QWncfxbh8e/VOgCrygrqqxCysoMZqWVVX6NnvSrZOd79yonmKofoP/86/y1q5IYKXtVU/+lVmEmyQpYEfuDzVEX0m5WIK+E1AETVNFE8H+pMCg5QlCi1QvXA/QStX3I8/UIHdrW6733BI1fJWYhl3oAQTP9UVVOueIdMkfzCGu65I1ex+dZWlWqzI7U3RzoSWvPUZ2KV0GTCYIiD2Ld3lT2p40pkLeYd8zzFUr2RnoxlxbyFwa6P0thpOp59hLkz685xSsrk6IIl0B2pXPVYoRTOuBJC/t8ysZ7qVuRtN2mMr/OkWKEVtaok7qRRjaxzevu9QDdrVw5tKmSyP5VTV0twV9elysrVIsWAalxoyH9dobrSsIdmbey/bB8zzqt6B9f+Qsmq2UyvtNcSvNbOfjfFU99ZjmI90utnW96BS5UHvCmC0rYT5GwsKeV1dfdhUZ2cx+lmG85vvercJfyYnmRP+UktUMDvUYTOPFLrcu61gUlDV4k4JG+6+vZ3VmacvtiMUQ4iQF7mCTUR9SDqfjYpMv1C9R5mvpiCIejaRWwvJbLIu7b/DAJVvz0tjAmgincA00YCmmoH6wDiqTPc3qqAEH7aVDkrqxcU4cwXiF6k6YhQgSCpkGHStXaFwwEQ2QaDVsg0JIEekKtkssiBCd6MEN11JOaJIGESdWxiLoGDVrUapKOz9HUQ7Kqc4jp2hNMPBP0iwTRqSe0PzCaJuhBvMKj+cajMSuYGUNGLxqOwrZExNF8lUI3Hpt/SdAUAas+LpCQ6R7kJ4WwGQrDl0+zIl2pIojakQCdMhjzP98lhz+ruP38nLo2TUN1wwftux4mJwIqku+xE9+WwobxeuJ7u0JVe7xi2sgNZ94LTYOAqbrxgmvqTWsOtFdn16CvsiipxiGc+i77mhp9NsBMhfqx1c2ujd/DSLDKOWzQY65cBJKwXDg+OpNGvZn/TxISnXduL/q6L/+2VQM8Wv/7Lnx4+PUeTTRVSPyZAtohCsm6YwOo0RvkSEqQQ+QQVdwHK6NqMQVV3NfQU5fCAsHoiesnQnBFCs32a9pkQiX/2US6oZJKIMMZdrjAFW5NXwBMMMMKFtiS0ao7bYiMRIYFCQec8AgewxN4Ci/gFbyBd/AZvKzanuC0andG+ZdvdsF5Z5x2SWUN)}@keyframes showHide{50%{visibility:hidden}to{visibility:visible}}.txt{text-anchor:middle;fill:#FFF;font-family:monkey;font-size:0.5rem;}.frame{animation-name:showHide;animation-iteration-count:infinite;animation-duration:.2s;animation-direction:alternate}</style>\n';
    string private constant layer1 = '<g class="frame" transform="translate(60 40)"><path style="fill:#000" d="M180 33v3h-6v3h-3v3h-15v-3h-6v-3h-30v3h-12v3h-3v3h-3v3h-3v3h-3v3h-6v3H78v-3h-6v-3h-3v12h6v3h3v6h3v18h-3v3h-3v3h-3v6h3v3h3v-3h12v-3h6v-3h3v-3h3v-3h6v-3h15v-3h6v-3h9v3h9v3h6v3h18v-3h12v-3h6v-3h3v-3h6v-3h3v-3h3v-3h-9v-3h-3v-3h-3v-9h3v-6h3v-3h15v-3h-3v-3h-3v-3h-6v-3zm24 36h3v-3h-3z"/><path style="fill:#fff" d="M129 45v3h-3v12h3v-6h6v6h-6v3h3v6h3v3h3v-3h3v3h3v-9h3v-3h-6v-6h6v6h3v-9h-3v-3h-3v-3zm12 27h-3v3h3zm0 3v3h3v-3zm-6-3h-3v3h3zm-6-9h-6v3h6zm-6 3h-6v3h6zm-6 3h-3v3h-6v6h6v-3h3zm51-24v6h-6v3h-9v3h12v-3h12v-3h-3v-6zm-57 3v3h-6v3h-3v3h3v3h6v-3h3v-6h9v-3zm36 18v3h3v-3zm3 3v3h3v3h3v3h6v3h6v-3h3v-6h-6v3h-6v-3h-3v-3z"/></g>\n';
    string private constant layer2 = '<g class="frame" style="visibility:hidden;animation-delay:.2s" transform="translate(60 40)"><path style="fill:#000" d="M177 36h-6v3h-3v3h-6v3h-12v-3h-6v-3h-6v-3h-18v3h-18v3h-3v3h-3v3h-3v3h-3v3h-6v3h-6v-3h-6v-3h-3v12h6v3h3v6h3v15h-3v3h-3v6h-3v6h3v3h3v-3h3v-3h3v-3h3v-3h9v-3h12v-3h15v-3h15v3h6v3h18v-3h9v-3h15v-3h9v-3h6v-3h6v-3h3v-3h-12v-3h-6V54h6v-3h3v-6h6v-3h3v-3h-12v-3h-9v-3h-12z" /><path style="fill:#fff" d="M135 48v3h-3v9h3v3h3v-6h6v6h-6v6h3v3h-3v3h3v-3h3v3h-3v3h9v-3h-3v-3h3v-3h-6v-3h6v3h3v-3h-3v-6h3v6h3v-9h-3v-6h-6v-3zm-15 21v3h-3v3h-6v6h6v-3h6v-6h3v-3h9v-3h-12v3zm48-21v3h-3v3h-6v3h9v-3h3v-3h9v-3h-3v-3h-6v3zm-45 0v-3h-12v3h-3v3h3v3h3v-3h3v-3h6v3h6v-3zm30 24v3h6v3h9v-3h9v-3h-3v-3h-6v6h-9v-3z" /></g>\n';

    function generateMetadata(uint tokenId, bool valid, uint victories) public pure returns (string memory)
    {   
        return Base64.encode(abi.encodePacked('{"name":"', (!valid ? 'Failed ' : ''), 'Pirate Insult #', ((tokenId >> 5) & 0x1F).toString() ,'", "description":"Genuine Pirate Insult Certification","image": "data:image/svg+xml;base64,', Base64.encode(generateFlag(((tokenId >> 5) & 0x1F), (tokenId & 0x1F), valid)), '", "attributes": [ { "trait_type": "Victories", "value": "', victories.toString(), '" } ]}'));         
        //return Base64.encode(abi.encodePacked('{"name":"', (!valid ? 'Failed ' : ''), 'Pirate Insult #', ((tokenId >> 5) & 0x1F).toString() ,'", "description":"Genuine Pirate Insult Certification","image": "data:image/svg+xml;base64,', Base64.encode(generateFlag(((tokenId >> 5) & 0x1F), (tokenId & 0x1F), valid)), '"}'));        
    }

    function generateFlag(uint insult, uint reply, bool valid) private pure returns (bytes memory)
    {        
        bytes memory output = abi.encodePacked(header, style, layer1, layer2);
        return abi.encodePacked(output, '<text x="50%" y="50" class="txt">', (!valid ? 'Failed ' : ''), 'Pirate Insult Emblem #', insult.toString(), '</text><text x="50%" y="200"  class="txt">', getInsult(insult), '</text><text x="50%" y="250"  class="txt">', getReply(reply), '</text>\n</svg>');        
    }


    function getInsult(uint id) private pure returns (string memory)
    {        
        return [ "This is the END for you, you gutter-crawling cur!", "Soon you'll be wearing my sword like a shish kebab!", "I'll use my hankerchief to wipe up your blood", "People usually fall at my feet when they see me coming", "I once owned a dog that was smarter than you", "You make me want to puke", "Nobody has drawn blood from me and no one ever will", "You fight like a dairy farmer!", "I got this scar on my face from my last great battle", "I've heard you are a contemptible sneak", "You're no match for my brain you poor fool!", "You have the manners of a begger!", "I wont take your insolence sitting down!", "There are no words for how disgusting you are", "I've spoken to apes more polite than you", "Have you stopped wearing diapers yet?", "My last fight ended with my hands covered in blood", "My tongue is sharper than any sword", "Only once have I met such a coward", "My name is feared in every dirty corner of this island", "I will milk every drop of blood from your body", "Every word you say to me is stupid", "Have you a boat ready for a quick escape?", "If your brother's like you, its better to marry a pig!", "I've got the courage and skill of a master swordsman", "You are a pain in the backside, Sir.", "There are no clever moves that can save you now", "No one will ever catch me fighting as badly as you do", "My sword is famous all over the Caribbean", "My wisest enemies run away at the meer sight of me", "I usually see people like you passed out on the tavern floors", "Now I know what filth and stupidity really are" ][id];
    }

    function getReply(uint id) private pure returns (string memory)
    {        
        return [ "And I've got a TIP for you, get the POINT?", "First you'd better stop waving it like a feather duster!", "You got that job as Janitor after all!", "Even BEFORE they've smelt your breath?", "He must have taught you everything you know", "You make me think someone already did!", "You run THAT fast?", "How appropriate you fight like a cow!", "I trust now you've learnt to stop picking your nose", "Too bad no one has heard of you at all!", "I'd be in real trouble if you ever used them!", "I wanted to make sure you were comfortable with me!", "Your hemorrhoids are playing up again huh?", "Yes there are, you just never learnt them!", "I'm glad to hear you attended your family reunion", "Why? Do you want to borrow one?" ][id];
    }
    
}