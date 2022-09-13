//SPDX-License-Identifier: MIT
//
//                                        @@@@%%%%%%@@       #@@@@@#
//                 @                 @@@%%%%%%%%@@  @@@@%%%%%%%%%%%%%@@@
//                 @@@@@         @@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@
//                 @@%%%@@    @@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@#
//                 @@%%%%%@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@
//      @@@@@@@@@  @@%%%%%%%%%%%%%%%%%%@@@@@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%@&
//    @@@@%%%%%%%%%%%%%%%%%%%%%%%%@@*,,,,,,,,,,,,,,,,,,,,,,,,*@@@&%%%%%%%%%%%%@.
//        [email protected]@%%%%%%%%%%%%%%%%%%%%@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@%%%@@&
//           ,@@%%%%%%%%%%%%%%%%@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@
//              @@%%%%%%%%%%%%%&@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@
//              @@%%%%%%%%%%%%%@&,,,,,,,,,,,,,,,@@,,,,,,,,,,,,,,,,@
//             @@%%%%%%@,,@%%%%@*,,,,,,,,,,,,,@@@@@@,,,,,#@@@@@,,,@
//            @@%%%%%%%@,,,@%&@@@,,,,,,,,,,@@@*****&@@@@********@@@@
//            @#%%%%%%%%@,,,,,,,,,,,,*@@@@************@@***********@@
//            @%%%%%%%%%%@@,,,,,,,,@@*************@@@[email protected]@@@@@@@@@@@@@@
//           /@%%%%%%%%%%@@,,,,,,,,@@@********(@@@@[email protected]@.../[email protected]@@
//           /@%%%%%%@%%%%@,,,,,,,,,@@@****@@%[email protected]@@@[email protected]@@@
//            @%@@@ @&%%%%@,,,,,,,,,,,@@@@[email protected]@@#@@@@@@@@,@
//            @@   @@%%%%%@*,,,,,,,,,,,,,@@@@@@@@@@@@@,,,,@,,,,,,,@
//                 @%%%%%%@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#@,,,,,,@
//                @@%%%%%@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@,,,,,,@
//                @@@@@   *@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@,,,,,,,@
//                @        @,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@
//                         @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@
//                         @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@
//                         @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@
//                         /@*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@
//                          @@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@
//                          @@,,,,,,,,,,,,,,%@@@@@@*,,,,,,,,,,,,,,,@
//                            @(,,,,,,,,,,,,,,,,,,,@@@@@@%,,,,,,,(@@
//                                 @@/,,,,,,,,,,,@@@@@@@@
//
//                                  "fuck around and find out"
//
pragma solidity ^0.8.9;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721A} from "erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable} from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {ERC721AQueryable} from "erc721a/contracts/extensions/ERC721AQueryable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Randeez is ERC721AQueryable, ERC721ABurnable, Ownable {
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public  maxMint = 5;
    uint256 public  maxFree = 1111;
    uint256 public  price = .0169 ether;
    string public   baseURI;
    bool public     saleState;
    string public   prerevealURI = "https://randeez.xyz/randee.json";

    constructor() ERC721A("Randeez", "DEEZ") {}

    function mint(uint256 amount) external payable {
        uint256 totalMinted = _totalMinted();
        require(msg.sender == tx.origin);
        require(saleState);
        require(totalMinted + amount <= MAX_SUPPLY);
        require(amount <= maxMint);
        if (totalMinted < maxFree) {
            if ((maxFree - totalMinted) < amount) {
                require(msg.value == price * (amount - (maxFree - totalMinted)));
            }
        } else {
            require(msg.value == price * amount);
        }
        _safeMint(msg.sender, amount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length == 0) {
            return prerevealURI;
        }
        return string(abi.encodePacked(baseURI, _toString(tokenId), '.json'));
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrerevealURI(string memory prerevealURI_) external onlyOwner {
        prerevealURI = prerevealURI_;
    }

    function setSaleState(bool saleState_) external onlyOwner {
        saleState = saleState_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxMint(uint256 maxMint_) external onlyOwner {
        maxMint = maxMint_;
    }

    function setMaxFree(uint256 maxFree_) external onlyOwner {
        maxFree = maxFree_;
    }

    function preMint(address[] calldata addresses, uint256[] calldata count) external onlyOwner {
        require(addresses.length == count.length);
        for (uint256 i; i < addresses.length; i++) {
            _safeMint(addresses[i], count[i]);
        }
        require(_totalMinted() <= MAX_SUPPLY);
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}