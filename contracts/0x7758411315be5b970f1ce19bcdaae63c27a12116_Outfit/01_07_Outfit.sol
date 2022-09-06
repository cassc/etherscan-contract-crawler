// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Surround.sol";
import "./Face.sol";
import "./Body.sol";

interface IOutfit {
    function metadata(uint256 tokenId) external view returns (string memory);
    function element(uint256 tokenId) external view returns (string memory);
}

/** @title Youts - Outfit Metadata contract 
  * @author @ok_0S / weatherlight.eth
  */
contract Outfit is Ownable {
    address public faceAddress;
    address public surroundAddress;
    address public bodyAddress;

    string[15] private outfitNames = [
        'Natural',
        'Drip',
        'Forested',
        'Tee',
        'Pocket',        
        'Crewneck',
        'Blouse',
        'Toga',
        'Kimono',
        'Kimono, Forested',
        'Overalls',
        'Tank',
        'Jersey',
        'Ancient',
        'Sci-fi'
    ];
    

	/** @dev Initialize metadata contracts  
	  * @param _faceAddress Address of Facce Metadata Contract 
	  * @param _surroundAddress Address of Surround Metadata Contract 
	  * @param _bodyAddress Address of Body Metadata Contract 
	  */ 
    constructor(address _faceAddress, address _surroundAddress, address _bodyAddress) 
        Ownable() 
    {
        faceAddress = _faceAddress;
        surroundAddress = _surroundAddress;
        bodyAddress = _bodyAddress;
    }


	/** @dev Sets the address for the Face Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Face Metadata Contract 
	  */
    function setFaceAddress(address addr) 
        public 
        onlyOwner 
    {
        faceAddress = addr;
    }


	/** @dev Sets the address for the Surround Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Surround Metadata Contract 
	  */
    function setSurroundAddress(address addr) 
        public 
        onlyOwner 
    {
        surroundAddress = addr;
    }


	/** @dev Sets the address for the Body Metadata contract. Allows for upgrading contract.  
	  * @param addr Address of Body Metadata Contract 
	  */
    function setBodyAddress(address addr) 
        public 
        onlyOwner 
    {
        bodyAddress = addr;
    }


    /** @dev Internal function that returns the Outfit index for this token
      * @notice This function will return a Outfit index for ANY token, even Youts that aren't wearing outfits
	  * @param tokenId A token's numeric ID
	  */
    function _outfitIndex(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return 
            uint256(keccak256(abi.encodePacked("OUTFIT", tokenId))) % ( 
                IFace(faceAddress).isWeird(tokenId) 
                    ? 15 
                    : 13
            );
    }


	/** @dev Renders a JSON string containing metadata for a Yout's Outfit
	  * @param tokenId A token's numeric ID
	  */
    function metadata(uint256 tokenId)
        external
        view
        returns (string memory) 
    {
        string memory traits;
        
        if (!IBody(bodyAddress).isRobed(tokenId)) {
            traits = string(abi.encodePacked(
                '{"trait_type":"Outfit","value":"', outfitNames[_outfitIndex(tokenId)], '"}'
            ));
        }

        return
            traits;
    }


	/** @dev Renders a SVG element containing a Yout's outfit  
	  * @param tokenId A token's numeric ID 
	  */
    function element(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory shirtOutline = string(abi.encodePacked(
            _path(
                'M592.521 757.644C540.289 810.837 452.375 840.491 336.999 744',
                's3'
            ),
            _path(
                'M292 871.612C301.641 884.617 314.115 951.654 298.906 984.035',
                's3 r'
            ),
            _path(
                'M640.627 876.644C635.766 891.774 638.767 963.632 656.222 994.838',
                's3 r'
            ),
            _path(
                'M182 956H767C745.333 910.811 687.8 811.756 631 777.05C620.696 770.754 589 750 583.5 745',
                's3'
            ),
            _path(
                'M174 955C195.667 909.811 253.2 810.756 310 776.05C317.237 771.628 343.5 755 356 745.5',
                's3'
            )
        ));

        string memory tank = string(abi.encodePacked(
            _path(
                "M293.572 774C301.322 797.795 313.655 867.784 300.99 957.374",
                's3'
            ),
            _path(
                "M348 752C348 752 342.808 754.918 335 760.071C324.532 766.98 314.145 773.518 310 776.05C303.156 780.232 296.301 785.348 289.5 791.192",
                "s3"
            ),
            _path(
                "M630 776.05L638.082 762.824L630 776.05ZM647.3 788.5L657.151 776.532L661.895 780.437L662.675 786.532L647.3 788.5ZM766 970.5H181V939.5H766V970.5ZM621.918 789.277C616.393 785.9 610.096 781.516 605.189 778.224C599.48 774.394 596.226 772.463 594.936 771.967L606.064 743.033C611.274 745.037 617.618 749.233 622.458 752.479C628.099 756.264 633.303 759.904 638.082 762.824L621.918 789.277ZM637.45 800.468C632.158 796.112 626.969 792.362 621.918 789.277L638.082 762.824C644.575 766.792 650.945 771.424 657.151 776.532L637.45 800.468ZM662.675 786.532C663.644 794.104 663.57 801.983 663.306 810.31C663.034 818.934 662.553 828.156 662.411 839.998C662.133 863.27 663.208 895.835 670.338 944.765L639.662 949.235C632.292 898.665 631.117 864.48 631.414 839.627C631.56 827.407 632.073 817.222 632.322 809.331C632.581 801.142 632.557 795.396 631.926 790.468L662.675 786.532Z",
                "fB nS mJ"
            ),
            _path(
                "M341 769C372.797 850.416 533.673 929.846 610.486 772.808",
                "s4"
            )
        ));

        string memory teeOutline = string(abi.encodePacked(
            _path(
                "M335 741.5C379.2 800.1 513 847 604.5 742", 
                "s3"
            ),
            _path(
                "M716 956.5C726.5 941.5 733 922 740.5 905.5C710 859.5 673.3 802.7 633 778.1C625.8 773.6 599.5 757 587 747.5",
                "s4 mJ"
            ),
            _path(
                "M225 956.5C214.5 941.5 207 923.5 199.5 907C227.5 859.8 267.7 802.7 308 778.1C315.2 773.6 341.5 757 354 747.5",
                "s4 mJ"
            )
        ));

        string memory teeDetails = string(abi.encodePacked(
            _path(
                "M644 847C637 863 635 943 651 979", 
                "r"
            ),
            _path(
                "M304 848C314 861 327 929 311 962", 
                "r"
            ),
            _path(
                "M304 773C344 838.4 543.5 900.2 636 773"
            )
        ));

        string memory kimono = string(abi.encodePacked(
            _path(
                "M289.053 858.253C289.053 858.253 289.053 925.753 312.556 1000.25", 
                "r"
            ),
            _path(
                "M659.672 863.206C661.148 879.46 659.748 926.159 642.335 982.924", 
                "r"
            ),
            _path(
                "M174 955.5C195.667 910.311 253.2 811.256 310 776.55C317.237 772.128 328.5 762.5 336.5 757.5C336.5 757.5 337 989 390.5 997",
                "s4 mJ"
            ),
            _path(
                "M766 955C744.333 909.811 688 812 632 777.05C621.756 770.657 616.5 767 608.5 761.5C608.5 761.5 608.5 861.5 605 914C602.694 948.591 585 987.5 585 987.5",
                "s4 mJ"
            )
        ));

        string memory forest = _path(
            'M444 901C502 931 528 878 484 845C469 833 448 847 452 860C457 873 468 878 482 873C534 856 523 806 469 807',
            's2 r'
        );

        string[15] memory outfits = [

            // NATURAL
            _chest(tokenId),

            // DRIP
            string(abi.encodePacked(
                _chest(tokenId),
                _dot(["360", "780"]),
                _dot(["392", "805"]),
                _dot(["427", "822"]),
                _dot(["468", "829"]),
                _dot(["509", "822"]),
                _dot(["546", "805"]),
                _dot(["609", "757"]),
                _dot(["336", "753"]),
                _dot(["580", "781"])
            )),

            // FORESTED
            string(abi.encodePacked(
                _dot(["591", "890"]),
                _dot(["349", "891"]),
                forest
            )),

            // TEE
            string(abi.encodePacked(
                teeOutline,
                teeDetails
            )),

            // POCKET
            string(abi.encodePacked(
                teeOutline,
                teeDetails,
                '<rect class="s2 r" x="492" y="910" width="89" height="86" transform="rotate(-7 492 910)" style="stroke-linejoin: round !important;"/>'
            )),

            // CREWNECK
            string(abi.encodePacked(
                shirtOutline,
                _path(
                    'M625.349 779.069C564.36 845.906 459.088 887.056 315 779.718',
                    's3'
                ),
                _path(
                    'M517.546 844.266C480.503 920.583 484.972 922.989 440.999 846.167'
                )
            )),

            // BLOUSE
            shirtOutline,

            // TOGA
            string(abi.encodePacked(
                _path(
                    "M637.5 781C621.5 770.5 588 750 583.5 744", 
                    "s4"
                ),
                _path(
                    "M220 875.5C198.5 909 196 912 173.5 956H765", 
                    "s4"
                ),
                _path(
                    "M586.719 755.355C572.782 840.371 382.485 988.716 223 895",
                    "s3"
                ),
                _path(
                    "M601.441 763C619.73 852.138 491.4 1049.82 302.435 995.962"
                ),
                _path(
                    "M633.705 777.151C687.532 845.185 664.386 1047.31 481.727 1060.18",
                    "s3"
                )
            )),

            // KIMONO
            kimono,

            // KIMONO, FORESTED
            string(abi.encodePacked(
                kimono,
                forest
            )),

            // OVERALLS
            string(abi.encodePacked(
                teeOutline,
                _dot(["504", "889"]),
                _path(
                    "M351 763C361 788 384 862 382 961"
                ),
                _path(
                    "M374 851C436 854 570 856 612 843"
                ),
                _path(
                    "M649 790C658 816 674 892 667 991"
                ),
                _path(
                    "M299 779C309 804 329 879 327 978", 
                    "s3"
                ),
                _path(
                    "M586 753C596 778 616 851 614 949" 
                    "s3"
                ),
                _path(
                    "M381 909C411 910 462 921 506 925C552 916 598 907 619 900"
                )
            )),

            // TANK
            tank,

            // JERSEY
            string(abi.encodePacked(
                tank,
                '<circle class="s2" cx="360.5" cy="875.5" r="22.5"/>',
                '<rect class="s2" x="585" y="861" width="30" height="30"/>',
                _path(
                    'M461.527 908.453C413.027 882.953 375.491 926.949 390.252 978.953',
                    'r'
                ),
                _path(
                    'M518 1010C531 1013 543 1007 551 998C559 990 565 978 568 964C571 951 570 937 565 926C561 915 552 905 539 903C526 900 515 906 506 915C498 923 492 935 489 949C487 962 488 976 492 987C497 998 505 1008 518 1010Z',
                    'r'
                )
            )),

            // ANCIENT
            string(abi.encodePacked(
                _path(
                    "M655 801C611 902 392 999 289 804"
                ),
                _path(
                    "M691 825C639 949 379 1068 257 829"
                ),
                _path(
                    "M612 780C577.743 852.16 405.783 921.495 325.366 782.347",
                    "s3"
                ),
                _path(
                    "M174 955C195.667 909.811 253.2 810.756 310 776.05C317.237 771.628 323 768 331 763",
                    "s4"
                ),
                _path(
                    "M766 955C744.333 909.811 686.8 810.756 630 776.05C619.696 769.754 613.5 765.5 606 761",
                    "s4"
                )
            )),

            // SCI-FI
            string(abi.encodePacked(
                _dot(['372','785']),
                _dot(['401','809']),
                _path(
                    'M612 780C592.948 820.133 478 887.5 468.5 892C458 887.5 361.059 844.106 325.366 782.347',
                    's4'
                ),
                _path(
                    'M630.18 834.851C608.691 875.004 479.13 942.491 468.422 947.001C456.593 942.512 347.376 899.219 307.187 837.496',
                    'r'
                ),
                _path(
                    'M174 955C195.667 909.811 253.2 810.756 310 776.05C317.237 771.628 323 768 331 763',
                    's4'
                ),
                _path(
                    'M766 955C744.333 909.811 686.8 810.756 630 776.05C619.696 769.754 613.5 765.5 606 761',
                    's4'
                )
            ))

        ];

        return
            string(abi.encodePacked(
                '<g id="o" filter="url(#ds)">', outfits[_outfitIndex(tokenId)], "</g>"
            ));
    }


	/** @dev Returns an appropriate chest for the token
	  * @param tokenId A token's numeric ID
	  */
    function _chest(uint256 tokenId)
        internal
        view
        returns
        (string memory) 
    {
        string memory xs = string(abi.encodePacked(
            '<line class="s2 r" x1="349" y1="859" x2="382" y2="892"/>',
            '<line class="s2 r" x1="557" y1="859" x2="590" y2="892"/>',
            '<line class="s2 r" x1="349" y1="892" x2="382" y2="859"/>',
            '<line class="s2 r" x1="557" y1="892" x2="590" y2="859"/>'
        ));

        if (ISurround(surroundAddress).hasLongHair(tokenId)) {
            return
                string(abi.encodePacked(
                    xs,
                    _path(
                        "M459 869C459 913 405 929 366 929C326 929 299 909 295 875C292 855 297 827 327 810",
                        "r"
                    ),
                    _path(
                        "M484 869C484 913 537 929 575 929C613 929 640 909 644 875C647 855 642 827 612 810",
                        "r"
                    )
                ));
        } else if (IFace(faceAddress).isWeird(tokenId)) {
            return
                string(abi.encodePacked(
                    '<ellipse class="fB" rx="16.5" ry="7.5" transform="matrix(0 1 1 -4.37114e-08 577.5 897.5)"/>',
                    '<ellipse class="fB" rx="17" ry="7.5" transform="matrix(1 -8.74228e-08 -8.74228e-08 -1 577 897.5)"/>',
                    '<ellipse class="fB" rx="16.5" ry="7.5" transform="matrix(-1 0 0 1 357.5 889.5)"/>',
                    '<ellipse class="fB" rx="17" ry="7.5" transform="matrix(0 1 1 -4.37114e-08 357.5 890)"/>'
                ));
        }
        
        return
            uint256(keccak256(abi.encodePacked("NATURAL", tokenId))) % 2 == 2
                ? xs
                : string(abi.encodePacked(
                    _dot(["591", "890"]), _dot(["349", "891"])
                ));
    }


	/** @dev Internal drawing helper function that renders a small dot
	  * @param position The X and Y coordinates for the dot
	  */
    function _dot(string[2] memory position)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<circle class="fB i" cx="',
                position[0],
                '" cy="',
                position[1],
                '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element
	  * @param d A string containing the path's `d` attribute
	  */
    function _path(string memory d) 
        internal 
        pure 
        returns (string memory) 
    {
        return
            string(abi.encodePacked(
                '<path d="', d, '"/>'
            ));
    }


	/** @dev Internal drawing helper function that renders a path element with the provided class attribute
	  * @param d A string containing the path's `d` attribute
	  * @param classNames A string containing the path's `class` attribute
	  */
    function _path(string memory d, string memory classNames)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                '<path class="', classNames, '" d="', d, '"/>'
            ));
    }
}