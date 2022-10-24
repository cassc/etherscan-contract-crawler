// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

struct Semi {
    uint8 semiType;
    uint8 x;
    uint8 y;
}

interface ISemiNFT {
    function semis(uint256) external view returns (Semi memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract Renderer is Ownable {
    using Strings for uint256;
    using Strings for uint8;

    ISemiNFT public nftContract;
    string public soundBaseURI = "https://raw.githubusercontent.com/avcdsld/code-as-art/main/semi/metadata/sounds/";
    string public soundURIPostfix = ".mp3";
    string public percentEncodedImageBaseURI = "https%3A%2F%2Fraw.githubusercontent.com%2Favcdsld%2Fcode-as-art%2Fmain%2Fsemi%2Fmetadata%2Fimages%2F";
    string public imageURIPostfix = ".png";

    function setNftContract(address contractAddress) public onlyOwner {
        nftContract = ISemiNFT(contractAddress);
    }

    function setSoundBaseURI(string memory uri) public onlyOwner {
        soundBaseURI = uri;
    }

    function setSoundURIPostfix(string memory str) public onlyOwner {
        soundURIPostfix = str;
    }

    function setPercentEncodedImageBaseURI(string memory uri) public onlyOwner {
        percentEncodedImageBaseURI = uri;
    }

    function setImageURIPostfix(string memory str) public onlyOwner {
        imageURIPostfix = str;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        Semi memory semi = nftContract.semis(tokenId);

        string[4] memory svgParts;
        svgParts[0] = '%253Csvg%250D%250AviewBox%253D%25220%252C%25200%252C%2520256%252C%2520256%2522%250D%250Axmlns%253D%2522http%253A%252F%252Fwww.w3.org%252F2000%252Fsvg%2522%250D%250Aclass%253D%2522content%2522%250D%250A%253E%250D%250A';
        svgParts[1] = string.concat(
            '%253Ccircle%2520cx%253D%2522',
            (semi.x + 15).toString(),
            '%2522%2520cy%253D%2522',
            (semi.y + 15).toString(),
            '%2522%2520r%253D%252215%2522%2520fill%253D%2522%2523fffdb3%2522%2520%252F%253E'
        );
        address owner = nftContract.ownerOf(tokenId);
        uint256 balance = nftContract.balanceOf(owner);
        for (uint256 i = 0; i < balance; i++) {
            uint256 id = nftContract.tokenOfOwnerByIndex(owner, i);
            Semi memory s = nftContract.semis(id);
            svgParts[2] = string.concat(
                svgParts[2],
                '%253Cimage%250D%250Ax%253D%2522',
                s.x.toString(),
                '%2522%250D%250Ay%253D%2522',
                s.y.toString(),
                '%2522%250D%250Awidth%253D%252230%2522%250D%250Aheight%253D%252230%2522%250D%250ApreserveAspectRatio%253D%2522xMidYMid%2520meet%2522%250D%250Axlink%253Ahref%253D%2522',
                percentEncodedImageBaseURI,
                s.semiType.toString(),
                imageURIPostfix,
                '%2522%250D%250Adata-type%253D%2522',
                s.semiType.toString(),
                '%2522%252F%253E%250D%250A'
            );
        }
        svgParts[3] = '%253C%252Fsvg%253E';

        string memory js = string.concat(
            'const semis = document.querySelectorAll("image");',
            'for (let i = 0, l = semis.length; l > i; i++) {',
            ' const file = semis[i].getAttribute("data-type");',
            ' const src = `',
            soundBaseURI,
            '${file}',
            soundURIPostfix,
            '`;',
            ' const audio = new Audio(src);',
            ' semis[i].addEventListener("mousedown", () => {',
            '  audio.currentTime = 0;',
            '  audio.play();',
            ' });',
            '}'
        );

        string memory html = string.concat(
            '%253C%2521DOCTYPE%2520html%253E%253Chtml%253E%253Chead%253E%253Cmeta%2520charset%253D%2522utf-8%2522%2520%252F%253E%253Ctitle%253ESemi%253C%252Ftitle%253E%253Cstyle%253Ebody%257Bmargin%253A0px%253B%257D.container%257Bposition%253Arelative%253Bwidth%253A100vmin%253Bheight%253A100vmin%253Bbackground-color%253A%2523f4f4f4%253B%257D.content%257Bposition%253Aabsolute%253Btop%253A0%253Bleft%253A0%253B%257D%253C%252Fstyle%253E%253C%252Fhead%253E%253Cbody%253E%253Cdiv%2520class%253D%2522container%2522%253E%250D%250A',
            svgParts[0], svgParts[1], svgParts[2], svgParts[3],
            '%253C%252Fdiv%253E%253Cscript%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C',
            Base64.encode(bytes(js)),
            '%2522%253E%253C%252Fscript%253E%253C%252Fbody%253E%253C%252Fhtml%253E%250D%250A'
        );

        string memory json = string.concat(
            'data:application/json,',
            "%7B",
            '%22name%22%3A%20%22Semi%20%23', tokenId.toString(), '%22%2C',
            '%22description%22%3A%20%22Semi%22%2C',
            '%22animation_url%22%3A%20%22data%3Atext%2Fhtml%2C', html, '%22',
            "%7D"
        );

        return json;
    }
}