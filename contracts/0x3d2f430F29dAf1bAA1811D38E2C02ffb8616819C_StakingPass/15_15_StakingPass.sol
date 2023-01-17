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

    function mint(address to, uint256 tokenId) external onlyController {
        _mint(to, tokenId);
    }

    function toggleController (address controller) external onlyOwner {
        isController[controller] = !isController[controller];
    }

    function initialize(string memory name, string memory symbol) public initializer {
        __Ownable_init();
        __ERC721Enumerable_init();
        __ERC721_init(name, symbol);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)  {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    ///@dev Setters
    function setBaseURI(string memory baseURI) public onlyOwner {
        if (bytes(baseURI).length == 0) {
            revert IncorrectBaseUri({
            _uri:baseURI
            });
        }
        baseTokenURI = baseURI;
    }

    function checkExistence(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
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