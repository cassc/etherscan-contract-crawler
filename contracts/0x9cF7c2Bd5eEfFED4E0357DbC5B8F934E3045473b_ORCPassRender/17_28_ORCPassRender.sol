pragma solidity 0.8.15;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./AdministeredSVG.sol";
import "./Common.sol";
import "./IORCPass.sol";

error IdNotFound();
error IdAlreadyUsed();
error NotTheOwner();
error WrongPaymentValue();
error AlreadyBought();
error FailedToTransferEther();
error BackgroundNotOwned();
error WrongLength();

contract ORCPassRender is Common, AdministeredSVG {
    /**
        @dev Emitted when somebody buys a specific background id
    */
    event BackgroundSold(
        address seller,
        address buyer,
        string backgroundID,
        uint256 price
    );
    /**
        @dev Emitted when somebody adds a background to a given tokenID
    */
    event CreateBackground(
        address sender,
        uint256 tokenID,
        string backgroundID
    );

    /**
        @dev Emitted when somebody updates the background content
    */
    event UpdateBackgroundContent(
        address sender,
        uint256 tokenID,
        string backgroundID
    );

    /**
        @dev Emitted when somebody updates the background CSS
    */
    event UpdateBackgroundCSS(
        address sender,
        uint256 tokenID,
        string backgroundID
    );

    /**
        @dev Emitted when somebody updates the background price
    */
    event UpdateBackgroundPrice(
        address sender,
        string backgroundID,
        uint256 oldPrice,
        uint256 newPRice
    );

    /**
        @dev Emitted when a moderator has blacklisted a background
    */
    event BackgroundBlacklisted(
        address sender,
        string[] backgroundIDs,
        bool[] blacklisted
    );

    struct BackgroundData {
        uint16 tokenID;
        string background;
        string css;
        uint256 index;
        uint256 price;
        uint256 sold;
        uint256 revenue;
        bool blacklist;
    }

    struct TokenContent {
        BackgroundOrigin[] backgroundsIDs;
        uint256 main;
        uint256 backPass;
        string backPassContent;
        string backPassContentCSS;
        string backPassContentFilters;
    }

    struct BackgroundOrigin {
        uint256 index;
        bool created;
    }

    IORCPass public nft;

    // details that a given token ID has to be rendered as background or content on the backend side of the pass
    mapping(uint256 => TokenContent) public tokenContent;

    // specific informations regarding a background id
    mapping(string => BackgroundData) public backgroundsData;

    // background ids
    string[] public backgroundIDs;

    string[6] private _stars = [
        "M425 225 L433 245 L412 233 L438 233 L417 245 L425 225",
        "M425 201 L433 221 L412 209 L438 209 L417 221 L425 201"
        "M425 177 L433 197 L412 185 L438 185 L417 197 L425 177",
        "M425 153 L433 173 L412 161 L438 161 L417 173 L425 153",
        "M425 129 L433 149 L412 137 L438 137 L417 149 L425 129",
        "M425 105 L433 125 L412 113 L438 113 L417 125 L425 105"
    ];
    string[5][6] private grv = [
        ["#CFCFCF", "#C0C0C0", "#B1B1B1", "#B1B1B1", "#A2A2A2"],
        ["#CD7F31", "#B56E26", "#9E5D1C", "#B56E26", "#CD7F31"],
        ["#CE910A", "#C1860D", "#B57C0F", "#C1860D", "#CE910A"],
        ["#ECECE9", "#E5E4E1", "#DFDEDC", "#D9D9D7", "#D3D3D2"],
        ["#F98902", "#F66A03", "#F11900", "#F66A03", "#F98902"],
        ["#7E8F13", "#697B10", "#54680D", "#697B10", "#7E8F13"]
    ];

    string[6] private bv = ["0.15", "0.7", "0.6", "0.4", "0.7", "0.7"];
    string[6] private bg = [
        "#575454",
        "#CD7F32",
        "#ffd700",
        "#e5e4e2",
        "#e22822",
        "#90EE90"
    ];
    string[6] private bor = [
        "#242323",
        "#3e260f",
        "#996515",
        "#1a1b1d",
        "#421212",
        "#1B4D3E"
    ];

    constructor(IORCPass nft_) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MODERATOR, _msgSender());

        nft = nft_;
        backgroundIDs.push("");
    }

    function getBackgrounds(uint256 start, uint256 end)
        public
        view
        returns (string[] memory ids)
    {
        if (start > end) {
            return ids;
        }

        if (start == 0) {
            start++;
        }

        if (end == 0 || end > backgroundIDs.length) {
            end = backgroundIDs.length;
        }

        ids = new string[](end - start);

        uint256 count;
        for (uint256 i = start; i < end; i++) {
            ids[count] = backgroundIDs[i];
            count++;
        }

        return ids;
    }

    function clearBackground(
        uint16 tokenID,
        bool main,
        bool backPass
    ) public {
        if (nft.ownerOfERC721Like(tokenID) != _msgSender())
            revert NotTheOwner();
        if (main) {
            tokenContent[tokenID].main = 0;
        }
        if (backPass) {
            tokenContent[tokenID].backPass = 0;
        }
    }

    function applyMainBackgronund(uint16 tokenID, string memory backgroundID)
        public
    {
        _applyBackgroundCheck(tokenID, backgroundID);
        tokenContent[tokenID].main = backgroundsData[backgroundID].index;
    }

    function applyBackPassBackgronund(
        uint16 tokenID,
        string memory backgroundID
    ) public {
        _applyBackgroundCheck(tokenID, backgroundID);
        tokenContent[tokenID].backPass = backgroundsData[backgroundID].index;
    }

    function _applyBackgroundCheck(uint16 tokenID, string memory backgroundID)
        private
        view
    {
        if (nft.ownerOfERC721Like(tokenID) != _msgSender())
            revert NotTheOwner();
        if (backgroundsData[backgroundID].tokenID == 0) revert IdNotFound();

        if (!_ownsBackground(tokenID, backgroundID))
            revert BackgroundNotOwned();
    }

    function resetBackPass(uint16 tokenID) public {
        if (nft.ownerOfERC721Like(tokenID) != _msgSender())
            revert NotTheOwner();

        tokenContent[tokenID].backPassContent = "";
        tokenContent[tokenID].backPassContentCSS = "";
        tokenContent[tokenID].backPassContentFilters = "";
    }

    function customizeBackPassContent(
        uint16 tokenID,
        string memory backPassContent
    ) public {
        if (nft.ownerOfERC721Like(tokenID) != _msgSender())
            revert NotTheOwner();

        tokenContent[tokenID].backPassContent = backPassContent;
    }

    function customizeBackPassContentCSS(
        uint16 tokenID,
        string memory backPassContentCSS
    ) public {
        if (nft.ownerOfERC721Like(tokenID) != _msgSender())
            revert NotTheOwner();

        tokenContent[tokenID].backPassContentCSS = backPassContentCSS;
    }

    function customizeBackPassContentFilters(
        uint16 tokenID,
        string memory backPassContentFilters
    ) public {
        if (nft.ownerOfERC721Like(tokenID) != _msgSender())
            revert NotTheOwner();

        tokenContent[tokenID].backPassContentFilters = backPassContentFilters;
    }

    function blacklistBackgrounds(
        string[] memory backgroundID,
        bool[] memory blacklist
    ) public onlyRole(MODERATOR) {
        if (backgroundID.length != blacklist.length) revert WrongLength();
        for (uint256 i; i < backgroundID.length; i++) {
            if (backgroundsData[backgroundID[i]].tokenID == 0)
                revert IdNotFound();
            backgroundsData[backgroundID[i]].blacklist = blacklist[i];
        }

        emit BackgroundBlacklisted(msg.sender, backgroundID, blacklist);
    }

    function buyBackground(uint256 tokenID, string memory backgroundID)
        public
        payable
    {
        if (backgroundsData[backgroundID].tokenID == 0) revert IdNotFound();
        if (backgroundsData[backgroundID].price != msg.value)
            revert WrongPaymentValue();

        if (_ownsBackground(tokenID, backgroundID)) revert AlreadyBought();

        backgroundsData[backgroundID].revenue += msg.value;
        backgroundsData[backgroundID].sold++;
        tokenContent[tokenID].backgroundsIDs.push(
            BackgroundOrigin(backgroundsData[backgroundID].index, false)
        );

        address backgroundOwner = nft.ownerOfERC721Like(
            backgroundsData[backgroundID].tokenID
        );
        (bool sent, ) = backgroundOwner.call{value: msg.value}("");
        if (!sent) revert FailedToTransferEther();

        emit BackgroundSold(
            backgroundOwner,
            msg.sender,
            backgroundID,
            msg.value
        );
    }

    function _ownsBackground(uint256 tokenID, string memory backgroundID)
        private
        view
        returns (bool)
    {
        BackgroundOrigin[] memory ids = tokenContent[tokenID].backgroundsIDs;

        for (uint256 i; i < ids.length; i++) {
            if (
                keccak256(abi.encodePacked(backgroundID)) ==
                keccak256(abi.encodePacked(backgroundIDs[ids[i].index]))
            ) {
                return true;
            }
        }
        return false;
    }

    function addBackground(
        uint16 tokenID,
        string memory backgroundID,
        string memory background,
        string memory css,
        uint256 price
    ) public {
        if (nft.ownerOfERC721Like(tokenID) != _msgSender())
            revert NotTheOwner();
        if (backgroundsData[backgroundID].tokenID != 0) revert IdAlreadyUsed();

        backgroundsData[backgroundID] = BackgroundData(
            tokenID,
            background,
            css,
            backgroundIDs.length,
            price,
            0,
            0,
            false
        );
        tokenContent[tokenID].backgroundsIDs.push(
            BackgroundOrigin(backgroundIDs.length, true)
        );
        backgroundIDs.push(backgroundID);

        emit CreateBackground(msg.sender, tokenID, background);
    }

    function updateBackgroundContent(
        string memory backgroundID,
        string memory backgroundData
    ) public {
        _updateBackgroundCheck(backgroundID);
        backgroundsData[backgroundID].background = backgroundData;

        emit UpdateBackgroundContent(
            msg.sender,
            backgroundsData[backgroundID].tokenID,
            backgroundID
        );
    }

    function updateBackgroundCSS(string memory backgroundID, string memory css)
        public
    {
        _updateBackgroundCheck(backgroundID);
        backgroundsData[backgroundID].css = css;

        emit UpdateBackgroundCSS(
            msg.sender,
            backgroundsData[backgroundID].tokenID,
            backgroundID
        );
    }

    function updateBackgroundPrice(string memory backgroundID, uint256 price)
        public
    {
        _updateBackgroundCheck(backgroundID);
        backgroundsData[backgroundID].price = price;

        emit UpdateBackgroundPrice(
            msg.sender,
            backgroundID,
            backgroundsData[backgroundID].price,
            price
        );
    }

    function _updateBackgroundCheck(string memory backgroundID) private view {
        if (
            nft.ownerOfERC721Like(backgroundsData[backgroundID].tokenID) !=
            _msgSender()
        ) revert NotTheOwner();
    }

    function getSVGContent(
        uint256 tokenID,
        address owner,
        PassType passType
    ) public view returns (string memory) {
        string memory passNameDisplay = getPassDisplayName(passType);
        uint256[] memory createdIndex = getCreatedBackgroundsIndexses(tokenID);

        uint256 createdBackgrounds = createdIndex.length;
        uint256 soldBackgrounds = _getSoldBackgrounds(createdIndex);
        uint256 revenueBackgrounds = _getRevenueBackgrounds(createdIndex);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "',
                            passNameDisplay,
                            ' ORC Pass", "attributes": [{"trait_type": "PASS TYPE", "value": "',
                            passNameDisplay,
                            '"},{"trait_type": "Backgrounds", "value": ',
                            Strings.toString(createdBackgrounds),
                            '},{"trait_type": "Backgrounds Sold", "value": ',
                            Strings.toString(soldBackgrounds),
                            '}],"image_data": "',
                            string(
                                abi.encodePacked(
                                    "data:application/json;base64,",
                                    Base64.encode(
                                        _renderSVG(
                                            tokenID,
                                            owner,
                                            passType,
                                            createdBackgrounds,
                                            soldBackgrounds,
                                            revenueBackgrounds
                                        )
                                    )
                                )
                            ),
                            '"}'
                        )
                    )
                )
            );
    }

    function renderSVG(
        uint256 tokenID,
        address owner,
        PassType passType,
        uint256 createdBackgrounds,
        uint256 soldBackgrounds,
        uint256 revenueBackgrounds
    ) public view returns (string memory) {
        return
            string(
                _renderSVG(
                    tokenID,
                    owner,
                    passType,
                    createdBackgrounds,
                    soldBackgrounds,
                    revenueBackgrounds
                )
            );
    }

    function _renderSVG(
        uint256 tokenID,
        address owner,
        PassType passType,
        uint256 createdBackgrounds,
        uint256 soldBackgrounds,
        uint256 revenueBackgrounds
    ) private view returns (bytes memory) {
        string memory passNameDisplay = getPassDisplayName(passType);
        uint8 starsCount = uint8(passType);
        uint8 index = starsCount - 1;

        string memory textColor;
        if (passType == PassType.SILVER || passType == PassType.PLATINUM) {
            textColor = bor[index];
        } else {
            textColor = bg[index];
        }

        string memory stars;

        for (uint256 i; i < starsCount; i++) {
            stars = string(
                abi.encodePacked(
                    stars,
                    ' <path d="',
                    _stars[i],
                    '" filter="url(#fLight)" fill="',
                    textColor,
                    '"/>'
                )
            );
        }

        uint256 mainIndex = tokenContent[tokenID].main;
        uint256 backPassIndex = tokenContent[tokenID].backPass;

        string memory mainBackground;
        string memory mainBackgroundID;
        string memory mainBackgroundCSS;

        string memory backPassBackground;
        string memory backPassBackgroundID;
        string memory backPassBackgroundCSS;

        if (mainIndex > 0) {
            BackgroundData memory data = backgroundsData[
                backgroundIDs[mainIndex]
            ];
            mainBackground = data.background;
            mainBackgroundCSS = data.css;
            mainBackgroundID = string(
                abi.encodePacked("url(#", backgroundIDs[mainIndex], ")")
            );
        } else {
            mainBackgroundID = bor[index];
        }

        if (backPassIndex > 0) {
            if (mainIndex != backPassIndex) {
                BackgroundData memory data = backgroundsData[
                    backgroundIDs[backPassIndex]
                ];
                backPassBackground = data.background;
                backPassBackgroundCSS = data.css;
            }
            backPassBackgroundID = backgroundIDs[backPassIndex];
        } else {
            backPassBackgroundID = "fGradient";
        }

        string memory backPassContentFilters;
        string memory backPassContentCSS;
        string memory backPassContent = tokenContent[tokenID].backPassContent;
        if (bytes(backPassContent).length > 0) {
            backPassContentCSS = tokenContent[tokenID].backPassContentCSS;
            backPassContentFilters = tokenContent[tokenID]
                .backPassContentFilters;
        } else {
            backPassContent = string(
                abi.encodePacked(
                    '<g class="rotate" font-size="28" font-family="sans-serif"><path id="circle" d="M140, 250 a110,110 0 1,0 220,0 a110,110 0 1,0 -220,0" style="fill:transparent"/><text letter-spacing="1.2" filter="url(#fLight)" fill="',
                    textColor,
                    '"><textPath alignment-baseline="top" href="#circle">',
                    _toAsciiString(owner),
                    '</textPath></text></g><text x="250" y="230" text-anchor="middle" filter="url(#fLight)" fill="',
                    textColor,
                    '" font-family="Montserrat" font-size="45px" font-weight="900">ORC</text><text x="250" y="290" text-anchor="middle" filter="url(#fLight)" fill="',
                    textColor,
                    '" font-family="Montserrat" font-size="45px" font-weight="900">PASS</text>'
                )
            );
        }
        return
            abi.encodePacked(
                '<svg width="500px" height="500px" viewBox="0 0 500 500" preserveAspectRatio="none" xmlns="http://www.w3.org/2000/svg"><defs><linearGradient id="fGradient"><stop stop-color="',
                grv[index][0],
                '" offset="0%"/><stop stop-color="',
                grv[index][1],
                '" offset="25%"/><stop stop-color="',
                grv[index][2],
                '" offset="50%"/><stop stop-color="',
                grv[index][3],
                '" offset="75%"/><stop stop-color="',
                grv[index][4],
                '" offset="100%"/></linearGradient><filter id="df"><feTurbulence baseFrequency="0.17" numOctaves="5" result="tu"/><feColorMatrix in="tu" type="hueRotate" values="0" result="cl"><animate attributeName="values" from="0" to="360" dur="2.3s" repeatCount="indefinite"/></feColorMatrix><feDisplacementMap in2="cl" in="SourceGraphic" scale="12" xChannelSelector="R" yChannelSelector="G"/></filter><filter id="fLight"><feGaussianBlur in="SourceAlpha" stdDeviation="0.3" result="blur"/><feSpecularLighting in="blur" surfaceScale="1" specularConstant="10.5" specularExponent="7.5" result="so"><fePointLight x="-5000" y="10000"/></feSpecularLighting><feComposite in="so" in2="SourceAlpha" operator="in" result="so2"/><feComposite in="SourceGraphic" in2="so2" operator="arithmetic" k1="0" k2="1" k4="0" k3="',
                bv[index],
                '" result="ccc"/><feTurbulence result="TURBULENCE" baseFrequency="0.1" numOctaves="2" seed="',
                Strings.toString(tokenID),
                '"/><feDisplacementMap in="ccc" in2="TURBULENCE" scale="3"/></filter>',
                mainBackground,
                backPassBackground,
                backPassContentFilters,
                '  </defs><style type="text/css"><![CDATA[',
                mainBackgroundCSS,
                backPassBackgroundCSS,
                backPassContentCSS,
                ".fc {width: 400px;height: 400px;perspective: 2000px;}.fci {width: 100%;height: 100%;position: relative;text-align: center;transform-style: preserve-3d;animation: flip 15s ease-in-out infinite alternate;transform-origin: center;animation-play-state: running;}.fci:hover,.fcf:hover,.fcb:hover {animation-play-state: paused;}.fcf, .fcb {width: 100%;height: 100%;position: absolute;transform-origin: center;}.fcf {-webkit-backface-visibility: visible;backface-visibility: visible;}.fcb {transform: rotateY(180deg);-webkit-backface-visibility: hidden;backface-visibility: hidden;opacity:0;animation: flipb 15s ease-in-out infinite alternate;animation-play-state: running;}@keyframes flip{0%,15% {transform:rotateY(0);}30%,60% {transform:rotateY(180deg);}75%, 100% {transform:rotateY(0);}}@keyframes flipb{22.5% {opacity:0;}22.51% {opacity:1;}67.5% {opacity:1;}67.51% {opacity:0;}100% {opacity:0;}}svg .rotate{animation: 14s linear infinite rotate;transform-box:fill-box;transform-origin:center }@keyframes rotate{from{transform:rotate(0) }to{transform:rotate(360deg) }}.glowshadow{animation: glowshadow 1.5s ease-in-out infinite alternate;}",
                "@keyframes glowshadow{from{filter:drop-shadow( 0 0 15px #fff)drop-shadow( 0 0 20px ",
                bor[index],
                ")drop-shadow( 0 0 15px ",
                bg[index],
                ");}to{filter:drop-shadow( 0 0 10px #fff)drop-shadow( 0 0 10px ",
                bg[index],
                ")drop-shadow( 0 0 15px ",
                bor[index],
                ');}}]]></style><rect width="500" height="500" fill="',
                mainBackgroundID,
                '"/><g class="glowshadow fc"><rect x="38" y="113" rx="15" ry="15" width="430" height="280" fill="transparent"/><g class="fci"><g class="fcf"><rect x="38" y="113" rx="15" ry="15" width="424" height="274" filter="url(#df)" fill="',
                bg[index],
                '"/><rect x="52" y="127" rx="15" ry="15" width="400" height="250" fill="url(#fGradient)"/><rect x="50" y="125" rx="15" ry="15" width="400" height="250" fill="transparent" filter="url(#df)" stroke-width="8" stroke="',
                bor[index],
                '"/><rect x="130" y="203" rx="15" ry="15" width="240" height="83" fill="transparent" filter="url(#df)" stroke-width="8" stroke="',
                bor[index],
                '"/><text x="250" y="260" text-anchor="middle" filter="url(#fLight)" fill="',
                textColor,
                '" font-family="Montserrat" font-size="45px" font-weight="900">ORC PASS</text><text x="70" y="165" filter="url(#fLight)" fill="',
                textColor,
                '" font-family="Montserrat" font-size="30px" font-weight="900">',
                passNameDisplay,
                '</text><text x="',
                Strings.toString(390 - _lengthNumber(tokenID) * 5),
                '" y="165" text-anchor="middle" filter="url(#fLight)" fill="',
                textColor,
                '" font-family="Montserrat" font-size="30px" font-weight="900">NR. ',
                Strings.toString(tokenID),
                '</text><text x="250" y="330" text-anchor="middle" filter="url(#fLight)" fill="',
                textColor,
                '" font-family="Montserrat" font-size="22px" font-weight="900">Backgrounds: ',
                Strings.toString(createdBackgrounds),
                " - Sold: ",
                Strings.toString(soldBackgrounds),
                '</text><text x="250" y="360" text-anchor="middle" filter="url(#fLight)" fill="',
                textColor,
                '" font-family="Montserrat" font-size="22px" font-weight="900">Revenue: ',
                toString(revenueBackgrounds),
                ' ETH</text><g transform="translate(0,',
                Strings.toString(12 * starsCount),
                ')">',
                stars,
                '</g></g><g class="fcb"><rect x="38" y="113" rx="15" ry="15" width="424" height="274" filter="url(#df)" fill="',
                bg[index],
                '"/><rect x="52" y="127" rx="15" ry="15" width="400" height="250" fill="url(#',
                backPassBackgroundID,
                ')"/><rect x="50" y="125" rx="15" ry="15" width="400" height="250" fill="transparent" filter="url(#df)" stroke-width="8" stroke="',
                bor[index],
                '"/>',
                backPassContent,
                "</g></g></g></svg>"
            );
    }

    function getNumberOfCreatedBackground(uint256 tokenID)
        public
        view
        returns (uint256)
    {
        uint256 count;
        BackgroundOrigin[] memory ids = tokenContent[tokenID].backgroundsIDs;
        for (uint256 i; i < ids.length; i++) {
            if (ids[i].created) {
                count++;
            }
        }
        return count;
    }

    function getSoldBackgrounds(uint256 tokenID) public view returns (uint256) {
        uint256 sold;
        BackgroundOrigin[] memory ids = tokenContent[tokenID].backgroundsIDs;
        for (uint256 i; i < ids.length; i++) {
            if (ids[i].created) {
                sold += backgroundsData[backgroundIDs[ids[i].index]].sold;
            }
        }
        return sold;
    }

    function getRevenuedBackgrounds(uint256 tokenID)
        public
        view
        returns (uint256)
    {
        uint256 revenue;

        BackgroundOrigin[] memory ids = tokenContent[tokenID].backgroundsIDs;

        for (uint256 i; i < ids.length; i++) {
            if (ids[i].created) {
                revenue += backgroundsData[backgroundIDs[ids[i].index]].revenue;
            }
        }

        return revenue;
    }

    function getCreatedBackgroundsIndexses(uint256 tokenID)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count;

        BackgroundOrigin[] memory ids = tokenContent[tokenID].backgroundsIDs;

        uint256[] memory temp = new uint256[](ids.length);

        for (uint256 i; i < ids.length; i++) {
            if (ids[i].created) {
                temp[count] = ids[i].index;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);

        for (uint256 i; i < count; i++) {
            result[i] = temp[i];
        }

        return result;
    }

    function _getSoldBackgrounds(uint256[] memory indexes)
        private
        view
        returns (uint256)
    {
        uint256 sold;

        for (uint256 i; i < indexes.length; i++) {
            sold += backgroundsData[backgroundIDs[indexes[i]]].sold;
        }

        return sold;
    }

    function _getRevenueBackgrounds(uint256[] memory indexes)
        private
        view
        returns (uint256)
    {
        uint256 revenue;

        for (uint256 i; i < indexes.length; i++) {
            revenue += backgroundsData[backgroundIDs[indexes[i]]].revenue;
        }

        return revenue;
    }

    function _toAsciiString(address x) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = _char(hi);
            s[2 * i + 1] = _char(lo);
        }
        return string(abi.encodePacked("0x", s));
    }

    function _char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _lengthNumber(uint256 tokenID) private pure returns (uint256) {
        uint256 length = 1;
        while (tokenID / 10 > 0) {
            length++;
            tokenID /= 10;
        }
        return length;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        value /= 1000000000000000;

        if (value == 0) {
            return "0";
        }

        uint256 count;
        for (uint256 i = 0; i < 3 && value != 0; i++) {
            if (value % 10 == 0) {
                count++;
                value /= 10;
            } else {
                break;
            }
        }

        uint256 temp = value;
        uint256 numberOfDigits;
        while (temp != 0) {
            numberOfDigits++;
            temp /= 10;
        }

        uint256 totalDigits = numberOfDigits + count;

        bool hasPoint = count < 3;

        bool isSmall = numberOfDigits + count < 4;

        count = 3 - count;
        uint256 digits = ((totalDigits < 3) ? (3 - totalDigits) : 0) +
            numberOfDigits +
            (hasPoint ? (isSmall ? 2 : 1) : 0);
        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;

            if (hasPoint && count == 0) {
                hasPoint = false;
                buffer[digits] = bytes1(".");
                continue;
            }
            if (count > 0) {
                count--;
            }
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        if (isSmall) {
            for (uint256 i; i < 3 - totalDigits; i++) {
                digits--;
                buffer[digits] = bytes1("0");
            }
            buffer[1] = bytes1(".");
            buffer[0] = bytes1("0");
        }
        return string(buffer);
    }
}