// SPDX-License-Identifier: MIT
//  ___   _  __   __  ______   _______  _______  _______  ___      
// |   | | ||  | |  ||      | |   _   ||       ||   _   ||   |     
// |   |_| ||  | |  ||  _    ||  |_|  ||  _____||  |_|  ||   |     
// |      _||  |_|  || | |   ||       || |_____ |       ||   |     
// |     |_ |       || |_|   ||       ||_____  ||       ||   |     
// |    _  ||       ||       ||   _   | _____| ||   _   ||   |     
// |___| |_||_______||______| |__| |__||_______||__| |__||___|     
//  _______  _______  _______  ______    _______  _______  _______ 
// |       ||       ||       ||    _ |  |   _   ||       ||       |
// |  _____||_     _||   _   ||   | ||  |  |_|  ||    ___||    ___|
// | |_____   |   |  |  | |  ||   |_||_ |       ||   | __ |   |___ 
// |_____  |  |   |  |  |_|  ||    __  ||       ||   ||  ||    ___|
//  _____| |  |   |  |       ||   |  | ||   _   ||   |_| ||   |___ 
// |_______|  |___|  |_______||___|  |_||__| |__||_______||_______|

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KudasaiStorage is Ownable {
    enum Parts {
        back,
        body,
        hair,
        eyewear,
        face
    }
    mapping(Parts => uint256) public imageIdCounter;
    mapping(Parts => mapping(uint256 => string)) public images;
    mapping(Parts => mapping(uint256 => string)) public imageNames;
    mapping(Parts => mapping(uint256 => uint256)) public weights;
    mapping(Parts => uint256) public totalWeight;
    string public haka;

    function getKudasai(uint256 _back, uint256 _body, uint256 _hair, uint256 _eyewear, uint256 _face) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" buffered-rendering="static" width="1200px" height="1200px" viewBox="0,0,1200,1200"><defs>',
                    '<g id="bk">', images[Parts.back][_back], '</g>',
                    '<g id="bd">', images[Parts.body][_body], '</g>',
                    '<g id="h">', images[Parts.hair][_hair], '</g>',
                    '<g id="e">', images[Parts.eyewear][_eyewear], '</g>',
                    '<g id="f">', images[Parts.face][_face], '</g>',
                    '</defs><use href="#bk"/><use href="#bd"/><use href="#f"/><use href="#h"/><use href="#e"/></svg>'
                )
            );
    }

    function getHaka() external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" buffered-rendering="static" width="1200px" height="1200px" viewBox="0,0,1200,1200"><defs>',
                    '<g id="hakc">', haka, '</g>',
                    '</defs><use href="#hakc"/></svg>'
                )
            );
    }

    function getWeight(uint256 _parts, uint256 _id) external view returns (uint256) {
        return weights[Parts(_parts)][_id];
    }

    function getTotalWeight(uint256 _parts) external view returns (uint256) {
        return totalWeight[Parts(_parts)];
    }

    function getImageName(uint256 _parts, uint256 _id) external view returns (string memory) {
        return imageNames[Parts(_parts)][_id];
    }

    function getImageIdCounter(uint256 _parts) external view returns (uint256) {
        return imageIdCounter[Parts(_parts)];
    }

    function importHaka(string memory _svg) external onlyOwner {
        haka = _svg;
    }

    function importImage(uint256 _parts, uint256 _weight, string memory _svg, string memory _name) external onlyOwner {
        images[Parts(_parts)][imageIdCounter[Parts(_parts)]] = _svg;
        imageNames[Parts(_parts)][imageIdCounter[Parts(_parts)]] = _name;
        weights[Parts(_parts)][imageIdCounter[Parts(_parts)]] = _weight;
        totalWeight[Parts(_parts)] += _weight;
        imageIdCounter[Parts(_parts)]++;
    }

    function changeImage(uint256 _parts, uint256 _id, uint256 _weight, string memory _svg, string memory _name) external onlyOwner {
        require(_id < imageIdCounter[Parts(_parts)], "None");
        images[Parts(_parts)][_id] = _svg;
        imageNames[Parts(_parts)][imageIdCounter[Parts(_parts)]] = _name;
        totalWeight[Parts(_parts)] -= weights[Parts(_parts)][_id];
        weights[Parts(_parts)][_id] = _weight;
        totalWeight[Parts(_parts)] += _weight;
    }
}