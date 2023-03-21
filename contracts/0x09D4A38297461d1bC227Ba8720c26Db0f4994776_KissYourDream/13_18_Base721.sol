pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Base721 is ERC721AQueryable, Ownable {
    uint256 public maxSupply;

    string public defaultURI;

    string public baseURI;

    mapping(uint256 => bool) public blackList;

    using SafeERC20 for IERC20;

    using Strings for uint256;

    function adminMint(uint256 _num) external onlyOwner {
        require(totalSupply() + _num <= maxSupply, "Must lower than maxSupply");
        _mint(_msgSender(), _num);
    }

    function withdrawETH(address payable _to) external onlyOwner {
        (bool success, ) = _to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(address _erc20, address _to) external onlyOwner {
        IERC20(_erc20).safeTransfer(
            _to,
            IERC20(_erc20).balanceOf(address(this))
        );
    }

    function withdrawERC721(
        address _erc721,
        address _to,
        uint256[] calldata _tokenIds
    ) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721A(_erc721).transferFrom(address(this), _to, _tokenIds[i]);
        }
    }

    function withdrawERC1155(
        address _erc1155,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external onlyOwner {
        IERC1155(_erc1155).safeBatchTransferFrom(
            address(this),
            _to,
            _ids,
            _amounts,
            _data
        );
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        for (uint256 i = startTokenId; i < startTokenId + quantity; i++) {
            require(!blackList[i], "In blacklist");
        }
    }

    function setBlackList(
        uint256[] calldata _blackList,
        bool _status
    ) external onlyOwner {
        for (uint256 i = 0; i < _blackList.length; i++) {
            blackList[_blackList[i]] = _status;
        }
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory imageURI = bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _tokenId.toString()))
            : defaultURI;

        return imageURI;
    }
}