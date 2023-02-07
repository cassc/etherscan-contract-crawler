// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// Renderer + SVG.sol + Utils.sol from hot-chain-svg.
// Modified to fit the project.
// https://github.com/w1nt3r-eth/hot-chain-svg

import './svg.sol';
import './utils.sol';
import "./Witness.sol";

contract CollectionDescriptor {

    Witness public witness;

    // piece => seed
    mapping(uint => uint) seeds;

    // structs help with packing to avoid local variable stack limit
    struct PupilStorage {
        uint offsetx;
        uint offsety;
        uint r;
        uint xmidPoint;
        uint ymidPoint;
    }

    struct ColourInformation {
        uint currentColour;
        uint colourShift;
        uint backgroundColour;
    }

    constructor(address wAddress) {
        // the witness.sol used during November 2022 for recording the draft each day.
        // You can find Witness.sol here: https://etherscan.io/address/0xfde89d4b870e05187dc9bbfe740686798724f614
        witness = Witness(wAddress); 

        // seeds used with generator for each id.
        // this was chosen one by one to create a varied collection.
        seeds[0] = 80044491973980591444808345409934770915066006939993750435561322058588730240570; // 1
        seeds[1] = 18004466893686479750475846750781066599149533972578027177114034110612094094; // 2
        seeds[2] = 46446408789816314722985168527441250197500521464882862309868837379927497532300; // 3
        seeds[3] = 78243037955834598523754296354330632136231478761149777578091086279129948865705; // 4
        seeds[4] = 38719296808200095583233004137618424690296591149532452788354194921204740345598; // 5
        seeds[5] = 77141802634089181467468603668221328868116219376682981861897821028177395497724; // 6
        seeds[6] = 72240521973445462610965342106016983640932131370665609701456594393275291179136; // 7
        seeds[7] = 5016666528319720015994271893753993707160980119870930048193164266259859124657; // 8
        seeds[8] = 50683257957555221759441885924191778421951004669995229656364770507571699393537; // 9
        seeds[9] = 20485178893473727651555360136417090399213245805450429254690334471105182129070; // 10
        seeds[10] = 12898696858260200341493872813335639159615801200131909000013731746475826312735; // 11
        seeds[11] = 31450826090461710289246588418804345918107614504279013968666658642511836923672; // 12
        seeds[12] = 94397855848486195516281070775395676345526392813158518681787488609733347855048; // 13
        seeds[13] = 98047131257039562884189345037860937953655768579418633991401566747818554076092; // 14
        seeds[14] = 67937897153124172776566621112416148433929625029801518339226115196339591034631; // 15
        seeds[15] = 96513893435222072307039622901872387084010436523105178485723157347629094868909; // 16
        seeds[16] = 109936017627078776323170070668277740871202538860536782716108493139900530289193; // 17
        seeds[17] = 33241366968212039706794958209826905999660298292001238319345056928852181894976; // 18
        seeds[18] = 56866880486253441401961689381106735099610752563121796109237592164452812905961; // 19
        seeds[19] = 55682218754982249538672892917008104370252653468285639152580181875870162766749; // 20
        seeds[20] = 33386271639093271881338818096777559636239584853676765874245542850568381168488; // 21
        seeds[21] = 16979836803601825051267772746902854725526632224683644575787589429367332016344; // 22
        seeds[22] = 37146998103272876516168461399621631436835667105793433232786382939985764792416; // 23
        seeds[23] = 57826396149430866801743976976221609825441772722059613285641233131804547381208; // 24
        seeds[24] = 64014563562513447582805130756543578931712322821465759392667894119375361812007; // 25
        seeds[25] = 61745189215979355044195499951452558027574883951533122692785463552262059243084; // 26
        seeds[26] = 111980497258566850477615869299848135050990077617415938482923331732736978645644; // 27
        seeds[27] = 106241896171550461100197439432765486778276244230634551778639901197856125186644; // 28
        seeds[28] = 11530649775351803752718581600331065550866939730465207956172132102202209430704; // 29
        seeds[29] = 18120611061039310530414837610873998323043825134871278279888729668251509774738; // 30
    }

    /* called from Collection (tokenURI) */

    function generateName(uint tokenId) public view returns (string memory) {
        Witness.Day memory d;
        (d.logged, d.day, d.wordCount, d.words, d.extra) = witness.dayss(tokenId);
        return string(abi.encodePacked('Day ', d.day, ': ', d.words));
    }

     function generateDescription() public pure returns (string memory) {
        string memory description = "Witness The Draft. An art project that is a fusion of 30-day literature, provenance, creativity, and dynamic social on-chain NFTs. The 30 pieces are able to witness each other, opening the eyes in other pieces.";
        return description;
    }

        function generateImage(uint256 tokenId, bool[30] memory witnesses) public view returns (string memory) {
        return render(tokenId, witnesses);
    } 
    
    function generateTraits(uint256 tokenId) public view returns (string memory) {
        Witness.Day memory d;
        (d.logged, d.day, d.wordCount, d.words, d.extra) = witness.dayss(tokenId);

        return string(abi.encodePacked('"attributes": [',
            createTrait('logged', utils.uint2str(d.logged)),',',
            createTrait('day', d.day),',',
            createTrait('total words written', d.wordCount),',',
            createTrait('words witnessed', d.words),
            ']'
        ));
    }

    function createTrait(string memory traitType, string memory traitValue) internal pure returns (string memory) {
        return string.concat(
            '{"trait_type": "',
            traitType,
            '", "value": "',
            traitValue,
            '"}'
        );
    }
    
    /* actual drawing functions */

    /*
    It's slightly janky, using a mix of hotsvg + custom svg in strings.
    */

    function render(uint256 _tokenId, bool[30] memory witnesses) internal view returns (string memory) {
        uint seed = seeds[_tokenId];
        bytes memory hash = abi.encodePacked(bytes32(seed));

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="420" style="background:#000">',
                defins(),
                draw(_tokenId, hash, witnesses),
                distortFilter(),
                text(_tokenId),
                '</svg>'
            );
    }

    function defins() internal pure returns (string memory) {
        string memory d;
        d = string.concat(d, '<clipPath id="keepTop" clipPathUnits="objectBoundingBox"><rect y="-0.1" width="1" height="0.35"/></clipPath>');
        d = string.concat(d, '<clipPath id="keepBottom" clipPathUnits="objectBoundingBox"><rect y="0.75" width="1" height="0.5"/></clipPath>');
        return d;
    }

    function draw(uint256 _tokenId, bytes memory hash, bool[30] memory witnesses) internal pure returns (string memory) {
        ColourInformation memory ci;
        ci.currentColour = utils.getColour(hash);// 0 - 360
        ci.colourShift = utils.getColourShift(hash); // 0 - 255
        string memory c;
        uint i;
        uint j;

        string memory cutout = string.concat('<mask id="eyes',utils.uint2str(_tokenId),'"> <rect width="300" height="360" fill="white" />');
        string memory background = ""; // background rect + pupil

        for(i = 0; i<6; i+=1) { //y (6 slots)
            for(j = 0; j<5; j+=1) { //x (5 slots)
                uint wi = i*5+j;
                bool open; // = false
                bool ownEye; // = false
                if (witnesses[wi] == true) { // if witnessed
                    open = true;

                    if(wi == _tokenId) { // own eye has different features
                        ownEye = true;
                        ci.backgroundColour = ci.currentColour+180; 
                    }
                } 
                
                background = string.concat(background, generateEye(hash, ci.currentColour, i, j, open, ownEye));
                cutout = string.concat(cutout, eyeCutout(i, j, open));

                ci.currentColour+=ci.colourShift;
            }
        }

        cutout = string.concat(cutout, '</mask>');
        c = string.concat(cutout, background, '<rect width="300" height="360" fill="',string.concat('hsl(',utils.uint2str(ci.backgroundColour),',70%,50%)'),'" mask="url(#eyes',utils.uint2str(_tokenId),')"/>');

        return c;
    }

    function generateEye(bytes memory hash, uint colour, uint i, uint j, bool open, bool ownEye) internal pure returns (string memory) {
        PupilStorage memory p;
        p.offsetx = utils.toUint8(hash, (i+1)*(j+1))/16; // 0 - 15
        p.offsety = utils.toUint8(hash, 32-(i+1)*(j+1))/16; // 0 - 15
        p.r = 6+utils.toUint8(hash, i*5+j+1)/64;
        p.xmidPoint = j*60;
        p.ymidPoint = i*60;
       
        string memory background = svg.rect(string.concat(
            svg.prop('width', '60'),
            svg.prop('height', '60'),
            svg.prop('x', utils.uint2str(p.xmidPoint)),
            svg.prop('y', utils.uint2str(p.ymidPoint)),
            svg.prop('fill', string.concat('hsl(',utils.uint2str(colour),',70%,50%)'))
        ));
       
        string memory eye;

        if(open == true) {
            eye = generatePupil(p, colour, ownEye);
        }

        return string.concat(
                background,
                eye,
                borders(i, j)
        );  

    }

    function generatePupil(PupilStorage memory p, uint colour, bool ownEye) internal pure returns (string memory) {
        string memory props = string.concat(
            svg.prop('r', '9'),
            svg.prop('cx',utils.uint2str(23+p.offsetx+p.xmidPoint)),
            svg.prop('cy',utils.uint2str(23+p.offsety+p.ymidPoint)),
            svg.prop('stroke-width', '7'),
            svg.prop('stroke', string.concat('hsl(',utils.uint2str(colour+180),',70%,50%)')),
            svg.prop('fill', 'black')
        );

        if(ownEye) {
            props = string.concat(
                props,
                svg.prop('stroke-dasharray', '1')
            );
        }

        return svg.el('circle', props);
    }

    function borders(uint i, uint j) internal pure returns (string memory) {
        string memory circles;

        circles = string.concat(circles, svg.el('circle', string.concat(
                    svg.prop('r', '30'),
                    svg.prop('cx',utils.uint2str(30+j*60)),
                    svg.prop('cy',utils.uint2str(45+i*60)),
                    svg.prop('fill', 'none'),
                    svg.prop('stroke','black'),
                    svg.prop('stroke-width', '5')
                )
            )
        );

        circles = string.concat(circles, svg.el('circle', string.concat(
                    svg.prop('r', '30'),
                    svg.prop('cx',utils.uint2str(30+j*60)),
                    svg.prop('cy',utils.uint2str(15+i*60)),
                    svg.prop('fill', 'none'),
                    svg.prop('stroke','black'),
                    svg.prop('stroke-width', '5')
                )
            )   
        );

        return circles;
    }

    function eyeCutout(uint i, uint j, bool open) internal pure returns (string memory) {
        // top circle
        string memory circles;

        string memory topStrokeFill = "none";
        if(open == true) { topStrokeFill = "black"; }

        circles = string.concat(circles, svg.el('circle', string.concat(
                    svg.prop('r', '30'),
                    svg.prop('cx',utils.uint2str(30+j*60)),
                    svg.prop('cy',utils.uint2str(45+i*60)),
                    svg.prop('fill', 'black'),
                    svg.prop('clip-path','url(#keepTop)'),
                    svg.prop('stroke', topStrokeFill),
                    svg.prop('stroke-width', '5'),
                    svg.prop('stroke-dashoffset', '1.5'), // not 100% accurate, but close enough
                    svg.prop('stroke-dasharray', '2') // eyelash  
                )
            )
        );

        // bottom circle
        circles = string.concat(circles, svg.el('circle', string.concat(
                    svg.prop('r', '30'),
                    svg.prop('cx',utils.uint2str(30+j*60)),
                    svg.prop('cy',utils.uint2str(15+i*60)),
                    svg.prop('fill', 'black'),
                    svg.prop('clip-path','url(#keepBottom)'),
                    svg.prop('stroke', 'black'),
                    svg.prop('stroke-width', '5'),
                    svg.prop('stroke-dasharray', '2') // eyelash  
                )
            )   
        );

        // add line:
        // there's an odd bug on chrome where it somehow renders a thin border/line to the clip-path.
        // so this basically just lays out a line over this middle and also connects the eyes for a stronger grid-like effect.
        circles = string.concat(circles,
            '<line x1="',utils.uint2str(j*60),'" y1="',utils.uint2str(30+i*60),'" x2="',utils.uint2str(j*60+60),'" y2="',utils.uint2str(30+i*60),'" stroke="black" />'
        );

        return circles;
    }

    function text(uint tokenId) internal view returns (string memory) {
        Witness.Day memory d;
        (d.logged, d.day, d.wordCount, d.words, d.extra) = witness.dayss(tokenId);
        string memory t = string.concat('<text x="10" y="380" fill="white" font-family="Courier" font-size="8">day ',utils.uint2str(tokenId+1),' (timestamped: ',utils.uint2str(d.logged),')</text><text y="390" x="10" fill="white" font-family="Courier" font-size="8">',d.wordCount,' total words written</text><text y="400" x="10" fill="white" font-family="Courier" font-size="8">');
        t = string.concat(t, d.words, '</text>');
        return t;
    }

    // note: designed originally with help from zond.eth
    function distortFilter() internal pure returns (string memory) {
       return '<filter id="noise-filter" x="-20%" y="-20%" width="140%" height="140%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="linearRGB"><feTurbulence type="fractalNoise" baseFrequency="3" numOctaves="1" seed="1" stitchTiles="stitch" x="0%" y="0%" width="100%" height="100%" result="turbulence"/><feSpecularLighting surfaceScale="5" specularConstant="100" specularExponent="100" lighting-color="#ffffff" x="0%" y="0%" width="100%" height="100%" in="turbulence" result="specularLighting"><feDistantLight azimuth="1" elevation="90"/></feSpecularLighting> </filter><rect width="300" height="360" fill="white" opacity="0.2" filter="url(#noise-filter)"/>';
    }

    /*helper*/
    // via: https://ethereum.stackexchange.com/questions/2519/how-to-convert-a-bytes32-to-string
    /*function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }*/
}