// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract DiamondHandsPass is ERC1155Supply, Ownable {

    uint256 constant TOKEN_ID = 1;
    uint256 constant RESERVED_MAX = 10;
    string constant public name = "DiamondHands Pass";
    string constant public symbol = "DHP";

    address public stakingAddress;
    address public royaltyAddress;

    uint96 private royaltyBasisPoints;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(string memory uri, address _stakingAddress) ERC1155(uri) {
        stakingAddress = _stakingAddress;
        royaltyBasisPoints = 500;
    }

    function mint(address recipient, uint256 quantity) external {
        require(msg.sender == stakingAddress, "UNAUTHORIZED");
        _mint(recipient, TOKEN_ID, quantity, "");
    }

    function reserve() external onlyOwner {
       _mint(msg.sender, TOKEN_ID, RESERVED_MAX, "");
    }

    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function setStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyRate(uint96 _royaltyBasisPoints) external onlyOwner {
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_tokenId == TOKEN_ID, "INVALID_TOKENID");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}