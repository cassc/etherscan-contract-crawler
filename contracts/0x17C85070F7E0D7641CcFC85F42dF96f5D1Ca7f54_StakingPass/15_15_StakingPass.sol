//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract StakingPass is ERC721EnumerableUpgradeable, OwnableUpgradeable {

    error IncorrectBaseUri(string _uri);
    error IllegalTransferOfToken(address _user,  uint256 _illegalTokenId);

    using StringsUpgradeable for uint256;
    string public baseTokenURI;

    mapping (address => bool) public isController;

    modifier onlyController() {
        require(isController[msg.sender], "Only contract controller can call this function.");
        _;
    }

    function mint(address _to, uint256 _tokenId) external onlyController {
        _mint(_to, _tokenId);
    }

    function setController (address _controller) external onlyOwner {
        isController[_controller] = true;
    }

    function initialize(string memory _name, string memory _symbol) public initializer {
        __Ownable_init();
        __ERC721Enumerable_init();
        __ERC721_init(_name, _symbol);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory)  {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
    }

    ///@dev Setters
    function setBaseURI(string memory _baseURI) public onlyOwner {
        if (bytes(_baseURI).length == 0) {
            revert IncorrectBaseUri({
            _uri:_baseURI
            });
        }
        baseTokenURI = _baseURI;
    }

    function checkExistence(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require (isController[msg.sender], "Error: Only contract controller can call this function.");
        super._transfer(from, to, tokenId);
    }

}