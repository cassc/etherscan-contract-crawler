// SPDX-License-Identifier: MIT
//  ___   _  __   __  ______   _______  _______  _______  ___  
// |   | | ||  | |  ||      | |   _   ||       ||   _   ||   | 
// |   |_| ||  | |  ||  _    ||  |_|  ||  _____||  |_|  ||   | 
// |      _||  |_|  || | |   ||       || |_____ |       ||   | 
// |     |_ |       || |_|   ||       ||_____  ||       ||   | 
// |    _  ||       ||       ||   _   | _____| ||   _   ||   | 
// |___| |_||_______||______| |__| |__||_______||__| |__||___| 

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface Storage {
    function getKudasai(uint256 _back, uint256 _body, uint256 _hair, uint256 _eyewear, uint256 _face) external view returns (string memory);
    function getWeight(uint256 _parts, uint256 _id) external view returns (uint256);
    function getTotalWeight(uint256 _parts) external view returns (uint256);
    function getImageName(uint256 _parts, uint256 _id) external view returns (string memory);
    function getImageIdCounter(uint256 _parts) external view returns (uint256);
    function getHaka() external view returns (string memory);
}

contract Kudasai is ERC721Enumerable, ERC2981, Ownable {
    enum Parts {
        back,
        body,
        hair,
        eyewear,
        face
    }

    uint256 private constant _reserve = 500;
    uint256 private _tokenIdCounter = _reserve;
    uint256 private constant _tokenMaxSupply = 2000;
    address public minter;
    mapping(uint256 => uint256) private _seeds;
    mapping(uint256 => bool) private _hakaList;
    address private immutable _imageStorage;
    bool locked = false;
    event Mint(uint256 id);

    constructor(string memory name_, string memory symbol_, address storage_) ERC721(name_, symbol_) {
        _imageStorage = storage_;
        _setDefaultRoyalty(msg.sender, 1000);
    }

    modifier onlyMinter() {
        require(minter == msg.sender, "You do not have Mint authority");
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable) {
        require(!locked, "Transfers are locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _weightedChoiceOne(uint256 _parts, uint256 _weight) private view returns (uint256) {
        require(_weight < Storage(_imageStorage).getTotalWeight(_parts), "total weight is over");
        for (uint256 i = 0; i < Storage(_imageStorage).getImageIdCounter(_parts); i++) {
            if (_weight+1 <= Storage(_imageStorage).getWeight(_parts, i)) {
                return i;
            } else {
                _weight -= Storage(_imageStorage).getWeight(_parts, i);
            }
        }
        return 0;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setLocked(bool _locked) external onlyOwner {
        locked = _locked;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(tokenId < _tokenIdCounter, "call to a non-exisitent token");

        uint256 seed = _seeds[tokenId];
        uint256 back = _weightedChoiceOne(uint256(Parts.back), seed % Storage(_imageStorage).getTotalWeight(uint256(Parts.back)));
        uint256 body = _weightedChoiceOne(uint256(Parts.body), (seed /= 1000) % Storage(_imageStorage).getTotalWeight(uint256(Parts.body)));
        uint256 hair = _weightedChoiceOne(uint256(Parts.hair), (seed /= 1000) % Storage(_imageStorage).getTotalWeight(uint256(Parts.hair)));
        uint256 eyewear = _weightedChoiceOne(uint256(Parts.eyewear), (seed /= 1000) % Storage(_imageStorage).getTotalWeight(uint256(Parts.eyewear)));
        uint256 face = _weightedChoiceOne(uint256(Parts.face), (seed /= 1000) % Storage(_imageStorage).getTotalWeight(uint256(Parts.face)));

        string memory output;
        if (_hakaList[tokenId]) {
            output = Storage(_imageStorage).getHaka();
        } else {
            output = Storage(_imageStorage).getKudasai(
                back, body, hair, eyewear, face
            );
        }

        string memory _metaData = "";

        if (!Util.hashCheck(Storage(_imageStorage).getImageName(uint256(Parts.back), back), "None")) {
            _metaData = string(abi.encodePacked(_metaData, '{"trait_type": "Background", "value": "', Storage(_imageStorage).getImageName(uint256(Parts.back), back), '"},'));
        }
        if (!Util.hashCheck(Storage(_imageStorage).getImageName(uint256(Parts.body), body), "None")) {
            _metaData = string(abi.encodePacked(_metaData, '{"trait_type": "Body", "value": "', Storage(_imageStorage).getImageName(uint256(Parts.body), body), '"},'));
        }
        if (!Util.hashCheck(Storage(_imageStorage).getImageName(uint256(Parts.hair), hair), "None")) {
            _metaData = string(abi.encodePacked(_metaData, '{"trait_type": "Hair", "value": "', Storage(_imageStorage).getImageName(uint256(Parts.hair), hair), '"},'));
        }
        if (!Util.hashCheck(Storage(_imageStorage).getImageName(uint256(Parts.eyewear), eyewear), "None")) {
            _metaData = string(abi.encodePacked(_metaData, '{"trait_type": "Eyewear", "value": "', Storage(_imageStorage).getImageName(uint256(Parts.eyewear), eyewear), '"},'));
        }
        if (!Util.hashCheck(Storage(_imageStorage).getImageName(uint256(Parts.face), face), "None")) {
            _metaData = string(abi.encodePacked(_metaData, '{"trait_type": "Face", "value": "', Storage(_imageStorage).getImageName(uint256(Parts.face), face), '"},'));
        }
        if (tokenId < _reserve) {
            _metaData = string(abi.encodePacked(_metaData, '{"trait_type": "Special", "value": "KudasaiOG"},'));
        }
    
        string memory attributes = string(
            abi.encodePacked(
                '[',
                _metaData,
                '{}]'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "MoreKudasai #',
                        Util.toStr(tokenId),
                        '", "description": "Kudasai, and you will recieve. More Genesis NFT for strong supporters. Let\'s seek, and find something interesting together. Opening the door to the new crypto world.","attributes":',
                        attributes,
                        ', "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function banbanban(uint256[] memory _ids) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            _hakaList[_ids[i]] = true;
        }
    }

    function dead(uint256[] memory _ids) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(ownerOf(_ids[i]) == msg.sender, "Not holder");
            _hakaList[_ids[i]] = true;
        }
    }

    function mintReserve(address _to, uint256[] memory _ids) public onlyMinter {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_ids[i] < _reserve, "Token ID cannot be used");
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        uint256(uint160(_to)),
                        uint256(blockhash(block.number - 1)),
                        _ids[i],
                        "kudasai"
                    )
                )
            );
            _seeds[_ids[i]] = seed;
            _safeMint(_to, _ids[i]);
            emit Mint(_ids[i]);
        }
    }

    function mintKudasai(address _to, uint256 _quantity) public onlyMinter {
        require(_tokenIdCounter + _quantity <= _tokenMaxSupply, "No more");
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 seed = uint256(
                keccak256(
                    abi.encodePacked(
                        uint256(uint160(_to)),
                        uint256(blockhash(block.number - 1)),
                        _tokenIdCounter,
                        "kudasai"
                    )
                )
            );
            _seeds[_tokenIdCounter] = seed;
            _safeMint(_to, _tokenIdCounter);
            emit Mint(_tokenIdCounter);
            _tokenIdCounter++;
        }
    }
}

library Util {
    function toStr(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory buffer = new bytes(len);
        while (_i != 0) {
            len -= 1;
            buffer[len] = bytes1(uint8(48 + uint256(_i % 10)));
            _i /= 10;
        }
        return string(buffer);
    }

    function hashCheck(string memory a, string memory b) pure internal returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }
}