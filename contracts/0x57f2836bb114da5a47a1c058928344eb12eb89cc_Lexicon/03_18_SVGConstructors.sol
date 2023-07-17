// SPDX-License-Identifier: MIT

/************************************************************************************
 *       :::        :::::::::: :::    ::: ::::::::::: ::::::::   ::::::::  ::::    :::* 
 *     :+:        :+:        :+:    :+:     :+:    :+:    :+: :+:    :+: :+:+:   :+:  *
 *    +:+        +:+         +:+  +:+      +:+    +:+        +:+    +:+ :+:+:+  +:+   *
 *   +#+        +#++:++#     +#++:+       +#+    +#+        +#+    +:+ +#+ +:+ +#+    *
 *  +#+        +#+         +#+  +#+      +#+    +#+        +#+    +#+ +#+  +#+#+#     *
 * #+#        #+#        #+#    #+#     #+#    #+#    #+# #+#    #+# #+#   #+#+#      *
 *########## ########## ###    ### ########### ########   ########  ###    ####       *
 *************************************************************************************/

import {Base64} from "./Base64.sol";

library SVGConstructors{
    // 
    bytes constant private base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /** 
        Constructs single line of SVG
        
        @param one - First word
        @param two - Second word
        @param dyOffset - Offset to center, based off position, length and found in getOffset()

        @return string
     */
    function constructLine(string memory one, string memory two, string memory dyOffset) pure internal returns(string memory){
        string[4] memory parts;

        parts[0] = string(
            abi.encodePacked('<tspan x="50%" dy="', dyOffset, '">')
        );

        parts[1] = string(
            abi.encodePacked(one, " ")
        );

        parts[2] = two;

        parts[3] = '</tspan>';

        string memory line = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3])
        );

        return line;
    }

   function concat(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    // This function does the same as 'dataPtr(bytes memory)', but will also return the
    // length of the provided bytes array.
    function fromBytes(bytes memory bts) internal pure returns (uint addr, uint len) {
        len = bts.length;
        assembly {
            addr := add(bts, /*BYTES_HEADER_SIZE*/32)
        }
    }

    /** 
        Gets the dy offset for the svg
        
        @param current - the current line
        @param length - the length of the phrase
        
        @return string
     */
    function getOffset(uint current, uint length) pure internal returns (string memory){
        // single line
        if(length == 1 || length == 2){
            return "0em";
        }

        // two lines 
        if(length > 2 && length <= 4){
            return current == 0 ? "-0.6em" : "1.2em";
        }

        // three lines
        if(length > 4 && length <= 6){
            return current == 0 ? "-1.2em" : "1.2em";
        }

        // four lines
        if(length > 6 && length <= 8){
            return current == 0 ? "-1.8em" : "1.2em";
        }

        // five lines
        if(length > 8 && length <= 10){
            return current == 0 ? "-2.4em" : "1.2em";
        } 
    }


    /** 
        Converts a value to string
    
        @param value - value to convert

        @return - string
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/etreceipt
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

    function jsonBuilder(uint256 tokenId,  string memory output, string[] memory words) pure internal returns (string memory){
        string memory stringWords = words[0];
        for (uint i = 1; i < words.length; i++){
           stringWords = string(abi.encodePacked(stringWords, " ", words[i]));
        }
        return Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "LEXICON #',
                        toString(tokenId),
                        ' - ',
                        stringWords,
                        '", "description": "Lexicon is words.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
    }
}