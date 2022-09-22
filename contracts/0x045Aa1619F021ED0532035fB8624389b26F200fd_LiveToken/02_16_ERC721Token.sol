//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
 
contract ERC721Token is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string public metadataURI;

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change controllers and transfer it's ownership
    EnumerableSet.AddressSet controller;

    event controllerEvent(address _address, bool mode);
    event tokenMetadataUriChanged(string _metadataURI);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataURI,
        address _receiver
    ) ERC721(_name, _symbol) {
        metadataURI = _metadataURI;
        for(uint256 i = 1; i <= 9; i++ ) {
            _mint(_receiver, i);
        }
    }

    /**
    * @dev Get metadata server url for tokenId
    */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), 'Token: Token does not exist');
        return string(abi.encodePacked(metadataURI, "/", _tokenId.toString(), ".json"));
    }

    //// Controllers
    function updateMetadataURI(string memory _metadataURI) public onlyAllowed {
        metadataURI = _metadataURI;
        emit tokenMetadataUriChanged(_metadataURI);
    }

    //// Admin
    function setController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            controller.add(_controller);
        } else {
            controller.remove(_controller);
        }
        emit controllerEvent(_controller, _mode);
    }

    function getControllerLength() public view returns (uint256) {
        return controller.length();
    }

    function getControllerAt(uint256 _index) public view returns (address) {
        return controller.at(_index);
    }

    function getControllerContains(address _addr) public view returns (bool) {
        return controller.contains(_addr);
    }

    function getControllers() public view returns (address[] memory) {
        return controller.values();
    }


    //// Modifiers
    modifier onlyAllowed() {
        require(
            msg.sender == owner() || controller.contains(msg.sender),
            "NFT: Not Authorised"
        );
        _;
    }


    //// blackhole prevention methods / drain
    function drain() external onlyAllowed {
        payable(owner()).transfer(address(this).balance);
    }

    function retrieveERC20(address _tracker, uint256 amount) external onlyAllowed {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyAllowed {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}