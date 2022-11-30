// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC721 {
    function totalSupply() external returns(uint256);
    function currentTokenId() external view returns(uint256);
    function mint(address _to, uint256 _tokenId, string memory _hashs) external;
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint _tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
contract OpenBoxSLegend is Ownable {
    ERC1155Burnable public immutable box;
    address public immutable items721;
    address public signer;
    mapping(uint => bool) public nonces;
    mapping(uint => string[]) public itemsFlag; // group => flags, 0,1,2,3 => player; 4,5,6,7 => equip
    function setItemsFlag(uint index, string[] memory itemHash) external onlyOwner {
        itemsFlag[index] = itemHash;
    }
    mapping(address => bool) public isClaimed;
    constructor(ERC1155Burnable _box, address _items721, address _signer) {
        box = _box;
        items721 = _items721;
        signer = _signer;
    }
    function getMessageHash(address _user) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function permit(address _user, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return ecrecover(getEthSignedMessageHash(getMessageHash(_user)), v, r, s) == signer;
    }
    function claim(uint8 v, bytes32 r, bytes32 s) external {
        require(permit(_msgSender(), v, r, s), "OpenBoxSLegend::claim: Invalid signature");
        require(!isClaimed[_msgSender()], "OpenBoxSLegend::claim: user registered");
        box.safeTransferFrom(owner(), _msgSender(), 6, 1, '0x');
        isClaimed[_msgSender()] = true;

    }

    function random(uint nonce, uint percentDecimal) public view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)))%percentDecimal;
    }
    function randomHash(uint group, uint nonce, uint tokenId) internal {
        uint resultNumber = random(++nonce, 100);
        IERC721(items721).mint(_msgSender(), tokenId, itemsFlag[group][resultNumber]);
    }
    function handleOpen(uint nonce, uint tokenId) internal {
        uint resultNumber = random(nonce, 100);
        nonces[nonce] = true;
        if(resultNumber < 20) randomHash(0, nonce, tokenId);
        else if(resultNumber >= 20 && resultNumber < 50) randomHash(1, nonce, tokenId);
        else if(resultNumber >= 50 && resultNumber < 85) randomHash(2, nonce, tokenId);
        else if(resultNumber >= 85 && resultNumber < 95) randomHash(3, nonce, tokenId);
        else randomHash(4, nonce, tokenId);
    }
    function claimAndOpen(uint nonce, uint8 v, bytes32 r, bytes32 s) external {
        require(permit(_msgSender(), v, r, s), "OpenBoxSLegend::claim: Invalid signature");
        require(!isClaimed[_msgSender()], "OpenBoxSLegend::claim: user registered");
        uint tokenId = IERC721(items721).currentTokenId();
        handleOpen(nonce, tokenId+1);

        isClaimed[_msgSender()] = true;

    }
    function open(uint nonce, uint[] memory tokenIds, uint[] memory amounts) public {
        require(!nonces[nonce], "OpenBoxSLegend::open: nonce used");
        require(tokenIds.length == 1 && amounts.length == 1 && tokenIds[0] == 6, "OpenBoxSLegend::open: invalid token ids");
        uint balanceOf = box.balanceOf(_msgSender(), 6);
        require(amounts[0] > 0 && amounts[0] <= 100 && amounts[0] <= balanceOf, "OpenBoxSLegend::open: amount invalid");
        box.burnBatch(_msgSender(), tokenIds, amounts);
        uint tokenId = IERC721(items721).currentTokenId();
        for(uint i = 0; i < amounts[0]; i++) {
            handleOpen(nonce+i, tokenId+1+i);
        }

    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
    }
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
}