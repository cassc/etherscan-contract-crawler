//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/*
    The elves have been working hard to get presents ready for Christmas Eve.
    So busy that they did not notice that the Heat Miser snuck in and stole their christmas tree.
    Fortunately, Santa gives free christmas trees to anybody on his nice list.
    Unfortunately, it appears that the Heat Miser took the magical ornaments that give each reindeer their flying power and hid them in the EVM!
    You need to get a new christmas tree and find the ornaments or else Christmas may be cancelled.
*/
/* 
Ornaments
-------------------
Dasher  - 0x0573221EedD49feacb8c0b347f4f32A6411eae04
Dancer  - 0xe8c15fB0C9872D8fC30BD5948717fe125335E2f9
Prancer - 0x0000000000000000000000000000000000000000
Vixen   - 0xA211338c33A9Bdd29F541478ECFEf51417904Be9
Comet   - 0xE4c58b0e88418a9a6Db163EDd860B48B4a8Aa28A
Cupid   - 0x1aCd5e8e822F04683f9695bC819C3e99F7D43280
Donner  - 0xC1c5c5Fa50500923330Bedfa2daDcBF55e7690d6
Blitzen - 0x2af26b58802CF09AF1B0bE0C0Ba82AF45691667E
Rudolph - 0xcF1783Ca45E9BC3deA1819e2EB448030e85Ea286
*/
/*
    To claim an ornament, you need to sign a message with your address from the ornament.
    let wallet = new ethers.Wallet(ORNAMENT_PRIVATE_KEY);
    let sig = await wallet.signMessage(ethers.utils.arrayify(ethers.utils.solidityKeccak256(['address'], [YOUR_ADDRESS])));
*/
/*
    The first person to claim all 9 ornaments will be able to save Christmas.
    As a reward, they will receive a star topper on their tree.
*/

interface ISantasList {
    function isNice(address person_) external;
}

contract Cr0wnChristmas is ERC721, Ownable {
    using ECDSA for bytes32;
    uint256 public constant PRANCER =
        0xFD15EA5ED15EA5ED15EA5ED15EA5ED15EA5ED15EA5ED15EA5ED15EA5ED15EA5E;
    ISantasList private _santasList;
    address[9] private _ornament;
    address[8] public ornamentLocations;
    uint256 private _tokenId;
    mapping(address => mapping(address => bool)) private _ornamentMap;
    address public isChristmasSaved;

    constructor(address[9] memory ornament_) ERC721("Cr0wnChristmas", "CC") {
        _ornament = ornament_;
    }

    function startChristmas(address santasList_, address[8] calldata locations_)
        public
        onlyOwner
    {
        _santasList = ISantasList(santasList_);
        ornamentLocations = locations_;
    }

    function updateChristmas(address santasList_, address[9] memory ornament_, address[8] calldata locations_)
        public
        onlyOwner
    {
        _santasList = ISantasList(santasList_);
        _ornament = ornament_;
        ornamentLocations = locations_;
    }

    function claimOrnaments(
        address[] calldata ornament_,
        bytes[] calldata signature_
    ) public {
        require(balanceOf(msg.sender) > 0, "Must get a Christmas tree first");
        for (uint8 i = 0; i < ornament_.length; i++) {
            require(_ornamentExists(ornament_[i]), "Invalid Ornament");
            require(!_ornamentMap[msg.sender][ornament_[i]], "Already claimed");
            require(
                ornament_[i] ==
                    keccak256(abi.encodePacked(msg.sender))
                        .toEthSignedMessageHash()
                        .recover(signature_[i]),
                "Invalid Signature"
            );
            _ornamentMap[msg.sender][ornament_[i]] = true;
        }
    }

    function saveChristmas() public {
        require(isChristmasSaved == address(0), "Christmas is already saved");
        uint8 oc = ornamentCount(msg.sender);
        if (oc == 9) {
            isChristmasSaved = msg.sender;
            return;
        }
        revert("Not enough ornaments");
    }

    function ornamentCount(address treeHolder_) public view returns (uint8) {
        uint8 oc = 0;
        for (uint256 i = 0; i < _ornament.length; i++) {
            if (_ornamentMap[treeHolder_][_ornament[i]]) {
                oc++;
            }
        }
        return oc;
    }

    function getTree() public {
        require(balanceOf(msg.sender) == 0, "Already has a tree");
        _santasList.isNice(msg.sender);
        _tokenId++;
        _mint(msg.sender, _tokenId);
    }

    function getPrancerOrnament(uint256 christmasCheer) external {
        uint256 magic = uint256(
            keccak256(abi.encodePacked(PRANCER, christmasCheer, msg.sender))
        );
        if (magic > PRANCER) {
            _ornamentMap[msg.sender][_ornament[6]] = true;
            return;
        }
        revert("Not strong enough magic");
    }

    function _ornamentExists(address ornament_) internal view returns (bool) {
        for (uint8 i = 0; i < _ornament.length; i++) {
            if (_ornament[i] == ornament_) {
                return true;
            }
        }
        return false;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId_),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string
            memory imageData = "<svg xmlns='http://www.w3.org/2000/svg' height='800' width='800' viewBox='0 0 800 800'><rect fill='black' width='100%' height='100%' /><g transform='translate(140 93)'><path d='M173.95 230.77c-9.84-3.29-19.16-6.29-28.39-9.56q-8.11-2.88-16-6.45c-9.88-4.51-12.3-14.42-5.53-22.82 33.72-41.79 62.76-86.76 90.19-132.81 10-16.71 19.73-33.53 29.64-50.27 7-11.78 22.5-11.85 29.64 0 6.22 10.31 11.91 20.94 18.22 31.19 17.38 28.25 34.46 56.7 52.63 84.43 13.07 19.81 27.6 38.59 41.53 57.81 2.39 3.3 5.12 6.34 7.68 9.52 6.69 8.33 4.49 18.8-5.52 22.83-12.85 5.19-26 9.54-39.08 14.23-1.71.62-3.46 1.11-5.76 1.84 2.44 4 4.56 7.67 6.84 11.21 22.11 34.49 44.4 68.87 69.24 101.49 9.76 12.82 20 25.27 30.12 37.85 4.67 5.83 5.17 13 .65 18.33a19.47 19.47 0 01-6.69 4.73 384.79 384.79 0 01-43.86 17.36c-1.9.61-3.77 1.29-6.39 2.19 3.76 5.93 7.12 11.37 10.64 16.71 26 39.51 52.67 78.51 82.06 115.6 8.63 10.89 17.6 21.52 26.43 32.27 2.35 2.86 4.86 5.61 5.39 9.52.94 6.89-2.37 12.71-9.53 15.89-10.32 4.59-20.67 9.14-31.14 13.37a540.26 540.26 0 01-80.9 25.63c-18.18 4.18-36.69 7-55.05 10.38-1.78.33-3.54.84-5.69 1.35v5.81c0 8.54.05 17.07 0 25.61-.06 6.55-3.3 11.58-9.6 13.4a266.22 266.22 0 01-28.53 7c-13.86 2.39-27.88 4-42 3.47-20.78-.82-41.3-3.45-61.22-9.71-8.81-2.77-11.79-7-11.81-16.39V664.6c-2.37-.53-4.3-1.1-6.26-1.39a622.06 622.06 0 01-69.54-14.26 609.31 609.31 0 01-96-34.65c-8.22-3.73-11.54-9-9.93-17a16.76 16.76 0 013.63-7.3c32.1-37.28 61-76.94 88.49-117.71 9.73-14.45 19.27-29 28.88-43.55.9-1.37 1.69-2.8 2.87-4.77-4.11-1.49-7.91-2.77-11.64-4.22q-18.61-7.24-37.2-14.62c-4.25-1.69-7.81-4.3-9.86-8.54-2.78-5.75-1.09-10.75 2.68-15.42 8.27-10.23 16.88-20.22 24.67-30.82 14.59-19.85 29-39.86 42.92-60.19 12.35-18 23.92-36.61 35.81-55 .76-1.19 1.34-2.55 2.27-4.39z' fill='#34b401' /></g>";
        for (uint256 i = 0; i < _ornament.length; i++) {
            if (_ornamentMap[ownerOf(tokenId_)][_ornament[i]]) {
                imageData = string(
                    abi.encodePacked(imageData, getOrnamentImage(i))
                );
            }
        }
        if (isChristmasSaved == ownerOf(tokenId_)) {
            imageData = string(
                abi.encodePacked(
                    imageData,
                    "<g width='25' height='25' transform='translate(333 -5) scale(0.3)' paint-order='stroke fill markers' fill='yellow'><path d='M441.07,171.022l-152.385-22.144l-68.15-138.085l-68.148,138.085L0,171.022l110.268,107.484L84.237,430.277l136.298-71.656l136.299,71.656l-26.029-151.77L441.07,171.022z M220.535,313.018l-82.688,43.473l15.791-92.075l-66.896-65.208l92.449-13.435l41.344-83.774l41.346,83.773l92.449,13.435l-66.896,65.208l15.791,92.076L220.535,313.018z'/></g>"
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"Cr0wn Christmas","description":"NFT to track progress of the Cr0wn Christmas puzzle CTF event",',
                    '"image":"data:image/svg+xml;base64,',
                    Base64.encode(abi.encodePacked(imageData, "</svg>")),
                    '"}'
                )
            );
    }

    function getOrnamentImage(uint256 reindeerIdx)
        internal
        pure
        returns (string memory)
    {
        string
            memory pre = "<g paint-order='stroke fill markers' transform='translate(";
        string
            memory preEnd = ")'><circle transform='matrix(1 0 0 .98295 148 148.03)' fill='";
        string memory color;
        string memory pos;
        if (reindeerIdx == 0) {
            pos = "225 60";
            color = "hotpink";
        } else if (reindeerIdx == 1) {
            pos = "310 135";
            color = "red";
        } else if (reindeerIdx == 2) {
            pos = "180 205";
            color = "cyan";
        } else if (reindeerIdx == 3) {
            pos = "280 285";
            color = "blueviolet";
        } else if (reindeerIdx == 4) {
            pos = "380 385";
            color = "silver";
        } else if (reindeerIdx == 5) {
            pos = "160 365";
            color = "gold";
        } else if (reindeerIdx == 6) {
            pos = "130 515";
            color = "purple";
        } else if (reindeerIdx == 7) {
            pos = "257 465";
            color = "whitesmoke";
        } else if (reindeerIdx == 8) {
            pos = "390 540";
            color = "fuchsia";
        } else {
            revert("Invalid Reindeer");
        }
        string
            memory post = "' stroke='#000' r='50'/><rect width='25.147' height='12.573' rx='0' ry='0' transform='matrix(1.16 0 0 1.24 133.415 90.025)' fill='#e8b400' stroke='#000' stroke-width='.5'/><path d='M133.415 103.515c-.597 3.16-1.592 3.016 0 2.101q0 5.417 1.834 3.23l1.969-3.23c1.434 4.249 2.9 5.249 2.789 3.968s.606-2.551 2.132-3.855c-.313 1.37 1.269 3.307 2.707 4.101 1.969-.73 3.198-2.69 3.154-3.855 1.384.064 3.06 2.243 3.653 3.937.717-.398 2.01-2.547 2.625-4.1-.55 1.825 1.333 3.1 2.87 3.444.08-1.847.615-3.372 1.231-2.297.9-.56 2.074.774 2.46 2.297 1.914-.399 2.844-1.942 1.746-3.117 1.253-.406.76-1.767 0-2.624' fill='#e8b400' stroke='#000' stroke-width='.6' stroke-linejoin='round'/><path d='M135.25 89.889c8.523-33.634 16.908-33.701 25.155 0' fill='none' stroke='#000205' stroke-width='1.5'/></g>";
        return string(abi.encodePacked(pre, pos, preEnd, color, post));
    }
}