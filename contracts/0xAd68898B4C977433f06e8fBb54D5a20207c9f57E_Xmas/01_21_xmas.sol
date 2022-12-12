pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
// https://donate-xmas.com/
/*

                                         _«φ≥»_
                                ___       ;░▒[      ____
                           __ _           _▓▓_           _____
                        _           __   _▓▓▓▓_                __
                     _                  ╓▓▓▓▓▓▓╖_   ⁿ _           __
                  _         _       _▄▄▓▓╟▓▀▒▓▓▓▓▄▄__               __
                                     ╓▓█▓██▓▓██▓█▓▄                    _
               _                     _▓██████████▓__                    __
             _                     ,▄▓▓▓▓▓▓▓╬▓▀▓███▓M_     _              _
                      __          ▄▓███▓██▓▓█████▓▓▓▓ç__             _
           _                    └█████╣▓╣██████▒│╟█████─  _                 _
                            __  _▄▓██████████████████▓▄_ _                   _
               _                ___█████████▓█▓██████─_           _           _
         _                       ,▓███▓▓▓▓████████████_          __
                               ▀██████████████████▓████▓▄µ                     _
                      _--     ╓▓█████████▀░███████▓▓█████,_  _          _      _
                       _   "▀████████████▄▄████▓█████▓█████▀^                  _
        _                     ▀█████▓█▓▀█████████████████▀                     _
        _        _           ▄████████████▓▓▓▓████████████▄     ]~
                         "▓█████████▓███████████████▓████████▄  _
         _          ╓▄▄▄▓██▓█▓▓████╬▓█████████████████╬█████████▄▄▄,
         _          _'╙╙▀████▓███▓▓▀███▓█████▀░╠██████▓████████▀╙╙'_
          _            _▓█▀███████████▓███████▓▓█████████████▀▀█_  _
           _     'φ╓φ#_   ╙└└__▀▀▀▓████▀╝▀████▀▌╙▀████▀▀▀__└└╙╓▄_ ╓▄_       _
                 ╟▓▒╬▓▒       _ ,_''_  __j████⌐__ __ _       ╓╠╬╫▓╬╬╓_     _
             __  ╫▓▒╣▓L     ]▄▓▓▓▄⌐  α_▀███▓▓███▀            _▒▒╟▓╬▒╠
              _  ╣▓▒╣▓▌  ,╠▒φ╬▓▓▓╣  ▀▓╬▓▓▓▓▓▓▓▓▓▒▓▓⌐______   ]▒╠║▓╬╠╠_
         ,-»≤≤≤╫▓╣╣▓▓╣▓▓▓▓▓╬╟▓▓▓▓▓,,║▓╬╫▓▓▓▓▓▓▓▓╣▓▓▓▓▓╫╫╫╫╥╓,{▒╠╟▓╬▒╬╓╓▄▄≥≥≤»,,_
       _"=░││││║▓╣▓▓▓▓╣▓▓▓╫▒║╫╫▓▓▌│'▓▓╬╫▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬▒╬╬▒╠▒╟╣╬╬╬▓╣╬▓▌│││││Γ^
           _ __  `░││││││╚▀▀╝▀▀││││││││││││││░╙╙╙╙╙╙╙╙╙╙╙╙╙╙'││'└└│└└│ _ ____
                  __   ``"""""""ⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿ==ⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿ""""""``   _
*/

import "./ERC721Tradable.sol";

/**
 * @title Donate-Xmas
 */
contract Xmas is ERC721Tradable {


    struct NGO {
        address addr;
        string  name;
    }

    struct ICON {
        string name;
        string part_1;
        string part_2;
        string part_3;
        string part_4;
        string part_5;
        uint256 min_donation;
    }

    event new_NGO  (uint256 NGO_id );
    event new_ICON (uint256 icon_id);
    event new_COLOR(uint256 color_id);

    mapping (uint256 => string ) internal DONAs;
    mapping (uint256 => ICON   ) public   ICONs;
    mapping (uint256 => NGO    ) public   NGOs;
    mapping (uint256 => string ) public   COLORs;
    uint256 public number_of_NGOs;
    uint256 public number_of_icons;
    uint256 public number_of_colors;

    using strings for *;

    constructor(address _proxyRegistryAddress) ERC721Tradable("DonateXMas", "XMAS", _proxyRegistryAddress) {

        DONAs[   10000000000000000] = " 0.01";
        DONAs[   50000000000000000] = " 0.05";
        DONAs[  100000000000000000] = " 0.1";
        DONAs[  250000000000000000] = " 0.25";
        DONAs[  500000000000000000] = " 0.5";
        DONAs[ 1000000000000000000] = " 1";
        DONAs[ 5000000000000000000] = " 5";
        DONAs[10000000000000000000] = "10";

        // Icons

            ICONs[1] = ICON("Star 1",
                '<g transform="translate(100 470.37)" fill="',
                '"><circle cx="770.37" cy="29.63" r="29.63"/><circle cx="29.63" cy="29.63" r="29.63"/></g><g transform="translate(470.37 100)" fill="',
                '"><circle cx="29.63" cy="29.63" r="29.63"/><circle cx="29.63" cy="770.37" r="29.63"/></g><path fill="',
                '" d="m499.94 159.2 60.993 193.492 179.948-93.691-93.693 179.947 193.494 60.992-193.493 60.993L740.88 740.88l-179.948-93.692-60.992 193.493-60.993-193.493L259 740.88l93.692-179.948L159.2 499.94l193.492-60.993L259.001 259l179.947 93.692z"/><path fill="',
                '" />',
                100000000000000
            );

            ICONs[2] = ICON("Mountains",
                '<path fill="',
                '" d="m400 0 400 400H0z" transform="translate(100 100)"/><path fill="',
                '" d="m400 400 400 400H0z" transform="translate(100 100)"/><path d="m400 0 200 200H200L400 0ZM266.666 266.4 200 200h133.334l-66.667 66.4Zm266.668 0L466.667 200h133.334l-66.667 66.4ZM400 266.4 333.334 200h133.332L400 266.4Z" fill="',
                '" transform="translate(100 100)"/><path d="m400 400 200 200H200l200-200ZM266.666 666.4 200 600h133.334l-66.667 66.4Zm266.668 0L466.667 600h133.334l-66.667 66.4ZM400 666.4 333.334 600h133.332L400 666.4Z" fill="',
                '" transform="translate(100 100)"/>',
                100000000000000
            );

            ICONs[3] = ICON("Tree 1",
                '<g transform="translate(100 100)"><path fill="',
                '" d="m400 0 400 652H0z"/><circle fill="',
                '" cx="399.6" cy="726" r="74"/></g><path fill="',
                '" /><path fill="',
                '" />',
                100000000000000
            );

            ICONs[4] = ICON("Hat",
                '<g transform="translate(100 100)"><path fill="',
                '" d="m400 148.217 400 503.937H0z"/><ellipse fill="',
                '" cx="400" cy="74.109" rx="74.074" ry="74.109"/><path fill="',
                '" d="M.37 652.525h799.26V800H.37z"/></g><path fill="',
                '"/>',
                100000000000000
            );

            ICONs[5] = ICON("Tree 2",
                '<g transform="translate(100.000000, 100.000000)"><polygon fill="',
                '" points="400 59.2 800 244 0 244"></polygon><polygon fill="',
                '" points="400 429.6 800 615.2 0 615.2"></polygon><path d="M400,244.8 L800,430.4 L0,430.4 L400,244.8 Z M400,615.2 L800,800 L0,800 L400,615.2 Z" fill="',
                '"></path><circle fill="',
                '" cx="399.2" cy="29.6" r="29.6"></circle></g>',
                100000000000000
            );

            ICONs[6] = ICON("Snowman",
                '<g transform="translate(100 100)"><circle fill="',
                '" cx="400.8" cy="200" r="200"/><path fill="',
                '" d="M600.8 200.4 400 237.6v-74.4z"/><path d="M800 800H0c0-27.13 2.72-54.19 8.126-80.775a399.03 399.03 0 0 1 60.188-143.316 401.281 401.281 0 0 1 175.988-145.212 397.432 397.432 0 0 1 75.083-23.355 403.116 403.116 0 0 1 161.228 0 397.385 397.385 0 0 1 143.03 60.306C734.062 542.181 800.173 666.768 800 800Z" fill="',
                '"/></g><path fill="',
                '" />',
                100000000000000
            );

            ICONs[7] = ICON("Snow 1",
                '<g transform="translate(300 100)" fill="',
                '"><circle transform="rotate(90 400 400)" cx="400" cy="400" r="200"/><circle cx="200" cy="200" r="200"/></g><g transform="translate(100 300)" fill="',
                '"><circle transform="rotate(90 200 200)" cx="200" cy="200" r="200"/><circle cx="400" cy="400" r="200"/></g><path fill="',
                '"/><path fill="',
                '"/>',
                100000000000000
            );

            ICONs[8] = ICON("Ball 1",
                '<g transform="translate(100 100)"><circle fill="',
                '" cx="400" cy="400" r="400"/><path d="M800 400C800 179.086 620.914 0 400 0S0 179.086 0 400c0 .8 800 .8 800 0Z" fill="',
                '"/></g><path fill="',
                '" /><path fill="',
                '" />',
                100000000000000
            );

            ICONs[9] = ICON("Tree 3",
                '<path fill="',
                '" d="M902 1000 662.861 624.68h72.317L500.494 285 265.822 624.68h72.317L99 1000z"/><g transform="translate(176 124)" fill="',
                '"><path d="m331.903 4.966 14.365 29.101a8.819 8.819 0 0 0 6.677 4.812l32.123 4.668a8.879 8.879 0 0 1 4.909 15.134L366.733 81.37a8.914 8.914 0 0 0-2.551 7.855l5.486 31.988a8.854 8.854 0 0 1-12.8 9.348l-28.731-15.098a8.88 8.88 0 0 0-8.266 0l-28.73 15.098a8.856 8.856 0 0 1-12.861-9.348l5.486-31.988a8.89 8.89 0 0 0-2.563-7.855l-23.232-22.653a8.866 8.866 0 0 1 4.909-15.134l32.123-4.668a8.819 8.819 0 0 0 6.677-4.812l14.281-29.137a8.879 8.879 0 0 1 15.942 0Z"/><ellipse cx="429.788" cy="613.112" rx="37.212" ry="37.209"/><ellipse cx="37.212" cy="714.791" rx="37.212" ry="37.209"/></g><g transform="translate(345 399)" fill="',
                '"><ellipse cx="37.242" cy="37.239" rx="37.242" ry="37.239"/><ellipse cx="155.697" cy="172.89" rx="37.242" ry="37.239"/><ellipse cx="49.186" cy="338.002" rx="37.242" ry="37.239"/><ellipse cx="440.758" cy="439.761" rx="37.242" ry="37.239"/></g><g transform="translate(462 399)" fill="',
                '"><ellipse cx="143.789" cy="37.258" rx="37.211" ry="37.258"/><ellipse cx="37.211" cy="497.742" rx="37.211" ry="37.258"/></g>',
                100000000000000
            );
            ICONs[9] = ICON("Tree 3",
                '<path fill="',
                '" d="M902 1000 662.861 624.68h72.317L500.494 285 265.822 624.68h72.317L99 1000z"/><g transform="translate(176 124)" fill="',
                '"><path d="m331.903 4.966 14.365 29.101a8.819 8.819 0 0 0 6.677 4.812l32.123 4.668a8.879 8.879 0 0 1 4.909 15.134L366.733 81.37a8.914 8.914 0 0 0-2.551 7.855l5.486 31.988a8.854 8.854 0 0 1-12.8 9.348l-28.731-15.098a8.88 8.88 0 0 0-8.266 0l-28.73 15.098a8.856 8.856 0 0 1-12.861-9.348l5.486-31.988a8.89 8.89 0 0 0-2.563-7.855l-23.232-22.653a8.866 8.866 0 0 1 4.909-15.134l32.123-4.668a8.819 8.819 0 0 0 6.677-4.812l14.281-29.137a8.879 8.879 0 0 1 15.942 0Z"/><ellipse cx="429.788" cy="613.112" rx="37.212" ry="37.209"/><ellipse cx="37.212" cy="714.791" rx="37.212" ry="37.209"/></g><g transform="translate(345 399)" fill="',
                '"><ellipse cx="37.242" cy="37.239" rx="37.242" ry="37.239"/><ellipse cx="155.697" cy="172.89" rx="37.242" ry="37.239"/><ellipse cx="49.186" cy="338.002" rx="37.242" ry="37.239"/><ellipse cx="440.758" cy="439.761" rx="37.242" ry="37.239"/></g><g transform="translate(462 399)" fill="',
                '"><ellipse cx="143.789" cy="37.258" rx="37.211" ry="37.258"/><ellipse cx="37.211" cy="497.742" rx="37.211" ry="37.258"/></g>',
                100000000000000
            );

            ICONs[10] = ICON("Skate",
                '<g transform="translate(217 344)" fill="',
                '"><circle cx="541" cy="26" r="26"/><circle cx="26" cy="26" r="26"/><path d="M399.177 508a6.815 6.815 0 0 0-6.81 6.82c-.007 7.476-6.058 13.535-13.525 13.541H369.2v-15.038h-13.61v15.038h-40.983v-15.038h-13.621v15.038H289.81a6.815 6.815 0 0 0-6.811 6.82c0 3.766 3.05 6.819 6.81 6.819h89.044c14.987-.013 27.133-12.175 27.146-27.18 0-1.811-.72-3.548-1.999-4.827a6.806 6.806 0 0 0-4.824-1.993Zm-287.525-24.954a6.744 6.744 0 0 0-3.386-3.9 6.705 6.705 0 0 0-5.142-.35c-7.011 2.349-14.595-1.435-16.961-8.463l-3.018-9.061 14.099-4.788-4.294-12.832-14.087 4.788-12.93-38.58 14.087-4.787-4.294-12.82-14.086 4.788-3.543-10.522c-1.223-3.488-5.011-5.343-8.503-4.165-3.493 1.178-5.395 4.953-4.271 8.474l28.065 83.79c4.733 14.113 19.963 21.71 34.03 16.974 3.515-1.193 5.408-5.013 4.234-8.546Z"/></g><path d="M507 610h55v180h-55zM342.248 764 326 712.236l23.904-7.527c47.645-15.093 82.149-56.61 88.332-106.289V598L492 604.627l-.06.432c-8.801 70.766-57.945 129.91-125.812 151.414L342.248 764ZM436 324.154V205.878L577 205v119.202c0 39.1-31.564 70.798-70.5 70.798a70.338 70.338 0 0 1-49.871-20.75c-13.224-13.288-20.645-31.31-20.629-50.096Z" fill="',
                '"/><path d="M561.962 785v28.74c20.25 3.8 35.65 21.786 35.994 43.516l.006.744h-55v-1h-36v-72h55Zm-205.81-82.984 17.994 52.493-26.884 9.215a44.372 44.372 0 0 1-29.027 48.069l-.546.19-11.694-34.115-.002.002L288 725.377l68.153-23.36ZM438.49 343a70.85 70.85 0 0 0 18.1 31.25A70.338 70.338 0 0 0 506.463 395l1.166-.01c31.942-.52 58.72-22.372 66.822-51.99h135.512v67.836H595.324V613H412.56V410.836H292.962V343H438.49Zm69.297-229 1.12.009c36.889.57 67.446 28.938 70.53 65.71 6.101 1.074 10.543 6.368 10.525 12.545v13.048c0 7.007-5.698 12.688-12.727 12.688H437.69a12.747 12.747 0 0 1-9-3.716 12.669 12.669 0 0 1-3.728-8.972v-13.048c-.029-6.43 4.775-11.862 11.176-12.64 3.162-37.106 34.295-65.62 71.65-65.624Z" fill="',
                '"/><g transform="translate(258 218)" fill="',
                '"><rect x="452" y="118" width="35" height="79" rx="8.91"/><rect y="118" width="35" height="79" rx="8.91"/><path d="M197 0v14.294C197 42.07 222.142 67 250.196 67h-.06C278.19 67 300 42.07 300 14.294V.012L197 0Zm52 217c5.523 0 10-4.477 10-10s-4.477-10-10-10-10 4.477-10 10 4.477 10 10 10Zm.012 21a10 10 0 1 0 9.988 9.988 10 10 0 0 0-9.988-9.988ZM249 280c-5.523 0-10 4.477-10 10s4.477 10 10 10 10-4.477 10-10c-.007-5.52-4.48-9.993-10-10Z"/></g><g transform="translate(484 233)"><circle cx="7.5" cy="7.5" r="7.5"/><circle cx="41.5" cy="7.5" r="7.5"/></g>',
                100000000000000
            );

            ICONs[11] = ICON("Gifts",
                '<path fill="',
                '" d="M168.84 0H497.2v561.28H168.84z" transform="translate(251.4 219.77)"/><path fill="',
                '" d="M0 234.95h337.68v326.32H0z" transform="translate(251.4 219.77)"/><path d="M204.6 353.32V235.06c30.244-12.925 45.377-47.008 34.68-78.11a62.7 62.7 0 0 0-64.77 15 63.46 63.46 0 0 0-5.65 6.48 63.46 63.46 0 0 0-5.65-6.48 62.7 62.7 0 0 0-64.77-15c-10.697 31.102 4.436 65.185 34.68 78.11v118.26H0v71.48h133.1v136.43h71.5V424.8h133.1v-71.48H204.6Z" fill="',
                '" transform="translate(251.4 219.77)"/><path d="M412.2 110.1a41.89 41.89 0 0 0 29.65-51.32 41.9 41.9 0 0 0-51.33 29.64 41.88 41.88 0 0 0-51.32-29.64 41.87 41.87 0 0 0 29.65 51.32 41.89 41.89 0 0 0-29.65 51.33 41.89 41.89 0 0 0 51.32-29.65 41.91 41.91 0 0 0 51.33 29.65 41.91 41.91 0 0 0-29.65-51.33Z" fill="',
                '" transform="translate(251.4 219.77)"/>',
                100000000000000
            );

            ICONs[12] = ICON("Glasses",
                '<path d="M388.675 526.155 359.986 514l-68.59 161.446-41.227-17.48L238 686.623l111.132 47.105 12.169-28.645-41.216-17.481zM756.64 753.883l-43.845 9.146-35.86-171.69-30.506 6.363 35.86 171.68-43.833 9.146 6.36 30.472L763 784.355z" fill="',
                '"/><g fill="',
                '"><path d="m416.591 191.014 163.89 69.568-104.75 246.777c-19.214 45.266-71.486 66.386-116.752 47.17-45.246-19.226-66.347-71.485-47.138-116.737l104.75-246.779Z"/><path d="m508.847 299.818 174.311-36.384 54.78 262.445c10.048 48.139-20.831 95.307-68.969 105.355a89.04 89.04 0 0 1-105.354-68.969l-54.78-262.444.012-.002Z"/></g><path d="M363.087 316.992 527 386.57l-51.278 120.802c-19.214 45.266-71.485 66.385-116.752 47.17-45.266-19.214-66.386-71.485-47.171-116.752l51.277-120.8.01.004Z" fill="',
                '"/><path d="m535.582 427.924 174.323-36.386L737.95 525.89c10.038 48.121-20.82 95.272-68.936 105.336a89.04 89.04 0 0 1-105.354-68.969l-28.041-134.341-.036.007Z" fill="',
                '"/>',
                100000000000000
            );

            ICONs[13] = ICON("Snow 2",
                '<path d="M797.86 456.09 786.69 408l-82.94 19.2 33.5-53.74-41.93-26.14L635.69 443l-59.82 13.88a86.73 86.73 0 0 0-27.44-29.43l17.95-58.7 99.55-52.91-23.19-43.63-55.92 29.72 24.9-81.42-47.24-14.45-24.91 81.42-29.73-55.92-43.62 23.19 52.91 99.55-17.95 58.7a86.56 86.56 0 0 0-39.36 9.12l-41.9-44.89 3.88-112.68-49.38-1.7-2.18 63.3-58.1-62.24L278 297.62l58.1 62.24-63.3-2.18-1.7 49.38 112.68 3.88 41.89 44.88a86.66 86.66 0 0 0-11.78 38.65l-59.8 13.88-95.68-59.64-26.14 41.93 53.73 33.5-82.9 19.25 11.17 48.13 82.94-19.25-33.5 53.73 41.93 26.14 59.64-95.68 59.82-13.89A86.53 86.53 0 0 0 452.54 572l-18 58.7L335 683.64l23.19 43.63 55.92-29.73L389.24 779l47.25 14.46 24.9-81.46 29.73 55.93 43.63-23.19-52.92-99.56 18-58.69a86.68 86.68 0 0 0 39.35-9.12l41.91 44.89-3.88 112.68 49.38 1.7 2.18-63.3 58.1 62.24L723 701.86l-58.1-62.25 63.29 2.18 1.7-49.38-112.67-3.87-41.9-44.88A86.5 86.5 0 0 0 587.06 505l59.8-13.88 95.68 59.64 26.13-41.93-53.75-33.51 82.94-19.23Zm-264.21 53.79a34.68 34.68 0 1 1-23-43.31c18.305 5.615 28.6 25 23 43.31Z" fill="',
                '"/><path fill="',
                '"/><path fill="',
                '"/><path fill="',
                '"/>',
                100000000000000
            );

            ICONs[14] = ICON("Gift",
                '<path d="M412.09 733.7v25c-18.429 3.497-31.767 19.603-31.77 38.36h80.59V733.7h-48.82Zm129.65 25.03v-25h-48.82v63.39h80.59c.032-18.776-13.32-34.91-31.77-38.39Zm-67.38-400.01c43.986.006 79.64 35.664 79.64 79.65v194.69H394.71V438.37c0-43.99 35.66-79.65 79.65-79.65Z" fill="',
                '"/><path d="M509 228.14a41.44 41.44 0 1 0-79.8 4A56.776 56.776 0 1 0 476 335.6a56.75 56.75 0 1 0 33-107.46Zm-45.67 582.13h-13.46v-13.18h-12v13.18h-36v-13.18H390v13.18h-4.78c-6.555-.005-11.869-5.315-11.88-11.87a6 6 0 1 0-11.95 0c.017 13.153 10.678 23.81 23.83 23.82h78.12a6 6 0 1 0 0-12l-.01.05Zm123.15-17.85a6 6 0 0 0-6 6c-.005 6.554-5.317 11.865-11.87 11.87h-4.79v-13.2h-11.93v13.18h-36v-13.18H504v13.18h-13.5a6 6 0 0 0 0 12h78.13c13.149-.016 23.804-10.671 23.82-23.82a6 6 0 0 0-5.97-6.03ZM451.7 396.07h163.57v123.37H451.7z" fill="',
                '"/><g transform="translate(429.05 276.32)" fill="',
                '"><path d="M.38 0v36c0 26.82 24 50.89 50.85 50.89 26.82 0 47.66-24.07 47.66-50.89V0H.38Zm83.94 119.75h40.23v123.37H84.32z"/><circle cx="22.65" cy="203.3" r="22.65"/><circle cx="186.22" cy="203.3" r="22.65"/></g><path d="M412.505 633.05h48v105h-48zm129.065 105H493.1v-105h48.47zM429.43 314.21h210.15v89.4H429.43z" fill="',
                '"/><g transform="translate(443.27 294.61)"><circle cx="56.64" cy="6.36" r="6.36"/><circle cx="25.31" cy="6.36" r="6.36"/><circle cx="8.43" cy="79.46" r="8.43"/><path d="M35.39 40.47a8.43 8.43 0 1 0 0 16.86 8.43 8.43 0 0 0 0-16.86Z"/><circle cx="134.65" cy="83.47" r="8.43"/><circle cx="110.74" cy="43.29" r="8.43"/><circle cx="76.19" cy="75.03" r="8.43"/><circle cx="165.89" cy="46.3" r="8.43"/></g>',
                100000000000000
            );

            ICONs[15] = ICON("Candy",
                '<path d="M322.608 849 244 770.477l385.286-384.865a53.03 53.03 0 0 0 14.064-51.411c-4.892-18.416-19.291-32.8-37.727-37.686a53.166 53.166 0 0 0-51.468 14.048l-22.98 22.955-78.595-78.523 22.98-22.942c64.164-64.08 168.184-64.07 232.334.025 64.151 64.095 64.14 168-.025 232.082L322.61 849Z" fill="',
                '"/><path fill="',
                '" d="m492.321 522.428 124.662 32.519-25.974 25.945-124.662-32.519zm255.42-225.813-102.633 52.607a52.972 52.972 0 0 0-1.758-15.021 52.991 52.991 0 0 0-7.227-15.95l98.8-50.646a162.897 162.897 0 0 1 12.818 29.01ZM580.624 184.372l.529 111.486a53.12 53.12 0 0 0-26.998 14.705l-4.59 4.585-.597-125.524a164.925 164.925 0 0 1 31.656-5.252Zm13.392 236.472 136.161 15.649a164.743 164.743 0 0 1-22.308 27.667l-1.47 1.467-140.995-16.202 28.612-28.581ZM284.162 730.359l124.662 32.519-25.973 25.945-124.663-32.519zM388.285 626.35l124.991 32.191-26.066 26.037-124.99-32.192z"/><path fill="',
                '"/><path fill="',
                '"/>',
                100000000000000
            );

            ICONs[16] = ICON("Ball 2",
                '<circle fill="',
                '" cx="500.5" cy="574.5" r="294.5"/><path d="m268.898 393 521.259 232.081c-8.18 48.637-28.282 93.228-57.198 130.664L210 522.906c8.805-48.477 29.477-92.818 58.898-129.906Z" fill="',
                '"/><path d="M727.66 217.564c11.226-25.187 4.347-54.79-16.826-72.403-21.172-17.614-51.451-18.926-74.059-3.208-22.607 15.717-32.005 44.615-22.987 70.679l-16.722-7.52a26.16 26.16 0 0 0-20.069-.583 26.262 26.262 0 0 0-14.6 13.822L534 281.829 696.626 355l28.397-63.464a26.377 26.377 0 0 0 .587-20.135 26.275 26.275 0 0 0-13.788-14.65l-16.707-7.52a61.023 61.023 0 0 0 32.545-31.667Zm-27.242-12.294c-7.117 15.818-25.663 22.866-41.445 15.751s-22.836-25.705-15.764-41.543c7.072-15.838 25.598-22.94 41.4-15.87a31.272 31.272 0 0 1 16.59 17.516 31.394 31.394 0 0 1-.781 24.146Z" fill="',
                '"/><path fill="',
                '"/>',
                100000000000000
            );

            ICONs[17] = ICON("Tree 4",
                '<path fill="',
                '" d="M0 1000h1000V-1H826.307z"/><g transform="translate(429 113)" fill="',
                '"><circle cx="82" cy="716" r="82"/><path d="M571 14.257C536.894-9.04 490.806-3.26 463.488 27.74c-27.317 31-27.317 77.519 0 108.518 27.318 31 73.406 36.78 107.512 13.484V14.257Z"/></g><g transform="translate(418 335)" fill="',
                '"><circle cx="82" cy="82" r="82"/><path d="M582 558.215c-31.26-21.294-73.051-18.415-101.09 6.962-28.04 25.378-35.024 66.645-16.895 99.823H582V558.215Z"/></g><circle fill="',
                '" cx="790" cy="582" r="82"/>',
                100000000000000
            );

            ICONs[18] = ICON("Wreath",
                '<path d="M839.774 512.895a42.555 42.555 0 0 0-20.52-32.228 42.61 42.61 0 0 0 5.806-37.747 42.624 42.624 0 0 0-26.771-27.242 42.623 42.623 0 0 0-2.193-38.139 42.642 42.642 0 0 0-31.872-21.07 42.612 42.612 0 0 0-10.071-36.826 42.634 42.634 0 0 0-35.531-13.987 42.603 42.603 0 0 0-17.47-33.938 42.624 42.624 0 0 0-37.65-6.33 42.583 42.583 0 0 0-24.145-29.613 42.6 42.6 0 0 0-38.177 1.665 42.649 42.649 0 0 0-66.783-14.33 42.569 42.569 0 0 0-34.09-17.11h-.763a42.543 42.543 0 0 0-34.128 17.086 42.534 42.534 0 0 0-36.975-9.655 42.424 42.424 0 0 0-29.897 23.831 42.6 42.6 0 0 0-38.175-1.767 42.583 42.583 0 0 0-24.225 29.55 42.65 42.65 0 0 0-37.677 6.239 42.629 42.629 0 0 0-17.569 33.902 42.609 42.609 0 0 0-35.587 13.88 42.587 42.587 0 0 0-10.154 36.818 42.591 42.591 0 0 0-31.924 20.972 42.572 42.572 0 0 0-2.268 38.123 42.624 42.624 0 0 0-26.874 27.178 42.61 42.61 0 0 0 5.718 37.786 42.626 42.626 0 0 0-7.128 67.86 42.626 42.626 0 0 0 7.065 67.873 42.649 42.649 0 0 0-5.744 37.768 42.662 42.662 0 0 0 26.81 27.221 42.661 42.661 0 0 0 2.272 38.123 42.68 42.68 0 0 0 31.882 21.036 42.561 42.561 0 0 0 10.107 36.813 42.583 42.583 0 0 0 35.559 13.91 42.578 42.578 0 0 0 17.49 33.937 42.599 42.599 0 0 0 37.667 6.281 42.583 42.583 0 0 0 24.23 29.67 42.6 42.6 0 0 0 38.27-1.8 42.636 42.636 0 0 0 66.808 14.24A42.708 42.708 0 0 0 499.137 890a42.518 42.518 0 0 0 34.104-17.048 42.636 42.636 0 0 0 66.846-14.075 42.65 42.65 0 0 0 38.203 1.807 42.634 42.634 0 0 0 24.285-29.538 42.637 42.637 0 0 0 37.663-6.217 42.616 42.616 0 0 0 17.583-33.874 42.621 42.621 0 0 0 35.551-13.868 42.6 42.6 0 0 0 10.191-36.766 42.642 42.642 0 0 0 31.951-20.937 42.623 42.623 0 0 0 2.355-38.12 42.586 42.586 0 0 0 26.89-27.148 42.573 42.573 0 0 0-5.709-37.778 42.614 42.614 0 0 0 7.23-67.873 42.55 42.55 0 0 0 13.494-35.67ZM386.32 548.019c-.006-45.781 27.575-87.057 69.88-104.58 42.306-17.522 91.003-7.839 123.383 24.534 32.38 32.372 42.064 81.058 24.538 123.353-17.526 42.296-58.811 69.87-104.603 69.865-62.515-.007-113.191-50.672-113.198-113.172Z" fill="',
                '"/><g transform="translate(206 225)" fill="',
                '"><path d="m353 143-58.5-38.304L236 143V0h117z"/><circle cx="306" cy="568" r="31"/><circle cx="31" cy="351" r="31"/></g><g transform="translate(302 110)" fill="',
                '"><path d="M333 0 197.5 63.33 62 0v190l135.5-63.33L333 190z"/><circle cx="31" cy="621" r="31"/><circle cx="441" cy="438" r="31"/></g><g transform="translate(267 354)" fill="',
                '"><circle cx="31" cy="42" r="31"/><circle cx="415" cy="31" r="31"/><circle cx="403" cy="373" r="31"/></g>',
                100000000000000
            );

            ICONs[19] = ICON("Biscuit",
                '<path d="M802.175 372.242H576.994c55.785-34.82 81.736-102.352 63.61-165.529C622.477 143.536 564.659 100 498.884 100c-65.776 0-123.595 43.536-141.721 106.713-18.127 63.177 7.824 130.709 63.609 165.53H196.774c-39.316-.323-71.449 31.26-71.774 70.544-.32 39.283 31.29 71.39 70.605 71.713h173.782L292.6 784.32c-8.803 30.95-.412 64.24 22.012 87.333 22.424 23.092 55.474 32.477 86.7 24.62 31.227-7.858 55.886-31.765 64.69-62.714l30.333-106.666 30.361 106.638c8.508 31.302 33.202 55.616 64.652 63.655 31.449 8.04 64.795-1.437 87.303-24.81 22.507-23.374 30.699-57.034 21.446-88.124L623.27 514.527h177.736c39.014-.114 70.671-31.577 70.994-70.558.318-38.981-30.818-70.96-69.825-71.713v-.014Z" fill="',
                '"/><g transform="translate(449 189)" fill="',
                '"><circle cx="21" cy="21" r="21"/><circle cx="86" cy="24" r="21"/><path d="M97.817 71c.604.003 1.18.248 1.592.68.412.43.624 1.008.587 1.597C98.753 98.335 77.609 118.021 51.959 118 26.31 117.979 5.2 98.257 4 73.197a2.122 2.122 0 0 1 .623-1.55A2.217 2.217 0 0 1 6.193 71h91.624Z"/></g><g transform="translate(474 435)" fill="',
                '"><circle cx="27" cy="27" r="27"/><circle cx="27" cy="142" r="27"/></g><path fill="',
                '"/>',
                100000000000000
            );


            ICONs[20] = ICON("Star 2",
                '<g><path fill="',
                '" d="M424.489 410.228 163.048 377.05l222.061 141.774-159.805 210.463 234.206-118.64 101.616 243.414 15.348-264.194 261.494 33.266-222.077-141.956 159.825-210.235-234.218 118.502-101.715-243.497z"/><path fill="',
                '" d="m465.536 405.254-201.183-103.54 137.524 179.588-190.73 122.872 223.792-26.942 10.505 226.22 89.961-208.64 201.201 103.626-137.483-179.74L789.8 396.016l-223.76 26.828-10.56-226.317z"/><path fill="',
                '" d="m430.187 549.702-40.875 188.532 117.553-152.887 143.279 129.96-71.573-178.357 183.987-58.571-191.678-28.047 40.942-188.566-117.687 152.887-143.111-129.96 71.472 178.357-184.054 58.638z"/><path fill="',
                '" d="m464.108 448.517-138.044-29.929L438.01 504.66l-95.16 104.91 130.594-52.406 42.886 134.715 20.536-140.346 138.069 29.977-111.945-86.17 95.158-104.787-130.594 52.332-42.935-134.764z"/></g>',
                100000000000000
            );

            ICONs[21] = ICON("Nordic Trees",
                '<g><path fill="',
                '" d="m618.03 196 203.002 804.806H415.03z"/><path fill="',
                '" d="m154.813 557.23 154.812 443.576H0z"/><path fill="',
                '" d="m395.266 387.045 154.813 613.761H240.454z"/><path fill="',
                '" d="M838.05 583.58 1000 1000.807H676.101z"/></g>',
                100000000000000
            );

            number_of_icons = 21;


        // NGOs
            NGOs[1]  = NGO(0xc3e302e8FDa21b9C020e6388d8052C8055530AdA, "Save the Children");
            NGOs[2]  = NGO(0x63BBc9a8a5D3f66277d9553B73453f59A3C5EcA0, "Coral Restoration Foundation");
            NGOs[3]  = NGO(0xE9bc9DdcEd5685B3871d52EaD8253C4BeA78B935, "Stichting The Ocean Cleanup");
            NGOs[4]  = NGO(0xCdB1cd005918CB00514F3d31872fe40443A52c8c, "Pollinator Partnership Canada");
            NGOs[5]  = NGO(0xcD26C12578B3FDF80D4203CD932e99825F218E6B, "FundLife International");
            NGOs[6]  = NGO(0xB41077c30a1cD16b04776740806Fe2BA18E7AD8D, "AfricAid");
            NGOs[7]  = NGO(0xfA371b51f11B9B32AD597d7c43A302107F66bf94, "National PCF");
            NGOs[8]  = NGO(0x777e24f9d6Aa4CBe853079935560C8c5B80f9B42, "Fondazione Umberto Veronesi");
            NGOs[9]  = NGO(0x496c13C7Ab3cD4Ea167062956da08cade3A562dF, "Global Impact");
            NGOs[10] = NGO(0x8d53637779338c27FC41c323defe8dB4F8dFdDf0, "International Medical Corps");
            NGOs[11] = NGO(0xA4166BC4Be559b762B346CB4AAad3b051E584E39, "Razom");
            NGOs[12] = NGO(0x968DC9065969bBf2652639658b963E287336bF34, "Operation Broken Silence");
            NGOs[13] = NGO(0x36f66F445340E1d58419c6d5EeB71a19323B88e4, "Autism Speaks");
            NGOs[14] = NGO(0xaF3e16a5bf3320A919A6f67c85954d94EA70224e, "Girls Who Code");
            NGOs[15] = NGO(0xf6285e6a3293b4C658F19cC6cAA9123cF5190a84, "2535 Water");

            number_of_NGOs = 15;


        // Colors
            COLORs[0]  = '#000000';
            COLORs[1]  = '#2D2D2D';
            COLORs[2]  = '#0E1F4E';
            COLORs[3]  = '#7F336B';
            COLORs[4]  = '#144100';
            COLORs[5]  = '#006657';
            COLORs[6]  = '#8FAB70';
            COLORs[7]  = '#88171A';
            COLORs[8]  = '#EF4046';
            COLORs[9]  = '#FF5A00';
            COLORs[10] = '#85D1FF';
            COLORs[11] = '#94BAAF';
            COLORs[12] = '#E0B82F';
            COLORs[13] = '#F1E65E';
            COLORs[14] = '#FDE9F1';
            COLORs[15] = '#EBE6DC';
            COLORs[16] = '#FFFFFF';
            
            number_of_colors = 16;

    }
    
    string private constant BG_1     = '<svg xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000"><g stroke="none" fill="none"><rect fill="';
    string private constant BG_2     = '" x="0" y="0" width="1000" height="1000"></rect></g>';
    string private constant TEXT_1   = '<g stroke="none" stroke-width="1" font-family="Helvetica, Arial" font-size="83" font-weight="normal" letter-spacing="0.0166" line-spacing="79"><text x="60" y="1.5em" fill="#FFFFFF">';
    string private constant TX_1     = '</text></g><g stroke="none" stroke-width="1" font-family="Helvetica, Arial" font-size="30" font-weight="normal" letter-spacing="0.0166" line-spacing="79"><text x="50%" y="950" dominant-baseline="middle" text-anchor="middle" fill="#FFFFFF">';
    string private constant TX_2     = '</text></g>';

    function baseTokenURI() override public pure returns (string memory) { return ""; }

    // String Concat functions
        function con(string memory s_1, string memory s_2) internal pure returns (string memory) {
             return string(s_1.toSlice().concat(s_2.toSlice()));
        }
        function con(string memory s_1, string memory s_2, string memory s_3) internal pure returns (string memory) {
             return con(con(s_1,s_2),s_3);
        }
        function con(string memory s_1, string memory s_2, string memory s_3, string memory s_4) internal pure returns (string memory) {
             return con(con(s_1,s_2,s_3),s_4);
        }
        function con(string memory s_1, string memory s_2, string memory s_3, string memory s_4, string memory s_5) internal pure returns (string memory) {
             return con(con(s_1,s_2,s_3,s_4),s_5);
        }
        function con(string memory s_1, string memory s_2, string memory s_3, string memory s_4, string memory s_5, string memory s_6) internal pure returns (string memory) {
             return con(con(s_1,s_2,s_3,s_4,s_5),s_6);
        }

    function getTOKEN(uint256 _tokenId) public view returns (string memory) {
        
        Card   memory card = get_card(_tokenId);

        string memory   bg   = con(BG_1,   COLORs[card.bg_color], BG_2);
        
        string memory   icon;
        icon = con(ICONs[card.icon_id].part_1, COLORs[card.icon_color_1], ICONs[card.icon_id].part_2, COLORs[card.icon_color_2], ICONs[card.icon_id].part_3);
        icon = con(icon,     COLORs[card.icon_color_3], ICONs[card.icon_id].part_4, COLORs[card.icon_color_4], ICONs[card.icon_id].part_5);

        string memory txt  = con(TEXT_1, card.message);

        string memory dona = con(TX_1, DONAs[card.donated], ' ETH donated to ', NGOs[card.NGO_id].name, TX_2);

        string memory svg = con(bg, icon, txt, dona, '</svg>');

        return string(abi.encodePacked('","image":"data:image/svg+xml;base64,',Base64.encode(bytes(svg))));
        
    }

    function getAttributes(uint256 _tokenId) internal view returns (string memory) {
        
        Card   memory card = get_card(_tokenId);

        string memory json = con( '", "attributes":[  {"trait_type":"Donated to","value":"', NGOs[card.NGO_id].name);
        json = con( json,'"},{"trait_type":"Donated amount","value":"', DONAs[card.donated], ' ETH"},' );
        json = con( json, '{"trait_type":"Icon","value":"', ICONs[card.icon_id].name, '"}]}' );

        return json;

    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            con('{"name":"Xmas Card #', Strings.toString(_tokenId), '",'), 
                            con('"description":"This unique NFT certifies that', DONAs[get_card(_tokenId).donated], ' ETH were donated to ', NGOs[get_card(_tokenId).NGO_id].name),
                            getTOKEN(_tokenId), 
                            getAttributes(_tokenId)
                        )
                    )
                )
            )
        );
    }

   function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        '{"name":"Donate Xmas","description":"Create your NFT Christmas postcard and donate to a charity organization","image":"","external_link":"https://donate-xmas.com","seller_fee_basis_points":0,"fee_recipient":""}'
                    )
                )
        ));
    }


    // Donation
    function donate(uint256 amount, uint256 NGO_id) internal {
        payable(NGOs[NGO_id].addr).transfer(amount);
    }

    // Mint
    function mint_card(
        address _to,
        string  memory _message, 
        uint256 _NGO_id, 
        uint256 _icon_id, 
        uint256 _bg_color, 
        uint256 _icon_color_1, 
        uint256 _icon_color_2,
        uint256 _icon_color_3,
        uint256 _icon_color_4
    ) external payable returns(uint256 _token_id) {
        require(msg.value >= ICONs[_icon_id].min_donation, "Minimum donation amount not crossed");
        require( bytes(DONAs[msg.value]).length > 0, "Donation amount should be one of 0.01, 0.05, 0.1, 0.25, 0.5, 1, 5, or 10 ETH");
        uint256 token_id = mintTo(_to, _message, msg.value, _NGO_id, _icon_id, _bg_color, _icon_color_1, _icon_color_2, _icon_color_3, _icon_color_4);
        donate(msg.value, _NGO_id);
        return token_id;
    }

    
    // Functions to add new icons, colors, and NGOs after publication

    function add_icon(
        string memory name,
        string memory part_1,
        string memory part_2,
        string memory part_3,
        string memory part_4,
        string memory part_5,
        uint256 min_donation
    ) external returns(uint256 _number_of_icons) {
        require(msg.sender == owner(), 'Only the owner can do this');
        number_of_icons ++;
        ICONs[number_of_icons] = ICON(name, part_1, part_2, part_3, part_4, part_5, min_donation);
        emit new_ICON(number_of_icons);
        return number_of_icons;
    }

    function add_color(
        string memory color_hex
    ) external returns(uint256 _number_of_colors) {
        require(msg.sender == owner(), 'Only the owner can do this');
        number_of_colors ++;
        COLORs[number_of_colors] = color_hex;
        emit new_COLOR(number_of_colors);
        return number_of_colors;
    }

    function add_NGO(
        string memory name,
        address addr
    ) external returns(uint256 _number_of_NGOs) {
        require(msg.sender == owner(), 'Only the owner can do this');
        number_of_NGOs ++;
        NGOs[number_of_NGOs] = NGO(addr, name);
        emit new_NGO(number_of_NGOs);
        return number_of_NGOs;
    }

}