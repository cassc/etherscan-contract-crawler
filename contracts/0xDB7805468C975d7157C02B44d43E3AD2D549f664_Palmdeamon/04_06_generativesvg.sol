pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

//mapfunction example moisture: 411,300,1000,3600,5600   mapfactor: 1000
// moisture: 1013, temperature: 20.125,

contract GenerativeSvg {
    using Strings for string;

    string internal header =
        "<?xml version='1.0' encoding='UTF-8'?><svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' x='0px' y='0px' width='480px' height='740px' viewBox='0 0 480 740' enable-background='new 0 0 480 740' xml:space='preserve'>";
    string internal background =
        "<rect y='140' fill='#141414' width='480' height='500'/>";

    uint256 mapfactor;
    mapping(uint256 => colorscheme) cschemes;

    struct colorscheme {
        string firsthex;
        string secondhex;
        string venue;
        string plant;
        string curator;
    }

    constructor() {
        cschemes[0].firsthex = "#f63f3c";
        cschemes[0].secondhex = "#13b9bc";
        cschemes[0].venue = "Art Dubai";
        cschemes[0].plant = "Dypsis lutescens";
        cschemes[0].curator = "Fingerprints DAO";

        cschemes[1].firsthex = "#ffea00";
        cschemes[1].secondhex = "#481249";

        cschemes[2].firsthex = "#167d5e";
        cschemes[2].secondhex = "#5e67b0";

        mapfactor = 100;
    }

    function mapvalue(
        uint256 value,
        uint256 leftMin,
        uint256 leftMax,
        uint256 rightMin,
        uint256 rightMax
    ) public view returns (uint256) {
        uint256 leftSpan = leftMax - leftMin;
        uint256 rightSpan = rightMax - rightMin;
        uint256 s = (value - leftMin) * mapfactor;
        uint256 valueScaled = s / uint256(leftSpan);
        return rightMin + (valueScaled * rightSpan) / mapfactor;
    }

    function _generatecolorprofile(
        uint256 profile,
        string memory firsthex,
        string memory secondhex,
        string memory venue,
        string memory plant,
        string memory curator
    ) internal {
        cschemes[profile].firsthex = firsthex;
        cschemes[profile].secondhex = secondhex;
        cschemes[profile].venue = venue;
        cschemes[profile].plant = plant;
        cschemes[profile].curator = curator;
    }

    function buildhsl(uint256 temp, uint256 moisture)
        internal
        view
        returns (string memory)
    {
        string memory h = Strings.toString(
            mapvalue(moisture, 70000, 80000, 0, 360)
        );
        string memory l = Strings.toString(
            mapvalue(temp, 19000, 23000, 50, 100)
        );
        return string(abi.encodePacked("hsl(", h, ",100%,", l, "%)"));
        //= 'hsl(0, 100%, 50%)';
    }

    function gradienty(uint256 temp) internal view returns (string memory) {
        return Strings.toString(mapvalue(temp, 19000, 23000, 300, 1000));
    }

    function gradientx(uint256 moisture) internal view returns (string memory) {
        return Strings.toString(mapvalue(moisture, 70000, 80000, 50, 700));
    }

    function gradientz(uint256 moisture) internal view returns (string memory) {
        return Strings.toString(mapvalue(moisture, 70000, 80000, 100, 500));
    }

    function lineargradienty(uint256 temp, uint256 locationcolor)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<linearGradient id='SVGID_1_' gradientUnits='userSpaceOnUse' x1='180.0005' y1='",
                    gradienty(temp),
                    "' x2='180.0005' y2='160.0005'> <stop  offset='0' style='stop-color:",
                    cschemes[locationcolor].secondhex,
                    ";stop-opacity:0'/><stop  offset='0.5' style='stop-color:",
                    cschemes[locationcolor].secondhex,
                    "'/> <stop  offset='1' style='stop-color:",
                    cschemes[locationcolor].secondhex,
                    ";stop-opacity:0'/></linearGradient> <rect y='160' fill='url(#SVGID_1_)' width='360' height='480'/>"
                )
            );
    }

    function lineargradientx(uint256 moisture, uint256 locationcolor)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<linearGradient id='SVGID_2_' gradientUnits='userSpaceOnUse' x1='0' y1='400' x2='",
                    gradientx(moisture),
                    "' y2='400'><stop  offset='0' style='stop-color:",
                    cschemes[locationcolor].firsthex,
                    ";stop-opacity:0'/><stop  offset='0.5' style='stop-color:",
                    cschemes[locationcolor].firsthex,
                    "'/> <stop  offset='1' style='stop-color:",
                    cschemes[locationcolor].firsthex,
                    ";stop-opacity:0'/></linearGradient> <rect y='160' fill='url(#SVGID_2_)' width='360' height='480'/>"
                )
            );
    }

    function lineargradientz(uint256 temp, uint256 moisture)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<linearGradient id='SVGID_3_' gradientUnits='userSpaceOnUse' x1='220.0225' y1='329.4453' x2='",
                    gradientz(moisture),
                    "' y2='219.445' gradientTransform='matrix(3.6 0 0 3.6 -684.0762 -606)'> <stop  offset='0' style='stop-color:",
                    buildhsl(temp, moisture),
                    ";stop-opacity:0'/> <stop  offset='1' style='stop-color:",
                    buildhsl(temp, moisture),
                    "'/> </linearGradient> <rect y='220' fill='url(#SVGID_3_)' width='360.001' height='360'/>"
                )
            );
    }

    function returnfixtext() internal pure returns (string memory) {
        return
            "<text transform='matrix(1 0 0 1 10 185.2061)' font-family='Arial' font-size='16'>Soil Moisture (x-axis)</text><text transform='matrix(1 0 0 1 10 141.4561)' font-family='Arial' font-size='16'>Time</text><text transform='matrix(1 0 0 1 10 605.2061)' font-family='Arial' font-size='16'>Plant</text><text transform='matrix(1 0 0 1 10 651.4561)' font-family='Arial' font-size='16'>Location</text><text transform='matrix(1 0 0 1 250 185.2061)' font-family='Arial' font-size='16'>Temperature (y-axis)</text><text transform='matrix(1 0 0 1 427.0029 241.4556)' fill='#EBEBEB' font-family='Arial' font-size='16'>terra0</text><text transform='matrix(1 0 0 1 9 80.7349)' fill='#141414' font-family='Times-Roman, Times' font-size='45'>Certificate of Growth </text>";
    }

    function buildpercentage(uint256 percentage)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    Strings.toString((percentage % 100000) / 1000),
                    ",",
                    Strings.toString((percentage % 1000) / 10)
                )
            );
    }



    function xypoint(uint256 moisture, uint256 temperature)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 ",
                    Strings.toString(mapvalue(moisture, 70000, 80000, 0, 335)),
                    " ",
                    Strings.toString(
                        580 -
                            (mapvalue(temperature, 19000, 23000, 245, 580) -
                                245)
                    ),
                    ")' fill='#EBEBEB' font-family='Courier, monospace' font-size='40'>+</text>"
                )
            );
    }

    function buildmoisture(uint256 moisture)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 9 205.3359)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    buildpercentage(moisture),
                    "%</text>"
                )
            );
    }

    function buildtemperature(uint256 temperature)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 249 205.3364)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    buildpercentage(temperature),
                    "C</text>"
                )
            );
    }

    function buildlocation(uint256 colorpointer)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 10 671.5859)'><tspan x='0' y='0' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    cschemes[colorpointer].venue,
                    "</tspan><tspan x='0' y='20' fill='#141414' font-family='Courier' font-size='24'>",
                    cschemes[colorpointer].curator,
                    "</tspan></text>"
                )
            );
    }

    function buildtokennumber(uint256 tokenid)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 412.3906 80)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    Strings.toString(tokenid),
                    "</text>"
                )
            );
    }

    function buildbars(uint256 moisture, uint256 temp)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 360 ",
                    Strings.toString(
                        650 - mapvalue(moisture, 70000, 80000, 250, 390)
                    ),
                    ")' fill='#EBEBEB' font-family='Courier, monospace' font-size='49'>_</text>",
                    "<text transform='matrix(1 0 0 1 390 ",
                    Strings.toString(
                        650 - mapvalue(temp, 19000, 23000, 250, 390)
                    ),
                    ")' fill='#EBEBEB' font-family='Courier, monospace' font-size='49'>_</text>"
                )
            );
    }

    function returndynamictext(
        uint256 moisture,
        uint256 temp,
        uint256 locationcolor,
        string memory humantimestamp,
        uint256 tokenid
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    buildtemperature(temp),
                    buildmoisture(moisture),
                    buildlocation(locationcolor),
                    "<text transform='matrix(1 0 0 1 10 625.3359)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    cschemes[locationcolor].plant,
                    "</text>",
                    buildtokennumber(tokenid),
                    "<text transform='matrix(1 0 0 1 10 161.5859)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    humantimestamp,
                    "</text>"
                )
            );
    }

    function generatebars() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<linearGradient id='SVGID_4_' gradientUnits='userSpaceOnUse' x1='405' y1='580' x2='405' y2='220.1191'> <stop  offset='0' style='stop-color:#00FF00'/> <stop  offset='1' style='stop-color:#C2000B'/> </linearGradient> <rect x='390' y='220.119' fill='url(#SVGID_4_)' width='30' height='359.881'/><linearGradient id='SVGID_5_' gradientUnits='userSpaceOnUse' x1='375' y1='580' x2='375' y2='220.1191'> <stop  offset='0' style='stop-color:#141414'/> <stop  offset='1' style='stop-color:#00A0C6'/> </linearGradient>",
                    "<path opacity='0.25' fill='none' stroke='#EBEBEB' stroke-width='2' stroke-miterlimit='10' d='M300,220v360 M240,220v360 M180,220 v360 M120,220v360 M60,220v360 M360,520H0 M360,460H0 M360,400H0 M360,340H0 M360,280H0'/><rect x='360' y='260' opacity='0.25' fill='#EBEBEB' width='30' height='120'/><rect x='390' y='240' opacity='0.25' fill='#EBEBEB' width='30' height='160'/>",
                    "<rect x='360' y='220.119' fill='url(#SVGID_5_)' width='30' height='359.881'/>"
                )
            );
    }

    function generatesvg(
        uint256 moisture,
        uint256 temp,
        uint256 locationcolor,
        string memory humantimestamp,
        uint256 id
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    header,
                    background,
                    generatebars(),
                    lineargradienty(temp, locationcolor),
                    lineargradientx(moisture, locationcolor),
                    lineargradientz(temp, moisture),
                    "<path fill='#EBEBEB' d='M0,580v160h480V580H0z'/> <path fill='#EBEBEB' d='M0,0v220h480V0H0z'/>",
                    "<path opacity='0.25' fill='none' stroke='#EBEBEB' stroke-width='2' stroke-miterlimit='10' d='M300,220v360 M240,220v360 M180,220v360 M120,220v360 M60,220v360 M360,520H0 M360,460H0 M360,400H0 M360,340H0 M360,280H0'/>",
                    returnfixtext(),
                    returndynamictext(
                        moisture,
                        temp,
                        locationcolor,
                        humantimestamp,
                        id
                    ),
                    xypoint(moisture, temp),
                    buildbars(moisture, temp),
                    "</svg >"
                )
            );
    }

    function getsvgbase64(
        uint256 moisture,
        uint256 temperature,
        uint256 locationcolor,
        string memory humantimestamp,
        uint256 id
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            generatesvg(
                                moisture,
                                temperature,
                                locationcolor,
                                humantimestamp,
                                id
                            )
                        )
                    )
                )
            );
    }
}