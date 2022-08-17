/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract Wardrobe {

    address owner;

    uint256 items   = 18;
    uint256 entropy = uint256(keccak256("SUDOMINOOORS-ENTROPY"));

    mapping(uint256 => uint256) public frequency; // How often an item of clothing appears

    constructor ()  { owner = msg.sender; }

    function setOcurrence(uint256 id, uint256 ocurrence) public {
        require(msg.sender == owner, "ONLY_OWNER");
        frequency[id] = ocurrence;
    }

    function setItems(uint256 newItems) public {
        require(msg.sender == owner, "ONLY_OWNER");
        items = newItems;
    }

    function tokenURI(uint256 id) public view returns (string memory meta) {
        (uint256[18] memory items_, uint256 count) = getItems(id);
        
        string memory svg = getImage(items_);

        meta = 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Strings.encode(
                        abi.encodePacked(
                            '{"name":"Minooor#', Strings.toString(id),
                            '","description":"A set of minooors trying to find new riches after the merge',
                            '","image": "data:image/svg+xml;base64,', svg,
                            '","attributes":[', _getItems(items_, count),']}')
                        )
                    )
                );
    }

    function getImage(uint256[18] memory items_) public pure returns (string memory) {
        bytes memory start = abi.encodePacked(header, wrapTag(bg), wrapTag(naked));
        for (uint256 i = 0; i < 18; i++) {
            if (i == 5 && items_[5] == 1 && items_[6] == 1) continue;
            if (i == 12 && items_[12] == 1 && (items_[13] == 1 || items_[14] == 1)) continue;
            if (i == 13 && items_[13] == 1 &&items_[14] == 1) continue;
            if (i == 15 && items_[15] == 1 && (items_[16] == 1 || items_[17] == 1)) continue;
            if (i == 16 && items_[16] == 1 &&items_[17] == 1) continue;

            start = abi.encodePacked(start, items_[i] == 0 ? "" : wrapTag(getPNG(i)));
        }
        start = abi.encodePacked(start, footer);

        return Strings.encode(start);
    }

    function getPNG(uint256 id) public pure returns (string memory) {
        if (id == 0) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgAgMAAAAAulYGAAAACVBMVEUAAAD///////9zeKVjAAAAAnRSTlMAAHaTzTgAAACPSURBVHja7dSxCoAgFEDRV9D/ubT3fbn0dS4tQdESLbZkdM4iCHrR4UUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0Iau/sh8u1umulv6t14sLCz8/fCDyTXGkK57OdbFVwsLC7c8uXbn+MrHYnIJCwsDAAAAAAAAAADwMxtKQgg6l+LZRQAAAABJRU5ErkJggg==";
        if (id == 1) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgAgMAAAAAulYGAAAACVBMVEUAAAD///////9zeKVjAAAAAnRSTlMAAHaTzTgAAAB1SURBVHja7c2hEYBAEATBM+SH2fwwmIuS4p8qAkDwoluNmyoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAf5dZ9JlXbU8lubGxsvPC4p3c8HMbGxsYLjwEAAAAAgM8ucG7NFXSttu8AAAAASUVORK5CYII=";
        if (id == 2) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAIVBMVEUAAAAVDAQhEwUoLC4qGQg/Jgyhs7sAAABjOQ9/TRmhs7skdTnxAAAAB3RSTlMAAAAAAAAAVWTqWAAAAT9JREFUeNrt1jERwmAMhuFawAIWsIAFLGABC7WABVRyX5Zc/2Mo0GOgzzPlkundMk0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAD13jETUJFixYsGDBggULFixYsGDBggULFixYsGDBggULFix438FNsGDBggULFixYsNdSsGDBggULFizYaylYsGDBggULFrzvYL+0YMGCBQsWLFjwRy5xjpqG62lJsGDBggULFixY8BtucY+aKr0PrwgWLFiwYMGCBQtepwqH6kP0rgkWLFiwYMGCBQveorrMUbuaBAsWLFiwYMGCBW9R3br1GIIFCxYsWLBgwYK/rB78YatgwYIFCxYsWDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMATLLHnCuKRSaUAAAAASUVORK5CYII=";
        if (id == 3) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgAgMAAAAAulYGAAAACVBMVEUAAAC6h1m6h1kjTWljAAAAAnRSTlMAAHaTzTgAAAC3SURBVHja7dcxDkAwGIDRkliczlLns1vcz8JQFQlDJyXvDV2ILyr5oyEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8U1N4fz89XxtLHtS+9cbCwsLfD5dOrm4I8fbCuoTZVgsLC9c6udJyMefFVgsLC1c3uXYxL+fvVlpstbCwcKWTKx0Zj1EViw+KvrGwsPALp8VzXl1mmNOisLAwAAAAAAAAQD02tLkVc7Rs0ZYAAAAASUVORK5CYII=";
        if (id == 4) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgAgMAAAAAulYGAAAACVBMVEUAAACgUi2gUi2e3i2lAAAAAnRSTlMAAHaTzTgAAAB1SURBVHja7c2hEYBAEATBM+SH2fwwmIuS4p8qAkDwoluNmyoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIAf5dZ9JlXbU8lubGxsvPC4p3c8HMbGxsYLjwEAAAAAgM8ucG7NFXSttu8AAAAASUVORK5CYII=";
        if (id == 5) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAG1BMVEUAAAAiEQQuFwZFIgloMw6LRRMAAACLRROsMjJd7nfRAAAABnRSTlMAAAAAAABupgeRAAABrklEQVR42u3c4amCUACG4WoDV3AFV2gFV2goV3CFVnAFV3CFEOJIYqmJhzo+zw/hQvdeX/THB4anEwAAAAAAAAAAAAAA/KNzjH+S94fr/Ofu/aHd91wuR7vCggULFixYsOB0l9YwsrL5D3cR5pZbWrBgwYIFCxaczNK6LRxZo7lVucKCBQsWLFiwYMGCBQsWLFiwYMGCBQsWLFiwYMGCBccW5enhep4eChYsWLBgwYItrWVLK1/zG62lJViwYMGCBQu2tJ7fdC/jn3TdHzpXWLBgwYIFCxac3tIavR0ri3/Sw8ha/0oIt7RgwYIFCxYs+JeX1voXN+y8uSpXWLBgwYIFCxZ8jKXV7XGWmaXllhYsWLBgwYKPsbSWPj2sNgyvLEy6z2vO00PBggULFixYcFpLa7SHyonN1YQf6+/+chkGVTGxr3wjXrBgwYIFCxac/tJ6u7macNiieF1aW/aVW1qwYMGCBQsWDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADs5AG+jyQN2bRLxQAAAABJRU5ErkJggg==";
        if (id == 6) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAElBMVEUAAAA/NzJVSUMAAAD2mYj/3cpr5f6LAAAAA3RSTlMAAAD6dsTeAAABmElEQVR42u3c0Y2CQABF0acdTAu0YP8l0AIt0II/RBLiiBKCOpzzt+tmzc348ULABAAAAAAAAAAAAAAA/tHlW29ckqR7/DgmyXDA+17PdsKCBQsWLFiw4MaX1mJVzebfDUfNLR9pwYIFCxYsWHALS6t7jKzUltbCkCS9ExYsWLBgwYIFW1prbm/uK0tLsGDBggULFixYsGDBggULFixY8Ed+5ZrWfHeWa1qCBQsWLFiwYEtr09Kq3u5ekumO+P7JCzs+o+gjLViwYMGCBQtuYWk9e+Kw1P54fPmvFs8o9k5YsGDBggULFnzypZVkurBV1gfVu08muqYlWLBgwYIFCz7n0irrk6lb31JV+3zblo+0YMGCBQsWLPiPltbGr82qvjA6YcGCBQsWLFiwpTX56Mb3wwaVExYsWLBgwYIFt7C0Fte0vr+lnLBgwYIFCxYsGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAKABd8xvIvlbK7X0AAAAAElFTkSuQmCC";
        if (id == 7) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgAgMAAAAAulYGAAAACVBMVEUAAAD///////9zeKVjAAAAAnRSTlMAAHaTzTgAAADGSURBVHja7dmhDsMgFEDRmv7fDIavm8HwlUuWR9neKia2UHGOgrThoghNtw0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADgG+XQeyvl/KU9noabsLCw8OJw7UM7XzW2NQgLCwuvDsdaY+nnKJ2Wsbd2jO7CwsLCi8PzElc/zs20o5gKCwsLXyCcrn3lRX2/4u3CwsLC1wxHKU2FhYWFrxKe36WplMzwL/9JCAsLCwMAAAAAAAAAAAAAAAAA/MsDhbZw4C1+v5oAAAAASUVORK5CYII=";
        if (id == 8) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAElBMVEUAAAClcWTDk0LSpDKlcWT/1wAziLsuAAAABHRSTlMAAAAAs5NmmgAAANRJREFUeNrtzzENgFAUQ9FvAQtYwAIW8G+FtPsbSBgIOWdtl7sWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADwqjO2GC9d+xMsWLBgwYIFCxYsWLBgwYIFCxYsWLBgwYIFCxYsWPDfg/cYL10FCxYsWLBgwYIFP3XFEeOla3+CBQsWLFiwYMGCAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOArboEYwJVi1oObAAAAAElFTkSuQmCC";
        if (id == 9) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgAQMAAABHGizWAAAABlBMVEUAAAD/1wDVht76AAAAAXRSTlMAQObYZgAAAD1JREFUeNrtyzENAAAIA7A5wL/aoYKEo/2bAAAAAAAAAAAAAAAAAAAAAAAAAAC8Mq0sH2YAAAAAAAAAeGgBLJgUg6AZQpMAAAAASUVORK5CYII=";
        if (id == 10) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAElBMVEUAAABQKRZ4PSGgUi0AAACgUi0xooo4AAAABHRSTlMAAAAAs5NmmgAAAM9JREFUeNrtz1ENgDAAQ8FZwAIWsIAF/Fsh7Q8GWALZnYA2bwwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgI84Y4sp813uh2DBggULFixY8HLBV+xxxIvL3etyPwQLFixYsGDBgtcMrinBz7xgwYIFCxYsWLBgwYIFCxYsWLBgwQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADwfzc3zxBUDZOwBgAAAABJRU5ErkJggg==";
        if (id == 11) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgAgMAAAAAulYGAAAADFBMVEUAAAA3HAAAAACnVQKhWD0xAAAAAnRSTlMAAHaTzTgAAADHSURBVHja7dg5CoUwFEBRFWxcnY3WLs1aG1dnY2McWjGC4MA5hfAhePkpHolJAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8E9p/NKijVlVR74te+ofCwsLfz98bXJVJ0umweQSFhYWFhYWFnZbFBYWdlt0WxQWFhYWFhYWvvnMlZfhzBUeh/rlzNXbamFh4RdNriBictlqYWHhl02u3fqtfmy2H93yqG21sLCwsLCwsDAAAE+aARxxEsJ/hOX2AAAAAElFTkSuQmCC";
        if (id == 12) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAElBMVEUAAAA/EgRMFQQAAACFJgm/NgzvHq8NAAAAA3RSTlMAAAD6dsTeAAABCklEQVR42u3bwQmAIBiAUWsDV2iF9h+hFVrBFUICg8CI7GD03iH01ocdfqJCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHjT0PsNxnyZ8iWV7bFay/au8W8nLFiwYMGCBQs2aVXNZdJaa6vFCQsWLFiwYMGCBbeJ2WnlhAULFixYsGDBHfvGO61r3mkJFixYsGDBgk1azyet6++0TFqCBQsWLFiwYMGNUnZaOWHBggULFixYcMf8e+iRFixYsGDBggUDAAAAALsNmawbiG++1V4AAAAASUVORK5CYII=";
        if (id == 13) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAGFBMVEUAAAANDQ0bGxsiEQT///8AAABSUlKLRRPirEIAAAAABXRSTlMAAAAAAMJrBrEAAAEFSURBVHja7dbLCYBADEDBbcEWbMEWbMEWbMH2JTm4IIooorDMnLKfy7ulFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAeGAM9TiFJeQkWLBgwYIFCxYs+DWCBQsWLFiwYMGCX9OHjOvCLrje5T/BggULFixYsGDBd3fJOUybGrx7FSxYsGDBggULFvxotZzPtLpLCxYsWLBgwYIFf1t9tFq21SpYsGDBggULFvyXIWRmTqV5ggULFixYsGDBAAAAAAAAAAAAXFoBNhWsG9MPqTAAAAAASUVORK5CYII=";
        if (id == 14) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAElBMVEUAAAAbGxsAAAA8PDxSUlKLRRPzHHi4AAAAAnRSTlMAAHaTzTgAAAD7SURBVHja7c9REYNAEAUwLKyFZ2EtrIXzb6V/PQFlYAqJgxwHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8Lkmy1lorSSIsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLPzGcL52+NFrYWFhYWFhYeFrwzMz093dMzMjLCwsLCwsLCwsLCwsLCwsLCz8H+FNWFhYWFhYWFj4DFVVtddJkqqqEhYWFhYWFhYWPnf9/KuwsLCwsLCwMAAAAADc5QMIaUwYIlZKbwAAAABJRU5ErkJggg==";
        if (id == 15) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAJFBMVEUAAAAiEQQuFwY/Pz9OQDZVVVVgUDMAAACLRRPjlAD/1wD////DkWR6AAAAB3RSTlMAAAAAAAAAVWTqWAAAAVJJREFUeNrt20ENwkAQQNFawAIWsIAFLGBhLWABC7WAOTJzYNINoTShEJr3Tpt0e/h7mmzTYQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYJtOoYVcCRYsWLBgwYIFC/6EQ8jWW9h+tWDBggULFixY8MoT5Dm0h2wdQ1ULFixYsGDBggULXqCbIK8hM3NV1XUSfz5kChYsWLBgwYIF/+DCLo1T1d8djGDBggULFixYsOBZu9C1Zle1ltx3DIIFCxYsWLBgwYLfu8S7hGcfSWu+7PYJFixYsGDBggULXjBadtVtqp7mG4IFCxYsWLBgwYKXzpevbes/AMGCBQsWLFiw4G/YhzYv9wkWLFiwYMGCBQsGAGBld0h73D+nd49NAAAAAElFTkSuQmCC";
        if (id == 16) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAD1BMVEUAAAAkEwYAAABuORP19dzn8aMXAAAAAnRSTlMAAHaTzTgAAAEmSURBVHja7duxCYQwGIZhdYOskP1nygquIFpEIhLJDxbi8xQHKa54yRUfh04TAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPzTHPxebo/lM8HL325YsGDBggULFvzR4LRzw4IFCxYsWLBgwffG/tNK9eM8rvW4tkc3LFiwYMGCBQu2tAbkdmldHCOruGHBggULFixYsODw0uqztAQLFixYsGDBguNLK3dHlqUlWLBgwYIFCxYcX1p9lpZgwYIFCxYsWHB8aXlOy09asGDBggULFvzC0krPS8u7h4IFCxYsWLBgwQAAvGwDTH0PApemwjkAAAAASUVORK5CYII=";
        if (id == 17) return "iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAElBMVEUAAAAbGxsiEQQAAABSUlKLRRMUITx8AAAAA3RSTlMAAAD6dsTeAAAA9klEQVR42u3YsQ2AQAhAUVZwBVe4FVzB/VcxUGhloYnF4XsVCdXvCBEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHQ30p5qEixYsGDBggULFixYsGDBggULFixYsGDBggULFixY8M+ClzROV3CprWDBggULFixYsOD3B+V2p+GRKViwYMGCBQsWLFiwYMGCBQsWLHh6vpaCBQsWLFiwYMHfW1Nl1hTtCRYsWLBgwYIFAwAAAAAAADxyAFrar7T8804rAAAAAElFTkSuQmCC";
    }

    function _getItems(uint256[18] memory items_, uint256 count) internal pure returns (string memory atts_) {
        uint256 added = 0;
        for (uint256 i = 0; i < items_.length; i++) {
            if (items_[i] == 1) {
                added++;
                if (added == count) {
                    // No trailing comma
                    atts_ = string(abi.encodePacked(atts_, items_[i] == 0 ? "" : '{"trait_type":"Item","value":"', getItemName(i),'"}'));
                } else {
                     atts_ = string(abi.encodePacked(atts_, items_[i] == 0 ? "" : '{"trait_type":"Item","value":"', getItemName(i),'"},'));
                }
            }
           
        }

    }

    function getItems(uint256 id) public view returns (uint256[18] memory equiped, uint256 count) {
        for (uint256 i = 0; i < items; i++) {
            uint256 draw = uint256(keccak256(abi.encodePacked(id, getItemName(i))));
            if (draw <= frequency[i]) {
                equiped[i] = 1;
                count++;
            }
        }
    }

    function getItemName(uint256 id) internal pure returns (string memory) {
        if (id == 0) return "undies";
        if (id == 1) return "socks";  
        if (id == 2) return "pipe";
        if (id == 3) return "pants";
        if (id == 4) return "boots";
        if (id == 5) return "hat";
        if (id == 6) return "sideways hat";
        if (id == 7) return "grandad shirt";
        if (id == 8) return "suspenders";
        if (id == 10) return "gloves";
        if (id == 9) return "gold watch";
        if (id == 11) return "cart";
        if (id == 12) return "tnt";
        if (id == 13) return "axe";
        if (id == 14) return "shovel";
        if (id == 15) return "gold chest";
        if (id == 16) return "moonshine";
        if (id == 17) return "hammer";
    }

    function wrapTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }

    string constant bg = 'iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAIVBMVEUAAAARGR0mMjg5RUtdaG5gfYt/SQaNbmOQpK6iiYCnVQKcx6tKAAAFLUlEQVR42u3d7XHaMACAYbcbsEJWyAqsEEboCmGEZIWOACt4BVZgBVbo1T+ksyo5EIgkp49++Pgq+Lmod+8ZI/94Gv4d57+bt2Fp7Od3XzIvOWaemN75FO5OH34Jm23YLH/uy3DdOIbPiOPn8J8NYGBgYGBg4Hbjx1PpmfP8bhJeY9i8ZAoq91gcMaj287ffL744ya3neUblPm2TuWVKAwMDAwMDA7corcv8mUvm1W/zyIqxcyy9/yZz95wpqHF+d7+YWzftQfzcjSkNDAwMDAwM3KC0LqW0Wu1IDsHtlRYwMDAwMDBwg9JK7icHiQ6ZfzJ+/K7blqRdprRibpnSwMDAwMDAwPVKKzm7PPkS7vCQDxkf8i7bj99vu1hapjQwMDAwMDBw29JKmuvwkFCqe4irWFqjKQ0MDAwMDAxct7SmbfI7vqS0Hj3GW4psvLncduElW6UFDAwMDAwM3L60phGPbsUVE64trZsOe919iGu5vnbzx5LlJExpYGBgYGBg4MqlVTxZ63BlUN0TT5/8crL4kbvSE2+mNDAwMDAwMHDd0opfHMalSk+l0np0Rn3J0a3fpcgypYGBgYGBgYErl1buwRhenzwj/vaCGh+XYLtMX5nSwMDAwMDAwC1KK3cZnKS07hmf/L7xnjW7rPIADAwMDAwM3FVpDSG3kvA6zPulxmlbt49dZk+t8uD/MDAwMDAwcFellYx9Jq0eM+5Zn+uKhrPKg//DwMDAwMDAnZbWeG8KdTK2pTYzpYGBgYGBgYFblNY4vxVXfkjWMN11tPvxjP3pF4dx8dXzvLTiolqmNDAwMDAwMHDl0kqOZOWW10qapvfSGjLN9WRKAwMDAwMDA9ctrdyDycV51lhal7AZ5k+Y0sDAwMDAwMD1SitZtDSXW72X1jTid5qbeWQpLWBgYGBgYOC2pZWMc6lpei+t4uJgpjQwMDAwMDBwz6X16+9mG5qmk5HsVfJDyqm5NuHuxpQGBgYGBgYGrltaSYjEyEqWNF1FaQ3hbryV5JYpDQwMDAwMDFyvtGJkTac2TT87PK66tIZ5aY2mNDAwMDAwMHCr0oqnNuXWdri2afosrWFejKY0MDAwMDAwcLPSeg4PPq21tOIPKV1hGhgYGBgYGLiX0hpCbiUjdlifa8QrLVMaGBgYGBh4HaVVzK2h39LK7VXxkoemNDAwMDAwMHAvpbWe6x4W90ppAQMDAwMDA7ctre08SYrnxq9i5dLlk/pNaWBgYGBgYOAWpTWEjJrGeq57mJynFUtrOlnrNH+xK0wDAwMDAwMDVy6t4jOruO5hsbSOmcgypYGBgYGBgYErl9byF25Tbp2UlikNDAwMDAwM/IDSmkbuq7eOz9OKexWPw0WCK0wDAwMDAwMDd1Ba8ZKHp1LTTKO73x4m/fdciixTGhgYGBgYGLhFaRXPH48JtorSigutTmMTNpdwy5QGBgYGBgYGrldaz4uRdUVpvVbd3/ePSyuOfeirQWkBAwMDAwMDd1Jaw7xQLplnX5vv+XvmsWRxsFxumdLAwMDAwMDA9UqrGE/vj0ureI76F4dXciGeMWxMaWBgYGBgYOAWpfX6nTS541yvpjQwMDAwMDCw0rpq3H14zJQGBgYGBgYGblFat0dMjW8F/YWBgYGBgYGBv0NpdTK+ON9MaWBgYGBgYOBeSmuNR62WHaY0MDAwMDAwcLPSqpFWTfPNlAYGBgYGBgZuVlrfZRRrzpQGBgYGBgYGVlr+wsDAwMDAwMDAwMDAwMDAwMDAhfEHF0D3H2n0CB4AAAAASUVORK5CYII=';
    string constant naked = 'iVBORw0KGgoAAAANSUhEUgAAAeAAAAHgBAMAAACP+qOmAAAAMFBMVEUAAAAXFxciEQQvJSQwLi42Li07Ly1MQUBOPjwAAABdXV2RjIzsvLTzbGD/1wD///8SKPM+AAAACXRSTlMAAAAAAAAAAABzZJuhAAADj0lEQVR42u3d4XHaMACGYbcbeAVWYIWs0BXiEcoI6QjJCqyQFVjBK7BCz7pEqhXJFi3lDvy8P3xpIbTPmR/fOQS6TpIkSZIkSZIkSZIkSZIkSZIkSZIkSZIkSZIkSZIkSZIkSZIkSZKke+/bLf6Rl+nQr9/vPB0O//f/8n1rZxgYGBgYGBj4cZdWGln79TufbjC3PKWBgYGBgYGBH2FpPU2HH40jK5tbx+nw7gwDAwMDAwMDW1rlXqfDbjr0l3xbuKY1TofBGQYGBgYGBgYGBgYGBgYGBgYGLnS7a1rn+a3Lf+eaFjAwMDAwMLCl9bXs9wzT0gqvv3qOX4XDPh7e4ldpaXXxjwdnGBgYGBgYGNjS+riSlSZTNx9eqbS0srJvC/cb4mgbnWFgYGBgYGBgS+tjMi2/GH55bmVLyxkGBgYGBgYGtrQuWFrVuWVpAQMDAwMDA1taX/s5HXbx0K+vqurSGuPhlzMMDAwMDAwMbGn9+RuH3XxppddfZa+1ariza1rAwMDAwMDAllZlaZ0veYDe0vKUBgYGBgYGtrSallY3n0zLVb/N0gIGBgYGBga2tD6XVh8Ppd0UPgvxuD6yzvFgaQEDAwMDAwNbWp/76qU2ntLcWh5Z6X6HOLecYWBgYGBgYOCtL63Q8oWtLo6n5VuvfTnLUxoYGBgYGBj4EZZW+Png03TY/d0DhMtZ79Ph6AwDAwMDAwMDb3xpZZ92GApvkXW6eG6N8+9NXecTED2lgYGBgYGBge9oaaWRVfpYnVO8teHd4tPPDKsP9c9zy1MaGBgYGBgY+I6W1ut8GaULUdnfNVzYGhsfanCGgYGBgYGBgbe2tMIKeos3PBc2UunqVulKVvWhLC1gYGBgYGDgDS+toXBDN19QpUr3G9b/DWcYGBgYGBgYeEtLK12NSje0fiRPul8aVOlylqUFDAwMDAwMvOGl1c2nUOmaVmvVR7G0gIGBgYGBgYGBgYGBgYGBgYGv+S4PofQ2DNW3f8h+jpi9QP5Ue5Ts4Z1hYGBgYGBg4MdfWq07LPsJ4H7+VWlkOcPAwMDAwMDAltZqpVe1l77K3tvBGQYGBgYGBga2tNrKfkcxdZ3fKXSGgYGBgYGBgTe3tLKXWWWrqrS+/PQQGBgYGBgY2NJqq/r2pcP6rc4wMDAwMDAwsKW1VHZNK1T9xcLsVmcYGBgYGBgYWJIkSZIkSZIkSZIkSZKker8Bf5+edlmG5NIAAAAASUVORK5CYII='; 
    string constant header = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="naked" width="100%" height="100%" version="1.1" viewBox="0 0 64 64">';
    string constant footer = '<style>#naked{shape-rendering: crispedges;image-rendering: -webkit-crisp-edges;image-rendering: -moz-crisp-edges;image-rendering: crisp-edges;image-rendering: pixelated;-ms-interpolation-mode: nearest-neighbor;}</style></svg>';
}

library Strings {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}