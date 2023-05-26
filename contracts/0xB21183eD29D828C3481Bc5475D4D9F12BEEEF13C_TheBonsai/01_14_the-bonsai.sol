// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheBonsai is AccessControl, ERC721, Ownable, Pausable {
    using Strings for uint256;

    bytes32 public constant ADMIN = "ADMIN";
    string public baseURI;
    string public baseExtension;
    uint256 public totalSupply = 0;
    address public withdrawAddress;

    // Constructor
    constructor() ERC721("TheBonsai", "BONSAI") {
        grantRole(ADMIN, msg.sender);
    }

    // Event
    event Donate(address _address, uint256 _value);

    // Modifier
    modifier shouldPay() {
        require(msg.value > 0, 'Payment is required');
        _;
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // Pausable
    function pause() external onlyRole(ADMIN) {
        _pause();
    }
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    // Setter
    function setWithdrawAddress(address _value) public onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyRole(ADMIN) {
        baseExtension = "";
    }

    // Mint / Donate
    function airdrop(address[] calldata addresses) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (balanceOf(addresses[i]) == 0) {
                _mintCommon(addresses[i]);
            }
        }
    }
    function mint() external payable
        whenNotPaused
        shouldPay()
    {
        require(balanceOf(msg.sender) == 0, 'Already Owner');
        _mintCommon(msg.sender);
        emit Donate(msg.sender, msg.value);
    }
    function donate() external payable
        whenNotPaused
        shouldPay()
    {
        require(balanceOf(msg.sender) > 0, 'Not Owner');
        emit Donate(msg.sender, msg.value);
    }


    function _mintCommon(address mintTo) private {
        uint256 tokenId = totalSupply + 1;
        _mint(mintTo, tokenId);
        totalSupply++;
    }


    // ERC721
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension));
    }
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }
    function withdraw() public payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // SBT
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT.");
    }
    function approve(address, uint256) public virtual override {
        revert("This token is SBT.");
    }
    function _beforeTokenTransfer(address from, address to, uint256) internal virtual override {
        require(from == address(0) || to == address(0), "This token is SBT");
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}