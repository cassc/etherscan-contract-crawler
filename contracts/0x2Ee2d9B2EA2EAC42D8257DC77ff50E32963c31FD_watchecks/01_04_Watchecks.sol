// SPDX-License-Identifier: MIT


import {Base64} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Base64.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

pragma solidity ^0.8.0;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function initializeWithData(bytes memory initData) external;
}

interface Imini721 {
    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract watchecks is IMetadataRenderer, Ownable {
    address private targetContract = 0xC3120F76424c21A4019A10Fbc90AF0481b267123;
    string private _contractURI;

    string private svgPart0 =
        '<svg width="400" height="400" viewBox="0 0 400 400" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M400 209.375c0 13.984-3.359 26.953-10.078 38.828-6.719 11.875-27.031 27.656-27.031 27.656s.468 5.391.468 9.844c0 21.172-7.109 39.141-21.171 53.985-14.141 14.921-31.172 22.343-51.094 22.343-8.906 0-17.422-1.64-25.469-4.922-6.25 12.813-15.234 23.125-27.031 31.016C226.875 396.094 213.984 400 200 400c-14.297 0-27.266-3.828-38.828-11.641-11.641-7.734-20.547-18.125-26.797-31.25-8.047 3.282-16.484 4.922-25.469 4.922-19.922 0-37.031-7.422-51.328-22.343-14.297-14.844-21.406-32.891-21.406-53.985 0-2.344.312-5.625.86-9.844-11.329-6.562-20.313-15.781-27.032-27.656-6.64-11.875-10-24.844-10-38.828 0-14.844 3.75-28.516 11.172-40.859 7.422-12.344 17.422-21.485 29.922-27.422-3.282-8.906-4.922-17.891-4.922-26.797 0-21.094 7.11-39.14 21.406-53.984 14.297-14.844 31.406-22.344 51.328-22.344 8.906 0 17.422 1.64 25.469 4.922 6.25-12.813 15.234-23.125 27.031-31.016C173.125 3.985 186.016 0 200 0c13.984 0 26.875 3.984 38.594 11.797 11.718 7.89 20.781 18.203 27.031 31.015 8.047-3.28 16.484-4.921 25.469-4.921 19.922 0 36.953 7.422 51.094 22.343 14.14 14.922 21.171 32.891 21.171 53.985 0 9.843-1.484 18.75-4.453 26.797 12.5 5.937 22.5 15.078 29.922 27.422C396.25 180.859 400 194.531 400 209.375Z" fill="#';
    string private svgPart1 = '"/><g id="houru" transform="rotate(';
    string private svgPart1b = ',200,200)" fill="#';
    string private svgPart2 =
        '"><circle cx="200" cy="200" r="15"/><circle cx="200" cy="135" r="15"/><path d="M185 135h30v65h-30z"/></g><g  id="minu" transform="rotate(';
    string private svgPart2b = '0,200,200)" fill="#';
    string svgPart3 =
        '"><circle cx="200" cy="200" r="15"/><circle cx="200" cy="62" r="15"/><path d="M185 62h30v138h-30z"/></g><g id="secondCenter" transform="rotate(';
    string private svgPart3b = ',200,200)" fill="#';
    string private svgPart4 =
        '"><path d="M201 54.746c0-17.659-2-17.659-2 0v142.25h2V54.746Z" /><path d="M215 200.703a5.815 5.815 0 0 1-.756 2.912c-.504.891-1.178 1.588-2.027 2.074.023.159.035.405.035.739 0 1.588-.533 2.935-1.588 4.049-1.06 1.119-2.338 1.675-3.832 1.675a5.016 5.016 0 0 1-1.91-.369 5.812 5.812 0 0 1-2.027 2.326A5.037 5.037 0 0 1 200 215c-1.072 0-2.045-.287-2.912-.873-.873-.58-1.541-1.359-2.01-2.344a4.994 4.994 0 0 1-1.91.369c-1.494 0-2.777-.556-3.85-1.675-1.072-1.114-1.605-2.467-1.605-4.049 0-.176.023-.422.064-.739a5.431 5.431 0 0 1-2.027-2.074 5.873 5.873 0 0 1-.75-2.912 5.84 5.84 0 0 1 .838-3.064c.557-.926 1.307-1.612 2.244-2.057a5.797 5.797 0 0 1-.369-2.01c0-1.582.533-2.935 1.605-4.049 1.073-1.113 2.356-1.675 3.85-1.675.668 0 1.307.123 1.91.369a5.812 5.812 0 0 1 2.027-2.326A5.082 5.082 0 0 1 200 185c1.049 0 2.016.299 2.895.885a5.864 5.864 0 0 1 2.027 2.326 4.994 4.994 0 0 1 1.91-.369c1.494 0 2.772.556 3.832 1.676 1.061 1.119 1.588 2.466 1.588 4.048 0 .739-.111 1.407-.334 2.01.937.445 1.687 1.131 2.244 2.057.557.931.838 1.957.838 3.07Zm-15.639 4.518 6.194-9.276c.158-.246.205-.515.152-.802a.98.98 0 0 0-.451-.668 1.138 1.138 0 0 0-.803-.17 1.028 1.028 0 0 0-.703.433l-5.455 8.203-2.514-2.507a.993.993 0 0 0-.767-.317 1.185 1.185 0 0 0-.768.317 1.024 1.024 0 0 0-.299.755c0 .299.1.551.299.756l3.451 3.451.17.135c.199.135.404.199.604.199.392-.005.691-.169.89-.509Z" /></g><script> var apiTime, mainTaskInterval, _offSet = ';
    string private svgPart5 =
        ' , timeDelta = 0, paused = !1; async function getUTC() { try { await fetch("https://worldtimeapi.org/api/timezone/Etc/UTC", {}).then((e => e.json())).then((e => { apiTime = e.unixtime })) } catch { apiTime = Math.floor((new Date).getTime() / 1e3) } } document.getElementById("secondCenter").addEventListener("click", (async e => { if (paused) return await run(), void (paused = !1); window.clearInterval(mainTaskInterval), paused = !0 })); const hourHand = document.getElementById("houru"), minHand = document.getElementById("minu"), secHand = document.getElementById("secondCenter"); function baseDateObj() { var e = new Date; timeDelta = Math.floor(e.getTime()) - 1e3 * apiTime; var t = new Date(0); return t.setUTCSeconds(apiTime + _offSet), t } function generateCurrentTime(e) { return new Date(e.getTime() + 6e4 * e.getTimezoneOffset() + timeDelta) } function generateCurrentAngles(e) { var t = 6 * e.getSeconds() + 6 * e.getMilliseconds() / 1e3, n = 6 * e.getMinutes() + .1 * e.getSeconds(), a = 30 * e.getHours() + .5 * e.getMinutes(); minHand.setAttribute("transform", `rotate(${n},200,200)`), hourHand.setAttribute("transform", `rotate(${a},200,200)`), secHand.setAttribute("transform", `rotate(${t},200,200)`) } function actual() { generateCurrentAngles(generateCurrentTime(baseDateObj())) } var update; async function run() { await getUTC(), mainTaskInterval = setInterval(update, 200) } update = function () { actual() }, run(); </script> </svg>';

    string[2] private handColor = ["000000", "ffffff"];

    string[23] private faceColor = [
        "ce8120",
        "e5a0c8",
        "b5252d",
        "52365e",
        "ea392a",
        "98d9f0",
        "f36e6e",
        "e22e2d",
        "e76f65",
        "f6db46",
        "7fcfdd",
        "aada4a",
        "e6444c",
        "2d6485",
        "4f60a7",
        "edaa3e",
        "2b5452",
        "fad450",
        "685620",
        "d0f4e2",
        "569e32",
        "5fcd8c",
        "2d5352"
    ];
    //tokenID -> time
    mapping(uint256 => uint256) private _offsets;

    function setContractURI(string memory _uri) public onlyOwner {
        _contractURI = _uri;
    }

    // less than 86400
    ///@notice this function setTimeZone for specific Watchecks, can be called only by token owner
    ///@param id is the token that you want set time zone for
    ///@param time is the offset with respect to UTC, time should be less than 86400
    function setTimeZone(uint256 id, uint256 time) public {
        require(time < 86400, "bad time");
        require(msg.sender == Imini721(targetContract).ownerOf(id),"you are not the owner");
        _offsets[id] = time;
    }

    function getTimeZone(uint256 id) public view returns (uint256) {
        return _offsets[id];
    }

    function renderTokenById(uint256 id) public view returns (string memory) {
        uint256 _time = _offsets[id];
        string memory _svg0 = string(
            abi.encodePacked(
                svgPart0,
                faceColor[id % 23],
                svgPart1,
                _toString((_time % 43200) / 120),
                svgPart1b,
                handColor[id % 2],
                svgPart2,
                _toString((_time % 3600) / 10),
                svgPart2b
            )
        );
        string memory _svg1 = string(
            abi.encodePacked(
                handColor[id % 2],
                svgPart3,
                _toString((_time % 60) * 6),
                svgPart3b,
                handColor[(id + 1) % 2],
                svgPart4,
                _toString(_time),
                svgPart5
            )
        );
        return string(abi.encodePacked(_svg0, _svg1));
    }

    function previewTokenById(uint256 id, uint256 time)
        public
        view
        returns (string memory)
    {
        uint256 _time = time;
        string memory _svg0 = string(
            abi.encodePacked(
                svgPart0,
                faceColor[id % 23],
                svgPart1,
                _toString((_time % 43200) / 120),
                svgPart1b,
                handColor[id % 2],
                svgPart2,
                _toString((_time % 3600) / 10),
                svgPart2b
            )
        );
        string memory _svg1 = string(
            abi.encodePacked(
                handColor[id % 2],
                svgPart3,
                _toString((_time % 60) * 6),
                svgPart3b,
                handColor[(id + 1) % 2],
                svgPart4,
                _toString(_time),
                svgPart5
            )
        );
        return string(abi.encodePacked(_svg0, _svg1));
    }

    function constructTokenURI(uint256 id)
        internal
        view
        returns (string memory)
    {
        string memory _imageData = Base64.encode(bytes(renderTokenById(id)));
        string
            memory _header = '{"name": "Watchecks ';
        string memory _mid  =    '","description": "This Clockwork is Adjustable",';
        string memory _attr = string(
            abi.encodePacked(
                '"attributes": [{"trait_type": "Reference","value": "Ref#',
                _toString(id % 46),
                '"},{"display_type": "number","trait_type": "Number","value": ',
                _toString(id),
                "}]}"
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                _header,
                                _toString(id),
                                _mid,
                                '"image": "data:image/svg+xml;base64,',
                                _imageData,
                                '", "animation_url": "data:image/svg+xml;base64,',
                                _imageData,
                                '",',
                                _attr
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        //zora proxy check the token existence
        return constructTokenURI(tokenId);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    function initializeWithData(bytes memory initData) external {
        //pass
    }
}