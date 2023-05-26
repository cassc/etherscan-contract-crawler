// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721psi/contracts/extension/ERC721PsiAddressData.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Micropass is ERC721PsiAddressData, Ownable {
    using Strings for uint256;

    string private baseURI =
        "ipfs://bafybeiay2dwijkz456mavyblppb4hzcr5te42oo4kchrdjwkq5536kwbye/";

    uint128 public constant PRICE = 0.09 ether;
    uint64 public constant MAX_SUPPLY = 1100;
    bool public mintIsOpen = false;
    bool private uriExtension = true;

    constructor() ERC721Psi("MicroPass", "MP") {
        _safeMint(msg.sender, 100);
    }

    function price() public pure returns (uint128) {
        return PRICE;
    }

    function getUserData(
        address user
    ) external view returns (AddressData memory) {
        return _addressData[user];
    }

    function openMint() external onlyOwner {
        mintIsOpen = true;
    }

    function setUri(string memory _uri, bool _extension) external onlyOwner {
        baseURI = _uri;
        uriExtension = _extension;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string.concat(
                _baseURI(),
                tokenId.toString(),
                uriExtension ? ".json" : ""
            );
    }

    function mint() external payable {
        if (!mintIsOpen) {
            revert MintClose();
        }

        if (totalSupply() >= MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        if (_addressData[msg.sender].numberMinted > 0) {
            revert MintLimitReached(msg.sender);
        }

        if (msg.value < PRICE) {
            revert NotEnoughEther(PRICE, msg.value);
        }

        _safeMint(msg.sender, 1);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    function rescueERC20(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    error NotEnoughEther(uint256 required, uint256 sent);
    error MaxSupplyReached();
    error MintLimitReached(address user);
    error MintClose();
}