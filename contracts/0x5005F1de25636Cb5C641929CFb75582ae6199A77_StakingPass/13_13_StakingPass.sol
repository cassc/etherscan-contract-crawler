//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract StakingPass is ERC1155Upgradeable, OwnableUpgradeable {

    error IncorrectBaseUri(string _uri);
    error IllegalTransferOfToken(address _user,  uint256 _illegalTokenId);

    using StringsUpgradeable for uint256;
    string public baseTokenURI;

    mapping (uint256 => bool) public exists;
    mapping (address => bool) public isController;

    modifier onlyController() {
        require(isController[msg.sender], "Only contract controller can call this function.");
        _;
    }

    function mint(address _to, uint256 _tokenId) external onlyController {
        require(!exists[_tokenId], "Token already exists.");
        exists[_tokenId] = true;
        _mint(_to, _tokenId, 1, "");
    }

    function setController (address _controller) external onlyOwner {
        isController[_controller] = true;
    }

    function initialize(string memory _uri) public initializer {
        __Ownable_init();
        __ERC1155_init(_uri);
        baseTokenURI = _uri;
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
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
        return exists[_tokenId];
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        require (isController[msg.sender], "Error: Only contract controller can call this function.");
        super._safeTransferFrom(from, to, id, amount, data);
    }

}