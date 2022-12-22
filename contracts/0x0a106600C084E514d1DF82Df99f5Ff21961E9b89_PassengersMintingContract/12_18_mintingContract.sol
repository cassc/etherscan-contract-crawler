//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721AUpgradeable} from "./utils/ERC721AUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableOperatorFiltererUpgradeable.sol";
import {RevokableDefaultOperatorFiltererUpgradeable} from "./OpenseaRegistries/RevokableDefaultOperatorFiltererUpgradeable.sol";
import {UpdatableOperatorFilterer} from "./OpenseaRegistries/UpdatableOperatorFilterer.sol";

contract PassengersMintingContract is OwnableUpgradeable, ERC721AUpgradeable, RevokableDefaultOperatorFiltererUpgradeable {

    mapping (address => bool) public isController;
    string public baseURI;

    modifier onlyController() {
        require(isController[msg.sender], "Not a controller");
        _;
    }

    function initialize() public initializer {
        __Ownable_init();
        __ERC721A_init("Passengers_Minting_Contract", "PASSENGERS");
    }

    function addController (address _controller) external onlyOwner {
        isController[_controller] = true;
    }

    function removeController (address _controller) external onlyOwner {
        isController[_controller] = false;
    }

    function mint(address _to, uint256 _amount) external onlyController {
            _mint(_to, _amount);
    }

    function burn(uint256 _tokenId) external {
        require (ownerOf(_tokenId) == msg.sender, "You are not the owner of this token");
        _burn(_tokenId);
    }

    function controllerBurn(uint256 _tokenId) external onlyController {
        _burn(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(bytes(baseURI_).length > 0, "Invalid Base URI Provided");
        baseURI = baseURI_;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner()
    public
    view
    virtual
    override (OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
    returns (address)
    {
        return OwnableUpgradeable.owner();
    }

}