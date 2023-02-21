// SPDX-License-Identifier: MIT

/*

██╗░░██╗███████╗██╗░░░░░██╗░░░░░░█████╗░  ██╗░░░██╗░█████╗░██╗░░░██╗  ░█████╗░██╗░░░██╗███╗░░██╗████████╗
██║░░██║██╔════╝██║░░░░░██║░░░░░██╔══██╗  ╚██╗░██╔╝██╔══██╗██║░░░██║  ██╔══██╗██║░░░██║████╗░██║╚══██╔══╝
███████║█████╗░░██║░░░░░██║░░░░░██║░░██║  ░╚████╔╝░██║░░██║██║░░░██║  ██║░░╚═╝██║░░░██║██╔██╗██║░░░██║░░░
██╔══██║██╔══╝░░██║░░░░░██║░░░░░██║░░██║  ░░╚██╔╝░░██║░░██║██║░░░██║  ██║░░██╗██║░░░██║██║╚████║░░░██║░░░
██║░░██║███████╗███████╗███████╗╚█████╔╝  ░░░██║░░░╚█████╔╝╚██████╔╝  ╚█████╔╝╚██████╔╝██║░╚███║░░░██║░░░
╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝░╚════╝░  ░░░╚═╝░░░░╚════╝░░╚═════╝░  ░╚════╝░░╚═════╝░╚═╝░░╚══╝░░░╚═╝░░░

*/

pragma solidity ^0.8.17;

import "./ERC721/ERC721AQueryableWithOperatorFilterer.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error SenderIsNotTradingInsults(address sender);
error NoBalanceDue(address account);
error KingNotBurnable();

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256);
}

contract TradingInsultsPOI is ERC721A, IERC2981, Ownable {
    string private _baseTokenURI;
    uint256 private _royaltyBps;
    address private _treasury;
    address private _tradingInsults;

    constructor(
        string memory baseTokenURI,
        uint256 royaltyBps,
        address treasury
    ) ERC721A("TradingInsultPOI", "POI") {
        _baseTokenURI = baseTokenURI;
        _royaltyBps = royaltyBps;
        _treasury = treasury;

        _mint(msg.sender, 1); // King of the Hill
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setTradingInsults(address tradingInsults) external onlyOwner {
        _tradingInsults = tradingInsults;
    }

    function mint(address insulter, uint256 quantity) external {
        if (_tradingInsults != msg.sender)
            revert SenderIsNotTradingInsults(msg.sender);
        _safeMint(insulter, quantity);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function release() external {
        address payable owner = payable(owner());
        uint256 payment = address(this).balance;
        if (payment == 0) revert NoBalanceDue(owner);
        Address.sendValue(owner, payment);
    }

    function releaseERC20(IERC20 token) public {
        uint256 payment = token.balanceOf(address(this));
        if (payment == 0) revert NoBalanceDue(owner());
        token.transfer(owner(), payment);
    }

    function releaseERC721(IERC721 token, uint256 tokenId) public {
        if (address(this) != token.ownerOf(tokenId)) revert NoBalanceDue(owner());
        token.transferFrom(address(this), owner(), tokenId);
    }


    function getTradingInsultsAddress() external view returns (address) {
        return _tradingInsults;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        if (msg.sender == _tradingInsults) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function royaltyInfo(
        uint256, /* _tokenId */
        uint256 _salePrice
    ) external view override returns (address, uint256) {
        return (_treasury, ((_salePrice * _royaltyBps) / 10000));
    }

    function setRoyaltyBps(uint256 royaltyBps) external onlyOwner {
        _royaltyBps = royaltyBps;
    }

    function setTreasury(address treasury) external onlyOwner {
        _treasury = treasury;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721A)
        returns (bool)
    {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            ERC721A.supportsInterface(_interfaceId);
    }
}