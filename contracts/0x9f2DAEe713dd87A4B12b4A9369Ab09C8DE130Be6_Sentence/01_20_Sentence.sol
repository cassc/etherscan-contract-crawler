// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./common/EnumerableMap.sol";
import "./common/Descriptor.sol";
import "./Word.sol";

contract Sentence is ERC721, ERC721Enumerable, Ownable {
    // lib
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using Strings for uint256;

    // struct

    // constant

    // storage
    uint256 private _counter;
    Word public wordAddress;
    string private _basePath;

    mapping(bytes32 => uint256) public sentenceHash2TokenID;
    mapping(uint256 => bytes32) public sentenceTokenID2Hash;
    mapping(bytes32 => string) public sentenceHash2String;
    mapping(uint256 => uint256) public sentenceTokenID2Color;

    // event

    constructor(address _word) ERC721("Sentence", "STC") {
        wordAddress = Word(_word);
    }

    function splitSentence(string memory sentence)
        public
        pure
        returns (string[] memory words)
    {
        bytes memory b = bytes(sentence);
        uint16 len = uint16(b.length);
        require(len >= 1 && len <= 319, "sentence length illegal!");

        uint16 count = 0;
        uint16 code = uint8(b[0]);
        require(
            code >= 32 && code <= 126,
            "sentence contains illegal characters!"
        );
        bool isPrevWord = (code >= 48 && code <= 57) ||
            (code >= 65 && code <= 90) ||
            (code >= 97 && code <= 122);
        bool isWord = false;
        uint16[] memory arrIndex = new uint16[](320);
        uint16 arrIndexIndex = 0;
        if (isPrevWord) {
            arrIndex[arrIndexIndex++] = 0;
        }

        for (uint16 i = 1; i < len - 1; ++i) {
            code = uint8(b[i]);
            require(
                code >= 32 && code <= 126,
                "sentence contains illegal characters!"
            );
            isWord =
                (code >= 48 && code <= 57) ||
                (code >= 65 && code <= 90) ||
                (code >= 97 && code <= 122);
            if (isWord && !isPrevWord) {
                arrIndex[arrIndexIndex++] = i;
            } else if (!isWord && isPrevWord) {
                arrIndex[arrIndexIndex++] = i;
                count++;
            }
            isPrevWord = isWord;
        }

        code = uint8(b[len - 1]);
        require(
            code >= 32 && code <= 126,
            "sentence contains illegal characters!"
        );
        isWord =
            (code >= 48 && code <= 57) ||
            (code >= 65 && code <= 90) ||
            (code >= 97 && code <= 122);
        if (isWord) {
            if (isPrevWord) {
                arrIndex[arrIndexIndex++] = len;
            } else {
                arrIndex[arrIndexIndex++] = len - 1;
                arrIndex[arrIndexIndex++] = len;
            }
            count++;
        } else {
            if (isPrevWord) {
                arrIndex[arrIndexIndex++] = len - 1;
                count++;
            }
        }

        words = new string[](count);
        for (uint16 i = 0; i < count; ++i) {
            uint16 start = arrIndex[i * 2];
            uint16 end = arrIndex[i * 2 + 1];
            bytes memory word = new bytes(end - start);
            for (uint16 j = start; j < end; ++j) {
                word[j - start] = b[j];
            }
            words[i] = string(word);
        }
    }

    function queryPrice(string memory sentence)
        public
        view
        returns (uint256 ret)
    {
        string[] memory words = splitSentence(sentence);
        bytes32[] memory wordHashs = new bytes32[](words.length);
        uint256 price = wordAddress.sentenceWordPrice();
        for (uint256 i = 0; i < words.length; ++i) {
            bytes32 wordHash = wordAddress.getWordHash(words[i]);
            if (wordAddress.isWordLock(wordHash)) {
                continue;
            }
            bool find = false;
            for (uint256 j = 0; j < i; ++j){
                if (wordHash == wordHashs[j]){
                    find = true;
                    continue;
                }
            }
            if (find){
                continue;
            }

            wordHashs[i] = wordHash;
            ret += price;
        }
    }

    function mint(string memory sentence, uint24 color) public payable {
        string[] memory words = splitSentence(sentence);

        bytes memory byteSentence = bytes(sentence);
        bytes memory byteLowerCaseSentence = new bytes(byteSentence.length);
        require((uint8)(byteSentence[byteSentence.length - 1]) != 32, "space at end");

        // tolowercase
        for (uint256 i = 0; i < byteLowerCaseSentence.length; ++i) {
            if (byteSentence[i] >= 0x41 && byteSentence[i] <= 0x5a) {
                byteLowerCaseSentence[i] = bytes1(uint8(byteSentence[i]) + 32);
            }
            else{
                byteLowerCaseSentence[i] = byteSentence[i];
            }
        }

        bytes32 hashSentence = keccak256(byteLowerCaseSentence);
        require(sentenceHash2TokenID[hashSentence] == 0, "sentence exsit!");

        // mint token
        _counter++;
        _mint(msg.sender, _counter);
        sentenceHash2TokenID[hashSentence] = _counter;
        sentenceHash2String[hashSentence] = sentence;
        sentenceTokenID2Hash[_counter] = hashSentence;
        sentenceTokenID2Color[_counter] = color;

        // word proc
        wordAddress.sentenceMint{value:msg.value}(_counter, words);
    }

    function queryTokenID(string memory sentence) public view returns (uint256) {
        bytes memory byteSentence = bytes(sentence);

        // tolowercase
        for (uint256 i = 0; i < byteSentence.length; ++i) {
            if (byteSentence[i] >= 0x41 && byteSentence[i] <= 0x5a) {
                byteSentence[i] = bytes1(uint8(byteSentence[i]) + 32);
            }
        }

        return sentenceHash2TokenID[keccak256(byteSentence)];
    }

    function querySentence(uint256 tokenID) public view returns (string memory) {
        return sentenceHash2String[sentenceTokenID2Hash[tokenID]];
    }

    // url
    function setBaseURI(string calldata path) public onlyOwner {
        _basePath = path;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (bytes(_basePath).length > 0) {
            return string(abi.encodePacked(_basePath, tokenId.toString()));
        }

        return Descriptor.GetSentenceDesc(tokenId, sentenceHash2String[sentenceTokenID2Hash[tokenId]], uint24(sentenceTokenID2Color[tokenId]));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}