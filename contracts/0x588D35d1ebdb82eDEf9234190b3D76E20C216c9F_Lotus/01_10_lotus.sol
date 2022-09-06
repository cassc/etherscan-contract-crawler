// SPDX-License-Identifier: MIT
// .__          __
// |  |   _____/  |_ __ __  ______
// |  |  /  _ \   __\  |  \/  ___/
// |  |_(  <_> )  | |  |  /\___ \
// |____/\____/|__| |____//____  >
//                             \/

pragma solidity ^0.8.10;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Lotus is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private _baseTokenURI;

    constructor(
        uint16 _maxTokenCount,
        address _teamAddress,
        address[] memory _airdropAddresses,
        uint8[] memory _airdropQuantities
    ) ERC721A("Lotus", "LOTUS") {
        uint16 _totalAirdropped = 0;
        for (uint16 i = 0; i < _airdropAddresses.length; i++) {
            _safeMint(_airdropAddresses[i], _airdropQuantities[i]);
            _totalAirdropped += _airdropQuantities[i];
        }

        require(
            _totalAirdropped < _maxTokenCount,
            "reserve cannot be greater than max token count"
        );

        _safeMint(_teamAddress, _maxTokenCount - _totalAirdropped);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Something went wrong.");
    }
}