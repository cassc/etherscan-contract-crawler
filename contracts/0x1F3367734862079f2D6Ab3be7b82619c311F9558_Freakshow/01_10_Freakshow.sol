//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract Freakshow is Ownable, ERC721A, IERC721Receiver, Pausable {
    using SafeMath for uint256;

    address clownzContract;
    string public baseTokenURI;
    uint256 public exchangeRate = 5;
    uint256[] customFreakshowTokens;
    mapping(uint256 => bool) public isCustomClown;

    constructor(address _clownzContract) ERC721A("Freakshow", "Freakshow") {
        isCustomClown[745] = true;
        isCustomClown[2062] = true;
        isCustomClown[4533] = true;
        isCustomClown[3310] = true;
        isCustomClown[1319] = true;
        isCustomClown[2264] = true;
        clownzContract = _clownzContract;
    }

    function setClownzContract(address _clownzContract) external onlyOwner {
        clownzContract = _clownzContract;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getCustomFreakshowTokens()
        external
        view
        returns (uint256[] memory)
    {
        return customFreakshowTokens;
    }

    function setExchangeRate(uint256 _exchangeRate) external onlyOwner {
        exchangeRate = _exchangeRate;
    }

    function setCustomClown(uint256 _token, bool _isCustom) external onlyOwner {
        isCustomClown[_token] = _isCustom;
    }

    function exchangeCustomMint(uint256[] calldata _tokens)
        external
        whenNotPaused
    {
        for (uint256 index; index < _tokens.length; index++) {
            require(isCustomClown[_tokens[index]], "Not custom token");
            IERC721(clownzContract).safeTransferFrom(
                msg.sender,
                address(this),
                _tokens[index]
            );
        }

        _safeMint(msg.sender, _tokens.length);
        customFreakshowTokens.push(_nextTokenId().sub(1));
    }

    function exchangeMint(uint256[] calldata _tokens) external whenNotPaused {
        require(
            _tokens.length % exchangeRate == 0,
            "Not enough tokens provided"
        );
        for (uint256 index; index < _tokens.length; index++) {
            require(
                !isCustomClown[_tokens[index]],
                "Can not exchange custom clown"
            );
            IERC721(clownzContract).safeTransferFrom(
                msg.sender,
                address(this),
                _tokens[index]
            );
        }

        _safeMint(msg.sender, _tokens.length / exchangeRate);
    }

    function teamMint(address _to, uint256 _amount) external onlyOwner {
        _safeMint(_to, _amount);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function withdraw(address _receiver, uint256 _amount) external onlyOwner {
        payable(_receiver).transfer(_amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}