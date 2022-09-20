//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {StringUtil} from "./util/StringUtil.sol";
import {IMessageValidator} from "./interface/IMessageValidator.sol";

/**
 * @dev Validation
 */
contract MessageValidator is IMessageValidator {
    using StringUtil for *;

    uint16 private _maxLenPerRow;
    uint16 private _maxRows;
    uint16 private _maxPages;

    constructor(
        uint16 maxLenPerRow,
        uint16 maxRows,
        uint16 maxPages
    ) {
        _maxLenPerRow = maxLenPerRow;
        _maxRows = maxRows;
        _maxPages = maxPages;
    }

    function validate(string memory _msg)
        external
        view
        override
        returns (Result memory)
    {
        if (!_isAllowedInput(_msg)) {
            return _asResult(false, "Validator: Invalid character found");
        }
        StringUtil.slice memory messageSlice = _msg.toSlice();
        // ページ数チェック / Check the numer of pages
        StringUtil.slice memory FF = "\x0c".toSlice();
        uint16 fFCount = uint16(messageSlice.count(FF));
        if (!(fFCount >= 0 && fFCount <= _maxPages - 1)) {
            return _asResult(false, "Validator: Too many pages");
        }

        // 各ページに対するチェック / Check for each page
        // 全体の文字数は行数と行あたりの文字数のチェックによって担保
        StringUtil.slice memory LF = "\n".toSlice();
        StringUtil.slice memory SPACE = " ".toSlice();

        uint16 lFCount;
        uint16 whiteSpaceCount;
        StringUtil.slice memory lhPage;
        StringUtil.slice memory lh;

        for (uint16 i = 0; i <= fFCount; i++) {
            lhPage = messageSlice.split(FF);
            // 空ページチェック
            if (lhPage._len == 0) {
                return _asResult(false, "Validator: Empty page");
            }
            // 行数のチェック
            lFCount = uint16(lhPage.count(LF));
            if (!(lFCount >= 0 && lFCount <= _maxRows - 1)) {
                return _asResult(false, "Validator: Too many rows");
            }
            // 改行/半角スペースのみは許可しない
            whiteSpaceCount = uint16(lhPage.count(SPACE));
            if (lFCount + whiteSpaceCount == lhPage._len) {
                return
                    _asResult(
                        false,
                        "Validator: Only line breaks or spaces are not allowed"
                    );
            }
            // 行あたりの文字数のチェック
            // 改行なしの場合は `split` では対応できないの先にチェック
            if (lFCount == 0) {
                if (lhPage._len > _maxLenPerRow) {
                    return _asResult(false, "Validator: Too long row");
                }
            }
            for (uint16 j = 0; j <= lFCount; j++) {
                lh = lhPage.split(LF);
                if (lh._len > _maxLenPerRow) {
                    return _asResult(false, "Validator: Too long row");
                }
            }
        }
        return _asResult(true, "");
    }

    function _asResult(bool isValid, string memory message)
        private
        pure
        returns (Result memory)
    {
        return Result({ isValid: isValid, message: message });
    }

    // Allowed characters: ^[[email protected]#$%&-+=/.,'<>*~:;\"()^ \n\f]+$
    function _isAllowedChar(bytes1 c) private pure returns (bool) {
        return (c[0] == bytes1(uint8(10)) || // 0x0a
            c[0] == bytes1(uint8(12)) || // 0x0c
            (c[0] >= bytes1(uint8(32)) && c[0] <= bytes1(uint8(90))) || // 0x20 .. 0x5a
            c[0] == bytes1(uint8(94)) || // 0x5e
            c[0] == bytes1(uint8(126))); // 0x7e
    }

    function _isAllowedInput(string memory input) private pure returns (bool) {
        bytes memory inputBytes = bytes(input);
        for (uint256 i = 0; i < inputBytes.length; i++) {
            if (!_isAllowedChar(inputBytes[i])) {
                return false;
            }
        }
        return true;
    }
}