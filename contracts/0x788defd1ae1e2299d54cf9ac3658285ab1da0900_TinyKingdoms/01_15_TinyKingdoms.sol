// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TinyKingdoms
 * @dev Generates beautiful tiny kingdoms
 */


contract TinyKingdoms is ERC721Enumerable,ReentrancyGuard,Ownable {

// 888888888888888888888888888888888888888888888888888888888888
// 888888888888888888888888888888888888888888888888888888888888
// 8888888888888888888888888P""  ""9888888888888888888888888888
// 8888888888888888P"88888P          988888"9888888888888888888
// 8888888888888888  "9888            888P"  888888888888888888
// 888888888888888888bo "9  d8o  o8b  P" od88888888888888888888
// 888888888888888888888bob 98"  "8P dod88888888888888888888888
// 888888888888888888888888    db    88888888888888888888888888
// 88888888888888888888888888      8888888888888888888888888888
// 88888888888888888888888P"9bo  odP"98888888888888888888888888
// 88888888888888888888P" od88888888bo "98888888888888888888888
// 888888888888888888   d88888888888888b   88888888888888888888
// 8888888888888888888oo8888888888888888oo888888888888888888888
// 8888888888888888888888888888888888888888888888888Ojo 9888888

    using Counters for Counters.Counter;
    
    uint256 private constant maxSupply = 4096;
    uint256 private  mintPrice = 0.025 ether;

    Counters.Counter private _tokenIdCounter;
    bool public saleIsActive = true; 
    

    constructor() ERC721("Tiny Kingdoms", "TNY") Ownable() {
        _tokenIdCounter.increment();
    }
       
    function setPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
    }
    
    
    string[] private nouns = [ 
        "Eagle","Meditation","Folklore","Star","Light","Play","Palace","Wildflower","Rescue","Fish","Painting",
        "Shadow","Revolution","Planet","Storm","Land","Surrounding","Spirit","Ocean","Night","Snow","River",
        "Sheep","Poison","State","Flame","River","Cloud","Pattern","Water","Forest","Tactic","Fire","Strategy",
        "Space","Time","Art","Stream","Spectrum","Fleet","Ship","Spring","Shore","Plant","Meadow","System","Past",
        "Parrot","Throne","Ken","Buffalo","Perspective","Tear","Moon","Moon","Wing","Summer","Broad","Owls",
        "Serpent","Desert","Fools","Spirit","Crystal","Persona","Dove","Rice","Crow","Ruin","Voice","Destiny",
        "Seashell","Structure","Toad","Shadow","Sparrow","Sun","Sky","Mist","Wind","Smoke","Division","Oasis",
        "Tundra","Blossom","Dune","Tree","Petal","Peach","Birch","Space","Flower","Valley","Cattail","Bulrush",
        "Wilderness","Ginger","Sunset","Riverbed","Fog","Leaf","Fruit","Country","Pillar","Bird","Reptile","Melody","Universe",
        "Majesty","Mirage","Lakes","Harvest","Warmth","Fever","Stirred","Orchid","Rock","Pine","Hill","Stone","Scent","Ocean",
        "Tide","Dream","Bog","Moss","Canyon","Grave","Dance","Hill","Valley","Cave","Meadow","Blackthorn","Mushroom","Bluebell",
        "Water","Dew","Mud","Family","Garden","Stork","Butterfly","Seed","Birdsong","Lullaby","Cupcake","Wish",
        "Laughter","Ghost","Gardenia","Lavender","Sage","Strawberry","Peaches","Pear","Rose","Thistle","Tulip",
        "Wheat","Thorn","Violet","Chrysanthemum","Amaranth","Corn","Sunflower","Sparrow","Sky","Daisy","Apple",
        "Oak","Bear","Pine","Poppy","Nightingale","Mockingbird","Ice","Daybreak","Coral","Daffodil","Butterfly",
        "Plum","Fern","Sidewalk","Lilac","Egg","Hummingbird","Heart","Creek","Bridge","Falling Leaf","Lupine","Creek",
        "Iris Amethyst","Ruby","Diamond","Saphire","Quartz","Clay","Coal","Briar","Dusk","Sand","Scale","Wave","Rapid",
        "Pearl","Opal","Dust","Sanctuary","Phoenix","Moonstone","Agate","Opal","Malachite","Jade","Peridot","Topaz",
        "Turquoise","Aquamarine","Amethyst","Garnet","Diamond","Emerald","Ruby","Sapphire","Typha","Sedge","Wood"
    ];
    
    string[] private adjectives = [
        "Central","Free","United","Socialist","Ancient Republic of","Third Republic of",
        "Eastern","Cyber","Northern","Northwestern","Galactic Empire of","Southern","Solar",
        "Islands of","Kingdom of","State of","Federation of","Confederation of",
        "Alliance of","Assembly of","Region of","Ruins of","Caliphate of","Republic of",
        "Province of","Grand","Duchy of","Capital Federation of","Autonomous Province of",
        "Free Democracy of","Federal Republic of","Unitary Republic of","Autonomous Regime of","New","Old Empire of"
    ];
    
    
    string[] private suffixes = [
        "Beach", "Center","City", "Coast","Creek", "Estates", "Falls", "Grove",
        "Heights","Hill","Hills","Island","Lake","Lakes","Park","Point","Ridge",
        "River","Springs","Valley","Village","Woods", "Waters", "Rivers", "Points", 
        "Mountains", "Volcanic Ridges", "Dunes", "Cliffs", "Summit"
    ];

      
    string[4][21] private colors = [            
        ["#006D77", "#83C5BE", "#FFDDD2", "#faf2e5"],
        ["#351F39", "#726A95", "#719FB0", "#f6f4ed"],
        ["#472E2A", "#E78A46", "#FAC459", "#fcefdf"],
        ["#0D1B2A", "#2F4865", "#7B88A7", "#fff8e7"],
        ["#E95145", "#F8B917", "#FFB2A2", "#f0f0e8"],
        ["#C54E84", "#F0BF36", "#3A67C2", "#F6F1EC"],
        ["#E66357", "#497FE3", "#8EA5FF", "#F1F0F0"],
        ["#ED7E62", "#F4B674", "#4D598B", "#F3EDED"],
        ["#D3EE9E", "#006838", "#96CF24", "#FBFBF8"],
        ["#FFE8F5", "#8756D1", "#D8709C", "#faf2e5"],
        ["#533549", "#F6B042", "#F9ED4E", "#f6f4ed"],
        ["#8175A3", "#A3759E", "#443C5B", "#fcefdf"],
        ["#788EA5", "#3D4C5C", "#7B5179", "#fff8e7"],
        ["#553C60", "#FFB0A0", "#FF6749", "#f0f0e8"],
        ["#99C1B2", "#49C293", "#467462", "#F6F1EC"],
        ["#ECBFAF", "#017724", "#0E2733", "#F1F0F0"],
        ["#D2DEB1", "#567BAE", "#60BF3C", "#F3EDED"],
        ["#FDE500", "#58BDBC", "#EFF0DD", "#FBFBF8"],
        ["#2f2043", "#f76975", "#E7E8CB", "#faf2e5"],
        ["#5EC227", "#302F35", "#63BDB3", "#f6f4ed"],
        ["#75974a", "#c83e3c", "#f39140", "#fcefdf"]
    ];

    string [2][25] private flags = [

        ['<rect class="cls-1" height="140" width="382" x="113" y="226" /><rect class="cls-2"  height="140" width="382" x="113" y="86" /><circle class="cls-3"  cx="304" cy="226" r="84"/>', "Rising Sun"], 
        ['<rect class="cls-1" height="279" width="127" x="113" y="86" /><rect class="cls-2"  height="279" width="128" x="240" y="86" /><rect class="cls-3"  height="279" width="128" x="367" y="86" /><rect class="contour"  x="113.5" y="86.5" width="2" height="279"/>', "Vertical Triband"], 
        ['<rect class="cls-1" height="279" width="382" x="113.65" y="86.26"/> <polygon class="cls-2"  points="113.65 86.27 304.65 225.76 113.65 365.26 113.65 86.27"/>', "Chevron"], 
        ['<rect class="cls-1" height="279" width="381" x="113.77" y="86.13"/> <polygon class="cls-2"  points="112.77 178.87 208.27 178.87 208.27 86.13 302.77 86.13 302.77 178.87 494.49 178.87 494.49 272.24 302.77 272.24 303.83 365.13 208.29 365.63 208.27 272.24 112.89 272.24 112.77 178.87"/>', "Nordic Cross"], 
        ['<rect class="cls-1" height="62"  width="381" x="114" y="86"/> <rect class="cls-2"  height="156" width="381" x="114" y="148"/> <rect class="cls-1"  height="62" width="381" x="114" y="304"/>', "Spanish Fess"], 
        ['<rect class="cls-1" height="155" width="381" x="114" y="148"/> <rect class="cls-2"  height="62" width="381" x="114" y="86"/> <rect class="cls-2"  height="62" width="381" x="114" y="195"/> <rect class="cls-2"  height="62" width="381" x="114" y="303"/>', "Five Stripes"], 
        ['<rect class="cls-1" height="279" width="382" x="113" y="87"/><circle  class="cls-2" cx="303.5" cy="224.5" r="95.5"/>', "Hinomaru"], 
        ['<rect class="cls-1" height="279" width="190" x="114" y="86"/> <rect class="cls-2"  height="279" width="191" x="304" y="86"/>', "Vertical Bicolor"], 
        ['<rect class="cls-1" height="279" width="381" x="114" y="86"/> <polygon class="cls-2"  points="165.74 86.5 113.85 86.5 113.85 125.1 252.77 225.84 113.85 326.58 113.85 364.9 165.47 364.9 304.79 263.56 445.19 365.38 495.45 365.38 495.45 325.6 358.44 226.25 495.45 126.09 495.45 87.59 444.92 87.59 304.79 188.12 165.74 86.5"/>', "Saltire"], 
        ['<rect class="cls-1" height="140" width="382" x="114" y="225"/> <rect class="cls-2"  height="140" width="382" x="114" y="85"/>', "Horizontal Bicolor"], 
        ['<rect class="cls-1" height="279" width="381" x="114" y="86"/> <rect class="cls-2"  height="279" width="128" x="177" y="86"/>',"Vertical Misplaced Bicolor"], 
        ['<rect class="cls-1" height="279" width="381" x="114" y="85"/> <rect class="cls-2"  height="279" width="382" x="113" y="86"/> <rect class="cls-3"  height="155" width="256" x="176" y="148"/>', "Bordure"], 
        ['<rect class="cls-1" height="279" width="382" x="112.75" y="86.62"/> <polyline class="cls-2"  points="113.07 365.29 391.75 365.62 112.85 226.33"/> <polyline class="cls-2"   points="113.07 85.96 391.75 85.62 112.85 226.58"/>', "Inverted Pall"], 
        ['<rect class="cls-1" height="280" width="381" x="114" y="85"/> <rect class="cls-2"   height="68.63" width="63" x="113.83" y="86.69"/><rect class="cls-2"   height="68.63" width="63" x="240.83" y="86.69"/><rect class="cls-2"   height="68.63" width="63" x="367.83" y="86.69"/><rect class="cls-2"   height="68.63" width="63" x="113.83" y="226.19"/><rect class="cls-2"   height="68.63" width="63" x="240.83" y="226.19"/><rect class="cls-2"   height="68.63" width="63" x="367.83" y="226.19"/><rect class="cls-2"   height="68.63" width="63" x="176.83" y="156.44"/><rect class="cls-2"   height="68.63" width="63" x="303.83" y="156.44"/><rect class="cls-2"   height="68.63" width="63" x="430.83" y="156.44"/><rect class="cls-2"   height="68.63" width="63" x="176.83" y="297.07"/><rect class="cls-2"   height="68.63" width="63" x="303.83" y="297.07"/><rect class="cls-2"   height="68.63" width="63" x="430.83" y="297.07"/>', "Twenty-four squared"], 
        ['<rect class="cls-1" height="278" width="383" x="112" y="87"/> <polygon class="cls-2"   points="113.1 85 289.69 85 494.1 365 318.1 365 113.1 85"/>', "Diagonal Bicolor"], 
        ['<rect class="cls-1" height="93" width="381.13" x="113.65" y="86.25"/> <rect class="cls-2"  height="93" width="381.13" x="113.65" y="272.25"/> <rect class="cls-3"  height="93" width="382" x="112.77" y="179.25"/>', "Horizontal Triband"], 
        ['<rect class="cls-1" height="278" width="382" x="113" y="87"/> <polygon class="cls-2"   points="494.66 86 318.06 86 113.66 365 289.66 364 494.66 86"/>', "Diagonal Bicolor Inverse"], 
        ['<rect class="cls-1" height="279" width="381" x="114" y="86"/> <rect class="cls-2"   height="139" width="191" x="113" y="86"/><rect class="cls-2"   height="139" width="191" x="304" y="226"/>', "Quadrisection"], 
        ['<polygon class="cls-1"  points="495.47 86.16 290.47 365 495.47 365 495.47 86.16"/> <polygon class="cls-2"  points="114.47 365.16 319.47 87.16 114.47 87.16 114.47 365.16"/> <polygon class="cls-3"  points="495.47 86.16 318.88 86.16 114.47 365.16 290.47 365 495.47 86.16"/>',"Diagonal Tricolor Inverse"], 
        ['<rect class="cls-1"  height="279" width="190" x="304" y="87"/><rect class="cls-2"  height="279" width="190" x="114" y="86"/><path class="cls-1"  d="M304,310a84,84,0,0,1,0-168"/><path class="cls-2"  d="M304,142a84,84,0,0,1,0,168"/>', "Rising Split Sun"], 
        ['<rect class="cls-2"  x="112.2" y="86.31" width="382" height="279"/> <path class="cls-3"  d="M184.37,121.45l7.84,15.88,17.52,2.55a1.52,1.52,0,0,1,.85,2.6L197.9,154.84l3,17.46a1.52,1.52,0,0,1-2.21,1.6L183,165.66l-15.68,8.24a1.52,1.52,0,0,1-2.21-1.6l3-17.46-12.68-12.36a1.52,1.52,0,0,1,.85-2.6l17.52-2.55,7.84-15.88A1.53,1.53,0,0,1,184.37,121.45Z"/>', "Lonely Star"],  
        ['<polygon class="cls-1"  points="113.2 365 495 86 113.7 86 113.2 365" /> <polygon class="cls-2"  points="113.2 364.81 495 364.81 495 85.81 113.2 364.81" /><rect class="contour"  x="113.5" y="86.5" width="382" height="279" /><polygon id="shadow" class="shadow" points="112.5 365.5 112.5 87.92 108 97 108 370 490 370 494.67 365.5 112.5 365.5" />', "Diagonal Bicolor Right"], 
        ['<rect class="cls-1"  x="113" y="227" width="382" height="140"/> <rect class="cls-2"  x="113" y="87" width="382" height="140"/> <path class="cls-3" d="M307.17,171.15l15.52,31.46,34.72,5a3,3,0,0,1,1.67,5.15L334,237.29l5.93,34.58a3,3,0,0,1-4.38,3.18l-31.05-16.32-31,16.32a3,3,0,0,1-4.38-3.18L275,237.29,249.84,212.8a3,3,0,0,1,1.67-5.15l34.72-5,15.52-31.46A3,3,0,0,1,307.17,171.15Z"/>', "Horizontal Bicolor with a star"], 
        ['<rect class="cls-1"  x="113.3" y="85.81" width="381" height="279" /> <rect class="cls-2"  x="112.2" y="86.31" width="382" height="279" /> <path class="cls-3"  d="M304.17,174.15l15.52,31.46,34.72,5a3,3,0,0,1,1.67,5.15L331,240.29l5.93,34.58a3,3,0,0,1-4.38,3.18l-31.05-16.32-31,16.32a3,3,0,0,1-4.38-3.18L272,240.29,246.84,215.8a3,3,0,0,1,1.67-5.15l34.72-5,15.52-31.46A3,3,0,0,1,304.17,174.15Z"/>  <rect class="contour"  x="113.5" y="86.5" width="382" height="279" /> <polygon id="shadow"  class="shadow" points="112.5 365.5 112.5 87.92 108 97 108 370 490 370 494.67 365.5 112.5 365.5"/>' ,"Bonnie Star"],
        ['<rect class="cls-1" x="113" y="86" width="382" height="279" /><path class="cls-2" d="M254.39,220.72c-12.06-26.86,6.15-59.35,37.05-57.18,35.54-4,73.17,11.34,57.82,52.45-4-41.61-10.06-3.76-5.07,11.77.36,3.53,3.81,2.36,6.28,3.09,7,3.35-4.56,9.81-6.68,13.37-3.19,1.4-7.43-.7-10.53,1.17-7.52,2.89-7.54,11.65-13.49,14.69-10,2-31,4.64-35.76-6.65,1-15.88-15.88-4.52-24-11-5.29-2.11-8.31-6.51-2.23-10.1,7.91-7.51-1.52-20.95,4.28-29.77,2.08-2.24-.15-6-3.11-5.13C252.15,202.65,256.43,214.06,254.39,220.72Zm23.93,17c9.31,1.15,17.39-5.16,17.29-14.21C294.2,192.84,246.71,231.75,278.32,237.73Zm31.41-15.43c.7,20,30.12,20.91,26.74-1.33C332.9,211.42,308.49,208,309.73,222.3ZM295.4,250c-.71,10.86,7.14-1.06,10.8,4.21C321.79,259.61,301,197.87,295.4,250Z"/> <path class="cls-2" d="M205.35,312.39c-2.6,0-4.58-3-3.6-4.91.59-1.16,1.36-2.22,2.05-3.33a4.24,4.24,0,0,0-.69-5.84,28.91,28.91,0,0,0-3.19-2.24c-1.51-1.05-3.09-2-4.51-3.17-1.68-1.37-1.86-4.68-.53-6.38a1.83,1.83,0,0,1,2.19-.54c2.33.65,4.64,1.44,7,1.87a31.84,31.84,0,0,0,6.25.42,5.39,5.39,0,0,0,2.74-1c4.17-2.82,8.29-5.71,12.4-8.61,5.24-3.72,10.47-7.44,15.67-11.21,2.76-2,5.45-4.12,8.14-6.23,3.25-2.57,6.78-1.75,10.29-.84,1.26.33,1.42,1.25.53,2.28a12.23,12.23,0,0,1-2,1.81c-9.38,6.82-18.64,13.83-28.21,20.37a50.14,50.14,0,0,0-13.41,13.44c-.65,1-1.44,1.86-2,2.85a38.27,38.27,0,0,0-2.16,4,14.57,14.57,0,0,1-4.89,6.31A14.2,14.2,0,0,1,205.35,312.39Z"/><path class="cls-2" d="M313.77,292.2c-18.18,2.17-38.88-2.2-38.81-24.88.65-2.67-1.22-14.79,3.62-9.12,1.73,24,24.92,15.23,42.09,15.47,8,.2,2.77-15.79,10.1-13.83C336.89,271.09,325.62,289.86,313.77,292.2Z"/><path class="cls-2" d="M188.66,158.18a8,8,0,0,1-5.57-2c-1.34-1.12-1.4-2.57.06-3.49A22.44,22.44,0,0,1,188,150.5c2.23-.74,4.59-1.27,5.95-3.38a9.8,9.8,0,0,0,1.15-3.2,15.58,15.58,0,0,0,0-2.56,4.38,4.38,0,0,1,3.41-4,2.54,2.54,0,0,1,3.26,1.61,43.05,43.05,0,0,1,1.73,4.81,12.93,12.93,0,0,0,6.26,7.93c5.2,3,10.48,6,15.55,9.19,4.55,2.9,9.19,5.61,14,8.12a94.18,94.18,0,0,1,9,5.84c1.66,1.14,1.84,2,.86,3.79a30.47,30.47,0,0,1-2.21,3.21,1.5,1.5,0,0,1-2.32.38c-2.26-1.54-4.55-3.05-6.83-4.58-.37-.25-.69-.57-1.07-.82-8.3-5.34-16.52-10.82-25-15.95-3.26-2-7-3.18-10.53-4.76a4.66,4.66,0,0,0-3.39-.08c-3,.9-6.12,1.68-9.18,2.51Z"/><path class="cls-2" d="M407.34,135.6c-.19.91-.35,1.83-.56,2.75-.55,2.37.1,3.45,2.39,4.36a15.53,15.53,0,0,1,3.86,2.1c2,1.55,2,5,.13,6.71l-.5.45c-4.1,3.53-4.11,3.57-9,1.41a6.54,6.54,0,0,0-6.27.29,103.21,103.21,0,0,0-15.93,10.55c-3.62,3-7.77,5.33-11.69,7.94-3.48,2.32-7,4.64-10.46,6.91-1.54,1-2,.89-2.85-.71-.7-1.39-1.24-2.88-1.84-4.32a2.23,2.23,0,0,1,.68-2.8,42.53,42.53,0,0,1,4-2.93c10.65-6.68,21.34-13.31,32-20a65.77,65.77,0,0,0,5.34-4.1,3.18,3.18,0,0,0,1.34-2.65c0-1.53.17-3,.18-4.58a6.59,6.59,0,0,1,2.68-5.2,2.68,2.68,0,0,1,3.48-.22C405.72,132.54,407.18,133.57,407.34,135.6Z"/><path class="cls-2" d="M344.09,258.87a37.13,37.13,0,0,1,5.42,1.38A84.26,84.26,0,0,1,368,271.45c1.72,1.33,3.74,2.26,5.6,3.42a42.57,42.57,0,0,1,3.78,2.57,69.52,69.52,0,0,0,13.29,8.18,28.56,28.56,0,0,0,10.55,2.51c4.3.31,8.61.53,12.91.84a9.09,9.09,0,0,1,2.22.53,2.72,2.72,0,0,1,2.12,2.89c-.05,1.75.1,3.51,0,5.25-.14,2.45-1.76,3.7-4.27,3.52-1.66-.13-3.32-.2-5-.27a3.32,3.32,0,0,0-3.34,2.07,23.4,23.4,0,0,0-1.45,4.3c-.41,1.88-1.95,2.67-3.47,1.47a8.45,8.45,0,0,1-1.86-2.42c-1-1.76-1.95-3.6-3-5.38a22.15,22.15,0,0,0-8.71-8.16c-3.76-2.18-7.24-4.84-10.92-7.17-3.1-2-6.47-3.56-9.44-5.7A173.89,173.89,0,0,0,344.66,266a1.35,1.35,0,0,1-.86-1.48C343.94,262.81,344,261.11,344.09,258.87Z"/>', "Jolly Roger"]
    ];


    uint256[3][6] private orders = [
        [1, 2, 3],
        [1, 3, 2],
        [2, 1, 3],
        [2, 3, 1],
        [3, 1, 2],
        [3, 2, 1]
    ];
    

    struct TinyFlag {
        string placeName;
        string flagType; 
        string flagName;
        
        uint256 themeIndex;
        uint256 orderIndex;
        uint256 flagIndex;

    }

    function getOrderIndex (uint256 tokenId) internal pure returns (uint256){
        uint256 rand = random(tokenId,"ORDER") % 1000;
        uint256  orderIndex= rand / 166;
        return orderIndex;
    
    }

    function getThemeIndex (uint256 tokenId) internal pure returns (uint256){
        uint256 rand = random(tokenId,"THEME") % 1050;
        uint256 themeIndex;

        if (rand<1000){themeIndex=rand/50;}
        else {themeIndex = 20;}
       
        return themeIndex;
    
    }
    
    function getFlagIndex(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(tokenId,"FLAG") % 1000;
        uint256 flagIndex =0;

        if (rand>980){flagIndex=24;}
        else {flagIndex = rand/40;}
        
        return flagIndex;
    }

    function getflagType(uint256 flagIndex) internal view returns (string memory) {       
        string memory f1 = flags[flagIndex][0];
        return string(abi.encodePacked(f1));
    }


    function getflagName(uint256 flagIndex) internal view returns (string memory) {       
        string memory f1 = flags[flagIndex][1];
        return string(abi.encodePacked(f1));
    }

     function getKingdom (uint256 tokenId, uint256 flagIndex) internal view returns (string memory) {
        uint256 rand = random(tokenId, "PLACE");
        
        
        string memory a1 = adjectives[(rand / 7) % adjectives.length];
        string memory n1 =nouns[(rand / 200) % nouns.length];
        string memory s1;

        if (flagIndex == 24) {
            s1 = "pirate ship";
        } else {
            s1 = suffixes[(rand /11) % suffixes.length];
        }
        
        string memory output= string(abi.encodePacked(a1,' ',n1,' ',s1));
        bytes memory b =bytes(output);

        uint256 y = 449;
        uint256 i = 0;
        uint256 e = 0;    
        uint256 ll = 20;
    
        while (true) {
        e = i + ll;
        if (e >= b.length) {
            e = b.length;
        } else {
            while (b[e] != ' ' && e > i) { e--; }
        }

      bytes memory line = new bytes(e-i);
      for (uint k = i; k < e; k++) {
        line[k-i] = _upper(b[k]);
      }
      
      output = string(abi.encodePacked(output,'<text text-anchor="middle" class="place" x="303" y="',Strings.toString(y),'">',line,'</text>'));
      if (y > 450) break;
      
      y += 38;
      if (e >= b.length) break;
      i = e + 1;
    }

    return output;

    }


    function randomFlag(uint256 tokenId) internal view  returns (TinyFlag memory) {
        TinyFlag memory flag;
        
        flag.themeIndex= getThemeIndex(tokenId);
        flag.orderIndex = getOrderIndex(tokenId);
        flag.flagIndex = getFlagIndex(tokenId);
        flag.flagType= getflagType(flag.flagIndex);
        flag.flagName = getflagName(flag.flagIndex);
        flag.placeName= getKingdom(tokenId, flag.flagIndex);

        return flag;
    }

    function getFlagStyle(TinyFlag memory flag) internal view returns (string memory){
        string[9] memory parts;

        parts[0]='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 609 602" style="background-color:'; //#faf2e5"> <defs> <style> .shadow{stroke-linecap:round;stroke-linejoin:round;fill:#565656;stroke:#565656} .cls-1{fill:';
        parts[1]=colors[flag.themeIndex][3];
        parts[2]='"> <defs> <style> .shadow{stroke-linecap:round;stroke-linejoin:round;fill:#565656;stroke:#565656} .cls-1{fill:';
        parts[3]=colors[flag.themeIndex][orders[flag.orderIndex][0]-1];
        parts[4]=';}.cls-2{fill:';
        parts[5]=colors[flag.themeIndex][orders[flag.orderIndex][1]-1];
        parts[6]=';}.cls-3{fill:';
        parts[7]=colors[flag.themeIndex][orders[flag.orderIndex][2]-1];
        parts[8]=';}.cls-5{fill:none;stroke:#565656;stroke-miterlimit:10;stroke-width:2px;} .contour{fill:none;stroke:#565656;stroke-miterlimit:10;stroke-width:2px;height:279,width:382, x:113, y:86}.place{font-size:36px;font-family:serif;fill:#565656}</style></defs>';

        string memory output = string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7], parts[8]));
        return output;
    }
    
    function getFlagSVG(TinyFlag memory flag, string memory style) internal pure returns (string memory){
        string[6] memory parts;

        parts[0]=style;
        parts[1]='<pattern id="backDots" width="64" height="64" patternUnits="userSpaceOnUse"><line fill="transparent" stroke="#565656" stroke-width="2" opacity=".6" x1="14.76" y1="24.94" x2="20.5" y2="19.5" /></pattern><filter id="back"><feTurbulence type="fractalNoise" baseFrequency="0.1" numOctaves="1" seed="42"/> <feDisplacementMap in="SourceGraphic" xChannelSelector="B" scale="200"/></filter><g filter="url(#back)"><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#backDots)" /></g><filter id="displacementFilter"><feTurbulence id="turbulenceMap" type="turbulence" baseFrequency="0.05" numOctaves="2" result= "turbulence"><animate attributeName="baseFrequency" values="0.01;0.001;0.01" dur="4s" repeatCount="indefinite"/></feTurbulence><feDisplacementMap in2="turbulence" in="SourceGraphic" scale="9" xChannelSelector="R" yChannelSelector="G" /></filter> <g id="layer_2" style="filter: url(#displacementFilter)">';
        parts[2]=flag.flagType;
        parts[3]='</g> <rect class="contour"  x="113.5" y="86.5" width="382" height="279" style="filter: url(#displacementFilter)"/><polygon class="shadow" points="112.5 365.5 112.5 87.92 108 97 108 370 490 370 494.67 365.5 112.5 365.5" style="filter: url(#displacementFilter)"/>';
        parts[4]=flag.placeName;
        parts[5]='</svg>';

        string memory output = string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5]));
        return output;
    }

   
    function random(uint256 tokenId, string memory seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, Strings.toString(tokenId))));
    }
    
    function _upper(bytes1 _b1) private pure returns (bytes1) {
          if (_b1 >= 0x61 && _b1 <= 0x7A) {
              return bytes1(uint8(_b1) - 32);
              }
              return _b1;
    }

    
    function tokenURI(uint256 tokenId) override public view  returns (string memory) {
        TinyFlag memory flag = randomFlag(tokenId);

        string memory json = Base64.encode(
            bytes(
                string(abi.encodePacked(
                    '{"name": "Tiny Kingdom #',
                     Strings.toString(tokenId),
                     '", "description": "Fully on-chain, randomly generated tiny flags.",',
                     '"image": "data:image/svg+xml;base64,', 
                     Base64.encode(bytes(getFlagSVG(flag, getFlagStyle(flag)))), 
                     '"',
                    ',"attributes":[{"trait_type":"Flag","value":"',flag.flagName,
                    '"}]}'
                    ))));
        
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
        }

    function claim() public payable {
         uint256 nextId = _tokenIdCounter.current();
        require(saleIsActive, "Sale is not active");
        require(mintPrice <= msg.value, "Ether value sent is not correct");
        require(nextId <= maxSupply, "Token limit reached");  
        _safeMint(_msgSender(), nextId);
        _tokenIdCounter.increment();
  }

  function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    
    // function flipSaleState() public onlyOwner {
    //     saleIsActive = !saleIsActive;
    //     }

}
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}