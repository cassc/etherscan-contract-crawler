// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DAO721 is
    ERC1155,
    ERC1155Supply,
    ERC1155Pausable,
    ERC1155Burnable,
    Ownable
{
    using Strings for uint256;

    string public constant name = "721DAO";
    string public constant symbol = "721DAO";
    uint256 public constant tokenId = 0;

    bool public saleIsActive = false;
    string public contractURI =
        "https://infura-ipfs.io/ipfs/QmQNNfgRqyeZssyC3h7UjATj9qDUPbVjLTbhE1Xhi26pxb?filename=contract.json";
    address public treasury = 0xd06a5d3baE616FdAf9fd0fe9DcdD14B2aa097155;
    uint256 public maxSupply = 10000;
    uint256 public maxAmountPerMint = 10;
    uint256 public price = 0.1 ether;
    uint256 public round = 0;
    IERC721Enumerable public club721;
    mapping(uint256 => mapping(uint256 => bool)) public usedToken;

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155, ERC1155Supply) {
        super._burnBatch(account, ids, amounts);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override(ERC1155, ERC1155Supply) {
        super._burn(account, id, amount);
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._mint(account, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._mintBatch(to, ids, amounts, data);
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return super.uri(_tokenId);
    }

    function totalSupply() external pure returns (uint256) {
        return tokenId + 1;
    }

    function listClub721Tokens(address target)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count = club721.balanceOf(target);
        uint256[] memory array = new uint256[](count);
        for (uint256 i = 0; i < count && i < 50; i++) {
            array[i] = club721.tokenOfOwnerByIndex(target, i);
        }
        return array;
    }

    constructor(IERC721Enumerable _club721)
        ERC1155(
            "https://infura-ipfs.io/ipfs/QmVdtZR3SdzkKC7RNpVcLNLbWCRzroiiMERE1Qk5yP3NVT?filename=token.json"
        )
    {
        club721 = _club721;
    }

    function quickMint(uint256 _amount) external payable {
        uint256 count = club721.balanceOf(msg.sender);
        require(count > 0, "DAO721: should own at least one club721 token.");
        for (uint256 i = 0; i < count && i < 30; i++) {
            uint256 _club721TokenId = club721.tokenOfOwnerByIndex(
                msg.sender,
                i
            );
            if (!usedToken[round][_club721TokenId]) {
                mint(_club721TokenId, _amount);
                return;
            }
        }
        revert("DAO721: all club721 tokens used.");
    }

    function mint(uint256 _club721TokenId, uint256 _amount) public payable {
        require(saleIsActive, "DAO721: Cannot mint now.");
        require(
            _amount >= 1 && _amount <= maxAmountPerMint,
            "DAO721: Invalid amount."
        );
        require(
            super.totalSupply(tokenId) + _amount <= maxSupply,
            "DAO721: supply reached limit."
        );
        require(
            !usedToken[round][_club721TokenId],
            "DAO721: Club721 token used."
        );
        require(
            club721.ownerOf(_club721TokenId) == msg.sender,
            "DAO721: Not own club token."
        );
        require(_amount * price == msg.value, "DAO721: Incorrect ethers.");

        usedToken[round][_club721TokenId] = true;
        _mint(msg.sender, tokenId, _amount, "");
        if (treasury != address(0)) {
            payable(treasury).transfer(address(this).balance);
        }
    }

    function doCall(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0), "DAO721: nil address");
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success, "DAO721: doCall fail.");
        return _result;
    }

    function batchAll(
        address[] calldata _targets,
        uint256 _value,
        bytes calldata _payload
    ) external payable onlyOwner {
        require(_targets.length > 0, "DAO721: _targets.length = 0");
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = payable(_targets[i]).call{
                value: _value
            }(_payload);
            require(_success, "DAO721: batchAll fail.");
            _response;
        }
    }

    function ownerBurn(address account, uint256 amount) external onlyOwner {
        _burn(account, tokenId, amount);
    }

    function ownerMint(address account, uint256 amount) external onlyOwner {
        _mint(account, tokenId, amount, "");
    }

    function ownerMintBatch(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(
            accounts.length == amounts.length,
            "DAO721: accounts and amounts length mismatch"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], tokenId, amounts[i], "");
        }
    }

    function ownerMintTokens(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function setClub721(IERC721Enumerable _club721) external onlyOwner {
        club721 = _club721;
    }

    function setMaxAmountPerMint(uint256 _maxAmountPerMint) external onlyOwner {
        maxAmountPerMint = _maxAmountPerMint;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setRound(uint256 _round) external onlyOwner {
        round = _round;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    function setURI(string memory uri_) external onlyOwner {
        _setURI(uri_);
    }

    function setContractURI(string calldata _uri) external onlyOwner {
        contractURI = _uri;
    }

    function setSaleState(bool newState) external onlyOwner {
        saleIsActive = newState;
        if (newState) {
            if (paused()) {
                _unpause();
            }
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw(address to) external onlyOwner {
        if (to == address(0)) {
            to = msg.sender;
        }
        payable(to).transfer(address(this).balance);
    }
}