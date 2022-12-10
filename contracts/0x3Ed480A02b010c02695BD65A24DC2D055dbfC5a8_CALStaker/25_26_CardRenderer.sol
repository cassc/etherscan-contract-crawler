// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './data/interface/ISVGData.sol';
import './data/interface/ICardSVGParts.sol';

contract CardRenderer is Ownable {
    using Strings for uint256;

    struct Datas {
        ISVGData black1;
        ISVGData black2;
        ISVGData black3;
        ISVGData gold1;
        ISVGData gold2;
        ISVGData gold3;
        ISVGData platinum1;
        ISVGData platinum2;
        ISVGData platinum3;
        ISVGData silver1;
        ISVGData silver2;
        ISVGData silver3;
        ICardSVGParts parts;
    }

    Datas public data;
    IERC721 public shuriken;

    constructor(Datas memory _data) {
        data = _data;
    }

    function get(
        string calldata name,
        address owner,
        uint256 tokenId
    ) public view returns (bytes memory) {
        uint256 balance = shuriken.balanceOf(owner);
        ISVGData target1 = data.silver1;
        ISVGData target2 = data.silver2;
        ISVGData target3 = data.silver3;
        if (balance > 99) {
            target1 = data.platinum1;
            target2 = data.platinum2;
            target3 = data.platinum3;
        } else if (balance > 49) {
            target1 = data.black1;
            target2 = data.black2;
            target3 = data.black3;
        } else if (balance > 19) {
            target1 = data.gold1;
            target2 = data.gold2;
            target3 = data.gold3;
        }
        return
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                target1.data(),
                Base64.encode(abi.encodePacked(Strings.toHexString(uint256(uint160(owner))))),
                'PC90c3Bhbj48dHNwYW4geT0iODciIHg9IjAiPi0tPC90c3Bhbj48L3RleHQ+PHRleHQgdHJhbnNmb3JtPSJtYXRyaXgoLjkzOTY5MyAtLjM0MjAyIC4zNDIwMiAuOTM5NjkzIDEzOS45MyA2MjEuNTkpIiBmb250LXNpemU9IjE1LjMiIGxldHRlci1zcGFjaW5nPSIuMDhlbSIgY2xhc3M9ImMiPiA8dHNwYW4geD0iMCIgeT0iMCI+',
                Base64.encode(abi.encodePacked(addSpace(name))),
                'PC90c3Bhbj4gIDx0c3BhbiB5PSIyMS43NSIgeD0iMCI+U04g',
                Base64.encode(abi.encodePacked(addSpace(string(abi.encodePacked(tokenId.toString(), '</tspan>'))))),
                target2.data(),
                target3.data(),
                data.parts.getStars(balance),
                'PC9nPiAgPC9zdmc+'
            );
    }

    function getColor(address owner) public view returns (string memory color) {
        uint256 balance = shuriken.balanceOf(owner);
        color = 'silver';
        if (balance > 99) {
            color = 'platinum';
        } else if (balance > 49) {
            color = 'black';
        } else if (balance > 19) {
            color = 'gold';
        }
    }

    function getShurikenBalance(address owner) public view returns (uint256) {
        return shuriken.balanceOf(owner);
    }

    function setShuriken(IERC721 _shuriken) public onlyOwner {
        shuriken = _shuriken;
    }

    function setDatas(Datas memory _data) public onlyOwner {
        data = _data;
    }

    function addSpace(string memory req) public pure returns (string memory) {
        uint256 l = bytes(req).length;
        for (uint256 i = 0; i < 3 - (l % 3); i++) {
            req = string(abi.encodePacked(req, ' '));
        }
        return req;
    }
}